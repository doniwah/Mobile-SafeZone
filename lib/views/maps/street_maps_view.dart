import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/gis_marker.dart';
import '../../models/red_zone.dart';
import '../../services/api_service.dart';
import '../../services/geofence_service.dart';
import '../../widgets/desktop_frame.dart';
import '../../widgets/safety_tips_bottom_sheet.dart';

class StreetMapsView extends StatefulWidget {
  final String? initialFilter; // 'Crime' or 'Accident' or null
  const StreetMapsView({super.key, this.initialFilter});

  @override
  State<StreetMapsView> createState() => _StreetMapsViewState();
}

class _StreetMapsViewState extends State<StreetMapsView> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  bool _filterCrime = true;
  bool _filterAccident = true;
  bool _heatmapEnabled = true;

  GisMarker? _selectedMarker;
  String _searchQuery = "";
  List<GisMarker> _markers = [];
  bool _isLoading = true;
  StreamSubscription<RedZone>? _zoneEnteredSub;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter == 'Crime') {
      _filterCrime = true;
      _filterAccident = false;
    } else if (widget.initialFilter == 'Accident') {
      _filterCrime = false;
      _filterAccident = true;
    }
    _loadMarkers();

    // Listen for geofence entry events to display in-app safety tips bottom sheet
    _zoneEnteredSub = GeofenceService().onZoneEntered.listen((zone) {
      if (mounted) {
        SafetyTipsBottomSheet.show(context, zone);
      }
    });
  }

  @override
  void dispose() {
    _zoneEnteredSub?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkers() async {
    try {
      final list = await ApiService.fetchGisMarkers();
      if (mounted) {
        setState(() {
          _markers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.6),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent() {
      // Filter list of markers based on selections and search string
      final visibleMarkers = _markers.where((m) {
        if (m.category == 'Crime' && !_filterCrime) return false;
        if (m.category == 'Accident' && !_filterAccident) return false;
        if (_searchQuery.isNotEmpty && !m.locationName.toLowerCase().contains(_searchQuery)) return false;
        return true;
      }).toList();

      return Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Premium Slate Dark
        body: Stack(
          children: [
            // GIS MAP INTERACTIVE VIEWPORT (OpenStreetMap)
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(-8.1331, 113.2224), // Alun-Alun Lumajang
                  initialZoom: 14.0,
                  minZoom: 8.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.geocrime.geocrime_app',
                  ),
                  // Geofence Red Zones Visual Circles
                  CircleLayer(
                    circles: GeofenceService().redZones.map((zone) {
                      return CircleMarker(
                        point: LatLng(zone.latitude, zone.longitude),
                        radius: zone.radius,
                        useRadiusInMeter: true,
                        color: const Color(0xFFEF4444).withOpacity(0.22),
                        borderColor: const Color(0xFFDC2626),
                        borderStrokeWidth: 2.0,
                      );
                    }).toList(),
                  ),
                  // Geofence Red Zones Interactive Centroid Markers
                  MarkerLayer(
                    markers: GeofenceService().redZones.map((zone) {
                      return Marker(
                        point: LatLng(zone.latitude, zone.longitude),
                        width: 38,
                        height: 38,
                        child: GestureDetector(
                          onTap: () {
                            SafetyTipsBottomSheet.show(context, zone);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.55),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_heatmapEnabled) ...[
                    PolygonLayer(
                      polygons: _districts.map<Polygon>((district) {
                        return Polygon(
                          points: district.polygonPoints,
                          color: district.color.withOpacity(0.55),
                          borderColor: Colors.white.withOpacity(0.75),
                          borderStrokeWidth: 1.5,
                        );
                      }).toList(),
                    ),
                    MarkerLayer(
                      markers: _districts.map((district) {
                        return Marker(
                          point: district.centroid,
                          width: 120,
                          height: 30,
                          child: Center(
                            child: Text(
                              district.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.black.withOpacity(0.75),
                                letterSpacing: 0.5,
                                shadows: const [
                                  Shadow(
                                    color: Colors.white,
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                  Shadow(
                                    color: Colors.white,
                                    offset: Offset(0, -1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  // User Current Location (Blue Dot) is always rendered
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: const LatLng(-8.1331, 113.2224),
                        width: 48,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!_heatmapEnabled)
                    MarkerLayer(
                      markers: visibleMarkers.map((marker) {
                        final markerColor = marker.category == 'Crime'
                            ? const Color(0xFFEF4444) // Red
                            : const Color(0xFFF97316); // Orange
                        final isSelected = _selectedMarker == marker;
                        final latLng = LatLng(marker.latitude, marker.longitude);

                        return Marker(
                          point: latLng,
                          width: isSelected ? 80 : 60,
                          height: isSelected ? 80 : 60,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMarker = marker;
                              });
                              _mapController.move(latLng, 15.0);
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isSelected)
                                  TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 1.0, end: 1.8),
                                    duration: const Duration(seconds: 1),
                                    builder: (context, double val, child) {
                                      return Container(
                                        width: 40 * val,
                                        height: 40 * val,
                                        decoration: BoxDecoration(
                                          color: markerColor.withOpacity(0.3 * (1.8 - val)),
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    },
                                  ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? markerColor.withOpacity(0.25)
                                        : markerColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? markerColor : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: markerColor,
                                    size: isSelected ? 36 : 30,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  ),
                ),
              ),

            // TOP NAVIGATION & CONTROL BAR
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Top Appbar Row with glassmorphism styling
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withOpacity(0.85),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.toLowerCase();
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Cari alamat kejahatan/kecelakaan...',
                                hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF3B82F6), size: 20),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Filters Checkboxes Row (Modern Chips)
                    Row(
                      children: [
                        // Accident Toggle
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _filterAccident = !_filterAccident;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: _filterAccident
                                  ? const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)])
                                  : null,
                              color: _filterAccident ? null : const Color(0xFF0F172A).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                              border: Border.all(
                                color: _filterAccident ? Colors.transparent : Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _filterAccident ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Accident',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Crime Toggle
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _filterCrime = !_filterCrime;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: _filterCrime
                                  ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                                  : null,
                              color: _filterCrime ? null : const Color(0xFF0F172A).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                              border: Border.all(
                                color: _filterCrime ? Colors.transparent : Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _filterCrime ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Crime',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // MAP LEGEND AND SIDE BAR TOGGLES
            Positioned(
              right: 16,
              bottom: _selectedMarker != null ? 250 : 36,
              child: Column(
                children: [
                  // Heatmap Button Toggle
                  FloatingActionButton.small(
                    heroTag: 'heatmapBtn',
                    onPressed: () {
                      setState(() {
                        _heatmapEnabled = !_heatmapEnabled;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF1E293B),
                          content: Text(
                            _heatmapEnabled ? 'Heatmap Kerawanan Aktif' : 'Heatmap Dinonaktifkan',
                            style: const TextStyle(color: Colors.white),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    backgroundColor: _heatmapEnabled ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: const Icon(Icons.map_rounded, size: 20),
                  ),
                  const SizedBox(height: 12),

                  // Geofence Test / Simulation Button
                  FloatingActionButton.small(
                    heroTag: 'geofenceSimBtn',
                    onPressed: () {
                      final zones = GeofenceService().redZones;
                      final targetZone = zones.isNotEmpty ? zones.first : null;
                      if (targetZone != null) {
                        _mapController.move(LatLng(targetZone.latitude, targetZone.longitude), 15.0);
                      }
                      GeofenceService().simulateZoneEntry(targetZone);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFFEF4444),
                          content: Row(
                            children: const [
                              Icon(Icons.warning_amber_rounded, color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Simulasi: Masuk Zona Merah (Notifikasi & Saran Pencegahan Aktif!)',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: const Icon(Icons.shield_rounded, size: 20),
                  ),
                  const SizedBox(height: 12),

                  // SafeZone Exit / Exit Red Zone Simulation Button
                  FloatingActionButton.small(
                    heroTag: 'safezoneExitSimBtn',
                    onPressed: () {
                      final zones = GeofenceService().redZones;
                      final targetZone = zones.isNotEmpty ? zones.first : null;
                      GeofenceService().simulateZoneExit(targetZone);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF10B981),
                          content: Row(
                            children: const [
                              Icon(Icons.verified_user_rounded, color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Simulasi SafeZone: Pengguna telah keluar dari Zona Merah & masuk Zona Aman!',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: const Icon(Icons.verified_user_rounded, size: 20),
                  ),
                  const SizedBox(height: 12),

                  // My Location Button
                  FloatingActionButton.small(
                    heroTag: 'myLocBtn',
                    onPressed: () {
                      _mapController.move(const LatLng(-8.1331, 113.2224), 14.0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFF1E293B),
                          content: Text('Memusatkan peta ke lokasi Anda...', style: TextStyle(color: Colors.white)),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: const Color(0xFF3B82F6),
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: const Icon(Icons.my_location_rounded, size: 20),
                  ),
                ],
              ),
            ),

            // MAP KEY/LEGEND (Polished panel)
            Positioned(
              left: 16,
              bottom: _selectedMarker != null ? 250 : 36,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.circle, color: Color(0xFFEF4444), size: 10),
                        SizedBox(width: 8),
                        Text(
                          'Kejahatan',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.circle, color: Color(0xFFF97316), size: 10),
                        SizedBox(width: 8),
                        Text(
                          'Kecelakaan',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.shield_rounded, color: Color(0xFFEF4444), size: 11),
                        SizedBox(width: 7),
                        Text(
                          'Zona Merah (Geofence)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFCA5A5)),
                        ),
                      ],
                    ),
                    if (_heatmapEnabled) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'KERAWANAN',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(width: 12, height: 6, color: const Color(0xFF10B981)),
                          Container(width: 12, height: 6, color: const Color(0xFFFBBF24)),
                          Container(width: 12, height: 6, color: const Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          const Text(
                            'Rndh - Tnggi',
                            style: TextStyle(fontSize: 8, color: Colors.white70),
                          ),
                        ],
                      )
                    ]
                  ],
                ),
              ),
            ),

            // MARKER DETAIL MODAL DIALOG (SLIDE POPUP - Premium Redesign)
            if (_selectedMarker != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header detail row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _selectedMarker!.category == 'Crime'
                                  ? const Color(0xFFEF4444).withOpacity(0.2)
                                  : const Color(0xFFF97316).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedMarker!.category == 'Crime'
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFF97316),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _selectedMarker!.category == 'Crime' ? 'KEJAHATAN' : 'KECELAKAAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: _selectedMarker!.category == 'Crime'
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFFFDBA74),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              setState(() {
                                _selectedMarker = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Title & Location name
                      Text(
                        _selectedMarker!.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedMarker!.locationName,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Divider
                      Container(
                        height: 1,
                        color: Colors.white.withOpacity(0.08),
                      ),
                      const SizedBox(height: 12),
                      // Chronology Text
                      Text(
                        _selectedMarker!.chronology,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      // Image Thumbnail & Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                _selectedMarker!.date,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedMarker!.imagePath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                _selectedMarker!.imagePath!,
                                width: 50,
                                height: 35,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 50,
                                  height: 35,
                                  color: Colors.white.withOpacity(0.05),
                                  child: const Icon(Icons.image_not_supported_rounded, size: 14, color: Colors.grey),
                                ),
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

            // HEATMAP / MARKERS Top-Right toggle button
            Positioned(
              top: 136,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _heatmapEnabled = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _heatmapEnabled ? const Color(0xFF1D4ED8) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'HEATMAP',
                          style: TextStyle(
                            color: _heatmapEnabled ? Colors.white : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _heatmapEnabled = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_heatmapEnabled ? const Color(0xFF1D4ED8) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'MARKERS',
                          style: TextStyle(
                            color: !_heatmapEnabled ? Colors.white : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Kriminalitas Heatmap Legend bottom-right card
            if (_heatmapEnabled)
              Positioned(
                bottom: 24,
                right: 16,
                child: Container(
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tingkat Kriminalitas',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildLegendItem('Aman', const Color(0xFFE2E8F0)),
                      const SizedBox(height: 6),
                      _buildLegendItem('Rawan (1-9)', const Color(0xFFF97316)),
                      const SizedBox(height: 6),
                      _buildLegendItem('Sangat Rawan (10-19)', const Color(0xFFEF4444)),
                      const SizedBox(height: 6),
                      _buildLegendItem('Kritis (>= 20)', const Color(0xFF991B1B)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return DesktopFrame(
      child: mainContent(),
    );
  }
}

class DistrictHeatmap {
  final String name;
  final List<LatLng> polygonPoints;
  final LatLng centroid;
  final String status;
  final Color color;

  const DistrictHeatmap({
    required this.name,
    required this.polygonPoints,
    required this.centroid,
    required this.status,
    required this.color,
  });
}

final List<DistrictHeatmap> _districts = [
  DistrictHeatmap(
    name: 'SUKODONO',
    centroid: const LatLng(-8.095, 113.225),
    status: 'Rawan',
    color: const Color(0xFFF97316),
    polygonPoints: const [
      LatLng(-8.115, 113.210),
      LatLng(-8.085, 113.215),
      LatLng(-8.075, 113.235),
      LatLng(-8.095, 113.245),
      LatLng(-8.105, 113.230),
    ],
  ),
  DistrictHeatmap(
    name: 'Lumajang',
    centroid: const LatLng(-8.125, 113.224),
    status: 'Kritis',
    color: const Color(0xFF991B1B),
    polygonPoints: const [
      LatLng(-8.115, 113.210),
      LatLng(-8.105, 113.230),
      LatLng(-8.120, 113.250),
      LatLng(-8.140, 113.245),
      LatLng(-8.145, 113.220),
      LatLng(-8.130, 113.205),
    ],
  ),
  DistrictHeatmap(
    name: 'Tekung',
    centroid: const LatLng(-8.130, 113.262),
    status: 'Rawan',
    color: const Color(0xFFF97316),
    polygonPoints: const [
      LatLng(-8.120, 113.250),
      LatLng(-8.110, 113.275),
      LatLng(-8.135, 113.285),
      LatLng(-8.150, 113.265),
      LatLng(-8.140, 113.245),
    ],
  ),
  DistrictHeatmap(
    name: 'Tempeh',
    centroid: const LatLng(-8.155, 113.195),
    status: 'Sangat Rawan',
    color: const Color(0xFFEF4444),
    polygonPoints: const [
      LatLng(-8.130, 113.205),
      LatLng(-8.145, 113.220),
      LatLng(-8.175, 113.205),
      LatLng(-8.185, 113.180),
      LatLng(-8.155, 113.175),
    ],
  ),
  DistrictHeatmap(
    name: 'KUNIR',
    centroid: const LatLng(-8.165, 113.235),
    status: 'Rawan',
    color: const Color(0xFFF97316),
    polygonPoints: const [
      LatLng(-8.145, 113.220),
      LatLng(-8.140, 113.245),
      LatLng(-8.150, 113.265),
      LatLng(-8.195, 113.250),
      LatLng(-8.190, 113.225),
      LatLng(-8.175, 113.205),
    ],
  ),
  DistrictHeatmap(
    name: 'Yosowilangun',
    centroid: const LatLng(-8.175, 113.275),
    status: 'Aman',
    color: const Color(0xFFE2E8F0),
    polygonPoints: const [
      LatLng(-8.150, 113.265),
      LatLng(-8.135, 113.285),
      LatLng(-8.165, 113.310),
      LatLng(-8.210, 113.290),
      LatLng(-8.195, 113.250),
    ],
  ),
  DistrictHeatmap(
    name: 'Sumberrejo',
    centroid: const LatLng(-8.180, 113.145),
    status: 'Sangat Rawan',
    color: const Color(0xFFEF4444),
    polygonPoints: const [
      LatLng(-8.155, 113.175),
      LatLng(-8.185, 113.180),
      LatLng(-8.215, 113.160),
      LatLng(-8.210, 113.120),
      LatLng(-8.160, 113.125),
    ],
  ),
];
