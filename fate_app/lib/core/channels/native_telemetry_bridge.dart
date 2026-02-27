import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class NativeTelemetryBridge {
  static const EventChannel _telemetryChannel = EventChannel('com.ate.telemetry/channel');
  static const MethodChannel _commandChannel = MethodChannel('com.ate.telemetry/commands');

  Stream<Map<String, dynamic>> get telemetryStream {
    return _telemetryChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is String) {
        try {
          return jsonDecode(event) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Telemetry Error: Event is String but not JSON: $event');
          return {};
        }
      }
      return Map<String, dynamic>.from(event as Map);
    });
  }

  Future<void> requestUsagePermissions() async {
    await _commandChannel.invokeMethod('requestUsagePermissions');
  }

  Future<void> requestNotificationPermissions() async {
    await _commandChannel.invokeMethod('requestNotificationPermissions');
  }

  Future<bool> checkAllPermissions() async {
    final bool result = await _commandChannel.invokeMethod('checkAllPermissions');
    return result;
  }
}
