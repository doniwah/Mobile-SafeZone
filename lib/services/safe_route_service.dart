import 'package:flutter/material.dart';
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

  /// Menghasilkan 3 variasi rute dari Start ke Destination dan mengukur skor keamanan masing-masing
  List<SafeRouteOption> calculateSafeRoutes({
    required LatLng start,
    required LatLng destination,
    List<GisMarker>? incidentMarkers,
    List<RedZone>? redZones,
  }) {
    final markers = incidentMarkers ?? [];
    final zones = redZones ?? AppDatabase.redZones.map((z) => RedZone.fromJson(z)).toList();
    
    final hazardPoints = markers.map((m) => LatLng(m.latitude, m.longitude)).toList();

    // 1. Rute Langsung / Direct Route
    final directPath = [
      start,
      destination,
    ];

    // 2. Rute Memutar Barat / Utara (Bypass West/North)
    final midLat1 = (start.latitude + destination.latitude) / 2.0 - 0.0050;
    final midLng1 = (start.longitude + destination.longitude) / 2.0 - 0.0060;
    final bypassPathWest = [
      start,
      LatLng((start.latitude + midLat1) / 2, start.longitude - 0.0040),
      LatLng(midLat1, midLng1),
      LatLng((destination.latitude + midLat1) / 2, destination.longitude - 0.0030),
      destination,
    ];

    // 3. Rute Memutar Timur / Selatan (Bypass East/South)
    final midLat2 = (start.latitude + destination.latitude) / 2.0 + 0.0050;
    final midLng2 = (start.longitude + destination.longitude) / 2.0 + 0.0060;
    final bypassPathEast = [
      start,
      LatLng((start.latitude + midLat2) / 2, start.longitude + 0.0040),
      LatLng(midLat2, midLng2),
      LatLng((destination.latitude + midLat2) / 2, destination.longitude + 0.0030),
      destination,
    ];

    // Hitung Keamanan untuk ketiga rute
    final score1 = calculateSafetyScore(directPath, hazardPoints, zones);
    final score2 = calculateSafetyScore(bypassPathWest, hazardPoints, zones);
    final score3 = calculateSafetyScore(bypassPathEast, hazardPoints, zones);

    final rawRoutes = [
      {
        'rawName': 'Rute Memutar Barat (Jalur Aman)',
        'path': bypassPathWest,
        'analysis': score2,
      },
      {
        'rawName': 'Rute Memutar Timur (Jalur Alternatif)',
        'path': bypassPathEast,
        'analysis': score3,
      },
      {
        'rawName': 'Rute Pintas Langsung',
        'path': directPath,
        'analysis': score1,
      },
    ];

    // Buat opsi rute
    final options = rawRoutes.map((item) {
      final analysis = item['analysis'] as Map<String, dynamic>;
      final path = item['path'] as List<LatLng>;
      final distKm = calculatePathDistanceKm(path);
      final estMins = (distKm * 2.5).round().clamp(2, 60);

      final score = analysis['score'] as int;
      final label = analysis['label'] as String;
      final color = analysis['color'] as Color;
      final minDist = analysis['minDistance'] as double;

      String desc;
      if (label == 'Aman') {
        desc = 'Jalur rekomendasi aman. Bebas dari titik kerawanan begal & kecelakaan (jarak terdekat bahaya: ${minDist.toInt()}m).';
      } else if (label == 'Rawan') {
        desc = 'Jalur melintasi daerah pengawasan (jarak titik rawan: ${minDist.toInt()}m). Tetap waspada.';
      } else {
        desc = 'Jalur tercepat namun melintasi langsung zona merah & titik rawan kejahatan (${minDist.toInt()}m).';
      }

      return SafeRouteOption(
        name: item['rawName'] as String,
        safetyScore: score,
        safetyLabel: label,
        color: color,
        distanceKm: distKm,
        estimatedMinutes: estMins,
        path: path,
        description: desc,
        minDistanceToHazardMeters: minDist,
      );
    }).toList();

    // Urutkan rute dari skor keamanan tertinggi ke terendah
    options.sort((a, b) => b.safetyScore.compareTo(a.safetyScore));

    return options;
  }
}
