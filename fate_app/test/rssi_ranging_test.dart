import 'dart:math';

import 'package:fate_app/logic/rssi_ranging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('path-loss model', () {
    test('RSSI equal to the 1 m reference is 1 m', () {
      expect(RssiRanging.distanceFromRssi(-59, -59), closeTo(1.0, 1e-9));
    });
    test('every 10*n dB of extra loss is 10x distance', () {
      const n = RssiRanging.pathLossExponent;
      expect(
        RssiRanging.distanceFromRssi(-59 - 10 * n, -59),
        closeTo(10.0, 1e-9),
      );
    });
    test('monotonic: weaker signal means farther', () {
      final a = RssiRanging.distanceFromRssi(-60, -59);
      final b = RssiRanging.distanceFromRssi(-75, -59);
      final c = RssiRanging.distanceFromRssi(-90, -59);
      expect(a < b && b < c, isTrue);
    });
    test('clamped to [0.1, 30] m', () {
      expect(RssiRanging.distanceFromRssi(-10, -59), 0.1);
      expect(RssiRanging.distanceFromRssi(-140, -59), 30.0);
    });
    test('uses the advertised per-device reference', () {
      // A phone with a weaker antenna that advertises -65 at 1 m reads -65 at 1 m.
      expect(RssiRanging.distanceFromRssi(-65, -65), closeTo(1.0, 1e-9));
    });
  });

  group('bands', () {
    test('thresholds', () {
      expect(RssiRanging.bandFor(null), ProximityBand.unknown);
      expect(RssiRanging.bandFor(0.8), ProximityBand.immediate);
      expect(RssiRanging.bandFor(2.5), ProximityBand.near);
      expect(RssiRanging.bandFor(8), ProximityBand.far);
    });
  });

  group('Kalman filter', () {
    test('first reading is taken as-is', () {
      expect(RssiKalman().update(-70), -70);
    });
    test('a single spike barely moves the estimate', () {
      final k = RssiKalman();
      for (var i = 0; i < 20; i++) {
        k.update(-70);
      }
      final after = k.update(-45); // body moved / reflection
      expect(after, lessThan(-65));
    });
    test('noisy stream converges near the true mean with lower variance', () {
      final rnd = Random(42);
      final k = RssiKalman();
      final raw = <double>[];
      final filt = <double>[];
      for (var i = 0; i < 200; i++) {
        final z = -72 + (rnd.nextDouble() * 16 - 8); // ±8 dB jitter
        raw.add(z);
        filt.add(k.update(z));
      }
      double variance(List<double> xs) {
        final m = xs.reduce((a, b) => a + b) / xs.length;
        return xs.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) /
            xs.length;
      }

      expect(k.value!, closeTo(-72, 2.5));
      expect(
        variance(filt.sublist(50)),
        lessThan(variance(raw.sublist(50)) / 4),
      );
    });
    test('tracks a real step change (someone walks away)', () {
      final k = RssiKalman();
      for (var i = 0; i < 30; i++) {
        k.update(-60);
      }
      for (var i = 0; i < 60; i++) {
        k.update(-85);
      }
      expect(k.value!, closeTo(-85, 3));
    });
  });

  group('PeerRangingTable', () {
    test('rejects out-of-range RSSI', () {
      final t = PeerRangingTable();
      expect(t.addReading('aa', 0, -59), isNull);
      expect(t.addReading('aa', -120, -59), isNull);
      expect(t.distanceOf('aa'), isNull);
    });
    test('distance goes stale and the filter resets after a gap', () {
      var now = DateTime(2026, 11, 6, 12);
      final t = PeerRangingTable(now: () => now);
      for (var i = 0; i < 10; i++) {
        t.addReading('bb', -59, -59);
      }
      expect(t.distanceOf('bb'), closeTo(1.0, 0.05));

      now = now.add(const Duration(seconds: 30));
      expect(t.distanceOf('bb'), isNull); // stale

      // Comes back far away: fresh filter, not dragged by the old -59 history.
      final d = t.addReading('bb', -86, -59)!;
      expect(d, greaterThan(9));
    });
    test('peers are independent and forget() clears', () {
      final t = PeerRangingTable();
      t.addReading('p1', -59, -59);
      t.addReading('p2', -80, -59);
      expect(t.distanceOf('p1')! < t.distanceOf('p2')!, isTrue);
      t.forget('p1');
      expect(t.distanceOf('p1'), isNull);
      expect(t.distanceOf('p2'), isNotNull);
    });
  });
}
