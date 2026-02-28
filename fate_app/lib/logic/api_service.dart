import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Production Server (Render Deployment)
  static const String baseUrl =
      'https://fate-server-g1co.onrender.com/api/ingest';

  static Future<void> sendTelemetry(
    String type,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/$type');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
          ...data,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Successfully sent $type telemetry to server.");
      } else {
        debugPrint("Failed to send $type: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error connecting to server: $e");
    }
  }

  // Overload for notifications specifically
  static Future<void> sendNotification(
    int userId,
    String package,
    String content,
  ) async {
    final url = Uri.parse('$baseUrl/notification');
    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
          'user_id': userId,
          'package': package,
          'content': content,
        }),
      );
    } catch (e) {
      debugPrint("Error sending notification telemetry: $e");
    }
  }

  // Device registration to get the user_id
  static Future<int?> registerDevice(String deviceId) async {
    // The auth endpoint is at /api/auth/register
    final authUrl = Uri.parse(
      baseUrl.replaceAll('/api/ingest', '/api/auth/register'),
    );
    try {
      final response = await http.post(
        authUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_id': deviceId, 'firebase_uid': null}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user_id'] as int?;
      }
    } catch (e) {
      debugPrint("Error registering device: $e");
    }
    return null;
  }
}
