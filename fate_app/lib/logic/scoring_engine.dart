import 'secure_db_service.dart';

class ScoringEngine {
  // ── PRODUCTIVE ZONES ──
  static const Map<String, double> zoneWeights = {
    "LHC": 4.0, // Lecture Hall Complex — core academic
    "Hostel Area": 0.0,
    "Unknown Campus Area": 0.0,
    "Shamiana": -2.0,
    "New Mess": -2.0,
    "Akash Complex": -1.5,
    "KT": -2.0,
    "FNG": -1.5,
  };

  // ── APP SEVERITY ── (Synced from fate_server/api/digital.py)
  static const Map<String, double> appSeverities = {
    // Distracting
    "com.instagram.android": 1.8,
    "com.google.android.youtube": 1.5,
    "com.zhiliaoapp.musically": 2.0, // TikTok
    "com.twitter.android": 1.2,
    "com.facebook.katana": 1.3,
    "com.netflix.mediaclient": 2.0,
    // Productive
    "com.google.android.apps.docs": -1.0,
    "com.microsoft.office.word": -1.0,
    "com.notion.id": -1.2,
    "com.github.android": -1.5,
    "com.stackexchange.stackoverflow": -1.0,
    // Neutral / Low impact
    "com.spotify.music": 0.3,
    "com.whatsapp": 0.5,
  };

  static const double pointsPerMinute = 0.5;
  static const double switchPenaltyThresholdSecs = 30.0;
  static const double switchPenaltyPoints = -2.0;

  // ── SOCIAL CONTAGION ──
  static const double contagionLowCas = 40.0;
  static const double contagionHighCas = 70.0;
  static const double contagionPenaltyPerMin = -0.5;
  static const double contagionRewardPerMin = 0.3;

  static double calculateSpatialScore(String zone, double hoursSpent) {
    final weight = zoneWeights[zone] ?? 0.0;
    return weight * hoursSpent;
  }

  static double calculateSocialScore(int nearbyPeers, bool isGroupStudy) {
    if (nearbyPeers == 0) return 0.0;

    double base;
    if (nearbyPeers <= 2) {
      base = nearbyPeers * 1.0;
    } else if (nearbyPeers <= 5) {
      base = 2.0 + (nearbyPeers - 2) * 0.5;
    } else {
      base = 3.5 + (nearbyPeers - 5) * 0.2;
    }

    if (isGroupStudy) {
      base *= 1.5;
    }
    return base;
  }

  static double calculateDigitalScore100(List<Map<String, dynamic>> usageLogs) {
    double score = 50.0;

    final sortedLogs = List<Map<String, dynamic>>.from(usageLogs);
    sortedLogs.sort((a, b) => (a['timestamp'] as num).compareTo(b['timestamp'] as num));

    Map<String, dynamic>? prevLog;
    for (final log in sortedLogs) {
      final pkg = log['package_name'] ?? '';
      final severity = appSeverities[pkg] ?? 0.5;
      final minutes = (log['usage_duration_seconds'] as num? ?? 0) / 60.0;

      score -= severity * minutes * pointsPerMinute;

      // Switch penalty
      if (prevLog != null) {
        final prevPkg = prevLog['package_name'] ?? '';
        final prevSeverity = appSeverities[prevPkg] ?? 0.5;
        final timeBetween = (log['timestamp'] as num) - (prevLog['timestamp'] as num);

        if (prevSeverity < 0 && severity > 0 && timeBetween < switchPenaltyThresholdSecs) {
          score += switchPenaltyPoints;
        }
      }
      prevLog = log;
    }

    return score.clamp(0.0, 100.0);
  }

  static double calculateNotificationScore(String category, double? responseTimeSecs) {
    if (responseTimeSecs == null) return 0.0;

    if (category == "DISTRACTING") {
      return responseTimeSecs < 60 ? -3.0 : -1.0;
    } else if (category == "PRODUCTIVE") {
      return responseTimeSecs < 120 ? 2.0 : 0.5;
    }
    return 0.0;
  }

  static double computeFinalCas(double sLoc, double sSoc, double sDig,
      {double wLoc = 0.3, double wSoc = 0.3, double wDig = 0.4}) {
    final raw = (wLoc * sLoc) + (wSoc * sSoc) + (wDig * sDig);
    final scaled = 50.0 + raw * 1.5;
    return scaled.clamp(0.0, 100.0);
  }

  static Future<Map<String, double>> calculateDailyCas(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch / 1000.0;
    final endOfDay = startOfDay + 86400;
    final dbService = SecureDbService();

    final where = 'timestamp >= ? AND timestamp < ?';
    final args = [startOfDay, endOfDay];

    // 1. Spatial
    final locations = await dbService.getLogs('location_logs', where: where, whereArgs: args);
    Map<String, double> zoneHours = {};
    for (var loc in locations) {
      final zone = loc['mapped_zone'] ?? "Unknown Campus Area";
      final hours = ((loc['periods_count'] as int? ?? 1) * 30.0) / 3600.0;
      zoneHours[zone] = (zoneHours[zone] ?? 0.0) + hours;
    }
    double sLoc = 0.0;
    zoneHours.forEach((zone, hours) {
      sLoc += calculateSpatialScore(zone, hours);
    });

    // 2. Social
    final proximities = await dbService.getLogs('proximity_logs', where: where, whereArgs: args);
    double avgPeers = 0;
    if (proximities.isNotEmpty) {
      avgPeers = proximities.map((p) => p['nearby_peers_count'] as int).reduce((a, b) => a + b) / proximities.length;
    }
    bool isGroupStudy = avgPeers >= 2 && zoneHours.keys.any((z) => (zoneWeights[z] ?? 0) > 0);
    double sSoc = calculateSocialScore(avgPeers.toInt(), isGroupStudy);

    // Social Contagion
    final engagements = await dbService.getLogs('engagement_logs', where: where, whereArgs: args);
    double contagionModifier = 0.0;
    for (var eng in engagements) {
      final peerCas = eng['peer_cas_at_time'] as double?;
      if (peerCas != null) {
        final minutes = (eng['engagement_duration_seconds'] as num) / 60.0;
        if (peerCas < contagionLowCas) {
          contagionModifier += contagionPenaltyPerMin * minutes;
        } else if (peerCas > contagionHighCas) {
          contagionModifier += contagionRewardPerMin * minutes;
        }
      }
    }
    sSoc += contagionModifier;

    // 3. Digital
    final usages = await dbService.getLogs('digital_logs', where: where, whereArgs: args);
    double sDig = calculateDigitalScore100(usages);

    final notifs = await dbService.getLogs('notification_logs', where: where, whereArgs: args);
    for (var n in notifs) {
      sDig += calculateNotificationScore(n['app_category'] ?? "OTHER", n['response_time_seconds'] as double?);
    }

    final cas = computeFinalCas(sLoc, sSoc, sDig.clamp(0.0, 100.0));

    return {
      'CAS': cas,
      'S_loc': sLoc,
      'S_soc': sSoc,
      'S_dig': sDig.clamp(0.0, 100.0),
    };
  }
}
