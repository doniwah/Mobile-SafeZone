import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'safe_route_service.dart';
import 'notification_service.dart';

class GeoCorridorService {
  static final GeoCorridorService _instance = GeoCorridorService._internal();
  factory GeoCorridorService() => _instance;
  GeoCorridorService._internal();

  StreamSubscription<Position>? _positionSubscription;
  bool _isMonitoring = false;
  SafeRouteOption? _activeRoute;
  double _corridorThresholdMeters = 50.0; // Toleransi penyimpangan default (50 meter)
  bool _isDeviated = false;

  final _corridorAlertController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCorridorAlert => _corridorAlertController.stream;

  bool get isMonitoring => _isMonitoring;
  SafeRouteOption? get activeRoute => _activeRoute;
  double get corridorThresholdMeters => _corridorThresholdMeters;
  bool get isDeviated => _isDeviated;

  /// Memulai pemantauan koridor rute aman
  void startMonitoring(SafeRouteOption route, {double corridorThresholdMeters = 50.0}) {
    _activeRoute = route;
    _corridorThresholdMeters = corridorThresholdMeters;
    _isMonitoring = true;
    _isDeviated = false;

    _startGpsTracking();
  }

  /// Menghentikan pemantauan koridor rute
  void stopMonitoring() {
    _isMonitoring = false;
    _activeRoute = null;
    _isDeviated = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void _startGpsTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update setiap 5 meter
      ),
    ).listen((Position position) {
      if (_isMonitoring && _activeRoute != null) {
        checkPosition(LatLng(position.latitude, position.longitude));
      }
    });
  }

  /// Menghitung jarak minimum (meter) posisi pengguna ke garis rute
  double calculateMinDistanceToRoute(LatLng userLoc, List<LatLng> path) {
    if (path.isEmpty) return 0.0;
    if (path.length == 1) {
      return Geolocator.distanceBetween(
        userLoc.latitude,
        userLoc.longitude,
        path.first.latitude,
        path.first.longitude,
      );
    }

    double minDistance = double.infinity;

    for (int i = 0; i < path.length - 1; i++) {
      final a = path[i];
      final b = path[i + 1];
      final closestPoint = _getClosestPointOnSegment(userLoc, a, b);
      final dist = Geolocator.distanceBetween(
        userLoc.latitude,
        userLoc.longitude,
        closestPoint.latitude,
        closestPoint.longitude,
      );

      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    return minDistance;
  }

  /// Mencari titik terdekat pada segmen garis AB dari titik P
  LatLng _getClosestPointOnSegment(LatLng p, LatLng a, LatLng b) {
    final double x = p.longitude;
    final double y = p.latitude;
    final double x1 = a.longitude;
    final double y1 = a.latitude;
    final double x2 = b.longitude;
    final double y2 = b.latitude;

    final double dx = x2 - x1;
    final double dy = y2 - y1;

    if (dx == 0 && dy == 0) return a;

    final double t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);

    if (t < 0) return a;
    if (t > 1) return b;

    return LatLng(y1 + t * dy, x1 + t * dx);
  }

  /// Memeriksa apakah posisi pengguna menyimpang dari koridor rute
  void checkPosition(LatLng userLoc) {
    if (!_isMonitoring || _activeRoute == null) return;

    final distanceMeters = calculateMinDistanceToRoute(userLoc, _activeRoute!.path);

    if (distanceMeters > _corridorThresholdMeters) {
      if (!_isDeviated) {
        _isDeviated = true;
        _triggerDeviationAlert(distanceMeters);
      }
    } else {
      if (_isDeviated) {
        _isDeviated = false; // Kembali masuk koridor
      }
    }
  }

  void _triggerDeviationAlert(double distanceMeters) {
    final routeName = _activeRoute?.name ?? 'Rute Aman';
    final title = 'PERINGATAN KORIDOR RUTE!';
    final body = 'Anda menyimpang ${distanceMeters.toInt()}m dari $routeName. Mohon kembali ke jalur aman!';

    NotificationService().showCorridorAlert(title, body);

    _corridorAlertController.add({
      'type': 'DEVIATION_ALERT',
      'title': title,
      'body': body,
      'distanceMeters': distanceMeters,
      'routeName': routeName,
    });
  }

  /// Helper untuk simulasi penyimpangan rute dari UI
  void simulateDeviation() {
    if (!_isMonitoring || _activeRoute == null) {
      // Jika belum aktif, aktifkan sampel rute secara otomatis
      final sampleRoute = SafeRouteOption(
        name: 'Rute Aman Lumajang',
        safetyScore: 95,
        safetyLabel: 'Aman',
        color: const Color(0xFF10B981),
        distanceKm: 2.5,
        estimatedMinutes: 6,
        path: const [
          LatLng(-8.1331, 113.2224),
          LatLng(-8.1331, 113.2150),
          LatLng(-8.1260, 113.2150),
          LatLng(-8.1250, 113.2190),
        ],
        description: 'Simulasi koridor rute aman',
        minDistanceToHazardMeters: 500,
      );
      startMonitoring(sampleRoute);
    }

    _isDeviated = true;
    _triggerDeviationAlert(145.0); // Simulasi menyimpang 145 meter dari koridor
  }

  void dispose() {
    _positionSubscription?.cancel();
    _corridorAlertController.close();
  }
}
