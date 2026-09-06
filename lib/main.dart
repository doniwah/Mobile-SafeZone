import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/emergency_sync_manager.dart';
import 'services/notification_service.dart';
import 'services/geofence_service.dart';
import 'views/home/home_view.dart';
import 'views/onboarding/onboarding_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  EmergencySyncManager().initialize();
  
  await NotificationService().initialize();
  GeofenceService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeZone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Blue (#1E3A8A)
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFFF97316), // Orange (#F97316)
        ),
        useMaterial3: true,
      ),
      home: ApiService.isAuthenticated ? const HomeView() : const OnboardingView(),
    );
  }
}
