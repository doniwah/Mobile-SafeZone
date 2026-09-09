import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_data.dart';
import '../models/report_data.dart';
import '../models/cctv_data.dart';
import '../models/gis_marker.dart';
import '../database/app_database.dart';

class ApiService {
  static const String baseUrl =
      'https://web-safezone-production.up.railway.app/api';
  static String? _token;
  static Map<String, dynamic>? currentUser;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('api_token');
    if (_token == 'mock_token_xyz') {
      _token = null;
      await prefs.remove('api_token');
      await prefs.remove('current_user');
    }
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      try {
        currentUser = jsonDecode(userJson);
      } catch (_) {}
    }
  }

  static String? get token => _token;
  static bool get isAuthenticated => _token != null;

  static Future<void> saveSession(
    String token,
    Map<String, dynamic> user,
  ) async {
    _token = token;
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
    await prefs.setString('current_user', jsonEncode(user));
  }

  static Future<void> clearSession() async {
    _token = null;
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
    await prefs.remove('current_user');
  }

  static Future<http.Response> getRequest(String endpoint) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    return http
        .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
        .timeout(const Duration(seconds: 15));
  }

  static Future<http.Response> postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    return http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await postRequest('/auth/login', {
        'email': email,
        'password': password,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final user = data['user'];
        await saveSession(token, user);
        return {
          'success': true,
          'message': data['message'] ?? 'Login berhasil',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Kredensial tidak valid',
        };
      }
    } catch (e) {
      final nameFromEmail = email.contains('@')
          ? email.split('@').first
          : email;
      final capitalizedName = nameFromEmail.isNotEmpty
          ? nameFromEmail[0].toUpperCase() + nameFromEmail.substring(1)
          : 'Pengguna';

      await saveSession('mock_token_xyz', {
        'id': 1,
        'name': capitalizedName,
        'email': email,
      });
      return {
        'success': true,
        'message': 'Masuk secara offline (Server sedang tidak aktif)',
      };
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await postRequest('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final user = data['user'];
        await saveSession(token, user);
        return {
          'success': true,
          'message': data['message'] ?? 'Pendaftaran berhasil',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Pendaftaran gagal',
        };
      }
    } catch (e) {
      await saveSession('mock_token_xyz', {
        'id': 99,
        'name': name,
        'email': email,
      });
      return {'success': true, 'message': 'Mendaftar secara offline'};
    }
  }

  static Future<void> logout() async {
    try {
      await postRequest('/auth/logout', {});
    } catch (_) {}
    await clearSession();
  }

  static Future<List<NewsData>> fetchNews() async {
    try {
      final response = await getRequest('/news');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data'] as List
            : decoded as List;
        return list.map((item) {
          return NewsData(
            title: item['judul_berita'] ?? item['title'] ?? '',
            summary: item['ringkasan'] ?? item['summary'] ?? '',
            content: item['konten'] ?? item['content'] ?? '',
            date: item['published_at'] ?? item['date'] ?? '',
            author: item['penulis'] ?? item['author'] ?? 'Admin',
            imagePath: 'assets/images/news_police_banner.png',
            category: item['kategori'] ?? 'Info',
          );
        }).toList();
      }
    } catch (_) {}
    return AppDatabase.newsArticles;
  }

  static Future<List<ReportData>> fetchReports() async {
    try {
      final response = await getRequest('/reports');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data'] as List
            : decoded as List;
        return list.map((item) {
          final statusVal = item['status'] ?? 'pending';
          String statusText = 'Menunggu Verifikasi';
          if (statusVal == 'proses') statusText = 'Laporan Diproses';
          if (statusVal == 'tindaklanjut') statusText = 'Ditindaklanjuti';
          if (statusVal == 'selesai') statusText = 'Kasus Selesai';
          if (statusVal == 'ditolak') statusText = 'Ditolak';

          return ReportData(
            title: item['judul_laporan'] ?? '',
            chronology: item['deskripsi'] ?? '',
            date: item['created_at'] != null
                ? item['created_at']
                      .toString()
                      .substring(0, 19)
                      .replaceAll('T', ' ')
                : '',
            location: item['lokasi'] != null
                ? item['lokasi']['nama_lokasi']
                : 'Panjaitan Street',
            category: item['kategori'] != null
                ? item['kategori']['nama_kategori']
                : 'Kejahatan',
            status: statusText,
            imagePath: 'assets/images/detective_crime.png',
          );
        }).toList();
      }
    } catch (_) {}
    return AppDatabase.reports;
  }

  static Future<bool> submitReport({
    required String title,
    required String description,
    required String category,
  }) async {
    try {
      int categoryId = 1;
      try {
        final response = await getRequest('/reports/create-options');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final cats = data['categories'] as List;
          for (final cat in cats) {
            if (cat['nama_kategori'].toString().toLowerCase() ==
                category.toLowerCase()) {
              categoryId = cat['id'];
              break;
            }
          }
        }
      } catch (_) {}

      final response = await postRequest('/reports', {
        'judul_laporan': title,
        'deskripsi': description,
        'kategori_id': categoryId,
        'latitude': -8.1331,
        'longitude': 113.2224,
      });
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  static Future<Map<String, dynamic>?> submitSos({
    required double latitude,
    required double longitude,
    String? detectedAddress,
    String? message,
  }) async {
    try {
      final response = await postRequest('/sos', {
        'latitude': latitude,
        'longitude': longitude,
        'alamat_terdeteksi': detectedAddress ?? 'Deteksi Koordinat GPS',
        'catatan': message ?? 'SOS dipicu dari aplikasi mobile',
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> submitSosWithEvent(dynamic event) async {
    try {
      final response = await postRequest('/sos', {
        'sos_id': event.sosId,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'alamat_terdeteksi': event.alamatTerdeteksi ?? 'Deteksi Koordinat GPS',
        'catatan': event.catatan,
        'created_at': event.createdAt,
      });
      // 200 or 201 indicates success (including idempotent successful retries)
      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          return {'success': true};
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<CctvData>> fetchCctvs() async {
    try {
      final response = await getRequest('/cctvs');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data'] as List
            : decoded as List;
        return list.map((item) {
          return CctvData(
            streetName: item['nama'] ?? item['name'] ?? '',
            isOnline:
                item['aktif'] == 1 ||
                item['aktif'] == true ||
                item['aktif'].toString() == 'true',
            urlStream: item['url_stream'] ?? item['stream_url'],
          );
        }).toList();
      }
    } catch (_) {}
    return const [
      CctvData(streetName: 'Panjaitan Street', isOnline: true),
      CctvData(streetName: 'Supratman Street', isOnline: true),
      CctvData(streetName: 'Mastrip Street', isOnline: true),
      CctvData(streetName: 'Tawangmangu Street', isOnline: true),
      CctvData(streetName: 'Jawa Street', isOnline: true),
      CctvData(streetName: 'Cempaka Street', isOnline: false),
      CctvData(streetName: 'Gebang Street', isOnline: false),
      CctvData(streetName: 'Sriwijaya Street', isOnline: false),
    ];
  }

  static Future<int> fetchSosCount() async {
    try {
      final response = await getRequest('/sos');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['total_sos'] ?? 0;
      }
    } catch (_) {}
    return AppDatabase.sosHistory.length;
  }

  /// Mengambil daftar kejadian SOS terbaru dari backend.
  /// Mengembalikan list of map dengan field: sos_id, latitude, longitude,
  /// alamat_terdeteksi, created_at. List kosong jika gagal atau tidak tersedia.
  static Future<List<Map<String, dynamic>>> fetchRecentSosEvents() async {
    try {
      final response = await getRequest('/sos');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Tangani berbagai format respons backend
        List<dynamic>? list;
        if (data is List) {
          list = data;
        } else if (data is Map) {
          list =
              data['data'] as List? ??
              data['sos'] as List? ??
              data['events'] as List?;
        }

        if (list == null) return [];

        return list.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return [];
  }

  static Offset mapLatLngToOffset(double lat, double lng) {
    const double latMin = -8.25;
    const double latMax = -8.05;
    const double lngMin = 113.00;
    const double lngMax = 113.44;

    final double x = ((lng - lngMin) / (lngMax - lngMin)).clamp(0.1, 0.9);
    final double y = ((latMax - lat) / (latMax - latMin)).clamp(0.1, 0.9);
    return Offset(x, y);
  }

  static Future<List<GisMarker>> fetchGisMarkers() async {
    try {
      final response = await getRequest('/home');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final points = data['map_points'] as List;
        return points.map((item) {
          double lat = -8.1331;
          double lng = 113.2224;

          try {
            if (item['lat'] != null) {
              final parsed = double.tryParse(item['lat'].toString());
              if (parsed != null && !parsed.isNaN) {
                lat = parsed;
              }
            }
          } catch (_) {}

          try {
            if (item['lng'] != null) {
              final parsed = double.tryParse(item['lng'].toString());
              if (parsed != null && !parsed.isNaN) {
                lng = parsed;
              }
            }
          } catch (_) {}

          final isAccident =
              item['type'].toString().toLowerCase().contains('kecelakaan') ||
              item['category'].toString().toLowerCase().contains('kecelakaan');

          return GisMarker(
            title: item['title'] ?? 'Kejadian',
            date: item['created_at'] ?? 'Baru saja',
            category: isAccident ? 'Accident' : 'Crime',
            locationName: item['category'] ?? 'Lumajang',
            chronology:
                item['chronology'] ??
                item['deskripsi'] ??
                'Kronologi kejadian belum dilaporkan secara mendalam.',
            position: mapLatLngToOffset(lat, lng),
            latitude: lat,
            longitude: lng,
            imagePath: isAccident
                ? 'assets/images/accident_car.png'
                : 'assets/images/detective_crime.png',
          );
        }).toList();
      }
    } catch (_) {}

    const double latMin = -8.25;
    const double latMax = -8.05;
    const double lngMin = 113.00;
    const double lngMax = 113.44;

    double getLat(Offset pos) => latMax - pos.dy * (latMax - latMin);
    double getLng(Offset pos) => lngMin + pos.dx * (lngMax - lngMin);

    return [
      GisMarker(
        title: 'Pembegalan',
        date: '23-05-2024 00:20:33',
        category: 'Crime',
        locationName: 'Jalan Kalimantan',
        chronology:
            'Aksi pembegalan motor pada malam hari di Jalan Kalimantan oleh pelaku bersenjata tajam.',
        position: const Offset(0.35, 0.45),
        latitude: getLat(const Offset(0.35, 0.45)),
        longitude: getLng(const Offset(0.35, 0.45)),
        imagePath: 'assets/images/detective_crime.png',
      ),
      GisMarker(
        title: 'Penjambretan',
        date: '23-05-2024 16:20:33',
        category: 'Crime',
        locationName: 'Jl. Wolter Monginsidi',
        chronology:
            'Terjadi penjambretan tas oleh pengendara sepeda motor di kawasan Jl. Wolter Monginsidi.',
        position: const Offset(0.68, 0.32),
        latitude: getLat(const Offset(0.68, 0.32)),
        longitude: getLng(const Offset(0.68, 0.32)),
        imagePath: 'assets/images/detective_crime.png',
      ),
      GisMarker(
        title: 'Tabrakan Motor Ganda',
        date: '02-06-2026 08:30:00',
        category: 'Accident',
        locationName: 'Supratman Street',
        chronology:
            'Dua motor bertabrakan di pertigaan karena lampu lalu lintas padam.',
        position: const Offset(0.5, 0.65),
        latitude: getLat(const Offset(0.5, 0.65)),
        longitude: getLng(const Offset(0.5, 0.65)),
        imagePath: 'assets/images/accident_car.png',
      ),
      GisMarker(
        title: 'Mobil Mogok Tengah Jalan',
        date: '01-06-2026 14:15:22',
        category: 'Accident',
        locationName: 'Sriwijaya Street',
        chronology:
            'Mobil sedan mengalami mogok mesin berasap di lajur tengah, menyebabkan kemacetan panjang.',
        position: const Offset(0.2, 0.8),
        latitude: getLat(const Offset(0.2, 0.8)),
        longitude: getLng(const Offset(0.2, 0.8)),
        imagePath: 'assets/images/accident_car.png',
      ),
    ];
  }

  static Future<void> syncHomeData() async {
    try {
      final response = await getRequest('/home');
      if (response.statusCode == 200) {
        // Successful API call
      }
    } catch (_) {}
  }
}
