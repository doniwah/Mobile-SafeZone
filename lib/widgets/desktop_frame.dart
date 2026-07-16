import 'package:flutter/material.dart';

class DesktopFrame extends StatelessWidget {
  final Widget child;
  const DesktopFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Dark slate premium background
        body: Stack(
          children: [
            // Ambient glow behind the phone
            Center(
              child: Container(
                width: 420,
                height: 870,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            // The phone mockup
            Center(
              child: Container(
                width: 390,
                height: 844, // Modern standard smartphone dimensions (iPhone 13/14 size)
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(54),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF1E293B), // Premium border frame
                    width: 12,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(42),
                  child: Stack(
                    children: [
                      child,
                      // Subtle camera notch overlay
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 110,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E293B),
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return child;
  }
}
