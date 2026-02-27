import 'dart:async';
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

  Stream<AttentionMetrics> get metricsStream => _metricsController.stream;
  Stream<ContextData> get contextStream => _contextController.stream;

  AttentionMetrics _currentMetrics = AttentionMetrics.initial();
  List<TelemetryEvent> _buffer = [];

  void initialize() {
    _bridge.telemetryStream.listen((eventData) {
      _processIncomingNativeEvent(eventData);
    });

    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_buffer.isNotEmpty) {
        _currentMetrics = _engine.calculateRealTimeMetrics(_buffer, _currentMetrics);
        _metricsController.add(_currentMetrics);
        for (var event in _buffer) {
          _localRepo.saveEvent(event);
        }
        _buffer.clear();
      }
    });
  }

  void _processIncomingNativeEvent(Map<String, dynamic> data) {
    if (data.containsKey('latitude')) {
      _contextController.add(ContextData.fromJson(data));
    } else {
      final event = TelemetryEvent.fromJson(data);
      _buffer.add(event);
    }
  }

  void dispose() {
    _metricsController.close();
    _contextController.close();
  }
}
