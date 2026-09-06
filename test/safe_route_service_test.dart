import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocrime_app/services/safe_route_service.dart';
import 'package:geocrime_app/models/red_zone.dart';
import 'package:geocrime_app/models/gis_marker.dart';

void main() {
  group('SafeRouteService - Lumajang Safe Routing Test', () {
    late SafeRouteService safeRouteService;

    setUp(() {
      safeRouteService = SafeRouteService();
    });

    test('Harus memberikan rute aman berdasarkan algoritma haversine ke Lumajang', () {
      // 1. Tentukan Titik Awal (Misal dari suatu titik di Lumajang)
      final startPoint = LatLng(-8.1500, 113.2200); 

      // 2. Tentukan Titik Akhir (Tujuan ke Alun-Alun Lumajang)
      final destinationPoint = LatLng(-8.1331, 113.2224); // Alun-Alun Lumajang

      // 3. Tentukan Zona Merah (Red Zones) - Simulasi titik rawan
      // Kita buat zona merah tepat di tengah rute langsung (direct route)
      // agar rute memutar (bypass) mendapatkan skor keamanan lebih tinggi.
      final directMidLat = (startPoint.latitude + destinationPoint.latitude) / 2;
      final directMidLng = (startPoint.longitude + destinationPoint.longitude) / 2;

      final mockRedZones = [
        RedZone(
          id: '1',
          name: 'Zona Rawan Tengah',
          latitude: directMidLat,
          longitude: directMidLng,
          radius: 300.0, // Radius 300 meter
        )
      ];

      final mockIncidentMarkers = <GisMarker>[];

      // 4. Hitung rute menggunakan layanan SafeRouteService
      final routeOptions = safeRouteService.calculateSafeRoutes(
        start: startPoint,
        destination: destinationPoint,
        redZones: mockRedZones,
        incidentMarkers: mockIncidentMarkers,
      );

      // 5. Verifikasi Hasil
      // Memastikan ada 3 opsi rute (Direct, Bypass Barat, Bypass Timur)
      expect(routeOptions.length, 3);

      // Memastikan rute sudah diurutkan dari skor keamanan tertinggi ke terendah (Aman ke Bahaya)
      expect(
        routeOptions[0].safetyScore >= routeOptions[1].safetyScore, 
        true, 
        reason: 'Rute pertama harus memiliki skor keamanan lebih tinggi atau sama dengan rute kedua'
      );
      expect(
        routeOptions[1].safetyScore >= routeOptions[2].safetyScore, 
        true,
        reason: 'Rute kedua harus memiliki skor keamanan lebih tinggi atau sama dengan rute ketiga'
      );

      // Memastikan rute teraman (indeks 0) BUKAN rute langsung, karena rute langsung melewati RedZone
      expect(routeOptions[0].name, isNot('Rute Pintas Langsung'));
      
      // Rute langsung seharusnya memiliki skor rendah atau label 'Bahaya' atau 'Rawan'
      final directRoute = routeOptions.firstWhere((route) => route.name == 'Rute Pintas Langsung');
      expect(directRoute.safetyScore, lessThan(85), reason: 'Rute langsung yang melewati zona merah tidak boleh berlabel Aman');
      
      // Memastikan pemetaan rute dari titik awal ke titik akhir valid (titik pertama = start, titik terakhir = end)
      for (var route in routeOptions) {
        expect(route.path.first, startPoint);
        expect(route.path.last, destinationPoint);
      }

      print('Test berhasil: Sistem berhasil menghitung skor keamanan, menghindari zona merah, dan memetakan rute dari awal ke tujuan Lumajang.');
    });
  });
}
