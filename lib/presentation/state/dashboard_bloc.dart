import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/controllers/telemetry_controller.dart';
import '../../data/models/attention_metrics.dart';
import '../../data/models/context_data.dart';

abstract class DashboardEvent {}
class DashboardMetricsUpdated extends DashboardEvent {
  final AttentionMetrics metrics;
  DashboardMetricsUpdated(this.metrics);
}
class DashboardContextUpdated extends DashboardEvent {
  final ContextData context;
  DashboardContextUpdated(this.context);
}

class DashboardState {
  final AttentionMetrics metrics;
  final ContextData context;

  DashboardState({required this.metrics, required this.context});

  factory DashboardState.initial() {
    return DashboardState(
      metrics: AttentionMetrics.initial(),
      context: ContextData.initial(),
    );
  }

  DashboardState copyWith({
    AttentionMetrics? metrics,
    ContextData? context,
  }) {
    return DashboardState(
      metrics: metrics ?? this.metrics,
      context: context ?? this.context,
    );
  }
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final TelemetryController telemetryController;

  DashboardBloc(this.telemetryController) : super(DashboardState.initial()) {
    telemetryController.metricsStream.listen((metrics) {
      add(DashboardMetricsUpdated(metrics));
    });

    telemetryController.contextStream.listen((context) {
      add(DashboardContextUpdated(context));
    });

    on<DashboardMetricsUpdated>((event, emit) {
      emit(state.copyWith(metrics: event.metrics));
    });

    on<DashboardContextUpdated>((event, emit) {
      emit(state.copyWith(context: event.context));
    });
  }
}
