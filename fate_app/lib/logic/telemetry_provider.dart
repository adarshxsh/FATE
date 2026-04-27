import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import 'api_service.dart';
import 'notification_service.dart';
import 'secure_db_service.dart';
import 'scoring_engine.dart';

class TelemetryProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  final SecureDbService _db = SecureDbService();

  // Using the singleton pattern that seems to be required by the local package/setup
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
  double _sLoc = 0.0;
  double _sSoc = 0.0;
  double _sDig = 0.0;
  String _currentContext = "Unknown";
  int _nearbyPeers = 0;
  final Map<String, String> _nearbyDevices = {};
  final Map<String, double> _peerDistances = {};
  final Map<String, DateTime> _peerFoundTimestamps =
      {}; // Track when each peer was first detected
  int? _userId;
  final Set<String> _closeFriends = {}; // Device IDs of close friends

  // Notification interaction tracking
  final Map<String, Map<String, dynamic>> _pendingNotifications = {};

  // App switch tracking
  String? _lastForegroundApp;
  DateTime? _lastAppSwitchTime;

  // Local app usage accumulation
  final Map<String, int> _appUsageStats = {};

  // Total daily usage pulled directly from OS UsageStatsManager
  final Map<String, int> _totalDailyUsage = {};

  // Track raw location for Maps
  double? _lastLat;
  double? _lastLng;

  // Zone-change location tracking (periods = number of 2-min GPS polls)
  String? _currentZone;
  int _periodsInCurrentZone = 0;
  final List<Map<String, dynamic>> _pendingLocationUpdates = [];

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
    _displayName = prefs.getString('user_display_name');
    _bluetoothId = prefs.getString('bluetooth_id');
  }

  String? _displayName;
  String? _bluetoothId;
  String? get displayName => _displayName;
  String? get bluetoothId => _bluetoothId;

  double get fragmentationScore => _fragmentationScore;
  double get focusScore => _focusScore;
  String get currentContext => _currentContext;
  int get nearbyPeers => _nearbyPeers;
  int? get userId => _userId;
  List<String> get connectedPeers => _nearbyDevices.values.toList();
  Map<String, String> get nearbyDevicesMap => Map.unmodifiable(_nearbyDevices);
  Map<String, double> get peerDistances => Map.unmodifiable(_peerDistances);
  Set<String> get closeFriends => Set.unmodifiable(_closeFriends);
  List<String> get privacyLogs => _privacyLogs;
  List<Map<String, dynamic>> get notificationLog => _notificationLog;
  Map<String, int> get appUsageStats => Map.unmodifiable(_appUsageStats);
  Map<String, int> get totalDailyUsage => Map.unmodifiable(_totalDailyUsage);
  bool get notificationEnabled => _notificationEnabled;
  bool get usageEnabled => _usageEnabled;
  double? get lastLat => _lastLat;
  double? get lastLng => _lastLng;
  double get sLoc => _sLoc;
  double get sSoc => _sSoc;
  double get sDig => _sDig;

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
    // Initializing using the method recommended in the setup guide
    await _googleSignIn.initialize(
      serverClientId:
          '899997490172-8o2ue35fs7hkm2tsp82founi8k23rb53.apps.googleusercontent.com',
    );

    if (_userId != null) {
      if (_bluetoothId == null) {
        final random = Random.secure();
        final values = List<int>.generate(8, (i) => random.nextInt(256));
        _bluetoothId = values
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        await prefs.setString('bluetooth_id', _bluetoothId!);
      }

      if (_displayName != null) {
        // Sync the mapping to the server so peers can see the identity
        await ApiService.updateDeviceMapping(
          _userId!,
          _displayName!,
          _bluetoothId!,
        );
      }

      await _startAppEngine();
    }
  }

  Future<bool> authenticateWithGoogle() async {
    try {
      // Using .authenticate() as per the guide's API
      final account = await _googleSignIn.authenticate();

      final deviceId = 'device_${account.id}';
      final firebaseUid = account.id;
      final username = account.displayName;

      final registeredId = await ApiService.registerDevice(
        deviceId,
        firebaseUid: firebaseUid,
        username: username,
      );

      if (registeredId != null) {
        _userId = registeredId;
        _displayName = username;

        if (_bluetoothId == null) {
          final random = Random.secure();
          final values = List<int>.generate(8, (i) => random.nextInt(256));
          _bluetoothId = values
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join();
        }

        await prefs.setInt('registered_user_id', _userId!);
        await prefs.setString('bluetooth_id', _bluetoothId!);
        if (username != null) {
          await prefs.setString('user_display_name', username);
          await ApiService.updateDeviceMapping(
            _userId!,
            username,
            _bluetoothId!,
          );
        }

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
    // Local-first: No server friends load or settings fetch needed for core function
    // But we keep them for P2P identity resolution
    _loadFriends(); 
    fetchSettings();

    if (Platform.isAndroid) {
      _startNativeTelemetry();
      _listenToEvents();
      
      // Initial score calculation
      _recalculateLocalScore();
    }
  }

  Future<void> _recalculateLocalScore() async {
    final scores = await ScoringEngine.calculateDailyCas(DateTime.now());
    _focusScore = scores['CAS'] ?? 50.0;
    _sLoc = scores['S_loc'] ?? 0.0;
    _sSoc = scores['S_soc'] ?? 0.0;
    _sDig = scores['S_dig'] ?? 0.0;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _userId = null;
    _displayName = null;
    await prefs.remove('registered_user_id');
    await prefs.remove('user_display_name');
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
          _notificationLog.insert(0, {
            'package': notifPkg,
            'title': data['title'] ?? '',
            'text': data['text'] ?? '',
            'time': DateTime.now().toIso8601String(),
            'status': 'pending',
          });
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
          _lastLat = (data['lat'] as num).toDouble();
          _lastLng = (data['lng'] as num).toDouble();

          final newLat = _lastLat!;
          final newLng = _lastLng!;
          final newZone = _detectZoneLocally(newLat, newLng);

          if (_currentZone == null) {
            // First reading — start counting
            _currentZone = newZone;
            _periodsInCurrentZone = 1;
          } else if (newZone == _currentZone) {
            // Still in the same zone — just count the period
            _periodsInCurrentZone++;
          } else {
            // Zone changed — queue the completed stay
            _pendingLocationUpdates.add({
              'lat': newLat,
              'lng': newLng,
              'zone': _currentZone,
              'periods_count': _periodsInCurrentZone,
            });
            _currentZone = newZone;
            _periodsInCurrentZone = 1;
          }

          // Local-first storage
          _db.insertLocationLog({
            'lat': newLat,
            'lng': newLng,
            'zone': _currentZone,
            'periods_count': _periodsInCurrentZone,
          });

          _currentContext = newZone;
          _addLog(
            "LOC_SECURE | Saved to encrypted vault | Zone: $newZone",
          );
          _recalculateLocalScore();
          notifyListeners();
          break;

        case 'peer_found':
          final endpointId = data['endpointId'] ?? 'unknown_id';
          final rawName = data['name'] ?? 'Unknown';
          final distance = (data['distance'] as num?)?.toDouble() ?? 5.0;

          String peerBluetoothId = rawName;
          String fallbackDeviceName = 'Unknown Device';

          if (rawName.contains('|')) {
            final parts = rawName.split('|');
            peerBluetoothId = parts[0];
            if (parts.length > 1) fallbackDeviceName = parts[1];
          }

          if (!_nearbyDevices.containsKey(endpointId)) {
            _nearbyPeers++;
            _peerFoundTimestamps[endpointId] = DateTime.now();
          }

          _nearbyDevices[endpointId] = 'Resolving...'; // Temporary placeholder
          _peerDistances[endpointId] = distance;

          ApiService.getDeviceMapping(peerBluetoothId).then((mapping) {
            String realName = fallbackDeviceName;
            bool isUnknown = true;
            if (mapping != null && mapping['google_name'] != null) {
              realName = mapping['google_name'];
              isUnknown = false;
            }

            // For unknown devices, show device model name (e.g. "V2240", "CPH2467")
            if (isUnknown && fallbackDeviceName != 'Unknown Device') {
              realName = '$fallbackDeviceName (Unknown)';
            }

            _nearbyDevices[endpointId] = realName;

            // Fire alert notification for unknown devices
            if (isUnknown) {
              LocalNotificationService.showUnknownDeviceAlert(
                fallbackDeviceName,
                distance,
              );
            }

            _db.insertProximityLog({
              'nearby_peers': _nearbyPeers,
              'peer_name': realName,
              'distance': distance,
            });
            _recalculateLocalScore();
            notifyListeners();
          });

          final proximityLabel = distance < 2.0 ? "CLOSE (Within 2m)" : "NEAR";
          _addLog(
            "PROX_SENT | $proximityLabel | $peerBluetoothId at ${distance.toStringAsFixed(1)}m",
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
                _db.insertEngagementLog({
                  'peer_device_id': endpointId,
                  'engagement_duration_seconds': durationSeconds.toDouble(),
                  // In a real P2P setup, we would have received the peer's CAS via Nearby payload
                  'peer_cas_at_time': 50.0, 
                });
                _addLog(
                  "ENG_SECURE | Vaulted engagement: $endpointId | ${durationSeconds}s",
                );
              }
            }
            _nearbyDevices.remove(endpointId);
            _peerDistances.remove(endpointId);
            if (_nearbyPeers > 0) _nearbyPeers--;
          }
          _db.insertProximityLog({
            'nearby_peers': _nearbyPeers,
          });
          _recalculateLocalScore();
          notifyListeners();
          break;

        case 'app_usage':
          final pkg = data['package'] ?? 'unknown';
          double? switchTimeSecs;
          final prevApp = _lastForegroundApp;
          if (_lastForegroundApp != null && _lastForegroundApp != pkg) {
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
          _appUsageStats[pkg] = (_appUsageStats[pkg] ?? 0) + 10;

          _db.insertDigitalLog({
            'package': pkg,
            'duration': 10000,
            'prev_package': prevApp,
            'switch_time_seconds': switchTimeSecs,
          });
          _addLog(
            "USG_SECURE | Vaulted digital: $pkg",
          );

          if (_pendingNotifications.containsKey(pkg)) {
            final notifData = _pendingNotifications.remove(pkg)!;
            final postTimeMs = notifData['postTimeMs'] as int;
            final responseTimeSeconds =
                (DateTime.now().millisecondsSinceEpoch - postTimeMs) / 1000.0;
            final content = '${notifData['title']} ${notifData['text']}';
            _db.insertNotificationLog({
              'app_category': 'OTHER', // Classification could happen here
              'content': content,
              'response_time_seconds': responseTimeSeconds,
            });
            for (final entry in _notificationLog) {
              if (entry['package'] == pkg && entry['status'] == 'pending') {
                entry['status'] = 'clicked';
                entry['response_time'] = responseTimeSeconds;
                break;
              }
            }
            _addLog(
              "NOTIF_SECURE | Vaulted interaction: $pkg",
            );
          }
          notifyListeners();
          break;
      }
    });
  }

  void _cleanExpiredNotifications() {
    final now = DateTime.now().millisecondsSinceEpoch;
    const expiryMs = 5 * 60 * 1000;
    _pendingNotifications.removeWhere((_, data) {
      final postTimeMs = data['postTimeMs'] as int;
      return (now - postTimeMs) > expiryMs;
    });
  }

  /// Mirrors the server-side zone lookup so we can detect zone changes locally
  /// without a network call on every 2-min GPS poll.
  String _detectZoneLocally(double lat, double lng) {
    const zones = [
      {'name': 'LHC', 'lat': 26.473123, 'lng': 73.114013, 'radius': 150.0},
      {
        'name': 'Shamiana',
        'lat': 26.4768079,
        'lng': 73.1142273,
        'radius': 150.0,
      },
      {
        'name': 'New Mess',
        'lat': 26.4728026,
        'lng': 73.1173692,
        'radius': 150.0,
      },
      {
        'name': 'Akash Complex',
        'lat': 26.4768229,
        'lng': 73.1197027,
        'radius': 150.0,
      },
      {'name': 'KT', 'lat': 26.4693031, 'lng': 73.1141130, 'radius': 150.0},
      {'name': 'FNG', 'lat': 26.4662537, 'lng': 73.1119672, 'radius': 150.0},
      // Hostel area — neutral, tracked but no score impact
      {'name': 'Hostel Area', 'lat': 26.4730, 'lng': 73.1100, 'radius': 300.0},
    ];

    for (final z in zones) {
      final dLat = ((z['lat']! as double) - lat) * 111111.0;
      final dLng =
          ((z['lng']! as double) - lng) * 111111.0 * 0.8985; // cos(26°)
      final distM = sqrt(dLat * dLat + dLng * dLng);
      if (distM <= (z['radius']! as double)) {
        return z['name'] as String;
      }
    }
    return 'Unknown Campus Area';
  }

  Future<void> _startNativeTelemetry() async {
    _channel
        .invokeMethod('startTelemetry', {'userName': _bluetoothId})
        .then((res) {
          debugPrint("Native telemetry started: $res");
        })
        .catchError((e) {
          debugPrint("Failed to start native telemetry: $e");
        });
  }

  void updateMetrics(double frag, double focus, String context, int peers) {
    _fragmentationScore = frag;
    _focusScore = focus;
    _currentContext = context;
    _nearbyPeers = peers;
    if (peers > 0 && _nearbyDevices.isEmpty) {
      _nearbyDevices['test_device_1'] = 'Galaxy M35 (Test)';
    } else if (peers == 0) {
      _nearbyDevices.clear();
    }
    notifyListeners();
  }
}
