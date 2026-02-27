class ContextData {
  final double latitude;
  final double longitude;
  final String locationTag;
  final List<String> nearbyPeers;
  final int peerCount;

  ContextData({
    required this.latitude,
    required this.longitude,
    required this.locationTag,
    required this.nearbyPeers,
    required this.peerCount,
  });

  factory ContextData.initial() {
    return ContextData(
      latitude: 0.0,
      longitude: 0.0,
      locationTag: 'Unknown Location',
      nearbyPeers: [],
      peerCount: 0,
    );
  }

  factory ContextData.fromJson(Map<String, dynamic> json) {
    return ContextData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationTag: json['locationTag'] as String,
      nearbyPeers: List<String>.from(json['nearbyPeers'] as List),
      peerCount: json['peerCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'locationTag': locationTag,
      'nearbyPeers': nearbyPeers,
      'peerCount': peerCount,
    };
  }
}
