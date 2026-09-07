import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'notification_service.dart';

/// Service yang melakukan polling ke backend setiap [_pollInterval] detik
/// untuk mendeteksi kejadian SOS baru dalam radius [_radiusMeters] meter
/// dari posisi pengguna saat ini, lalu menampilkan notifikasi lokal.
class SosNearbyService {
  static final SosNearbyService _instance = SosNearbyService._internal();
  factory SosNearbyService() => _instance;
  SosNearbyService._internal();

  static const double _radiusMeters = 2000.0; // 2 km
  static const Duration _pollInterval = Duration(seconds: 30);

  Timer? _timer;
  double? _userLat;
  double? _userLng;

  /// ID SOS yang sudah pernah dinotifikasi agar tidak tampil berulang kali
  final Set<String> _notifiedSosIds = {};

  /// Mulai polling. Panggil ini setelah user login & lokasi tersedia.
  void start({double? lat, double? lng}) {
    _userLat = lat;
    _userLng = lng;

    // Cegah double-start
    _timer?.cancel();

    _timer = Timer.periodic(_pollInterval, (_) => _checkNearbySos());

    // Juga langsung cek sekali saat mulai
    _checkNearbySos();
  }

  /// Update lokasi user (dipanggil saat user berpindah lokasi atau buka app)
  void updateLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
  }

  /// Hentikan polling (saat user logout)
  void stop() {
    _timer?.cancel();
    _timer = null;
    _notifiedSosIds.clear();
  }

  /// Ambil lokasi terbaru device, update internal state
  Future<void> refreshLocation() async {
    try {
      final loc = await _getCurrentLocation();
      if (loc != null) {
        _userLat = loc.latitude;
        _userLng = loc.longitude;
      }
    } catch (_) {}
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkNearbySos() async {
    // Perbarui lokasi sebelum cek
    await refreshLocation();

    final userLat = _userLat;
    final userLng = _userLng;
    if (userLat == null || userLng == null) return;

    try {
      final events = await ApiService.fetchRecentSosEvents();
      if (events.isEmpty) return;

      for (final sos in events) {
        final sosId = sos['sos_id']?.toString() ?? sos['id']?.toString();
        if (sosId == null) continue;

        // Lewati jika sudah pernah dinotifikasi
        if (_notifiedSosIds.contains(sosId)) continue;

        final sosLat = _toDouble(sos['latitude']);
        final sosLng = _toDouble(sos['longitude']);
        if (sosLat == null || sosLng == null) continue;

        // Hitung jarak Haversine
        final distanceM = _haversineDistance(userLat, userLng, sosLat, sosLng);

        if (distanceM <= _radiusMeters) {
          // Tandai sudah dinotifikasi
          _notifiedSosIds.add(sosId);

          final address =
              sos['alamat_terdeteksi']?.toString() ??
              sos['address']?.toString() ??
              'Lokasi tidak diketahui';

          final distanceLabel = distanceM < 1000
              ? '${distanceM.toStringAsFixed(0)} m'
              : '${(distanceM / 1000).toStringAsFixed(1)} km';

          // Tampilkan notifikasi push lokal
          await NotificationService().showSosNearbyAlert(
            address: address,
            distanceLabel: distanceLabel,
          );
        }
      }
    } catch (_) {
      // Abaikan error jaringan; polling akan coba lagi di iterasi berikutnya
    }
  }

  /// Haversine formula – mengembalikan jarak dalam meter
  double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0; // meter
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double deg) => deg * (pi / 180);

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
