import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import 'api_service.dart';

class TelemetryProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  final google_auth.GoogleSignIn _googleSignIn =
      google_auth.GoogleSignIn.instance;
  static const MethodChannel _channel = MethodChannel(
    'com.ate.telemetry/channel',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.ate.telemetry/events',
  );

  // Core metrics
  double _fragmentationScore = 0.0;
  double _focusScore = 100.0;
  String _currentContext = "Unknown";
  int _nearbyPeers = 0;
  final Map<String, String> _nearbyDevices = {};
  final Map<String, DateTime> _peerFoundTimestamps =
      {}; // Track when each peer was first detected
  int? _userId;
  final Set<String> _closeFriends = {}; // Device IDs of close friends

  // Notification interaction tracking
  // Key: package, Value: {postTimeMs, title, text}
  final Map<String, Map<String, dynamic>> _pendingNotifications = {};

  // App switch tracking
  String? _lastForegroundApp;
  DateTime? _lastAppSwitchTime;

  // Local app usage accumulation (cleared after each analysis poll if desired)
  final Map<String, int> _appUsageStats = {};

  // Total daily usage pulled directly from OS UsageStatsManager
  final Map<String, int> _totalDailyUsage = {};

  // Notification log for UI display
  final List<Map<String, dynamic>> _notificationLog = [];

  bool _notificationEnabled = false;
  bool _usageEnabled = false;

  // Configuration weights from Backend
  double _spatialWeight = 0.3;
  double _socialWeight = 0.3;
  double _digitalWeight = 0.4;
  bool _isLoadingSettings = false;

  // Privacy Log tracking transmissions
  final List<String> _privacyLogs = [];

  TelemetryProvider(this.prefs) {
    _notificationEnabled = prefs.getBool('notification_enabled') ?? false;
    _usageEnabled = prefs.getBool('usage_enabled') ?? false;
    _userId = prefs.getInt('registered_user_id');
  }

  double get fragmentationScore => _fragmentationScore;
  double get focusScore => _focusScore;
  String get currentContext => _currentContext;
  int get nearbyPeers => _nearbyPeers;
  int? get userId => _userId;
  List<String> get connectedPeers => _nearbyDevices.values.toList();
  Map<String, String> get nearbyDevicesMap => Map.unmodifiable(_nearbyDevices);
  Set<String> get closeFriends => Set.unmodifiable(_closeFriends);
  List<String> get privacyLogs => _privacyLogs;
  List<Map<String, dynamic>> get notificationLog => _notificationLog;
  Map<String, int> get appUsageStats => Map.unmodifiable(_appUsageStats);
  Map<String, int> get totalDailyUsage => Map.unmodifiable(_totalDailyUsage);
  bool get notificationEnabled => _notificationEnabled;
  bool get usageEnabled => _usageEnabled;

  double get spatialWeight => _spatialWeight;
  double get socialWeight => _socialWeight;
  double get digitalWeight => _digitalWeight;
  bool get isLoadingSettings => _isLoadingSettings;

  bool isFriend(String deviceId) => _closeFriends.contains(deviceId);

  Future<void> addFriend(String peerDeviceId) async {
    if (_userId == null) return;
    final ok = await ApiService.addFriend(_userId!, peerDeviceId);
    if (ok) {
      _closeFriends.add(peerDeviceId);
      _addLog("FRIEND_ADD | $peerDeviceId added as close friend");
      notifyListeners();
    }
  }

  Future<void> removeFriend(String peerDeviceId) async {
    if (_userId == null) return;
    final ok = await ApiService.removeFriend(_userId!, peerDeviceId);
    if (ok) {
      _closeFriends.remove(peerDeviceId);
      _addLog("FRIEND_REM | $peerDeviceId removed from close friends");
      notifyListeners();
    }
  }

  Future<void> _loadFriends() async {
    if (_userId == null) return;
    final friends = await ApiService.getFriends(_userId!);
    _closeFriends.clear();
    _closeFriends.addAll(friends);
  }

  void setNotificationEnabled(bool value) {
    _notificationEnabled = value;
    prefs.setBool('notification_enabled', value);
    notifyListeners();
  }

  void setUsageEnabled(bool value) {
    _usageEnabled = value;
    prefs.setBool('usage_enabled', value);
    notifyListeners();
  }

  Future<void> fetchTotalDailyUsage() async {
    if (!Platform.isAndroid || !_usageEnabled) return;

    try {
      final dynamic result = await _channel.invokeMethod('getDailyUsage');
      if (result != null && result is Map) {
        _totalDailyUsage.clear();
        result.forEach((key, value) {
          if (value is int) {
            _totalDailyUsage[key.toString()] = value; // seconds
          } else if (value is num) {
            _totalDailyUsage[key.toString()] = value.toInt(); // seconds
          }
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to fetch absolute daily usage: $e");
    }
  }

  Future<void> requestUsagePermission() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('requestUsagePermission');
        setUsageEnabled(true);
      } catch (e) {
        debugPrint("Failed to request usage permission: $e");
      }
    }
  }

  // ── Settings API Interfacing ──

  Future<void> fetchSettings() async {
    if (_userId == null) return;
    _isLoadingSettings = true;
    notifyListeners();

    final settings = await ApiService.getSettings(_userId!);
    if (settings != null) {
      _spatialWeight = (settings['weight_spatial'] as num).toDouble();
      _socialWeight = (settings['weight_social'] as num).toDouble();
      _digitalWeight = (settings['weight_digital'] as num).toDouble();
    }

    _isLoadingSettings = false;
    notifyListeners();
  }

  Future<bool> saveSettings(double sLoc, double sSoc, double sDig) async {
    if (_userId == null) return false;
    _isLoadingSettings = true;
    notifyListeners();

    final success = await ApiService.updateSettings(_userId!, sLoc, sSoc, sDig);
    if (success) {
      _spatialWeight = sLoc;
      _socialWeight = sSoc;
      _digitalWeight = sDig;
    }

    _isLoadingSettings = false;
    notifyListeners();
    return success;
  }

  void _addLog(String log) {
    final timeStr = DateTime.now()
        .toIso8601String()
        .split('T')[1]
        .substring(0, 8);
    _privacyLogs.insert(0, "[$timeStr] $log");
    if (_privacyLogs.length > 100) _privacyLogs.removeLast();
  }

  void resetAppUsageStats() {
    _appUsageStats.clear();
    notifyListeners();
  }

  Future<void> initialize() async {
    await _googleSignIn.initialize(
      serverClientId:
          '899997490172-8o2ue35fs7hkm2tsp82founi8k23rb53.apps.googleusercontent.com',
    );

    // If not authenticated, we should wait until user authenticates.
    // So if _userId == null, we don't start native telemetry yet.
    if (_userId != null) {
      await _startAppEngine();
    }
  }

  Future<bool> authenticateWithGoogle() async {
    try {
      final account = await _googleSignIn.authenticate();
      final deviceId = 'device_${account.id}';
      final firebaseUid = account.id; // Passing Google Auth ID as firebase UID

      final registeredId = await ApiService.registerDevice(
        deviceId,
        firebaseUid: firebaseUid,
      );

      if (registeredId != null) {
        _userId = registeredId;
        await prefs.setInt('registered_user_id', _userId!);

        await _startAppEngine();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
    }
    return false;
  }

  Future<void> _startAppEngine() async {
    // Load close friends list from server
    await _loadFriends();

    // Load custom weights
    await fetchSettings();

    if (Platform.isAndroid) {
      _startNativeTelemetry();
      _listenToEvents();
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _userId = null;
    await prefs.remove('registered_user_id');
    notifyListeners();
  }

  void _listenToEvents() {
    _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      if (_userId == null) return;

      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      final String type = map['type'] as String;
      final Map<dynamic, dynamic> data = map['data'] as Map<dynamic, dynamic>;

      debugPrint("Received native event: $type");

      switch (type) {
        case 'notification_posted':
          _fragmentationScore = (_fragmentationScore + 0.05).clamp(0.0, 1.0);
          final notifPkg = data['package'] ?? 'unknown';
          final postTimeMs =
              data['post_time'] ?? DateTime.now().millisecondsSinceEpoch;
          _pendingNotifications[notifPkg] = {
            'postTimeMs': postTimeMs,
            'title': data['title'] ?? '',
            'text': data['text'] ?? '',
          };
          // Add to notification UI log
          _notificationLog.insert(0, {
            'package': notifPkg,
            'title': data['title'] ?? '',
            'text': data['text'] ?? '',
            'time': DateTime.now().toIso8601String(),
            'status': 'pending', // pending, dismissed, clicked
          });
          // Keep only last 100 notifications
          if (_notificationLog.length > 100) {
            _notificationLog.removeRange(100, _notificationLog.length);
          }
          _addLog("NOTIF_RECV | From: $notifPkg | ${data['title']}");
          _cleanExpiredNotifications();
          notifyListeners();
          break;

        case 'notification_removed':
          final removedPkg = data['package'] ?? 'unknown';
          _pendingNotifications.remove(removedPkg);
          // Mark as dismissed in UI log
          for (final entry in _notificationLog) {
            if (entry['package'] == removedPkg &&
                entry['status'] == 'pending') {
              entry['status'] = 'dismissed';
              break;
            }
          }
          _addLog("NOTIF_DISMISS | $removedPkg dismissed (ignored by scoring)");
          notifyListeners();
          break;

        case 'location_update':
          _currentContext =
              "Geofenced: ${data['lat'].toStringAsFixed(2)}, ${data['lng'].toStringAsFixed(2)}";
          ApiService.sendTelemetry('location', {
            'user_id': _userId,
            'lat': data['lat'],
            'lng': data['lng'],
          });
          _addLog(
            "LOC_SENT | To: /location | Lat: ${data['lat'].toStringAsFixed(4)}, Lng: ${data['lng'].toStringAsFixed(4)}",
          );
          notifyListeners();
          break;

        case 'peer_found':
          final endpointId = data['endpointId'] ?? 'unknown_id';
          final peerName = data['name'] ?? 'Unknown';
          if (!_nearbyDevices.containsKey(endpointId)) {
            _nearbyPeers++;
            _peerFoundTimestamps[endpointId] = DateTime.now();
          }
          _nearbyDevices[endpointId] = peerName;
          ApiService.sendTelemetry('proximity', {
            'user_id': _userId,
            'nearby_peers': _nearbyPeers,
            'peer_name': peerName,
          });
          _addLog(
            "PROX_SENT | To: /proximity | Found Peer: $peerName | Count: $_nearbyPeers",
          );
          notifyListeners();
          break;

        case 'peer_lost':
          final endpointId = data['endpointId'] ?? 'unknown_id';
          if (_nearbyDevices.containsKey(endpointId)) {
            final foundAt = _peerFoundTimestamps[endpointId];
            if (foundAt != null) {
              final durationSeconds = DateTime.now()
                  .difference(foundAt)
                  .inSeconds;
              _peerFoundTimestamps.remove(endpointId);
              if (durationSeconds > 60) {
                ApiService.sendTelemetry('engagement', {
                  'user_id': _userId,
                  'peer_device_id': endpointId,
                  'engagement_duration_seconds': durationSeconds.toDouble(),
                });
                _addLog(
                  "ENG_SENT | To: /engagement | Peer: $endpointId | Duration: ${durationSeconds}s",
                );
              }
            }
            _nearbyDevices.remove(endpointId);
            if (_nearbyPeers > 0) _nearbyPeers--;
          }
          ApiService.sendTelemetry('proximity', {
            'user_id': _userId,
            'nearby_peers': _nearbyPeers,
          });
          _addLog("PROX_SENT | To: /proximity | Nearby Peers: $_nearbyPeers");
          notifyListeners();
          break;

        case 'app_usage':
          final pkg = data['package'] ?? 'unknown';

          // Detect app switch
          double? switchTimeSecs;
          final prevApp = _lastForegroundApp;
          if (_lastForegroundApp != null && _lastForegroundApp != pkg) {
            // App changed! Calculate time since last switch
            if (_lastAppSwitchTime != null) {
              switchTimeSecs =
                  DateTime.now()
                      .difference(_lastAppSwitchTime!)
                      .inMilliseconds /
                  1000.0;
            }
            _lastAppSwitchTime = DateTime.now();
          } else if (_lastForegroundApp == null) {
            _lastAppSwitchTime = DateTime.now();
          }
          _lastForegroundApp = pkg;

          // Locally accumulate for the dashboard
          _appUsageStats[pkg] = (_appUsageStats[pkg] ?? 0) + 10;

          ApiService.sendTelemetry('digital', {
            'user_id': _userId,
            'package': pkg,
            'duration': 10000, // 10 second blocks
            if (prevApp != null && prevApp != pkg) 'prev_package': prevApp,
            if (switchTimeSecs != null) 'switch_time_seconds': switchTimeSecs,
          });
          _addLog(
            "USG_SENT | To: /digital | Foreground: $pkg${switchTimeSecs != null ? ' | Switch: ${switchTimeSecs.toStringAsFixed(1)}s' : ''}",
          );

          // Check if foreground app matches a pending notification → user clicked it!
          if (_pendingNotifications.containsKey(pkg)) {
            final notifData = _pendingNotifications.remove(pkg)!;
            final postTimeMs = notifData['postTimeMs'] as int;
            final responseTimeSeconds =
                (DateTime.now().millisecondsSinceEpoch - postTimeMs) / 1000.0;
            final content = '${notifData['title']} ${notifData['text']}';
            ApiService.sendNotification(
              _userId ?? 0,
              pkg,
              content,
              responseTimeSeconds: responseTimeSeconds,
            );
            // Mark as clicked in UI log
            for (final entry in _notificationLog) {
              if (entry['package'] == pkg && entry['status'] == 'pending') {
                entry['status'] = 'clicked';
                entry['response_time'] = responseTimeSeconds;
                break;
              }
            }
            _addLog(
              "NOTIF_CLICK | $pkg | response: ${responseTimeSeconds.toStringAsFixed(1)}s",
            );
          }

          notifyListeners();
          break;
      }
    });
  }

  /// Remove pending notifications older than 5 minutes (expired = ignored)
  void _cleanExpiredNotifications() {
    final now = DateTime.now().millisecondsSinceEpoch;
    const expiryMs = 5 * 60 * 1000; // 5 minutes
    _pendingNotifications.removeWhere((_, data) {
      final postTimeMs = data['postTimeMs'] as int;
      return (now - postTimeMs) > expiryMs;
    });
  }

  Future<void> _startNativeTelemetry() async {
    try {
      final name = _googleSignIn.currentUser?.displayName ?? '';
      final result = await _channel.invokeMethod('startTelemetry', {'userName': name});
      debugPrint("Native telemetry status: $result");
    } on PlatformException catch (e) {
      debugPrint("Failed to start telemetry: '${e.message}'.");
    }
  }

  // Simulated update for the dashboard preview
  void updateMetrics(double frag, double focus, String context, int peers) {
    _fragmentationScore = frag;
    _focusScore = focus;
    _currentContext = context;
    _nearbyPeers = peers;

    // Simulate finding a peer for testing if none exist
    if (peers > 0 && _nearbyDevices.isEmpty) {
      _nearbyDevices['test_device_1'] = 'Galaxy M35 (Test)';
    } else if (peers == 0) {
      _nearbyDevices.clear();
    }

    notifyListeners();
  }
}
