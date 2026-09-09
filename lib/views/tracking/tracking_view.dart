import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/gis_marker.dart';
import '../../services/api_service.dart';
import '../../services/geofence_service.dart';
import '../../services/safe_route_service.dart';
import '../../services/geo_corridor_service.dart';
import '../../widgets/safety_tips_bottom_sheet.dart';

class TrackingView extends StatefulWidget {
  const TrackingView({super.key});

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class FamilyMember {
  final String name;
  final String location;
  final double distance;
  final String status;

  FamilyMember({
    required this.name,
    required this.location,
    required this.distance,
    required this.status,
  });
}

class _TrackingViewState extends State<TrackingView> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final MapController _mapController = MapController();

  List<GisMarker> _incidentMarkers = [];
  bool _showStartSuggestions = false;
  bool _showDestSuggestions = false;
  bool _isFetchingGps = false;

  // Default start location is Lokasi Saat Ini (GPS Realtime)
  LumajangLocation _startLocation = LumajangLocation(
    id: 'current_location',
    name: 'Lokasi Saat Ini',
    location: const LatLng(-8.1331, 113.2224),
    address: 'Menghubungkan ke GPS perangkat...',
  );
  LumajangLocation? _destinationLocation;

  SafeRouteOption? _selectedRoute;
  List<SafeRouteOption> _availableRoutes = [];
  StreamSubscription<Map<String, dynamic>>? _corridorSubscription;

  final List<FamilyMember> _family = [
    FamilyMember(name: 'Ibu', location: 'Rumah', distance: 2.4, status: 'AMAN'),
  ];

  @override
  void initState() {
    super.initState();
    _startController.text = 'Lokasi Saat Ini';
    _loadIncidentMarkers();
    _fetchCurrentLocation();

    // Listen to Geo-Corridor route deviation alerts
    _corridorSubscription = GeoCorridorService().onCorridorAlert.listen((event) {
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${event['title']} - ${event['body']}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _corridorSubscription?.cancel();
    _startController.dispose();
    _destinationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _loadIncidentMarkers() async {
    try {
      final markers = await ApiService.fetchGisMarkers();
      setState(() {
        _incidentMarkers = markers;
      });
    } catch (_) {}
  }

  void _recalculateRoutes() {
    if (_destinationLocation == null) return;

    final routes = SafeRouteService().calculateSafeRoutes(
      start: _startLocation.location,
      destination: _destinationLocation!.location,
      incidentMarkers: _incidentMarkers,
      redZones: GeofenceService().redZones,
    );

    setState(() {
      _availableRoutes = routes;
      _selectedRoute = routes.isNotEmpty ? routes[0] : null;
      _showStartSuggestions = false;
      _showDestSuggestions = false;
    });

    if (_destinationLocation != null) {
      _mapController.move(_destinationLocation!.location, 14.2);
    }
  }

  Future<void> _fetchCurrentLocation({bool showFeedback = false}) async {
    if (_isFetchingGps) return;
    setState(() {
      _isFetchingGps = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Layanan lokasi (GPS) tidak aktif.'),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted && _startLocation.name == 'Lokasi Saat Ini') {
        setState(() {
          _startLocation = LumajangLocation(
            id: 'current_location',
            name: 'Lokasi Saat Ini',
            location: LatLng(lastKnown.latitude, lastKnown.longitude),
            address: 'GPS Akurasi Cepat',
          );
        });
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );

      if (mounted) {
        setState(() {
          _startLocation = LumajangLocation(
            id: 'current_location',
            name: 'Lokasi Saat Ini',
            location: LatLng(position.latitude, position.longitude),
            address: 'GPS Presisi Tinggi',
          );
          _startController.text = 'Lokasi Saat Ini';
          if (_destinationLocation != null) {
            _recalculateRoutes();
          }
        });

        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF10B981),
              content: Text('Berhasil menggunakan Lokasi Saat Ini (GPS)'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingGps = false;
        });
      }
    }
  }

  void _selectCurrentLocationAsStart() {
    setState(() {
      _startLocation = LumajangLocation(
        id: 'current_location',
        name: 'Lokasi Saat Ini',
        location: _startLocation.name == 'Lokasi Saat Ini'
            ? _startLocation.location
            : const LatLng(-8.1331, 113.2224),
        address: 'GPS Realtime Terkini',
      );
      _startController.text = 'Lokasi Saat Ini';
      _showStartSuggestions = false;
    });
    _fetchCurrentLocation(showFeedback: true);
    if (_destinationLocation != null) {
      _recalculateRoutes();
    }
  }

  void _selectStartLocation(LumajangLocation loc) {
    setState(() {
      _startLocation = loc;
      _startController.text = loc.name;
      _showStartSuggestions = false;
    });
    if (_destinationLocation != null) {
      _recalculateRoutes();
    }
  }

  void _selectDestinationLocation(LumajangLocation loc) {
    setState(() {
      _destinationLocation = loc;
      _destinationController.text = loc.name;
      _showDestSuggestions = false;
    });
    _recalculateRoutes();
  }

  void _addFamilyMember() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final distanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Tambah Keluarga',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Masukkan nama anggota keluarga',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi',
                  hintText: 'Misal: Kantor, Sekolah, dll',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: distanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Jarak (km)',
                  hintText: 'Misal: 1.5',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final location = locationController.text.trim();
                final distStr = distanceController.text.trim();
                final distance = double.tryParse(distStr) ?? 1.0;

                if (name.isNotEmpty && location.isNotEmpty) {
                  setState(() {
                    _family.add(
                      FamilyMember(
                        name: name,
                        location: location,
                        distance: distance,
                        status: 'AMAN',
                      ),
                    );
                  });
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B0F19),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRouteCard(SafeRouteOption route) {
    final isSelected = _selectedRoute == route;
    final isRecommended = _availableRoutes.isNotEmpty && _availableRoutes.first == route;
    final isMonitoringThisRoute = GeoCorridorService().isMonitoring && GeoCorridorService().activeRoute == route;

    Color cardBorderColor = const Color(0xFFE2E8F0);
    Color safetyBgColor = const Color(0xFFF1F5F9);
    Color safetyTextColor = const Color(0xFF64748B);

    if (isSelected) {
      cardBorderColor = route.color;
    }

    if (route.safetyLabel == 'Aman') {
      safetyBgColor = const Color(0xFFECFDF5);
      safetyTextColor = const Color(0xFF10B981);
    } else if (route.safetyLabel == 'Rawan') {
      safetyBgColor = const Color(0xFFFFFBEB);
      safetyTextColor = const Color(0xFFD97706);
    } else {
      safetyBgColor = const Color(0xFFFEF2F2);
      safetyTextColor = const Color(0xFFEF4444);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRoute = route;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor, width: isSelected ? 2.5 : 1),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: route.color.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: route.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          route.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? route.color : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: safetyBgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: safetyTextColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        route.safetyLabel == 'Aman'
                            ? Icons.verified_user_rounded
                            : (route.safetyLabel == 'Rawan' ? Icons.warning_rounded : Icons.dangerous_rounded),
                        color: safetyTextColor,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${route.safetyScore}/100 • ${route.safetyLabel.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: safetyTextColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              route.description,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Jarak: ${route.distanceKm} km',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: safetyTextColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Est: ${route.estimatedMinutes} Mnt',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'DIREKOMENDASIKAN SISTEM',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),

            // Geo-Corridor Action Bar inside selected route card
            if (isSelected) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.black.withOpacity(0.06)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          if (isMonitoringThisRoute) {
                            GeoCorridorService().stopMonitoring();
                          } else {
                            GeoCorridorService().startMonitoring(route);
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: isMonitoringThisRoute ? const Color(0xFF1E293B) : const Color(0xFF10B981),
                            content: Text(
                              isMonitoringThisRoute
                                  ? 'Pemantauan Koridor Aman Dihentikan'
                                  : 'Pemantauan Koridor Aman Aktif (Toleransi: 50m)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        isMonitoringThisRoute ? Icons.stop_circle_rounded : Icons.navigation_rounded,
                        size: 16,
                      ),
                      label: Text(
                        isMonitoringThisRoute ? 'Hentikan Koridor' : 'Aktifkan Geo-Koridor',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMonitoringThisRoute ? const Color(0xFF0F172A) : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Simulasi Penyimpangan Koridor',
                    onPressed: () {
                      GeoCorridorService().simulateDeviation();
                      setState(() {});
                    },
                    icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF2F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                      ),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchFilteredStart = SafeRouteService.lumajangLocations.where((loc) {
      final query = _startController.text.toLowerCase();
      return loc.name.toLowerCase().contains(query) || loc.address.toLowerCase().contains(query);
    }).toList();

    final searchFilteredDest = SafeRouteService.lumajangLocations.where((loc) {
      final query = _destinationController.text.toLowerCase();
      return loc.name.toLowerCase().contains(query) || loc.address.toLowerCase().contains(query);
    }).toList();

    final isCorridorActive = GeoCorridorService().isMonitoring;
    final activeCorridorRoute = GeoCorridorService().activeRoute;
    final isDeviated = GeoCorridorService().isDeviated;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'RUTE AMAN & GEO-CORRIDOR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 28,
                      color: Color(0xFF0F172A),
                      height: 1.2,
                      fontFamily: 'Inter',
                    ),
                    children: [
                      TextSpan(
                        text: 'Panduan Koridor ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'Jalur Bebas Bahaya.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Geo-Corridor Active Status Warning Banner
                if (isCorridorActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDeviated ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDeviated ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDeviated ? Colors.red : Colors.green).withOpacity(0.10),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDeviated ? Icons.warning_amber_rounded : Icons.shield_rounded,
                          color: isDeviated ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDeviated ? 'PENYIMPANGAN RUTE TERDETEKSI!' : 'PEMANTAUAN GEO-KORIDOR AKTIF',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: isDeviated ? const Color(0xFFEF4444) : const Color(0xFF047857),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isDeviated
                                    ? 'Posisi Anda menyimpang >50m dari rute ${activeCorridorRoute?.name ?? ""}. Segera kembali ke koridor aman!'
                                    : 'Pengawal rute aktif. Toleransi koridor: 50m dari ${activeCorridorRoute?.name ?? ""}.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDeviated ? const Color(0xFF7F1D1D) : const Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Location / Destination Search Card (Interactive Route Selector)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Start Location Input
                      Row(
                        children: [
                          const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _startController,
                              onTap: () {
                                setState(() {
                                  _showStartSuggestions = true;
                                  _showDestSuggestions = false;
                                });
                              },
                              onChanged: (_) {
                                setState(() {
                                  _showStartSuggestions = true;
                                });
                              },
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Pilih titik awal di Lumajang...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                          ),
                          if (_startLocation.name == 'Lokasi Saat Ini')
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _isFetchingGps
                                      ? const SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF10B981)),
                                        )
                                      : const Icon(Icons.gps_fixed_rounded, color: Color(0xFF10B981), size: 11),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'GPS AKTIF',
                                    style: TextStyle(color: Color(0xFF059669), fontSize: 9.5, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          GestureDetector(
                            onTap: () => _selectCurrentLocationAsStart(),
                            child: Tooltip(
                              message: 'Gunakan Lokasi Saat Ini (GPS)',
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.my_location_rounded,
                                  color: _startLocation.name == 'Lokasi Saat Ini' ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            height: 14,
                            child: VerticalDivider(
                              color: Color(0xFFCBD5E1),
                              thickness: 1.5,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      // Destination Input
                      Row(
                        children: [
                          const Icon(Icons.place_rounded, color: Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _destinationController,
                              onTap: () {
                                setState(() {
                                  _showDestSuggestions = true;
                                  _showStartSuggestions = false;
                                });
                              },
                              onChanged: (_) {
                                setState(() {
                                  _showDestSuggestions = true;
                                });
                              },
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Pilih titik tujuan di Lumajang...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                          ),
                          if (_destinationController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _destinationController.clear();
                                  _destinationLocation = null;
                                  _availableRoutes.clear();
                                  _selectedRoute = null;
                                });
                              },
                              child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                            )
                        ],
                      ),
                    ],
                  ),
                ),

                // Start Location Suggestions Dropdown
                if (_showStartSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 230),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)
                      ],
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        // Priority option: Lokasi Saat Ini (GPS)
                        ListTile(
                          dense: true,
                          tileColor: const Color(0xFFF0FDF4),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 14),
                          ),
                          title: Row(
                            children: const [
                              Text(
                                'Lokasi Saat Ini',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '(GPS DEFAULT)',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            _startLocation.address,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF065F46)),
                          ),
                          onTap: () => _selectCurrentLocationAsStart(),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ...searchFilteredStart.map((loc) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, color: Color(0xFF64748B), size: 16),
                            title: Text(
                              loc.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            subtitle: Text(
                              loc.address,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            onTap: () => _selectStartLocation(loc),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                // Destination Suggestions Dropdown
                if (_showDestSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchFilteredDest.length,
                      itemBuilder: (context, index) {
                        final loc = searchFilteredDest[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_rounded, color: Color(0xFFEF4444), size: 16),
                          title: Text(
                            loc.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          subtitle: Text(
                            loc.address,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          onTap: () => _selectDestinationLocation(loc),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),

                // Interactive Map View Container
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _startLocation.location,
                        initialZoom: 14.0,
                        minZoom: 10.0,
                        maxZoom: 17.0,
                      ),
                      children: [
                        // Map Tiles (OpenStreetMap)
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.geocrime.geocrime_app',
                        ),

                        // Red Zones circles
                        CircleLayer(
                          circles: GeofenceService().redZones.map((zone) {
                            return CircleMarker(
                              point: LatLng(zone.latitude, zone.longitude),
                              radius: zone.radius,
                              useRadiusInMeter: true,
                              color: const Color(0xFFEF4444).withOpacity(0.18),
                              borderColor: const Color(0xFFEF4444),
                              borderStrokeWidth: 1.5,
                            );
                          }).toList(),
                        ),

                        // Red Zones interactive markers (Tapping opens Safety Tips)
                        MarkerLayer(
                          markers: GeofenceService().redZones.map((zone) {
                            return Marker(
                              point: LatLng(zone.latitude, zone.longitude),
                              width: 34,
                              height: 34,
                              child: GestureDetector(
                                onTap: () {
                                  SafetyTipsBottomSheet.show(context, zone);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444).withOpacity(0.5),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.shield_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // Incident Markers circles
                        CircleLayer(
                          circles: _incidentMarkers.map((marker) {
                            final color = marker.category == 'Crime'
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF97316);
                            return CircleMarker(
                              point: LatLng(marker.latitude, marker.longitude),
                              radius: 120,
                              useRadiusInMeter: true,
                              color: color.withOpacity(0.20),
                              borderStrokeWidth: 0,
                            );
                          }).toList(),
                        ),

                        // Geo-Corridor Buffer Visual Layer (thick boundary when monitoring)
                        if (isCorridorActive && activeCorridorRoute != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: activeCorridorRoute.path,
                                color: (isDeviated ? const Color(0xFFEF4444) : activeCorridorRoute.color).withOpacity(0.25),
                                strokeWidth: 36.0, // Visual corridor buffer representation
                              ),
                            ],
                          ),

                        // Safe / Warning / Danger Polyline routing
                        if (_availableRoutes.isNotEmpty)
                          PolylineLayer(
                            polylines: _availableRoutes.map((route) {
                              final isSelected = _selectedRoute == route;
                              return Polyline(
                                points: route.path,
                                color: isSelected ? route.color : route.color.withOpacity(0.35),
                                strokeWidth: isSelected ? 6.0 : 3.5,
                                pattern: isSelected ? const StrokePattern.solid() : StrokePattern.dashed(segments: [6, 4]),
                              );
                            }).toList(),
                          ),

                        // User Start location and Destination Pin Markers
                        MarkerLayer(
                          markers: [
                            // Start Location Marker
                            Marker(
                              point: _startLocation.location,
                              width: 80,
                              height: 50,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _startLocation.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 24),
                                ],
                              ),
                            ),
                            // Destination Location Marker
                            if (_destinationLocation != null)
                              Marker(
                                point: _destinationLocation!.location,
                                width: 90,
                                height: 50,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _selectedRoute?.color ?? const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _destinationLocation!.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: _selectedRoute?.color ?? const Color(0xFFEF4444),
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Predefined Route Selector Options (under map)
                if (_availableRoutes.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'HASIL KALKULASI SKOR KEAMANAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Formula Haversine',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._availableRoutes.map((route) => _buildRouteCard(route)),
                  const SizedBox(height: 20),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.route_rounded, color: Color(0xFF94A3B8), size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Pilih Titik Tujuan di atas untuk menghitung Skor Keamanan Haversine & memetakan rute aman di Lumajang.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Anggota Keluarga Tracking Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PANTAU KELUARGA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: _addFamilyMember,
                      child: const Text(
                        '+ Tambah',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._family.map((member) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE0E7FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded, color: Color(0xFF4338CA), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${member.location} • ${member.distance} km dari Anda',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            member.status,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
