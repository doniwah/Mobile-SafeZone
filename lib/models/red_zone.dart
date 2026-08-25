class RedZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters

  RedZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory RedZone.fromJson(Map<String, dynamic> json) {
    return RedZone(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['nama_zona'] ?? 'Zona Berbahaya',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble() ?? 500.0,
    );
  }
}
