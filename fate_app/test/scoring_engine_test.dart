import 'package:fate_app/logic/scoring_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateSocialScore', () {
    test('zero peers scores zero', () {
      expect(ScoringEngine.calculateSocialScore(0, true), 0.0);
    });
    test('diminishing returns past 2 and 5 peers', () {
      expect(ScoringEngine.calculateSocialScore(2, false), 2.0);
      expect(ScoringEngine.calculateSocialScore(5, false), 3.5);
      expect(ScoringEngine.calculateSocialScore(10, false), closeTo(4.5, 1e-9));
    });
    test('group study multiplies by 1.5', () {
      expect(ScoringEngine.calculateSocialScore(2, true), 3.0);
    });
  });

  group('calculateDigitalScore100', () {
    test('no usage stays at baseline 50', () {
      expect(ScoringEngine.calculateDigitalScore100([]), 50.0);
    });
    test('distracting app lowers score', () {
      final s = ScoringEngine.calculateDigitalScore100([
        {
          'timestamp': 0,
          'package_name': 'com.instagram.android',
          'usage_duration_seconds': 600,
        },
      ]);
      // 1.8 severity * 10 min * 0.5 = 9
      expect(s, closeTo(41.0, 1e-9));
    });
    test('productive app raises score', () {
      final s = ScoringEngine.calculateDigitalScore100([
        {
          'timestamp': 0,
          'package_name': 'com.github.android',
          'usage_duration_seconds': 600,
        },
      ]);
      expect(s, closeTo(57.5, 1e-9));
    });
    test('quick switch productive -> distracting is penalised', () {
      final logs = [
        {
          'timestamp': 0,
          'package_name': 'com.github.android',
          'usage_duration_seconds': 0,
        },
        {
          'timestamp': 10,
          'package_name': 'com.instagram.android',
          'usage_duration_seconds': 0,
        },
      ];
      expect(ScoringEngine.calculateDigitalScore100(logs), 48.0);
    });
    test('clamped to [0, 100]', () {
      final s = ScoringEngine.calculateDigitalScore100([
        {
          'timestamp': 0,
          'package_name': 'com.netflix.mediaclient',
          'usage_duration_seconds': 36000,
        },
      ]);
      expect(s, 0.0);
    });
  });

  group('notification and final CAS', () {
    test('fast reaction to distracting notification costs more', () {
      expect(ScoringEngine.calculateNotificationScore('DISTRACTING', 10), -3.0);
      expect(
        ScoringEngine.calculateNotificationScore('DISTRACTING', 600),
        -1.0,
      );
      expect(ScoringEngine.calculateNotificationScore('OTHER', 10), 0.0);
      expect(
        ScoringEngine.calculateNotificationScore('DISTRACTING', null),
        0.0,
      );
    });
    test('computeFinalCas is centred at 50 and clamped', () {
      expect(ScoringEngine.computeFinalCas(0, 0, 0), 50.0);
      expect(ScoringEngine.computeFinalCas(0, 0, 100), 100.0);
      expect(ScoringEngine.computeFinalCas(-500, 0, 0), 0.0);
    });
  });
}
