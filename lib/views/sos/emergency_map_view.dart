import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/desktop_frame.dart';

class EmergencyMapView extends StatefulWidget {
  final Map<String, dynamic>? sosData;
  const EmergencyMapView({super.key, this.sosData});

  @override
  State<EmergencyMapView> createState() => _EmergencyMapViewState();
}

class _EmergencyMapViewState extends State<EmergencyMapView> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  String _getEta(double km) {
    if (km < 1) return "1 Mnt";
    if (km > 100) {
      final hours = (km / 60).round();
      return "$hours Jam";
    }
    final mins = (km * 1.5).round();
    return "$mins Mnt";
  }

  @override
  Widget build(BuildContext context) {
    // Extract report and polsek data flexibly from sosData
    Map<String, dynamic>? report;
    if (widget.sosData != null) {
      if (widget.sosData!['emergency_report'] is Map) {
        report = Map<String, dynamic>.from(widget.sosData!['emergency_report'] as Map);
      } else if (widget.sosData!['data'] is Map) {
        final d = widget.sosData!['data'] as Map;
        if (d['emergency_report'] is Map) {
          report = Map<String, dynamic>.from(d['emergency_report'] as Map);
        } else {
          report = Map<String, dynamic>.from(d);
        }
      } else {
        report = widget.sosData;
      }
    }

    final double userLat = (report?['latitude'] as num?)?.toDouble() ??
        (widget.sosData?['latitude'] as num?)?.toDouble() ??
        -5.1477;
    final double userLng = (report?['longitude'] as num?)?.toDouble() ??
        (widget.sosData?['longitude'] as num?)?.toDouble() ??
        119.4327;

    // Nearest polsek extraction
    Map<String, dynamic>? polsekMap;
    if (report?['nearest_polsek'] is Map) {
      polsekMap = Map<String, dynamic>.from(report!['nearest_polsek'] as Map);
    } else if (report?['polsek'] is Map) {
      polsekMap = Map<String, dynamic>.from(report!['polsek'] as Map);
    } else if (widget.sosData?['nearest_polsek'] is Map) {
      polsekMap = Map<String, dynamic>.from(widget.sosData!['nearest_polsek'] as Map);
    }

    final String polsekName = polsekMap?['nama'] ?? polsekMap?['name'] ?? 'Polsek Terdekat';

    // Polsek Lat & Lng
    double polsekLat = userLat;
    double polsekLng = userLng;
    if (polsekMap?['lokasi'] is Map) {
      final loc = polsekMap!['lokasi'] as Map;
      if (loc['latitude'] != null) polsekLat = (loc['latitude'] as num).toDouble();
      if (loc['longitude'] != null) polsekLng = (loc['longitude'] as num).toDouble();
    } else {
      if (polsekMap?['latitude'] != null) polsekLat = (polsekMap!['latitude'] as num).toDouble();
      if (polsekMap?['longitude'] != null) polsekLng = (polsekMap!['longitude'] as num).toDouble();
    }

    // Distance in KM: use reported distance or compute via Geolocator
    double distanceKm;
    if (report?['jarak_polsek_km'] != null) {
      distanceKm = (report!['jarak_polsek_km'] as num).toDouble();
    } else if (polsekLat != userLat || polsekLng != userLng) {
      distanceKm = Geolocator.distanceBetween(userLat, userLng, polsekLat, polsekLng) / 1000.0;
    } else {
      distanceKm = 1.2;
    }

    final String polsekPhone = polsekMap?['nomor_telepon'] ??
        polsekMap?['phone'] ??
        polsekMap?['telepon'] ??
        '110';
    final String alamatTerdeteksi = report?['alamat_terdeteksi'] ??
        widget.sosData?['alamat_terdeteksi'] ??
        'Lokasi Terdeteksi';

    final userPoint = LatLng(userLat, userLng);
    final polsekPoint = LatLng(polsekLat, polsekLng);

    Widget mainContent() {
      return SizedBox.expand(
        child: Stack(
          children: [
            // GIS Emergency Map Viewport (OpenStreetMap)
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng((userLat + polsekLat) / 2, (userLng + polsekLng) / 2),
                  initialZoom: distanceKm > 100 ? 8.0 : 13.0,
                  minZoom: 4.0,
                  maxZoom: 18.0,
                  onMapReady: () {
                    // Fit map bounds to show both user and responding Polsek
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: LatLngBounds(userPoint, polsekPoint),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 120),
                      ),
                    );
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.geocrime.geocrime_app',
                  ),
                  
                  // Radius circles around user location (visual warning)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: userPoint,
                        radius: distanceKm > 10 ? 2000 : 500, // radius in meters
                        useRadiusInMeter: true,
                        color: const Color(0xFFEF4444).withOpacity(0.08),
                        borderColor: const Color(0xFFEF4444).withOpacity(0.3),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),

                  // Polyline connecting User and Polsek
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [userPoint, polsekPoint],
                        color: const Color(0xFFEF4444),
                        strokeWidth: 3.0,
                        pattern: StrokePattern.dashed(segments: [8, 4]),
                      ),
                    ],
                  ),

                  // Markers Layer
                  MarkerLayer(
                    markers: [
                      // User Current Location (Glowing Red Marker)
                      Marker(
                        point: userPoint,
                        width: 60,
                        height: 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TweenAnimationBuilder(
                              tween: Tween<double>(begin: 1.0, end: 1.8),
                              duration: const Duration(seconds: 1),
                              builder: (context, double val, child) {
                                return Container(
                                  width: 30 * val,
                                  height: 30 * val,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.35 * (1.8 - val)),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              },
                            ),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2.5)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Nearest Polsek (Police Badge Blue Marker)
                      Marker(
                        point: polsekPoint,
                        width: 80,
                        height: 80,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)
                                ],
                              ),
                              child: Text(
                                polsekName,
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
                                ],
                              ),
                              child: const Icon(Icons.local_police_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Back Button Overlay
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.chevron_left_rounded, size: 20, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Kembali', 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top Status Overlay (Critical Warning)
            Positioned(
              left: 16,
              right: 16,
              top: 76,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.report_problem_rounded, color: Color(0xFFEF4444), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STATUS DARURAT SOS AKTIF', 
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFFEF4444), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            distanceKm > 100 
                              ? 'Sinyal terkirim. $polsekName siap siaga merespons.'
                              : 'Sinyal koordinat terkirim. $polsekName sedang merespons.', 
                            style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Distances Info detail cards overlay
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
                    BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.local_police_rounded, color: Color(0xFF3B82F6), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Polsek Terdekat Merespons', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Polsek Station Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Polsek Station Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                polsekName, 
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Alamat: $alamatTerdeteksi',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Jarak: ${distanceKm.toStringAsFixed(1)} km  •  Telp: $polsekPhone', 
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ETA display
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'ETA', 
                                style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getEta(distanceKm), 
                                style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      );
    }

    return DesktopFrame(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: mainContent(),
      ),
    );
  }
}
