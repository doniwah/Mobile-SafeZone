import 'package:flutter/material.dart';
import '../../models/report_data.dart';
import '../../widgets/desktop_frame.dart';

class ReportDetailView extends StatelessWidget {
  final ReportData report;
  const ReportDetailView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return DesktopFrame(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: ReportDetailViewContent(report: report),
      ),
    );
  }
}

class ReportDetailViewContent extends StatelessWidget {
  final ReportData report;
  const ReportDetailViewContent({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    // Logic status index
    int statusIndex = 0;
    if (report.status == 'Menunggu Verifikasi') statusIndex = 0;
    if (report.status == 'Diproses' || report.status == 'Laporan Diproses') statusIndex = 1;
    if (report.status == 'Ditindaklanjuti') statusIndex = 2;
    if (report.status == 'Selesai' || report.status == 'Kasus Selesai') statusIndex = 3;

    Widget stepIndicator(int index, String title, String description, String dateText) {
      final isActive = index <= statusIndex;
      final isCompleted = index < statusIndex;
      
      final activeColor = report.status == 'Ditolak' 
          ? const Color(0xFFEF4444) 
          : const Color(0xFF1E3A8A);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline node drawing
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? activeColor
                      : (isActive ? activeColor.withOpacity(0.15) : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? activeColor : const Color(0xFFCBD5E1),
                    width: 2.5,
                  ),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.25),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ] : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : (isActive
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: activeColor,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null),
                ),
              ),
              if (index < 3)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 2.5,
                  height: 54,
                  color: index < statusIndex 
                      ? activeColor 
                      : const Color(0xFFE2E8F0),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Timeline content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive ? dateText : 'Belum selesai',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button Row
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 24),

            // Category tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: report.category == 'Kejahatan' 
                    ? const Color(0xFFEF4444).withOpacity(0.1) 
                    : const Color(0xFFF97316).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: report.category == 'Kejahatan' ? const Color(0xFFEF4444) : const Color(0xFFF97316),
                  width: 1,
                ),
              ),
              child: Text(
                report.category.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: report.category == 'Kejahatan' ? const Color(0xFFEF4444) : const Color(0xFFF97316),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              report.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Date and Location Row
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF3B82F6)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Image Thumbnail if any
            if (report.imagePath.isNotEmpty)
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    report.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(Icons.image_not_supported_rounded, color: Color(0xFF94A3B8), size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Chronology Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Kejadian / Kronologi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.chronology,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Divider line
            Container(height: 1, color: const Color(0xFFE2E8F0)),
            const SizedBox(height: 28),

            // Stepper Status Title
            const Text(
              'Status Tindak Lanjut',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
            ),
            const SizedBox(height: 24),

            // Stepper layout
            stepIndicator(
              0, 
              'Laporan Dibuat', 
              'Laporan Anda berhasil dikirim dan terdaftar di database utama GeoCrime.', 
              report.date
            ),
            stepIndicator(
              1, 
              'Verifikasi Laporan', 
              'Petugas / Administrator sedang memeriksa kesahihan berkas kronologi.', 
              'Meninjau kelengkapan...'
            ),
            stepIndicator(
              2, 
              'Tindakan Lapangan', 
              'Unit Kepolisian Terdekat atau tim medis darurat telah diberangkatkan ke koordinat terkait.', 
              'Sedang dikirim...'
            ),
            stepIndicator(
              3, 
              'Laporan Selesai', 
              'Kasus telah berhasil diselesaikan secara administratif maupun operasional di lapangan.', 
              'Menyelesaikan...'
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
