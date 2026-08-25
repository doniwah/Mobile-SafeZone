import 'dart:convert';

enum SosStatus {
  created,
  pendingSync,
  syncing,
  synced,
  failedRetry,
  cancelled
}

class SosEvent {
  final String sosId;
  final String? userId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String? alamatTerdeteksi;
  final String catatan;
  final String createdAt;
  SosStatus status;
  int retryCount;
  bool smsIntentOpened;

  SosEvent({
    required this.sosId,
    this.userId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.alamatTerdeteksi,
    required this.catatan,
    required this.createdAt,
    this.status = SosStatus.created,
    this.retryCount = 0,
    this.smsIntentOpened = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'sos_id': sosId,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'alamat_terdeteksi': alamatTerdeteksi,
      'catatan': catatan,
      'created_at': createdAt,
      'status': status.name,
      'retry_count': retryCount,
      'sms_intent_opened': smsIntentOpened,
    };
  }

  factory SosEvent.fromMap(Map<String, dynamic> map) {
    return SosEvent(
      sosId: map['sos_id'],
      userId: map['user_id'],
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      alamatTerdeteksi: map['alamat_terdeteksi'],
      catatan: map['catatan'] ?? '',
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
      status: SosStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => SosStatus.created),
      retryCount: map['retry_count'] ?? 0,
      smsIntentOpened: map['sms_intent_opened'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory SosEvent.fromJson(String source) => SosEvent.fromMap(json.decode(source));
}
