import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocrime_app/services/geo_corridor_service.dart';
import 'package:geocrime_app/services/safe_route_service.dart';

void main() {
  group('GeoCorridorService - Corridor Deviation Alert Test', () {
    late GeoCorridorService corridorService;

    setUp(() {
      corridorService = GeoCorridorService();
      // Pastikan status monitoring di-reset di setiap pengujian
      corridorService.stopMonitoring(); 
    });

    test('Harus memicu notifikasi peringatan jika user menyimpang dari koridor rute', () async {
      // 1. Buat Dummy SafeRoute (Contoh rute sederhana lurus)
      final dummyRoute = SafeRouteOption(
        name: 'Rute Utama',
        safetyScore: 90,
        safetyLabel: 'Aman',
        color: const Color(0xFF10B981),
        distanceKm: 2.0,
        estimatedMinutes: 5,
        path: [
          LatLng(-8.1300, 113.2200), // Titik A
          LatLng(-8.1300, 113.2300), // Titik B (Perjalanan lurus ke timur)
        ],
        description: 'Test Route',
        minDistanceToHazardMeters: 1000,
      );

      // 2. Mulai Monitoring dengan batas toleransi 50 meter
      corridorService.startMonitoring(dummyRoute, corridorThresholdMeters: 50.0);
      expect(corridorService.isMonitoring, isTrue);

      // 3. Persiapkan Listener untuk menangkap notifikasi peringatan dari Stream
      bool alertTriggered = false;
      double? deviatedDistance;

      final subscription = corridorService.onCorridorAlert.listen((alertData) {
        alertTriggered = true;
        deviatedDistance = alertData['distanceMeters'];
      });

      // 4. Simulasi Lokasi User (Masih di dalam jalur rute/koridor)
      // Titik ini berada persis di atas garis rute
      corridorService.checkPosition(LatLng(-8.1300, 113.2250)); 
      
      // Tunggu sebentar agar event stream terproses
      await Future.delayed(Duration(milliseconds: 100));
      
      // Harusnya TIDAK ada peringatan
      expect(alertTriggered, isFalse);
      expect(corridorService.isDeviated, isFalse);

      // 5. Simulasi Lokasi User (Menyimpang sangat jauh ke arah Utara)
      // Jarak -8.1350 dari -8.1300 adalah sekitar ~550 meter (Sangat melebihi 50 meter)
      final deviatedLocation = LatLng(-8.1350, 113.2250);
      corridorService.checkPosition(deviatedLocation);

      await Future.delayed(Duration(milliseconds: 100));

      // 6. Verifikasi Peringatan Terpicu
      expect(alertTriggered, isTrue, reason: 'Peringatan deviasi harus terpicu ketika user melampaui threshold');
      expect(corridorService.isDeviated, isTrue);
      expect(deviatedDistance, greaterThan(50.0), reason: 'Jarak penyimpangan harus lebih dari batas 50 meter');

      // Cleanup
      subscription.cancel();
      corridorService.stopMonitoring();
    });
  });
}
