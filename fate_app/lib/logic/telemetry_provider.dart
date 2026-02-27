import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class TelemetryProvider extends ChangeNotifier {
  final SharedPreferences prefs;
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

  // Permission state
  bool _notificationEnabled = false;
  bool _usageEnabled = false;

  // Privacy Log tracking transmissions
  final List<String> _privacyLogs = [];

  TelemetryProvider(this.prefs) {
    _notificationEnabled = prefs.getBool('notification_enabled') ?? false;
    _usageEnabled = prefs.getBool('usage_enabled') ?? false;
  }

  double get fragmentationScore => _fragmentationScore;
  double get focusScore => _focusScore;
  String get currentContext => _currentContext;
  int get nearbyPeers => _nearbyPeers;
  List<String> get privacyLogs => _privacyLogs;
  bool get notificationEnabled => _notificationEnabled;
  bool get usageEnabled => _usageEnabled;

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

  void _addLog(String log) {
    final timeStr = DateTime.now()
        .toIso8601String()
        .split('T')[1]
        .substring(0, 8);
    _privacyLogs.insert(0, "[$timeStr] $log");
    if (_privacyLogs.length > 100) _privacyLogs.removeLast();
  }

  Future<void> initialize() async {
    if (Platform.isAndroid) {
      _startNativeTelemetry();
      _listenToEvents();
    }
  }

  void _listenToEvents() {
    _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      final String type = map['type'] as String;
      final Map<dynamic, dynamic> data = map['data'] as Map<dynamic, dynamic>;

      debugPrint("Received native event: $type");

      switch (type) {
        case 'notification_posted':
          _fragmentationScore = (_fragmentationScore + 0.05).clamp(0.0, 1.0);
          final pkg = data['package'] ?? 'unknown';
          final txt = data['text'] ?? '';
          final title = data['title'] ?? '';
          ApiService.sendNotification(pkg, txt);
          _addLog(
            "TXT_SENT | To: /notification | Pkg: $pkg | Content: $title: $txt",
          );
          notifyListeners();
          break;
        case 'location_update':
          _currentContext =
              "Geofenced: ${data['lat'].toStringAsFixed(2)}, ${data['lng'].toStringAsFixed(2)}";
          ApiService.sendTelemetry('location', {
            'lat': data['lat'],
            'lng': data['lng'],
          });
          _addLog(
            "LOC_SENT | To: /location | Lat: ${data['lat'].toStringAsFixed(4)}, Lng: ${data['lng'].toStringAsFixed(4)}",
          );
          notifyListeners();
          break;
        case 'peer_found':
        case 'peer_lost':
          if (type == 'peer_found')
            _nearbyPeers++;
          else if (_nearbyPeers > 0)
            _nearbyPeers--;
          ApiService.sendTelemetry('proximity', {'nearby_peers': _nearbyPeers});
          _addLog("PROX_SENT | To: /proximity | Nearby Peers: $_nearbyPeers");
          notifyListeners();
          break;
        case 'app_usage':
          final pkg = data['package'] ?? 'unknown';
          ApiService.sendTelemetry('digital', {
            'package': pkg,
            'duration': 10000,
          }); // 10 sec blocks
          _addLog("USG_SENT | To: /digital | Foreground: $pkg");
          notifyListeners();
          break;
      }
    });
  }

  Future<void> _startNativeTelemetry() async {
    try {
      final result = await _channel.invokeMethod('startTelemetry');
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
    notifyListeners();
  }
}
