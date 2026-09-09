import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class RedZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String category;
  final String dangerLevel;
  final List<String> preventionTips;
  final List<List<double>>? polygonCoordinates; // List of [lng, lat] vertices

  RedZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.category = 'Zona Rawan Kejahatan',
    this.dangerLevel = 'Tinggi',
    this.preventionTips = const [],
    this.polygonCoordinates,
  });

  factory RedZone.fromJson(Map<String, dynamic> json) {
    List<String> tips = [];
    if (json['prevention_tips'] is List) {
      tips = (json['prevention_tips'] as List).map((e) => e.toString()).toList();
    } else if (json['saran_pencegahan'] is List) {
      tips = (json['saran_pencegahan'] as List).map((e) => e.toString()).toList();
    }

    // Parse polygon_geojson if available
    List<List<double>>? polyCoords;
    dynamic geojson = json['polygon_geojson'];
    if (geojson is String && geojson.trim().isNotEmpty) {
      try {
        geojson = jsonDecode(geojson);
      } catch (_) {}
    }

    if (geojson is Map && geojson.containsKey('coordinates')) {
      try {
        final coords = geojson['coordinates'];
        final type = geojson['type']?.toString().toLowerCase();
        List<dynamic>? ring;
        if (type == 'polygon' && coords is List && coords.isNotEmpty) {
          ring = coords[0] as List;
        } else if (type == 'multipolygon' && coords is List && coords.isNotEmpty && coords[0] is List) {
          ring = coords[0][0] as List;
        }

        if (ring != null && ring.isNotEmpty) {
          polyCoords = [];
          for (var pt in ring) {
            if (pt is List && pt.length >= 2) {
              final lng = (pt[0] as num).toDouble();
              final lat = (pt[1] as num).toDouble();
              polyCoords.add([lng, lat]);
            }
          }
        }
      } catch (_) {}
    }

    double lat = (json['latitude'] as num?)?.toDouble() ?? (double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0);
    double lng = (json['longitude'] as num?)?.toDouble() ?? (double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0);
    double rad = (json['radius'] as num?)?.toDouble() ?? 500.0;

    // If coordinates are missing (common for polygon locations from admin panel), compute from centroid
    if ((lat == 0.0 || lng == 0.0) && polyCoords != null && polyCoords.isNotEmpty) {
      double sumLat = 0.0;
      double sumLng = 0.0;
      for (var pt in polyCoords) {
        sumLng += pt[0];
        sumLat += pt[1];
      }
      lat = sumLat / polyCoords.length;
      lng = sumLng / polyCoords.length;

      // Calculate radius as max distance to any vertex
      double maxDist = rad;
      for (var pt in polyCoords) {
        final d = Geolocator.distanceBetween(lat, lng, pt[1], pt[0]);
        if (d > maxDist) maxDist = d;
      }
      rad = maxDist;
    }

    return RedZone(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['nama_zona'] ?? json['nama_lokasi'] ?? 'Zona Berbahaya',
      latitude: lat,
      longitude: lng,
      radius: rad,
      category: json['category'] ?? json['kategori'] ?? (json['status_kerawanan'] != null ? 'Zona ${json['status_kerawanan']}' : 'Rawan Kejahatan'),
      dangerLevel: json['danger_level'] ?? json['tingkat_bahaya'] ?? json['status_kerawanan'] ?? 'Tinggi',
      preventionTips: tips,
      polygonCoordinates: polyCoords,
    );
  }

  /// Checks whether a given (lat, lng) point is inside this zone.
  /// Evaluates polygon geometry if present; falls back to circular distance.
  bool containsPoint(double userLat, double userLng) {
    // 1. Ray-casting point-in-polygon algorithm
    if (polygonCoordinates != null && polygonCoordinates!.length >= 3) {
      bool inside = false;
      for (int i = 0, j = polygonCoordinates!.length - 1; i < polygonCoordinates!.length; j = i++) {
        final xi = polygonCoordinates![i][0]; // longitude
        final yi = polygonCoordinates![i][1]; // latitude
        final xj = polygonCoordinates![j][0];
        final yj = polygonCoordinates![j][1];

        final intersect = ((yi > userLat) != (yj > userLat)) &&
            (userLng < (xj - xi) * (userLat - yi) / (yj - yi) + xi);
        if (intersect) inside = !inside;
      }
      if (inside) return true;
    }

    // 2. Circular radius check
    if (latitude != 0.0 && longitude != 0.0) {
      final distance = Geolocator.distanceBetween(userLat, userLng, latitude, longitude);
      if (distance <= radius) return true;
    }

    return false;
  }

  /// Menghasilkan saran pencegahan cerdas berbasis kategori ancaman jika tips spesifik belum ditentukan
  List<String> get effectivePreventionTips {
    if (preventionTips.isNotEmpty) return preventionTips;

    final lower = (name + ' ' + category).toLowerCase();
    if (lower.contains('begal')) {
      return [
        'Hindari melintas sendirian larut malam (terutama di atas pukul 21.00 WIB).',
        'Tetap melaju di lajur utama dengan pencahayaan memadai, jangan menepi di jalan sepi.',
        'Jangan terpancing berhenti jika ada orang tak dikenal meminta bantuan mencurigakan.',
        'Siagakan fitur Rute Aman (Safe Route) atau tombol Widget SOS di genggaman Anda.',
      ];
    } else if (lower.contains('jambret') || lower.contains('copet') || lower.contains('pasar')) {
      return [
        'Posisikan tas ransel atau selempang di bagian depan badan Anda.',
        'Hindari mengeluarkan dan memainkan smartphone di pinggir jalan raya yang ramai.',
        'Simpan dompet dan barang berharga di saku pakaian bagian dalam.',
        'Waspadai gerak-gerik pengendara motor berboncengan yang melambat di samping Anda.',
      ];
    } else if (lower.contains('curanmor') || lower.contains('parkir') || lower.contains('pencurian')) {
      return [
        'Pastikan selalu memasang kunci ganda atau gembok cakram tambahan pada motor.',
        'Pilih titik parkir resmi yang terpantau CCTV atau diawasi oleh petugas keamanan.',
        'Jangan pernah meninggalkan tiket karcis parkir atau STNK di bagasi kendaraan.',
      ];
    } else if (lower.contains('tawuran') || lower.contains('konflik')) {
      return [
        'Segera putar balik atau gunakan rute alternatif jika melihat kerumunan massa mencurigakan.',
        'Hindari mengenakan atribut provokatif atau berkumpul di titik rawan bentrok.',
        'Laporkan kerumunan mencurigakan melalui fitur Buat Laporan di aplikasi SafeZone.',
      ];
    } else {
      return [
        'Tingkatkan kewaspadaan dan perhatikan lingkungan sekitar secara berkala.',
        'Aktifkan fitur Safe Route untuk diarahkan ke rute perjalanan yang lebih aman.',
        'Bagikan live tracking perjalanan Anda kepada keluarga atau kontak darurat.',
        'Gunakan tombol darurat SOS jika Anda mendapati ancaman yang membahayakan.',
      ];
    }
  }
}

