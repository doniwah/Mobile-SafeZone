import 'package:flutter/material.dart';
import '../models/red_zone.dart';
import '../views/tracking/tracking_view.dart';
import '../views/sos/sos_view.dart';

class SafetyTipsBottomSheet extends StatelessWidget {
  final RedZone zone;

  const SafetyTipsBottomSheet({
    super.key,
    required this.zone,
  });

  /// Helper static method untuk memunculkan bottom sheet dari view manapun
  static Future<void> show(BuildContext context, RedZone zone) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafetyTipsBottomSheet(zone: zone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tips = zone.effectivePreventionTips;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark slate background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border(
          top: BorderSide(color: Color(0xFFEF4444), width: 2.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row: Warning Icon + Title + Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.6), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PERINGATAN ZONA MERAH',
                                style: TextStyle(
                                  color: Color(0xFFF87171),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          zone.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    splashRadius: 20,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Badges: Category & Radius & Danger Level
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildBadge(
                    icon: Icons.shield_outlined,
                    label: zone.category,
                    color: const Color(0xFFF97316),
                  ),
                  _buildBadge(
                    icon: Icons.radar_rounded,
                    label: 'Radius ${zone.radius.toInt()}m',
                    color: const Color(0xFF38BDF8),
                  ),
                  _buildBadge(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Tingkat: ${zone.dangerLevel}',
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 14),

              // Section Title: Saran Pencegahan
              Row(
                children: const [
                  Icon(Icons.lightbulb_rounded, color: Color(0xFFFBBF24), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Saran Pencegahan & Panduan Aman:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Prevention Tips List
              Column(
                children: tips.map((tip) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF10B981),
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Quick Action Buttons
              Row(
                children: [
                  // Button 1: Safe Route Alternative
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TrackingView(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.alt_route_rounded, size: 18),
                      label: const Text(
                        'Rute Aman',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Button 2: SOS Trigger
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SosView(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.emergency_rounded, size: 18),
                      label: const Text(
                        'Siaga SOS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Saya Mengerti, Tetap Waspada',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
