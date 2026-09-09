import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/gis_marker.dart';
import '../models/red_zone.dart';
import '../database/app_database.dart';

class LumajangLocation {
  final String id;
  final String name;
  final String address;
  final LatLng location;

  const LumajangLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
  });
}

class SafeRouteOption {
  final String name;
  final int safetyScore; // 0 - 100
  final String safetyLabel; // 'Aman', 'Rawan', 'Bahaya'
  final Color color;
  final double distanceKm;
  final int estimatedMinutes;
  final List<LatLng> path;
  final String description;
  final double minDistanceToHazardMeters;

  SafeRouteOption({
    required this.name,
    required this.safetyScore,
    required this.safetyLabel,
    required this.color,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.path,
    required this.description,
    required this.minDistanceToHazardMeters,
  });
}

class SafeRouteService {
  static final SafeRouteService _instance = SafeRouteService._internal();
  factory SafeRouteService() => _instance;
  SafeRouteService._internal();

  /// Daftar lokasi populer di Kabupaten Lumajang untuk titik awal & tujuan
  static const List<LumajangLocation> lumajangLocations = [
    LumajangLocation(
      id: 'alun_alun',
      name: 'Alun-Alun Lumajang',
      address: 'Jl. Alun-Alun Barat, Tompokersan',
      location: LatLng(-8.1331, 113.2224),
    ),
    LumajangLocation(
      id: 'jl_panjaitan',
      name: 'Jl. D.I. Panjaitan',
      address: 'Citrodiwangsan, Kec. Lumajang',
      location: LatLng(-8.1315, 113.2205),
    ),
    LumajangLocation(
      id: 'jl_kalimantan',
      name: 'Jl. Kalimantan (Zona Rawan)',
      address: 'Sumbersari, Kec. Lumajang',
      location: LatLng(-8.1250, 113.2190),
    ),
    LumajangLocation(
      id: 'jl_monginsidi',
      name: 'Jl. Wolter Monginsidi',
      address: 'Jogotrunan, Kec. Lumajang',
      location: LatLng(-8.1400, 113.2300),
    ),
    LumajangLocation(
      id: 'rsud_haryoto',
      name: 'RSUD H. Haryoto Lumajang',
      address: 'Jl. Jend. A. Yani No.281, Tompokersan',
      location: LatLng(-8.1365, 113.2260),
    ),
    LumajangLocation(
      id: 'terminal_koncar',
      name: 'Terminal Minak Koncar',
      address: 'Jl. Soekarno - Hatta, Sukodono',
      location: LatLng(-8.1550, 113.2410),
    ),
    LumajangLocation(
      id: 'pasar_seriti',
      name: 'Pasar Baru Lumajang',
      address: 'Jl. Kyai Muksin, Tompokersan',
      location: LatLng(-8.1385, 113.2215),
    ),
    LumajangLocation(
      id: 'polsek_kota',
      name: 'Polsek Lumajang Kota',
      address: 'Jl. Jendral Ahmad Yani No.14',
      location: LatLng(-8.1340, 113.2240),
    ),
    LumajangLocation(
      id: 'stie_widyagama',
      name: 'STIE Widya Gama Lumajang',
      address: 'Jl. Gatot Subroto No.4, Sukodono',
      location: LatLng(-8.1220, 113.2140),
    ),
  ];

  /// Menghitung jarak Haversine (meter) antara dua titik koordinat
  double haversineDistanceMeters(LatLng p1, LatLng p2) {
    return Geolocator.distanceBetween(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );
  }

  /// Kalkulasi Skor Keamanan Haversine (0-100) berdasarkan kedekatan dengan titik kriminalitas/zona merah
  Map<String, dynamic> calculateSafetyScore(
    List<LatLng> path,
    List<LatLng> hazardPoints,
    List<RedZone> redZones,
  ) {
    double minHazardDistance = double.infinity;
    double cumulativeRisk = 0.0;
    int sampledPoints = 0;

    // Interpolasi & sampel titik di sepanjang rute
    for (int i = 0; i < path.length - 1; i++) {
      final start = path[i];
      final end = path[i + 1];
      final distBetweenSegment = haversineDistanceMeters(start, end);
      
      // Jumlah sampel bergantung pada panjang segmen (setiap 50 meter)
      final steps = (distBetweenSegment / 50.0).ceil().clamp(1, 15);

      for (int s = 0; s <= steps; s++) {
        final fraction = s / steps;
        final sampleLat = start.latitude + (end.latitude - start.latitude) * fraction;
        final sampleLng = start.longitude + (end.longitude - start.longitude) * fraction;
        final samplePoint = LatLng(sampleLat, sampleLng);
        sampledPoints++;

        // 1. Cek jarak ke titik-titik kejadian kejahatan/kecelakaan (hazardPoints)
        for (var hazard in hazardPoints) {
          final dist = haversineDistanceMeters(samplePoint, hazard);
          if (dist < minHazardDistance) {
            minHazardDistance = dist;
          }
          if (dist < 500) {
            // Penalti risiko berdasarkan jarak (semakin dekat semakin tinggi)
            final riskWeight = (1.0 - (dist / 500.0)).clamp(0.0, 1.0);
            cumulativeRisk += riskWeight * 35;
          }
        }

        // 2. Cek jarak ke Zona Merah (RedZone)
        for (var zone in redZones) {
          final zoneCenter = LatLng(zone.latitude, zone.longitude);
          final dist = haversineDistanceMeters(samplePoint, zoneCenter);
          final effectiveDist = dist - zone.radius; // Jarak dari tepi radius zona merah

          if (dist < minHazardDistance) {
            minHazardDistance = dist;
          }

          if (effectiveDist <= 0) {
            // Didalam zona merah! Penalti maksimal
            cumulativeRisk += 100;
          } else if (effectiveDist < 400) {
            final riskWeight = (1.0 - (effectiveDist / 400.0)).clamp(0.0, 1.0);
            cumulativeRisk += riskWeight * 45;
          }
        }
      }
    }

    if (sampledPoints == 0) sampledPoints = 1;
    final averageRisk = cumulativeRisk / sampledPoints;
    int rawScore = (100 - averageRisk.round()).clamp(15, 99);

    // Jika jarak terdekat ke titik bahaya < 100m, pastikan skor di bawah 50 (Bahaya)
    if (minHazardDistance < 100) {
      rawScore = rawScore.clamp(15, 45);
    } else if (minHazardDistance < 300) {
      rawScore = rawScore.clamp(46, 75);
    }

    String label;
    Color color;

    if (rawScore >= 85) {
      label = 'Aman';
      color = const Color(0xFF10B981); // Emerald Green
    } else if (rawScore >= 50) {
      label = 'Rawan';
      color = const Color(0xFFF59E0B); // Amber / Yellow
    } else {
      label = 'Bahaya';
      color = const Color(0xFFEF4444); // Red
    }

    return {
      'score': rawScore,
      'label': label,
      'color': color,
      'minDistance': minHazardDistance == double.infinity ? 1000.0 : minHazardDistance,
    };
  }

  /// Menghitung total jarak rute dalam kilometer
  double calculatePathDistanceKm(List<LatLng> path) {
    double totalMeters = 0.0;
    for (int i = 0; i < path.length - 1; i++) {
      totalMeters += haversineDistanceMeters(path[i], path[i + 1]);
    }
    return double.parse((totalMeters / 1000.0).toStringAsFixed(1));
  }

  /// Mengambil rute yang presisi mengikuti jaringan jalan (road-snapping) via OSRM API
  Future<List<List<LatLng>>> _fetchRoadRoutes(LatLng start, LatLng destination) async {
    List<List<LatLng>> roadPaths = [];

    // 1. Panggil OSRM dengan alternatives=true
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&alternatives=true',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' && data['routes'] is List) {
          for (var r in data['routes']) {
            if (r['geometry'] != null && r['geometry']['coordinates'] is List) {
              final coords = r['geometry']['coordinates'] as List;
              final path = coords.map<LatLng>((c) {
                final lng = (c[0] as num).toDouble();
                final lat = (c[1] as num).toDouble();
                return LatLng(lat, lng);
              }).toList();
              if (path.length >= 2) {
                roadPaths.add(path);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('SafeRouteService: OSRM fetch error: $e');
    }

    // 2. Jika rute alternatif dari OSRM kurang dari 3, ambil rute tambahan via waypoint alternatif yang otomatis disnap ke jalan terdekat
    if (roadPaths.length < 3) {
      final midLat = (start.latitude + destination.latitude) / 2.0;
      final midLng = (start.longitude + destination.longitude) / 2.0;
      final dLat = destination.latitude - start.latitude;
      final dLng = destination.longitude - start.longitude;

      final offsetLat1 = -dLng * 0.30;
      final offsetLng1 = dLat * 0.30;

      final waypoints = [
        LatLng(midLat + offsetLat1, midLng + offsetLng1),
        LatLng(midLat - offsetLat1, midLng - offsetLng1),
      ];

      for (var wp in waypoints) {
        if (roadPaths.length >= 3) break;
        try {
          final viaUrl = Uri.parse(
            'https://router.project-osrm.org/route/v1/driving/'
            '${start.longitude},${start.latitude};${wp.longitude},${wp.latitude};${destination.longitude},${destination.latitude}'
            '?overview=full&geometries=geojson',
          );
          final res = await http.get(viaUrl).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data['code'] == 'Ok' && data['routes'] is List && (data['routes'] as List).isNotEmpty) {
              final r = data['routes'][0];
              if (r['geometry'] != null && r['geometry']['coordinates'] is List) {
                final coords = r['geometry']['coordinates'] as List;
                final path = coords.map<LatLng>((c) {
                  final lng = (c[0] as num).toDouble();
                  final lat = (c[1] as num).toDouble();
                  return LatLng(lat, lng);
                }).toList();
                if (path.length >= 2) {
                  roadPaths.add(path);
                }
              }
            }
          }
        } catch (_) {}
      }
    }

    return roadPaths;
  }

  /// Menghasilkan variasi rute yang mengikuti jalan nyata dari Start ke Destination dan mengukur skor keamanan masing-masing
  Future<List<SafeRouteOption>> calculateSafeRoutes({
    required LatLng start,
    required LatLng destination,
    List<GisMarker>? incidentMarkers,
    List<RedZone>? redZones,
  }) async {
    final markers = incidentMarkers ?? [];
    final zones = redZones ?? AppDatabase.redZones.map((z) => RedZone.fromJson(z)).toList();
    final hazardPoints = markers.map((m) => LatLng(m.latitude, m.longitude)).toList();

    // 1. Ambil rute jalan nyata via OSRM
    List<List<LatLng>> roadPaths = await _fetchRoadRoutes(start, destination);

    // 2. Fallback jika offline atau gagal koneksi: interpolasi bertahap
    if (roadPaths.isEmpty) {
      final midLat1 = (start.latitude + destination.latitude) / 2.0 - 0.0040;
      final midLng1 = (start.longitude + destination.longitude) / 2.0 - 0.0050;
      final midLat2 = (start.latitude + destination.latitude) / 2.0 + 0.0040;
      final midLng2 = (start.longitude + destination.longitude) / 2.0 + 0.0050;

      roadPaths = [
        [
          start,
          LatLng((start.latitude + midLat1) / 2, start.longitude - 0.0020),
          LatLng(midLat1, midLng1),
          LatLng((destination.latitude + midLat1) / 2, destination.longitude - 0.0020),
          destination,
        ],
        [
          start,
          LatLng((start.latitude + midLat2) / 2, start.longitude + 0.0020),
          LatLng(midLat2, midLng2),
          LatLng((destination.latitude + midLat2) / 2, destination.longitude + 0.0020),
          destination,
        ],
        [start, destination],
      ];
    }

    // 3. Analisis skor keamanan Haversine untuk tiap rute jalan
    final analyzedRoutes = <Map<String, dynamic>>[];
    for (int i = 0; i < roadPaths.length; i++) {
      final path = roadPaths[i];
      final analysis = calculateSafetyScore(path, hazardPoints, zones);
      analyzedRoutes.add({
        'index': i,
        'path': path,
        'analysis': analysis,
      });
    }

    // Urutkan rute dari skor keamanan tertinggi ke terendah
    analyzedRoutes.sort((a, b) {
      final scoreA = (a['analysis'] as Map<String, dynamic>)['score'] as int;
      final scoreB = (b['analysis'] as Map<String, dynamic>)['score'] as int;
      return scoreB.compareTo(scoreA);
    });

    // 4. Konversi ke SafeRouteOption dengan penamaan yang informatif
    final List<SafeRouteOption> options = [];
    for (int i = 0; i < analyzedRoutes.length; i++) {
      final item = analyzedRoutes[i];
      final analysis = item['analysis'] as Map<String, dynamic>;
      final path = item['path'] as List<LatLng>;
      final distKm = calculatePathDistanceKm(path);
      // Perkiraan waktu: kecepatan rata-rata dalam kota ~25 km/jam
      final estMins = ((distKm / 25.0) * 60).round().clamp(2, 90);

      final score = analysis['score'] as int;
      final label = analysis['label'] as String;
      final color = analysis['color'] as Color;
      final minDist = analysis['minDistance'] as double;

      String name;
      if (i == 0) {
        name = 'Rute Utama (Jalur Teraman)';
      } else if (i == 1) {
        name = 'Rute Alternatif 1';
      } else {
        name = 'Rute Alternatif 2';
      }

      String desc;
      if (label == 'Aman') {
        desc = 'Jalur jalan rekomendasi teraman. Menghindari zona rawan dan titik kejahatan (jarak terdekat: ${minDist.toInt()}m).';
      } else if (label == 'Rawan') {
        desc = 'Jalur jalan alternatif melintasi daerah pengawasan (jarak titik rawan: ${minDist.toInt()}m). Tetap waspada.';
      } else {
        desc = 'Jalur jalan melintasi dekat titik rawan kejahatan (${minDist.toInt()}m). Prioritaskan jalur aman.';
      }

      options.add(
        SafeRouteOption(
          name: name,
          safetyScore: score,
          safetyLabel: label,
          color: color,
          distanceKm: distKm,
          estimatedMinutes: estMins,
          path: path,
          description: desc,
          minDistanceToHazardMeters: minDist,
        ),
      );
    }

    return options;
  }
}
