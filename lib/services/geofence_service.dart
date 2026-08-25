import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/red_zone.dart';
import '../database/app_database.dart';
import 'api_service.dart';
import 'dart:convert';
import 'notification_service.dart';

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;

  GeofenceService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  List<RedZone> _redZones = [];
  final Set<String> _zonesInside = {}; // Track zones currently inside to avoid spamming notifications

  Future<void> initialize() async {
    await _fetchRedZones();
    _startLocationTracking();
  }

  Future<void> _fetchRedZones() async {
    try {
      final response = await ApiService.getRequest('/zones'); // Assuming this endpoint exists
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data is Map && data.containsKey('data')) ? data['data'] as List : data as List;
        _redZones = list.map((json) => RedZone.fromJson(json)).toList();
        return;
      }
    } catch (_) {}

    // Fallback to mock data if API fails or is unreachable
    _redZones = AppDatabase.redZones.map((json) => RedZone.fromJson(json)).toList();
  }

  void _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _checkGeofences(position);
    });
  }

  void _checkGeofences(Position position) {
    for (var zone in _redZones) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );

      if (distance <= zone.radius) {
        if (!_zonesInside.contains(zone.id)) {
          // Entered zone
          _zonesInside.add(zone.id);
          NotificationService().showGeofenceAlert(
            'PERINGATAN ZONA MERAH!',
            'Anda telah memasuki daerah berbahaya: ${zone.name}. Harap waspada.',
          );
        }
      } else {
        if (_zonesInside.contains(zone.id)) {
          // Exited zone
          _zonesInside.remove(zone.id);
        }
      }
    }
  }

  void dispose() {
    _positionStreamSubscription?.cancel();
  }
}
