import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Production Server (Render Deployment)
  static const String baseUrl = 'http://172.31.108.214:8000/api/ingest';

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

  // Notification with interaction data
  static Future<void> sendNotification(
    int userId,
    String package,
    String content, {
    double? responseTimeSeconds,
  }) async {
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
          'response_time_seconds': responseTimeSeconds,
        }),
      );
    } catch (e) {
      debugPrint("Error sending notification telemetry: $e");
    }
  }

  // Device registration to get the user_id
  static Future<int?> registerDevice(
    String deviceId, {
    String? firebaseUid,
  }) async {
    // The auth endpoint is at /api/auth/register
    final authUrl = Uri.parse(
      baseUrl.replaceAll('/api/ingest', '/api/auth/register'),
    );
    try {
      final response = await http.post(
        authUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_id': deviceId, 'firebase_uid': firebaseUid}),
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

  static String get _serverBase => baseUrl.replaceAll('/api/ingest', '');

  // ── Close Friends API ──

  static Future<bool> addFriend(int userId, String friendDeviceId) async {
    final url = Uri.parse('$_serverBase/api/friends/add');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'friend_device_id': friendDeviceId,
        }),
      );
      if (response.statusCode == 200) {
        debugPrint("Friend added: $friendDeviceId");
        return true;
      }
    } catch (e) {
      debugPrint("Error adding friend: $e");
    }
    return false;
  }

  static Future<bool> removeFriend(int userId, String friendDeviceId) async {
    final url = Uri.parse('$_serverBase/api/friends/remove');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'friend_device_id': friendDeviceId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error removing friend: $e");
    }
    return false;
  }

  static Future<List<String>> getFriends(int userId) async {
    final url = Uri.parse('$_serverBase/api/friends/list/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['friends'] ?? []);
      }
    } catch (e) {
      debugPrint("Error fetching friends: $e");
    }
    return [];
  }

  // ── User Settings (Weights) ──

  static Future<Map<String, dynamic>?> getSettings(int userId) async {
    final url = Uri.parse('$_serverBase/api/settings/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching settings: $e");
    }
    return null;
  }

  static Future<bool> updateSettings(
    int userId,
    double wLoc,
    double wSoc,
    double wDig,
  ) async {
    final url = Uri.parse('$_serverBase/api/settings/$userId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'weight_spatial': wLoc,
          'weight_social': wSoc,
          'weight_digital': wDig,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error updating settings: $e");
    }
    return false;
  }
}
