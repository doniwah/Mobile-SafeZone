import 'dart:async';
import 'package:flutter/foundation.dart';
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
  Timer? _refreshTimer;
  List<RedZone> _redZones = [];
  final Set<String> _zonesInside = {}; // Track zones currently inside to avoid spamming notifications

  final _geofenceStreamController = StreamController<String>.broadcast();
  Stream<String> get onGeofenceAlert => _geofenceStreamController.stream;

  final _zoneEnteredController = StreamController<RedZone>.broadcast();
  Stream<RedZone> get onZoneEntered => _zoneEnteredController.stream;

  List<RedZone> get redZones => List.unmodifiable(_redZones);
  Set<String> get zonesInside => Set.unmodifiable(_zonesInside);

  Future<void> initialize() async {
    await _fetchRedZones();
    _startLocationTracking();

    // Re-fetch red zones periodically every 5 minutes to keep up-to-date with backend changes
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _fetchRedZones();
    });
  }

  Future<void> refreshZones() async {
    await _fetchRedZones();
  }

  Future<void> _fetchRedZones() async {
    List<RedZone> loadedZones = [];

    // 1. Try public /map/statistics endpoint (Always accessible without auth token, contains full Makassar polygon zones)
    try {
      final response = await ApiService.getRequest('/map/statistics');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map) {
              final name = (item['nama_lokasi'] ?? '').toString();
              // Ignore safe zones
              if (name.toLowerCase().contains('safe zone') || name.toLowerCase().contains('zona aman')) {
                continue;
              }
              final reports = item['reports'] as List? ?? [];
              final totalLaporan = (item['total_laporan'] as num?)?.toInt() ?? reports.length;

              String dangerLevel = 'Tinggi';
              String category = 'Zona Rawan Kejahatan';
              if (reports.isNotEmpty) {
                final firstCat = reports[0]['kategori']?['nama_kategori'] ?? reports[0]['judul_laporan'];
                if (firstCat != null) category = firstCat.toString();
                dangerLevel = totalLaporan > 1 ? 'Sangat Tinggi' : 'Tinggi';
              } else if (name.toLowerCase().contains('rawan')) {
                dangerLevel = 'Tinggi';
              }

              final zoneMap = <String, dynamic>{
                'id': item['id']?.toString() ?? name,
                'name': name,
                'polygon_geojson': item['polygon_geojson'],
                'category': category,
                'danger_level': dangerLevel,
              };

              if (reports.isNotEmpty && reports[0]['latitude'] != null) {
                zoneMap['latitude'] = reports[0]['latitude'];
                zoneMap['longitude'] = reports[0]['longitude'];
              }

              final zone = RedZone.fromJson(zoneMap);
              loadedZones.add(zone);
            }
          }
          if (loadedZones.isNotEmpty) {
            debugPrint('GeofenceService: Berhasil memuat ${loadedZones.length} zona dari /map/statistics');
          }
        }
      }
    } catch (e) {
      debugPrint('GeofenceService: Error /map/statistics: $e');
    }

    // 2. Try dedicated /zones endpoint
    try {
      final response = await ApiService.getRequest('/zones');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data is Map && data.containsKey('data')) ? data['data'] as List : data as List;
        final zones = list.map((json) => RedZone.fromJson(json)).toList();
        for (var z in zones) {
          if (!loadedZones.any((lz) => lz.id == z.id || lz.name == z.name)) {
            loadedZones.add(z);
          }
        }
      }
    } catch (_) {}

    // 3. Try /home endpoint
    try {
      final response = await ApiService.getRequest('/home');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('locations')) {
          final locs = data['locations'] as List;
          final filtered = locs.where((loc) {
            final st = (loc['status_kerawanan'] ?? '').toString().toLowerCase();
            return st.contains('rawan') || st.contains('bahaya') || st.contains('tidak aman');
          }).map((json) => RedZone.fromJson(json)).toList();

          for (var z in filtered) {
            if (!loadedZones.any((lz) => lz.id == z.id || lz.name == z.name)) {
              loadedZones.add(z);
            }
          }
        }
      }
    } catch (_) {}

    if (loadedZones.isNotEmpty) {
      _redZones = loadedZones;
      debugPrint('GeofenceService: Total zona aktif: ${_redZones.length}');
    } else if (_redZones.isEmpty) {
      _redZones = AppDatabase.redZones.map((json) => RedZone.fromJson(json)).toList();
      debugPrint('GeofenceService: Menggunakan ${_redZones.length} zona mock bawaan');
    }
  }

  void startTracking() {
    _startLocationTracking();
  }

  Future<void> checkCurrentLocation() async {
    try {
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      checkCoordinates(pos.latitude, pos.longitude);
    } catch (_) {}
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

    // Immediate check on startup using last known or current position
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        _checkGeofences(lastPos);
      }
      final currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      _checkGeofences(currentPos);
    } catch (_) {}

    _positionStreamSubscription?.cancel();
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
      final bool isInside = zone.containsPoint(latitude, longitude);

      if (isInside) {
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
    final title = 'PERINGATAN ZONA MERAH: ${zone.name}';
    final body = 'Anda memasuki kawasan ${zone.category} (${zone.dangerLevel}). Harap waspada dan ikuti panduan keselamatan.';
    
    NotificationService().showGeofenceAlert(
      title,
      body,
      category: zone.category,
      tips: zone.effectivePreventionTips,
    );
    _geofenceStreamController.add('MASUK ZONA MERAH: ${zone.name}');
    _zoneEnteredController.add(zone);
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
      category: 'Rawan Begal & Penodongan',
      dangerLevel: 'Sangat Tinggi',
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
      category: 'Rawan Begal & Penodongan',
      dangerLevel: 'Sangat Tinggi',
    ));

    _zonesInside.remove(zone.id);
    _triggerSafeZoneExitAlert(zone);
  }

  void dispose() {
    _refreshTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _geofenceStreamController.close();
    _zoneEnteredController.close();
  }
}
