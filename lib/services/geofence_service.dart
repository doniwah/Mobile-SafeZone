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

  final _geofenceStreamController = StreamController<String>.broadcast();
  Stream<String> get onGeofenceAlert => _geofenceStreamController.stream;

  List<RedZone> get redZones => List.unmodifiable(_redZones);
  Set<String> get zonesInside => Set.unmodifiable(_zonesInside);

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

  void checkCoordinates(double latitude, double longitude) {
    for (var zone in _redZones) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        zone.latitude,
        zone.longitude,
      );

      if (distance <= zone.radius) {
        if (!_zonesInside.contains(zone.id)) {
          // Entered zone
          _zonesInside.add(zone.id);
          _triggerGeofenceAlert(zone);
        }
      } else {
        if (_zonesInside.contains(zone.id)) {
          // Exited zone into Safe Zone
          _zonesInside.remove(zone.id);
          _triggerSafeZoneExitAlert(zone);
        }
      }
    }
  }

  void _checkGeofences(Position position) {
    checkCoordinates(position.latitude, position.longitude);
  }

  void _triggerGeofenceAlert(RedZone zone) {
    final title = 'PERINGATAN ZONA MERAH!';
    final body = 'Anda telah memasuki daerah berbahaya: ${zone.name}. Harap waspada.';
    
    NotificationService().showGeofenceAlert(title, body);
    _geofenceStreamController.add('MASUK ZONA MERAH: ${zone.name}');
  }

  void _triggerSafeZoneExitAlert(RedZone zone) {
    final title = 'ANDA KEMBALI KE ZONA AMAN!';
    final body = 'Anda telah keluar dari area berbahaya: ${zone.name}. Anda sekarang berada di Zona Aman.';
    
    NotificationService().showSafeZoneAlert(title, body);
    _geofenceStreamController.add('KELUAR ZONA MERAH (ZONA AMAN): ${zone.name}');
  }

  /// Helper method for testing/simulating entering a red zone from UI
  void simulateZoneEntry([RedZone? targetZone]) {
    final zone = targetZone ?? (_redZones.isNotEmpty ? _redZones.first : RedZone(
      id: '99',
      name: 'Jl. Kalimantan (Rawan Begal)',
      latitude: -8.1725,
      longitude: 113.6983,
      radius: 300.0,
    ));

    _zonesInside.add(zone.id);
    _triggerGeofenceAlert(zone);
  }

  /// Helper method for testing/simulating exiting a red zone into SafeZone from UI
  void simulateZoneExit([RedZone? targetZone]) {
    final zone = targetZone ?? (_redZones.isNotEmpty ? _redZones.first : RedZone(
      id: '99',
      name: 'Jl. Kalimantan (Rawan Begal)',
      latitude: -8.1725,
      longitude: 113.6983,
      radius: 300.0,
    ));

    _zonesInside.remove(zone.id);
    _triggerSafeZoneExitAlert(zone);
  }

  void dispose() {
    _positionStreamSubscription?.cancel();
    _geofenceStreamController.close();
  }
}
