import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // For iOS, you might need to configure DarwinInitializationSettings
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

    // Request permissions for Android 13+ and iOS
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showGeofenceAlert(String title, String body) async {
    // Menggunakan channel baru 'geofence_danger_channel' agar custom sound terdaftar.
    // (Android tidak mengizinkan perubahan sound pada channel yang sudah ada)
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'geofence_danger_channel',
      'Geofence Danger Alerts',
      channelDescription: 'Notifikasi peringatan saat memasuki zona rawan',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('danger_alert'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      enableLights: true,
      color: const Color(0xFFEF4444),
      ledColor: const Color(0xFFEF4444),
      ledOnMs: 300,
      ledOffMs: 300,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentSound: true,
      sound: 'danger_alert.mp3', // Custom sound untuk iOS
      presentAlert: true,
      presentBadge: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id: 0, // Notification ID
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> showCorridorAlert(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'corridor_channel',
      'Geo-Corridor Route Alerts',
      channelDescription: 'Notifications for route deviation alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id: 1, // Notification ID for Corridor Alert
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> showSafeZoneAlert(String title, String body) async {
    // Channel baru 'safezone_safe_channel' dengan custom sound berbeda (lebih tenang)
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'safezone_safe_channel',
      'SafeZone Safe Alerts',
      channelDescription: 'Notifikasi saat keluar dari zona rawan ke zona aman',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('safe_zone_alert'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
      enableLights: true,
      color: const Color(0xFF22C55E),   // Hijau — zona aman
      ledColor: const Color(0xFF22C55E),
      ledOnMs: 500,
      ledOffMs: 1000,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentSound: true,
      sound: 'safe_zone_alert.mp3', // Custom sound untuk iOS
      presentAlert: true,
      presentBadge: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id: 2, // Notification ID for SafeZone Alert
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  /// Menampilkan notifikasi darurat ketika terdeteksi SOS dalam radius 2km
  /// dari posisi pengguna saat ini.
  Future<void> showSosNearbyAlert({
    required String address,
    required String distanceLabel,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_nearby_channel',
      'SOS Terdekat',
      channelDescription: 'Peringatan darurat SOS yang terjadi di sekitar Anda dalam radius 2 km',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFFEF4444),
      ledColor: Color(0xFFEF4444),
      ledOnMs: 500,
      ledOffMs: 500,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: 99, // ID tetap; notifikasi baru akan menggantikan yang lama
      title: '⚠️ Darurat di Sekitar Anda!',
      body: 'Ada sinyal SOS sejauh $distanceLabel dari Anda ($address). Harap waspada!',
      notificationDetails: platformDetails,
    );
  }
}
