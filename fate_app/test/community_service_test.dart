import 'dart:convert';

import 'package:fate_app/logic/community_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final svc = CommunityService();
  late List<http.Request> calls;

  void serve(http.Response Function(http.Request) handler) {
    calls = [];
    svc.resetForTest(MockClient((req) async {
      calls.add(req);
      return handler(req);
    }));
  }

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('calls without a token are skipped, not sent', () async {
    serve((_) => http.Response('{}', 200));
    expect(await svc.publishScore(cas: 50, sLoc: 0, sSoc: 0, sDig: 50), isFalse);
    expect(await svc.fetchCommunity(), isNull);
    expect(calls, isEmpty);
  });

  test('register stores token and sends it as bearer afterwards', () async {
    serve((req) {
      if (req.url.path.endsWith('/register')) {
        final body = jsonDecode(req.body);
        expect(body['local_id'], 'uuid-1234');
        expect(body['bluetooth_id'], 'abcd1234');
        return http.Response(jsonEncode({'device_id': 1, 'token': 'tok'}), 201);
      }
      expect(req.headers['Authorization'], 'Bearer tok');
      return http.Response('{"status":"ok"}', 200);
    });
    expect(await svc.ensureRegistered(localId: 'uuid-1234', bluetoothId: 'abcd1234'), isTrue);
    // Second call is a no-op: token already stored.
    expect(await svc.ensureRegistered(localId: 'uuid-1234', bluetoothId: 'abcd1234'), isTrue);
    expect(calls.where((c) => c.url.path.endsWith('/register')).length, 1);

    expect(await svc.publishScore(cas: 140, sLoc: 1, sSoc: 1, sDig: -5), isTrue);
    final sent = jsonDecode(calls.last.body);
    expect(sent['cas'], 100); // clamped client-side
    expect(sent['s_dig'], 0);
    expect(sent['zone'], isNull);
  });

  test('register failure (409) leaves service unregistered', () async {
    serve((_) => http.Response('{"detail":"Device already registered"}', 409));
    expect(await svc.ensureRegistered(localId: 'uuid-1234', bluetoothId: 'abcd1234'), isFalse);
    expect(await svc.isRegistered, isFalse);
  });

  group('with token', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({'fate_community_token': 'tok'}));

    test('engagement: 200 returns body, 422 says drop, 5xx retries later', () async {
      serve((_) => http.Response(jsonEncode({'peer_known': true, 'peer_cas': 82, 'effect': 'positive'}), 200));
      final ok = await svc.reportEngagement(peerBluetoothId: 'peer0001', durationSeconds: 120, endedAt: 1);
      expect(ok!['effect'], 'positive');
      expect(jsonDecode(calls.single.body)['ended_at'], 1);

      serve((_) => http.Response('{}', 422));
      expect(await svc.reportEngagement(peerBluetoothId: 'p', durationSeconds: 1, endedAt: 1), {'drop': true});

      serve((_) => http.Response('oops', 503));
      expect(await svc.reportEngagement(peerBluetoothId: 'p', durationSeconds: 1, endedAt: 1), isNull);
    });

    test('network error is swallowed (offline-first)', () async {
      serve((_) => throw http.ClientException('no route'));
      expect(await svc.lookupPeer('peer0001'), isNull);
      expect(await svc.publishScore(cas: 1, sLoc: 0, sSoc: 0, sDig: 1), isFalse);
    });

    test('peer lookup url-encodes the BLE id', () async {
      serve((_) => http.Response('{"known":false}', 200));
      expect(await svc.lookupPeer('a/b'), {'known': false});
      expect(calls.single.url.path, endsWith('/peers/a%2Fb'));
    });

    test('deleteRemoteData forgets token on 204', () async {
      serve((_) => http.Response('', 204));
      expect(await svc.deleteRemoteData(), isTrue);
      expect(calls.single.method, 'DELETE');
      expect(await svc.isRegistered, isFalse);
    });
  });
}
