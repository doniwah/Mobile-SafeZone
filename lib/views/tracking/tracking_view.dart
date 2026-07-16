import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/gis_marker.dart';
import '../../services/api_service.dart';

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

class RouteOption {
  final String name;
  final String safety; // 'Aman', 'Rawan', 'Bahaya'
  final Color color;
  final double distance;
  final List<LatLng> path;
  final String description;

  RouteOption({
    required this.name,
    required this.safety,
    required this.color,
    required this.distance,
    required this.path,
    required this.description,
  });
}

class _TrackingViewState extends State<TrackingView> {
  final TextEditingController _destinationController = TextEditingController();
  final MapController _mapController = MapController();
  
  List<GisMarker> _incidentMarkers = [];
  bool _showSuggestions = false;
  String _selectedDestination = '';
  RouteOption? _selectedRoute;
  List<RouteOption> _availableRoutes = [];

  final List<String> _suggestions = ['Jalan Kalimantan', 'Jl. Wolter Monginsidi'];
  
  final List<FamilyMember> _family = [
    FamilyMember(name: 'Ibu', location: 'Rumah', distance: 2.4, status: 'AMAN'),
  ];

  @override
  void initState() {
    super.initState();
    _loadIncidentMarkers();
  }

  @override
  void dispose() {
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

  void _selectDestination(String dest) {
    setState(() {
      _selectedDestination = dest;
      _showSuggestions = false;
      _destinationController.text = dest;

      LatLng destLatLng;
      if (dest == 'Jalan Kalimantan') {
        final marker = _incidentMarkers.firstWhere(
          (m) => m.locationName.toLowerCase().contains('kalimantan'),
          orElse: () => GisMarker(
            title: 'Pembegalan',
            date: '23-05-2024 00:20:33',
            category: 'Crime',
            locationName: 'Jalan Kalimantan',
            chronology: '',
            position: const Offset(0.35, 0.45),
            latitude: -8.125,
            longitude: 113.219,
            imagePath: '',
          ),
        );
        destLatLng = LatLng(marker.latitude, marker.longitude);
      } else {
        final marker = _incidentMarkers.firstWhere(
          (m) => m.locationName.toLowerCase().contains('monginsidi') || m.locationName.toLowerCase().contains('wolter'),
          orElse: () => GisMarker(
            title: 'Penjambretan',
            date: '23-05-2024 16:20:33',
            category: 'Crime',
            locationName: 'Jl. Wolter Monginsidi',
            chronology: '',
            position: const Offset(0.68, 0.32),
            latitude: -8.140,
            longitude: 113.230,
            imagePath: '',
          ),
        );
        destLatLng = LatLng(marker.latitude, marker.longitude);
      }

      final startLatLng = const LatLng(-8.1331, 113.2224); // Alun-alun
      
      if (dest == 'Jalan Kalimantan') {
        _availableRoutes = [
          RouteOption(
            name: 'Rute Aman (Via Barat)',
            safety: 'Aman',
            color: const Color(0xFF10B981), // Green
            distance: 2.6,
            description: 'Jalur memutar via barat menghindari area rawan pembegalan.',
            path: [
              startLatLng,
              const LatLng(-8.1331, 113.2150),
              const LatLng(-8.1260, 113.2150),
              destLatLng,
            ],
          ),
          RouteOption(
            name: 'Rute Rawan (Via Tengah)',
            safety: 'Rawan',
            color: const Color(0xFFF59E0B), // Yellow/Amber
            distance: 2.0,
            description: 'Jalur tengah, melintasi dekat batas terluar area rawan.',
            path: [
              startLatLng,
              const LatLng(-8.1310, 113.2250),
              const LatLng(-8.1250, 113.2250),
              destLatLng,
            ],
          ),
          RouteOption(
            name: 'Rute Bahaya (Via Timur)',
            safety: 'Bahaya',
            color: const Color(0xFFEF4444), // Red
            distance: 1.4,
            description: 'Jalur tercepat namun melintasi langsung titik kriminalitas aktif.',
            path: [
              startLatLng,
              const LatLng(-8.1300, 113.2210),
              destLatLng,
            ],
          ),
        ];
      } else {
        _availableRoutes = [
          RouteOption(
            name: 'Rute Aman (Via Barat-Selatan)',
            safety: 'Aman',
            color: const Color(0xFF10B981), // Green
            distance: 2.4,
            description: 'Jalur memutar memutari area kejadian penjambretan.',
            path: [
              startLatLng,
              const LatLng(-8.1380, 113.2150),
              const LatLng(-8.1420, 113.2250),
              destLatLng,
            ],
          ),
          RouteOption(
            name: 'Rute Rawan (Via Tengah)',
            safety: 'Rawan',
            color: const Color(0xFFF59E0B), // Yellow/Amber
            distance: 1.9,
            description: 'Jalur melintasi batas jalan utama yang cukup rawan.',
            path: [
              startLatLng,
              const LatLng(-8.1310, 113.2280),
              const LatLng(-8.1360, 113.2300),
              destLatLng,
            ],
          ),
          RouteOption(
            name: 'Rute Bahaya (Jalur Pintas)',
            safety: 'Bahaya',
            color: const Color(0xFFEF4444), // Red
            distance: 1.5,
            description: 'Jalur tersingkat, namun melintasi langsung wilayah rawan penjambretan.',
            path: [
              startLatLng,
              destLatLng,
            ],
          ),
        ];
      }

      // Default select the recommended safe route (Green, index 0)
      _selectedRoute = _availableRoutes[0];
      
      // Move map to center the routes
      _mapController.move(destLatLng, 14.5);
    });
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

  Widget _buildRouteCard(RouteOption route) {
    final isSelected = _selectedRoute == route;
    final isRecommended = route.safety == 'Aman';

    Color cardBorderColor = const Color(0xFFE2E8F0);
    Color safetyBgColor = const Color(0xFFF1F5F9);
    Color safetyTextColor = const Color(0xFF64748B);
    
    if (isSelected) {
      cardBorderColor = route.color;
    }
    
    if (route.safety == 'Aman') {
      safetyBgColor = const Color(0xFFECFDF5);
      safetyTextColor = const Color(0xFF10B981);
    } else if (route.safety == 'Rawan') {
      safetyBgColor = const Color(0xFFFFFBEB);
      safetyTextColor = const Color(0xFFD97706);
    } else if (route.safety == 'Bahaya') {
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
          border: Border.all(color: cardBorderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: route.color.withOpacity(0.08),
                blurRadius: 10,
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
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: route.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      route.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? route.color : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: safetyBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    route.safety.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: safetyTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              route.description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jarak: ${route.distance} km',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: safetyTextColor,
                  ),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'LIVE TRACKING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      color: Color(0xFF0F172A),
                      height: 1.2,
                      fontFamily: 'Inter',
                    ),
                    children: [
                      TextSpan(
                        text: 'Lokasi ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: 'orang terkasih.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Location / Destination Search Card (Google Maps Style)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Location Input
                      Row(
                        children: [
                          const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: 'Jl. Panjaitan #12 (Lokasi Anda)',
                              readOnly: true,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
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
                            height: 16,
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
                                  _showSuggestions = true;
                                });
                              },
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Masukkan tujuan...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
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
                                  _selectedDestination = '';
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
                
                // Autocomplete Suggestions List popup
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: _suggestions.map((dest) {
                        return ListTile(
                          leading: const Icon(Icons.history_rounded, color: Color(0xFF94A3B8), size: 18),
                          title: Text(
                            dest,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                          ),
                          onTap: () => _selectDestination(dest),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 20),

                // Interactive Map View container
                Container(
                  height: 300,
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
                      options: const MapOptions(
                        initialCenter: LatLng(-8.1331, 113.2224), // Alun-Alun Lumajang
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
                        // Live Heatmap density Layer centered on actual incidents
                        CircleLayer(
                          circles: _incidentMarkers.expand((marker) {
                            final color = marker.category == 'Crime'
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF97316);
                            final latLng = LatLng(marker.latitude, marker.longitude);
                            return [
                              CircleMarker(
                                point: latLng,
                                radius: 250,
                                useRadiusInMeter: true,
                                color: color.withOpacity(0.12),
                                borderStrokeWidth: 0,
                              ),
                              CircleMarker(
                                point: latLng,
                                radius: 120,
                                useRadiusInMeter: true,
                                color: color.withOpacity(0.22),
                                borderStrokeWidth: 0,
                              ),
                              CircleMarker(
                                point: latLng,
                                radius: 60,
                                useRadiusInMeter: true,
                                color: color.withOpacity(0.35),
                                borderStrokeWidth: 0,
                              ),
                            ];
                          }).toList(),
                        ),
                        // Safe / Warning / Danger Polyline routing
                        if (_availableRoutes.isNotEmpty)
                          PolylineLayer(
                            polylines: _availableRoutes.map((route) {
                              final isSelected = _selectedRoute == route;
                              return Polyline(
                                points: route.path,
                                color: isSelected ? route.color : route.color.withOpacity(0.35),
                                strokeWidth: isSelected ? 5.5 : 3.0,
                                pattern: isSelected ? const StrokePattern.solid() : StrokePattern.dashed(segments: [6, 4]),
                              );
                            }).toList(),
                          ),
                        // User Current location and Destination Pin Markers
                        MarkerLayer(
                          markers: [
                            // Start (My Location)
                            Marker(
                              point: const LatLng(-8.1331, 113.2224),
                              width: 45,
                              height: 45,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Saya',
                                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Icon(Icons.my_location_rounded, color: Color(0xFF3B82F6), size: 24),
                                ],
                              ),
                            ),
                            // Destination marker
                            if (_selectedRoute != null)
                              Marker(
                                point: _selectedRoute!.path.last,
                                width: 90,
                                height: 45,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _selectedRoute!.color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _selectedDestination,
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.location_on_rounded, color: _selectedRoute!.color, size: 24),
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
                  const Text(
                    'ANALISIS RUTE AMAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.5,
                    ),
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
                    child: const Text(
                      'Masukkan tujuan di atas untuk memuat rekomendasi rute aman.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Keluarga Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'KELUARGA',
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
                        'tambah',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Terpantau.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),

                // Family Member List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _family.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: Color(0xFFF1F5F9),
                    height: 1,
                    thickness: 1,
                  ),
                  itemBuilder: (context, index) {
                    final member = _family[index];
                    final initial = member.name.isNotEmpty ? member.name[0] : '?';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEDE9FE), // Light purple
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Color(0xFF8B5CF6),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.place_outlined,
                                      size: 13,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${member.location} · ${member.distance} km',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          Text(
                            member.status,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981), // AMAN
                              letterSpacing: 0.5,
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80), // Spacer padding for bottom floating bar
              ],
            ),
          ),
        ),
      ),
    );
  }
}
