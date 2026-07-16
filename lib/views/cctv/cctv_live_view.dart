import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../widgets/desktop_frame.dart';

class CctvLiveView extends StatefulWidget {
  final String streetName;
  final bool isOnline;
  final String? urlStream;
  const CctvLiveView({
    super.key,
    required this.streetName,
    required this.isOnline,
    this.urlStream,
  });

  @override
  State<CctvLiveView> createState() => _CctvLiveViewState();
}

class _CctvLiveViewState extends State<CctvLiveView> {
  YoutubePlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.isOnline) {
      _initYoutubePlayer();
    }
  }

  void _initYoutubePlayer() {
    try {
      final url = widget.urlStream ?? '';
      String? videoId;

      // Extract video ID from youtube URL
      final uri = Uri.parse(url);
      if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.first;
      } else if (uri.host.contains('youtube.com')) {
        videoId = uri.queryParameters['v'] ?? uri.pathSegments.last;
      } else {
        videoId = YoutubePlayerController.convertUrlToId(url);
      }

      videoId ??= '85WG8C8WdWM'; // Default fallback

      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: true, // Muted by default to bypass browser autoplay blocks
          pointerEvents: PointerEvents.auto,
        ),
      );
    } catch (_) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopFrame(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12), // Offset for notch
              // Back Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF0F172A),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.streetName,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isOnline ? 'Online - CCTV Lalu Lintas' : 'Offline - Sambungan Terputus',
                      style: TextStyle(
                        fontSize: 15,
                        color: widget.isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Video Player / Offline Notice
              if (widget.isOnline)
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        children: [
                          if (_controller != null && !_hasError)
                            YoutubePlayer(
                              controller: _controller!,
                              aspectRatio: 16 / 9,
                            )
                          else
                            Image.asset(
                              'assets/images/news_road_banner.png',
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          // Live Tag Bar
                          Container(
                            color: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'LIVE FEED | ${widget.streetName.toUpperCase()}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'LIVE STREAMING',
                                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.videocam_off_rounded, size: 48, color: Color(0xFFEF4444)),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Koneksi CCTV Gagal',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kamera sedang tidak aktif atau mengalami masalah jaringan teknis di lokasi kejadian.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
