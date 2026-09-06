import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/sos_signal.dart';
import '../../models/sos_event.dart';
import '../../database/app_database.dart';
import '../../services/connectivity_service.dart';
import '../../services/emergency_communication_manager.dart';
import 'sos_settings_view.dart';
import 'emergency_map_view.dart';

class SosView extends StatefulWidget {
  final bool autoTrigger;
  final VoidCallback? onTriggered;
  final VoidCallback? onBackPressed;

  const SosView({
    super.key,
    this.autoTrigger = false,
    this.onTriggered,
    this.onBackPressed,
  });

  @override
  State<SosView> createState() => _SosViewState();
}

class _SosViewState extends State<SosView> with SingleTickerProviderStateMixin {
  int _countdown = 5;
  Timer? _timer;
  bool _isTriggered = false;
  late AnimationController _pulseController;
  String _currentAddress = 'Jl. Panjaitan #12';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadCurrentAddress();

    if (widget.autoTrigger) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerSos();
        if (widget.onTriggered != null) {
          widget.onTriggered!();
        }
      });
    }
  }

  void _loadCurrentAddress() async {
    try {
      final loc = await _getCurrentLocation();
      final lat = loc['latitude']!;
      final lng = loc['longitude']!;
      final isYogya = (lat >= -8.1 && lat <= -7.5 && lng >= 110.0 && lng <= 110.6);
      if (mounted) {
        setState(() {
          _currentAddress = isYogya ? 'Yogyakarta, Indonesia' : 'Jl. Panjaitan #12';
        });
      }
    } catch (_) {}
  }

  Future<Map<String, double>> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return {'latitude': -7.7956, 'longitude': 110.3695, 'accuracy': 0.0};
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return {'latitude': -7.7956, 'longitude': 110.3695, 'accuracy': 0.0};
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return {'latitude': -7.7956, 'longitude': 110.3695, 'accuracy': 0.0};
    } 

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      return {'latitude': position.latitude, 'longitude': position.longitude, 'accuracy': position.accuracy};
    } catch (_) {
      return {'latitude': -7.7956, 'longitude': 110.3695, 'accuracy': 0.0};
    }
  }

  void _triggerSos() async {
    setState(() {
      _isTriggered = true;
      _countdown = 5;
    });

    // PARALLEL OPERATIONS: Acquire GPS and Check Connectivity simultaneously
    final locationFuture = _getCurrentLocation();
    final reachabilityFuture = ConnectivityService.checkBackendReachability();
    final networkTypeFuture = ConnectivityService.getNetworkType();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTriggered = false;
        });

        // Countdown finished. Wait for parallel operations to complete.
        // If GPS is not done, it will wait here (up to 5s internal limit).
        // If GPS failed, it returns fallback location.
        final loc = await locationFuture;
        final reachability = await reachabilityFuture;
        final networkType = await networkTypeFuture;

        final double lat = loc['latitude']!;
        final double lng = loc['longitude']!;
        final double accuracy = loc['accuracy'] ?? 0.0;

        final isYogya = (lat >= -8.1 && lat <= -7.5 && lng >= 110.0 && lng <= 110.6);
        final String address = isYogya ? 'Yogyakarta, Indonesia' : 'Lumajang, Jawa Timur';

        final manager = EmergencyCommunicationManager();
        final sosEvent = manager.createLocalSosEvent(
          latitude: lat,
          longitude: lng,
          accuracy: accuracy,
          alamatTerdeteksi: address,
          catatan: AppDatabase.sosMessageTemplate,
        );

        // Emergency Router: Decide best channel and save locally FIRST
        await manager.sendEmergency(sosEvent, reachability, networkType);

        AppDatabase.sosHistory.insert(
          0,
          SosSignal(
            time: DateTime.now().toString().substring(0, 19),
            location: address,
            status: sosEvent.status == SosStatus.synced ? 'Sinyal Terkirim' : 'Menunggu Koneksi',
          ),
        );

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              // Using existing API response format or map format for UI
              builder: (context) => EmergencyMapView(sosData: {'success': true, 'message': 'SOS Event Created'}),
            ),
          );
        }
      }
    });
  }

  void _cancelSos() {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() {
      _isTriggered = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Sinyal Darurat SOS Berhasil Dibatalkan!'),
        backgroundColor: Color(0xFFF59E0B),
      ),
    );
  }

  @override
  void dispose() {
    if (_timer != null) _timer!.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // Top Back & Settings Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Circular back button
                  GestureDetector(
                    onTap: widget.onBackPressed,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                  ),
                  const Text(
                    'EMERGENCY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 2.0,
                    ),
                  ),
                  // Circular settings button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SosSettingsView()),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Title & Subtitle
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 32,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: 'Tombol ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                      text: 'darurat.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tekan untuk mengirim sinyal SOS.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),

              // SOS Main Core Button & Pulse Animation
              Center(
                child: _isTriggered
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulsating critical warning circular count
                          Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFCA5A5), width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.15),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '$_countdown',
                                style: const TextStyle(
                                  fontSize: 84,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFEF4444),
                                  letterSpacing: -2.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          const Text(
                            'Mengirimkan Lokasi Anda dalam...',
                            style: TextStyle(fontSize: 15, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          // Batal Button
                          GestureDetector(
                            onTap: _cancelSos,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F172A).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Text(
                                'BATALKAN',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                              ),
                            ),
                          )
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _triggerSos,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Concentric pulsing rings (4 layers of waves)
                                    Container(
                                      width: 170 + (90 * _pulseController.value),
                                      height: 170 + (90 * _pulseController.value),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withOpacity(0.08 * (1.0 - _pulseController.value)),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 170 + (60 * _pulseController.value),
                                      height: 170 + (60 * _pulseController.value),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withOpacity(0.15 * (1.0 - _pulseController.value)),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 170 + (30 * _pulseController.value),
                                      height: 170 + (30 * _pulseController.value),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withOpacity(0.25 * (1.0 - _pulseController.value)),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    // Main SOS button circle
                                    Container(
                                      width: 180,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444), // Solid red
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444).withOpacity(0.4),
                                            blurRadius: 24,
                                            offset: const Offset(0, 10),
                                          )
                                        ],
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.shield_outlined,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'S O S',
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 36),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text(
                              'Sinyal marabahaya dan titik GPS-mu akan langsung terkirim ke aparat berwajib.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const Spacer(),

              // Bottom Info Cards
              Row(
                children: [
                  // Location Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF8B5CF6),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'LOKASI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currentAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Contact Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.phone_outlined,
                                color: Color(0xFF8B5CF6),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'KONTAK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${AppDatabase.emergencyContacts.length} tersimpan',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 76), // Padding space for navigation bar
            ],
          ),
        ),
      ),
    );
  }
}
