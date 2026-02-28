import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/channels/native_telemetry_bridge.dart';
import '../../data/models/telemetry_event.dart';
import '../../data/models/attention_metrics.dart';
import '../../data/models/context_data.dart';
import '../engines/attention_engine.dart';
import '../../data/repository/local_metrics_repository.dart';

class TelemetryController {
  final NativeTelemetryBridge _bridge = NativeTelemetryBridge();
  final AttentionEngine _engine = AttentionEngine();
  final LocalMetricsRepository _localRepo = LocalMetricsRepository();

  final StreamController<AttentionMetrics> _metricsController = StreamController<AttentionMetrics>.broadcast();
  final StreamController<ContextData> _contextController = StreamController<ContextData>.broadcast();
  final StreamController<List<String>> _logController = StreamController<List<String>>.broadcast();

  Stream<AttentionMetrics> get metricsStream => _metricsController.stream;
  Stream<ContextData> get contextStream => _contextController.stream;
  Stream<List<String>> get logsStream => _logController.stream;

  AttentionMetrics _currentMetrics = AttentionMetrics.initial();
  List<TelemetryEvent> _buffer = [];
  final List<String> _logs = [];

  void initialize() async {
    _addLog("SYSTEM: Telemetry Engine Initialized");
    
    // Check and request permissions, then start telemetry
    try {
      final bool hasPermission = await _bridge.checkAllPermissions();
      if (!hasPermission) {
        _addLog("SYSTEM: Requesting Permissions...");
        await _bridge.requestUsagePermissions();
      }
      
      _bridge.telemetryStream.listen((eventData) {
        _processIncomingNativeEvent(eventData);
      });
      
      _addLog("SYSTEM: Starting Native Telemetry...");
      // Using universal command channel if needed, but Native branch's MainActivity 
      // added 'startTelemetry' to the COMMAND_CHANNEL (mapped to 'com.ate.telemetry/commands')
      await const MethodChannel('com.ate.telemetry/commands').invokeMethod('startTelemetry');
      
    } catch (e) {
      _addLog("ERROR: Initialization failed: $e");
    }

    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_buffer.isNotEmpty) {
        _currentMetrics = _engine.calculateRealTimeMetrics(_buffer, _currentMetrics);
        _metricsController.add(_currentMetrics);
        for (var event in _buffer) {
          _localRepo.saveEvent(event);
        }
        _addLog("CALC: Updated Metrics (Score: ${_currentMetrics.currentCAS.toInt()}%)");
        _buffer.clear();
      }
    });
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].substring(0, 8);
    debugPrint("[$timestamp] $message");
    _logs.insert(0, "[$timestamp] $message");
    if (_logs.length > 200) _logs.removeLast();
    _logController.add(List.from(_logs));
  }

  void _processIncomingNativeEvent(Map<String, dynamic> payload) {
    // Handle nested format from Native branch
    final String type = payload['type'] as String? ?? 'unknown';
    final Map<String, dynamic> data = (payload['data'] as Map?)?.cast<String, dynamic>() ?? payload;

    if (type == 'location_update' || data.containsKey('latitude')) {
      final context = ContextData.fromJson(data);
      _contextController.add(context);
      _addLog("LOC_STAT: Lat ${context.latitude.toStringAsFixed(4)}, Lng ${context.longitude.toStringAsFixed(4)}");
    } else {
      try {
        final event = TelemetryEvent.fromJson(data);
        _buffer.add(event);
        _addLog("EVENT: ${event.eventType} | Target: ${event.packageName}");
      } catch (e) {
        _addLog("ERROR: Failed to parse event of type $type: $e");
      }
    }
  }

  void dispose() {
    _metricsController.close();
    _contextController.close();
    _logController.close();
  }
}
