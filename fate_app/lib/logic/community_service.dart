import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Client for the FATE community server (`/api/v2`).
///
/// Raw telemetry stays in the encrypted on-device DB. Only what needs more
/// than one phone goes over the wire: score snapshots, engagement edges
/// (peer BLE id + duration), and the campus aggregate coming back.
///
/// Every call is best-effort: offline or server errors return null/false
/// and the caller keeps working locally and retries later.
///
/// Point a build at your deployment with:
///   flutter run --dart-define=FATE_API=https://YOUR-SERVICE.onrender.com
class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  static const String baseUrl = String.fromEnvironment(
    'FATE_API',
    defaultValue: 'https://fate-server.onrender.com',
  );
  static const _tokenKey = 'fate_community_token';
  static const _storage = FlutterSecureStorage();
  // Render free tier cold-starts in ~30-50s; don't hang the UI that long.
  static const _timeout = Duration(seconds: 20);

  String? _token;
  http.Client? _client;
  http.Client get _http => _client ??= http.Client();

  /// Swap the HTTP client and drop the cached token (tests only).
  @visibleForTesting
  void resetForTest(http.Client client) {
    _client = client;
    _token = null;
  }

  Future<String?> _getToken() async =>
      _token ??= await _storage.read(key: _tokenKey);

  Future<bool> get isRegistered async => (await _getToken()) != null;

  Uri _u(String path) => Uri.parse('$baseUrl/api/v2$path');

  Future<Map<String, String>?> _authHeaders() async {
    final t = await _getToken();
    if (t == null) return null;
    return {'Authorization': 'Bearer $t', 'Content-Type': 'application/json'};
  }

  /// Registers this install once. Idempotent from the app's point of view:
  /// returns true if a token is already stored.
  Future<bool> ensureRegistered({
    required String localId,
    required String bluetoothId,
    String? displayName,
  }) async {
    if (await isRegistered) return true;
    try {
      final r = await _http
          .post(
            _u('/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'local_id': localId,
              'bluetooth_id': bluetoothId,
              'display_name': displayName,
            }),
          )
          .timeout(_timeout);
      if (r.statusCode == 201) {
        _token = jsonDecode(r.body)['token'] as String;
        await _storage.write(key: _tokenKey, value: _token);
        return true;
      }
      // 409: server already knows this local_id but we lost the token
      // (e.g. secure storage wiped). Can't recover without re-identity.
      debugPrint('[Community] register failed ${r.statusCode}: ${r.body}');
    } catch (e) {
      debugPrint('[Community] register offline: $e');
    }
    return false;
  }

  Future<bool> publishScore({
    required double cas,
    required double sLoc,
    required double sSoc,
    required double sDig,
    String? zone,
  }) async {
    final h = await _authHeaders();
    if (h == null) return false;
    try {
      final r = await _http
          .post(
            _u('/scores'),
            headers: h,
            body: jsonEncode({
              'cas': cas.clamp(0, 100),
              's_loc': sLoc,
              's_soc': sSoc,
              's_dig': sDig.clamp(0, 100),
              'zone': zone,
            }),
          )
          .timeout(_timeout);
      return r.statusCode == 200;
    } catch (e) {
      debugPrint('[Community] publishScore offline: $e');
      return false;
    }
  }

  /// Returns `{known, display_name, cas, cas_at}` or null when offline.
  Future<Map<String, dynamic>?> lookupPeer(String bluetoothId) async {
    final h = await _authHeaders();
    if (h == null) return null;
    try {
      final r = await _http
          .get(_u('/peers/${Uri.encodeComponent(bluetoothId)}'), headers: h)
          .timeout(_timeout);
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      debugPrint('[Community] lookupPeer offline: $e');
    }
    return null;
  }

  /// Returns `{peer_known, peer_cas, effect}`, or null if it should be retried.
  /// A 422 (stale/self) returns `{'drop': true}` so the caller stops retrying.
  Future<Map<String, dynamic>?> reportEngagement({
    required String peerBluetoothId,
    required double durationSeconds,
    required double endedAt,
  }) async {
    final h = await _authHeaders();
    if (h == null) return null;
    try {
      final r = await _http
          .post(
            _u('/engagements'),
            headers: h,
            body: jsonEncode({
              'peer_bluetooth_id': peerBluetoothId,
              'duration_seconds': durationSeconds,
              'ended_at': endedAt,
            }),
          )
          .timeout(_timeout);
      if (r.statusCode == 200) return jsonDecode(r.body);
      if (r.statusCode == 422) return {'drop': true};
    } catch (e) {
      debugPrint('[Community] reportEngagement offline: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchCommunity() async {
    final h = await _authHeaders();
    if (h == null) return null;
    try {
      final r = await _http.get(_u('/community'), headers: h).timeout(_timeout);
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      debugPrint('[Community] fetchCommunity offline: $e');
    }
    return null;
  }

  /// Erases this device's data on the server and forgets the token.
  Future<bool> deleteRemoteData() async {
    final h = await _authHeaders();
    if (h == null) return true;
    try {
      final r = await _http.delete(_u('/me'), headers: h).timeout(_timeout);
      if (r.statusCode == 204 || r.statusCode == 401) {
        _token = null;
        await _storage.delete(key: _tokenKey);
        return true;
      }
    } catch (e) {
      debugPrint('[Community] deleteRemoteData offline: $e');
    }
    return false;
  }
}
