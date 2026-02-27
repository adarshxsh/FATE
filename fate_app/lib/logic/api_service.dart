import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android Emulator to reach localhost on the host machine
  static const String baseUrl = 'http://10.0.2.2:8000/api/ingest';

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
  static Future<void> sendNotification(String package, String content) async {
    final url = Uri.parse('$baseUrl/notification');
    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
          'package': package,
          'content': content,
        }),
      );
    } catch (e) {
      debugPrint("Error sending notification telemetry: $e");
    }
  }
}
