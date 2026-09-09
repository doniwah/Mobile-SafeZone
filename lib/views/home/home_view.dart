import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/desktop_frame.dart';
import '../../services/geofence_service.dart';
import '../../services/notification_service.dart';
import 'home_view_content.dart';
import '../reports/reports_view.dart';
import '../sos/sos_view.dart';
import '../news/news_view.dart';
import '../profile/profile_view.dart';
import '../maps/street_maps_view.dart';
import '../tracking/tracking_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedTab = 0;
  bool _autoTriggerSos = false;
  static const _channel = MethodChannel('com.geocrime.geocrime_app/widget');

  @override
  void initState() {
    super.initState();
    _initWidgetChannel();
    _initGeofenceAndPermissions();
  }

  void _initGeofenceAndPermissions() async {
    // 1. Ensure notification permission is requested after UI is mounted
    await NotificationService().requestPermissions();

    // 2. Request location permission if not already granted
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 3. Start Geofence tracking and do an immediate location check
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      GeofenceService().startTracking();
      await GeofenceService().refreshZones();
      await GeofenceService().checkCurrentLocation();
    }
  }

  void _initWidgetChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'triggerSos') {
        if (mounted) {
          setState(() {
            _autoTriggerSos = true;
            _selectedTab = 2; // Open SOS view
          });
        }
      }
    });

    // Check if the app was launched from the widget
    _channel.invokeMethod<String>('getLaunchIntentAction').then((action) {
      if (action == 'trigger_sos') {
        if (mounted) {
          setState(() {
            _autoTriggerSos = true;
            _selectedTab = 2; // Open SOS view
          });
        }
      }
    });
  }

  Widget _getTabContent() {
    switch (_selectedTab) {
      case 0:
        return HomeViewContent(
          onOpenMap: (kategori) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => StreetMapsView(initialFilter: kategori)),
            );
          },
        );
      case 1:
        return const ReportsView();
      case 2:
        return SosView(
          autoTrigger: _autoTriggerSos,
          onTriggered: () {
            _autoTriggerSos = false;
          },
          onBackPressed: () {
            setState(() {
              _selectedTab = 0;
            });
          },
        );
      case 3:
        return const TrackingView();
      case 4:
        return const NewsView();
      default:
        return HomeViewContent(onOpenMap: (_) {});
    }
  }

  Widget _buildTabItem(int index, IconData icon, String label, double width) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterTabItem(double width) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = 2;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 60,
        child: Center(
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444), // Siren red
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFECDD3), // Soft pink border
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.crisis_alert_rounded, // siren light icon
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DesktopFrame(
      child: _buildNavigationScaffold(),
    );
  }

  Widget _buildNavigationScaffold() {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true, // Content slides beautifully behind the transparent bottom bar
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getTabContent(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      final itemWidth = totalWidth / 5;

                      // Calculate left position for selected tab indicator circle
                      double leftPosition = 0;
                      if (_selectedTab == 0) {
                        leftPosition = 0;
                      } else if (_selectedTab == 1) leftPosition = itemWidth;
                      else if (_selectedTab == 2) leftPosition = itemWidth * 2;
                      else if (_selectedTab == 3) leftPosition = itemWidth * 3;
                      else if (_selectedTab == 4) leftPosition = itemWidth * 4;

                      // Center the 60px circle inside the itemWidth slot
                      leftPosition += (itemWidth - 60) / 2;

                      // Only show indicator on inline selectable tabs (0: Home, 1: Laporan, 4: Berita)
                      final showIndicator = (_selectedTab == 0 || _selectedTab == 1 || _selectedTab == 3 || _selectedTab == 4);

                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Sliding Background Circle
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            left: leftPosition,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: showIndicator ? 1.0 : 0.0,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0B0F19),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          // Row of actual items
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTabItem(0, Icons.home_outlined, 'Beranda', itemWidth),
                              _buildTabItem(1, Icons.assignment_outlined, 'Laporan', itemWidth),
                              _buildCenterTabItem(itemWidth),
                              _buildTabItem(3, Icons.alt_route_rounded, 'Rute Aman', itemWidth),
                              _buildTabItem(4, Icons.newspaper_rounded, 'Berita', itemWidth),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
