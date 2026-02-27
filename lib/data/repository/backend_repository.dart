import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_routes.dart';
import '../models/telemetry_event.dart';

class BackendRepository {
  final ApiClient _apiClient = ApiClient();

  Future<bool> authenticateWithGoogle(String idToken) async {
    try {
      final response = await _apiClient.client.post(
        ApiRoutes.authGoogle,
        data: {'google_id_token': idToken},
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } on DioException catch (_) {
      return false;
    }
  }

  Future<bool> syncEvents(List<TelemetryEvent> events) async {
    if (events.isEmpty) return true;
    try {
      final data = events.map((e) => e.toJson()).toList();
      final response = await _apiClient.client.post(
        ApiRoutes.ingestTelemetry,
        data: {'events': data},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (_) {
      return false;
    }
  }
}
