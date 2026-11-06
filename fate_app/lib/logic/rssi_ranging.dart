import 'dart:math';

/// RSSI to distance estimation for BLE sightings of other FATE phones.
///
/// The pipeline is:
///   raw RSSI -> outlier gate -> 1-D Kalman filter -> log-distance path loss -> band
///
/// Accuracy limits: a single BLE RSSI reading swings by about ±8 dB from
/// multipath, body blocking and phone orientation. At ~2 m that is a factor
/// of 2 or more in distance. GAEN (the COVID exposure-notification protocol)
/// hit exactly this and settled on attenuation *buckets* instead of metres.
/// So the UI should lean on [ProximityBand] and treat the metre figure as
/// approximate.
enum ProximityBand { immediate, near, far, unknown }

class RssiRanging {
  /// Path-loss exponent: 2.0 in free space, 2.5-3.5 indoors (bodies, walls).
  /// 2.7 is a middle value for lecture halls and hostel rooms.
  static const double pathLossExponent = 2.7;

  /// Readings outside this range are radio noise, not a phone in range.
  static const int minValidRssi = -105;
  static const int maxValidRssi = -20;

  /// No sighting for this long: the distance is stale and reported as unknown.
  static const Duration staleAfter = Duration(seconds: 20);

  static const double immediateMaxM = 1.0;
  static const double nearMaxM = 3.0;

  /// Log-distance path-loss model: d = 10 ^ ((P_1m - RSSI) / (10 * n)).
  static double distanceFromRssi(
    double rssi,
    int measuredPowerAt1m, {
    double n = pathLossExponent,
  }) {
    final d = pow(10, (measuredPowerAt1m - rssi) / (10 * n)).toDouble();
    return d.clamp(0.1, 30.0);
  }

  static ProximityBand bandFor(double? metres) {
    if (metres == null) return ProximityBand.unknown;
    if (metres <= immediateMaxM) return ProximityBand.immediate;
    if (metres <= nearMaxM) return ProximityBand.near;
    return ProximityBand.far;
  }
}

/// Scalar Kalman filter for a slowly-varying signal (people mostly sit still).
///
/// Process noise [q] is small (the true RSSI drifts slowly) and measurement
/// noise [r] is large (each reading is jittery), so one spike moves the
/// estimate only a little, while a real change (someone walks away)
/// converges within a few seconds.
class RssiKalman {
  final double q;
  final double r;
  double? _x; // estimate
  double _p = 1.0; // estimate variance

  RssiKalman({this.q = 0.05, this.r = 4.0});

  double? get value => _x;

  double update(double z) {
    if (_x == null) {
      _x = z;
      _p = r;
      return z;
    }
    _p += q;
    final k = _p / (_p + r);
    _x = _x! + k * (z - _x!);
    _p = (1 - k) * _p;
    return _x!;
  }
}

/// Per-peer ranging state: filters each peer's RSSI stream and reports distance.
class PeerRangingTable {
  final Map<String, RssiKalman> _filters = {};
  final Map<String, int> _measuredPower = {};
  final Map<String, DateTime> _lastSeen = {};
  final DateTime Function() _now;

  PeerRangingTable({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Feeds one sighting. Returns the new distance estimate, or null if the reading was rejected.
  double? addReading(String bleId, int rssi, int measuredPowerAt1m) {
    if (rssi < RssiRanging.minValidRssi || rssi > RssiRanging.maxValidRssi) {
      return null;
    }
    // A long gap means the peer left and came back: start a fresh filter.
    final last = _lastSeen[bleId];
    if (last != null && _now().difference(last) > RssiRanging.staleAfter) {
      _filters.remove(bleId);
    }
    final smoothed =
        _filters.putIfAbsent(bleId, () => RssiKalman()).update(rssi.toDouble());
    _measuredPower[bleId] = measuredPowerAt1m;
    _lastSeen[bleId] = _now();
    return RssiRanging.distanceFromRssi(smoothed, measuredPowerAt1m);
  }

  /// Current distance, or null if never seen or stale.
  double? distanceOf(String bleId) {
    final last = _lastSeen[bleId];
    final f = _filters[bleId];
    if (last == null || f?.value == null) return null;
    if (_now().difference(last) > RssiRanging.staleAfter) return null;
    return RssiRanging.distanceFromRssi(f!.value!, _measuredPower[bleId]!);
  }

  double? smoothedRssi(String bleId) => _filters[bleId]?.value;

  void forget(String bleId) {
    _filters.remove(bleId);
    _measuredPower.remove(bleId);
    _lastSeen.remove(bleId);
  }
}
