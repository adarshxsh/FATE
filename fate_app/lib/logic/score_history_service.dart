import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'package:http/http.dart' as http;

/// Polls the server every 5 minutes for a fresh CAS snapshot.
/// Stores snapshots locally. At end of day, compresses into daily average.
/// After 7 daily averages, compresses into a weekly average.
///
/// Storage format in SharedPreferences:
///   "score_snapshots"  → List of 5-min snapshots for TODAY
///   "score_daily"      → List of daily averages (last 7 days)
///   "score_weekly"     → List of weekly averages (last 4 weeks)
class ScoreHistoryService extends ChangeNotifier {
  final SharedPreferences prefs;
  int? userId;
  Timer? _pollTimer;

  // Countdown timer state
  int secondsUntilNextAnalysis = 300; // 5 minutes

  // In-memory state
  List<Map<String, dynamic>> _todaySnapshots = [];
  List<Map<String, dynamic>> _dailyAverages = [];
  List<Map<String, dynamic>> _weeklyAverages = [];

  // Latest snapshot
  double currentCAS = 50.0;
  double currentSLoc = 0.0;
  double currentSSoc = 0.0;
  double currentSDig = 0.0;

  // Server-pushed insight notifications
  List<Map<String, dynamic>> _serverNotifications = [];

  ScoreHistoryService({required this.prefs, this.userId}) {
    _loadFromDisk();
  }

  void updateUserId(int? newId) {
    if (userId != newId) {
      userId = newId;
      notifyListeners();
      if (userId != null && _pollTimer == null) {
        startPolling();
      }
    }
  }

  List<Map<String, dynamic>> get todaySnapshots => _todaySnapshots;
  List<Map<String, dynamic>> get dailyAverages => _dailyAverages;
  List<Map<String, dynamic>> get weeklyAverages => _weeklyAverages;
  List<Map<String, dynamic>> get serverNotifications => _serverNotifications;

  /// Start the 5-minute polling loop with a 1-second countdown tick
  void startPolling() {
    // Immediately fetch once
    fetchAndStore(isBackground: false);

    // Then tick every 1 second
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsUntilNextAnalysis > 0) {
        secondsUntilNextAnalysis--;
        notifyListeners();
      } else {
        // Time to fetch!
        fetchAndStore(isBackground: false);
      }
    });
    debugPrint("[ScoreHistory] Polling countdown started");
  }

  /// Manually trigger analysis right now
  void triggerManualAnalysis() {
    debugPrint("[ScoreHistory] Manual analysis triggered");
    fetchAndStore(isBackground: false);
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Fetch fresh CAS from server, store locally, and reset timer
  Future<void> fetchAndStore({bool isBackground = true}) async {
    if (userId == null) return;

    // Reset timer back to 5 minutes
    secondsUntilNextAnalysis = 300;
    notifyListeners();

    try {
      final serverBase = ApiService.baseUrl.replaceAll('/api/ingest', '');
      final url = Uri.parse('$serverBase/api/analysis/$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        currentCAS = (data['CAS'] as num).toDouble();
        currentSLoc = (data['S_loc'] as num).toDouble();
        currentSSoc = (data['S_soc'] as num).toDouble();
        currentSDig = (data['S_dig'] as num).toDouble();

        final snapshot = {
          'ts': DateTime.now().toIso8601String(),
          'CAS': currentCAS,
          'S_loc': currentSLoc,
          'S_soc': currentSSoc,
          'S_dig': currentSDig,
        };

        _todaySnapshots.add(snapshot);

        // Limit to max 10 effectively
        if (_todaySnapshots.length > 10) {
          _todaySnapshots = _todaySnapshots.sublist(
            _todaySnapshots.length - 10,
          );
        }

        // Store server-pushed insight notifications
        final notifications = data['notifications'] as List<dynamic>?;
        if (notifications != null && notifications.isNotEmpty) {
          for (final n in notifications) {
            _serverNotifications.insert(0, {
              'type': n['type'] ?? 'info',
              'title': n['title'] ?? '',
              'body': n['body'] ?? '',
              'icon': n['icon'] ?? 'info',
              'time': DateTime.now().toIso8601String(),
              'cas': currentCAS,
            });
          }
          // Keep only last 50 notifications
          if (_serverNotifications.length > 50) {
            _serverNotifications = _serverNotifications.sublist(0, 50);
          }
        }

        _saveToDisk();
        _maybeRollover();
        notifyListeners();

        debugPrint(
          "[ScoreHistory] CAS=$currentCAS stored (${_todaySnapshots.length} snapshots, ${_serverNotifications.length} notifs)",
        );

        String? latestInsight;
        if (_serverNotifications.isNotEmpty) {
          latestInsight = _serverNotifications.first['body'];
        }
        await LocalNotificationService.initialize(); // Ensure initialized
        await LocalNotificationService.showAnalysisNotification(
          currentCAS,
          insight: latestInsight,
        );

        _maybeGarbageCollect();
      }
    } catch (e) {
      debugPrint("[ScoreHistory] Fetch failed: $e");
    }
  }

  /// Check if we need to roll yesterday's snapshots into a daily average
  void _maybeRollover() {
    if (_todaySnapshots.isEmpty) return;

    final firstTs = DateTime.parse(_todaySnapshots.first['ts']);
    final now = DateTime.now();

    // If the first snapshot is from a previous day, compress and roll over
    if (firstTs.day != now.day ||
        firstTs.month != now.month ||
        firstTs.year != now.year) {
      _compressDayIntoDaily();
    }

    // If we have 7+ daily averages, compress the oldest 7 into a weekly
    if (_dailyAverages.length >= 7) {
      _compressWeekIntoWeekly();
    }
  }

  void _compressDayIntoDaily() {
    if (_todaySnapshots.isEmpty) return;

    final avg = _averageSnapshots(_todaySnapshots);
    avg['date'] = _todaySnapshots.first['ts'].toString().substring(0, 10);

    _dailyAverages.insert(0, avg);

    // Keep only 10 daily records
    if (_dailyAverages.length > 10) {
      _dailyAverages = _dailyAverages.sublist(0, 10);
    }

    // Clear today's snapshots for the new day
    _todaySnapshots.clear();
    _saveToDisk();

    debugPrint("[ScoreHistory] Day rolled over → daily avg CAS=${avg['CAS']}");
  }

  void _compressWeekIntoWeekly() {
    if (_dailyAverages.length < 7) return;

    // Take the oldest 7 daily averages
    final weekSlice = _dailyAverages.sublist(_dailyAverages.length - 7);
    final weekAvg = _averageSnapshots(weekSlice);
    weekAvg['week_ending'] = weekSlice.first['date'];

    _weeklyAverages.insert(0, weekAvg);

    // Keep only 10 weekly records
    if (_weeklyAverages.length > 10) {
      _weeklyAverages = _weeklyAverages.sublist(0, 10);
    }

    // Remove the compressed daily records
    _dailyAverages = _dailyAverages.sublist(0, _dailyAverages.length - 7);
    _saveToDisk();

    debugPrint(
      "[ScoreHistory] Week rolled over → weekly avg CAS=${weekAvg['CAS']}",
    );
  }

  Map<String, dynamic> _averageSnapshots(List<Map<String, dynamic>> snapshots) {
    if (snapshots.isEmpty)
      return {'CAS': 0, 'S_loc': 0, 'S_soc': 0, 'S_dig': 0};

    double cas = 0, sLoc = 0, sSoc = 0, sDig = 0;
    for (final s in snapshots) {
      cas += (s['CAS'] as num).toDouble();
      sLoc += (s['S_loc'] as num).toDouble();
      sSoc += (s['S_soc'] as num).toDouble();
      sDig += (s['S_dig'] as num).toDouble();
    }
    final n = snapshots.length;
    return {
      'CAS': double.parse((cas / n).toStringAsFixed(2)),
      'S_loc': double.parse((sLoc / n).toStringAsFixed(2)),
      'S_soc': double.parse((sSoc / n).toStringAsFixed(2)),
      'S_dig': double.parse((sDig / n).toStringAsFixed(2)),
    };
  }

  /// Trigger server GC once per day
  void _maybeGarbageCollect() async {
    final lastGc = prefs.getString('last_gc_date');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastGc != today && userId != null) {
      try {
        final serverBase = ApiService.baseUrl.replaceAll('/api/ingest', '');
        final url = Uri.parse('$serverBase/api/gc/$userId');
        await http.post(url);
        prefs.setString('last_gc_date', today);
        debugPrint("[ScoreHistory] Server GC triggered for today");
      } catch (e) {
        debugPrint("[ScoreHistory] GC failed: $e");
      }
    }
  }

  // ─── Persistence ───

  void _saveToDisk() {
    prefs.setString('score_snapshots', jsonEncode(_todaySnapshots));
    prefs.setString('score_daily', jsonEncode(_dailyAverages));
    prefs.setString('score_weekly', jsonEncode(_weeklyAverages));
    prefs.setString('score_notifs', jsonEncode(_serverNotifications));
  }

  void _loadFromDisk() {
    final snapJson = prefs.getString('score_snapshots');
    final dailyJson = prefs.getString('score_daily');
    final weeklyJson = prefs.getString('score_weekly');

    if (snapJson != null) {
      _todaySnapshots = List<Map<String, dynamic>>.from(
        jsonDecode(snapJson).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    if (dailyJson != null) {
      _dailyAverages = List<Map<String, dynamic>>.from(
        jsonDecode(dailyJson).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    if (weeklyJson != null) {
      _weeklyAverages = List<Map<String, dynamic>>.from(
        jsonDecode(weeklyJson).map((e) => Map<String, dynamic>.from(e)),
      );
    }

    final notifsJson = prefs.getString('score_notifs');
    if (notifsJson != null) {
      _serverNotifications = List<Map<String, dynamic>>.from(
        jsonDecode(notifsJson).map((e) => Map<String, dynamic>.from(e)),
      );
    }

    // Restore latest CAS if we have snapshots
    if (_todaySnapshots.isNotEmpty) {
      final last = _todaySnapshots.last;
      currentCAS = (last['CAS'] as num).toDouble();
      currentSLoc = (last['S_loc'] as num).toDouble();
      currentSSoc = (last['S_soc'] as num).toDouble();
      currentSDig = (last['S_dig'] as num).toDouble();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
