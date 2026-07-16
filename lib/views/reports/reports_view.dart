import 'package:flutter/material.dart';
import '../../database/app_database.dart';
import '../../services/api_service.dart';
import 'create_report_view.dart';
import 'report_detail_view.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  bool _showOnlyMine = false;
  final Set<String> _defaultReportTitles = {
    'Penjambretan',
    'Pembegalan',
    'Pencurian motor'
  };

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() async {
    try {
      final list = await ApiService.fetchReports();
      if (list != AppDatabase.reports) {
        AppDatabase.reports.clear();
        AppDatabase.reports.addAll(list);
      }
      if (mounted) setState(() {});
    } catch (e) {
      // Handle potential errors silently or show fallback
    }
  }

  void _openCreateForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateReportView(
          onReportAdded: () {
            _loadReports();
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('selesai')) {
      return const Color(0xFF10B981); // Green
    } else if (lowerStatus.contains('proses')) {
      return const Color(0xFFF59E0B); // Orange/Amber
    } else if (lowerStatus.contains('tunggu') || lowerStatus.contains('verifikasi')) {
      return const Color(0xFF3B82F6); // Blue
    } else if (lowerStatus.contains('tindak')) {
      return const Color(0xFF8B5CF6); // Purple
    } else if (lowerStatus.contains('tolak')) {
      return const Color(0xFFEF4444); // Red
    }
    return const Color(0xFF64748B); // Slate
  }

  String _getStatusText(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('selesai')) return 'SELESAI';
    if (lowerStatus.contains('proses')) return 'DIPROSES';
    if (lowerStatus.contains('tunggu') || lowerStatus.contains('verifikasi')) return 'MENUNGGU VERIFIKASI';
    if (lowerStatus.contains('tindak')) return 'DITINDAKLANJUTI';
    if (lowerStatus.contains('tolak')) return 'DITOLAK';
    return status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final allReports = AppDatabase.reports;
    // Filter list to show default mock data + user-added data (when switch is off)
    // or ONLY user-added data (when switch is on)
    final reportsList = _showOnlyMine
        ? allReports.where((r) => !_defaultReportTitles.contains(r.title)).toList()
        : allReports;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag & Switch Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'LAPORANMU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 2.0,
                    ),
                  ),
                  // Custom Toggle Switch
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showOnlyMine = !_showOnlyMine;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 44,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _showOnlyMine ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: _showOnlyMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 32,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Rekap ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                      text: _showOnlyMine ? 'laporanku' : 'semua',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const TextSpan(
                      text: ' laporan.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Buat laporan baru kapan saja.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),

              // Display reports list or empty state screen
              Expanded(
                child: reportsList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment_late_rounded,
                                size: 54,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Belum Ada Laporan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Kamu belum mengirimkan laporan kejadian saat ini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: reportsList.length,
                        separatorBuilder: (context, index) => const Divider(
                          color: Color(0xFFF1F5F9),
                          height: 1,
                          thickness: 1,
                        ),
                        itemBuilder: (context, index) {
                          final report = reportsList[index];
                          final statusCol = _getStatusColor(report.status);

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ReportDetailView(report: report),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              child: Row(
                                children: [
                                  // Left circular category icon
                                  ClipOval(
                                    child: Image.asset(
                                      report.category == 'Kejahatan'
                                          ? 'assets/images/detective_crime.jpg'
                                          : 'assets/images/accident_car.jpg',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 60,
                                        height: 60,
                                        color: const Color(0xFFF1F5F9),
                                        child: const Icon(Icons.image_rounded, color: Color(0xFF94A3B8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Center info block
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          children: [
                                            Text(
                                              '• ${_getStatusText(report.status)}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: statusCol,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const Text(
                                              '·',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                            Text(
                                              report.category,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          report.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.place_outlined,
                                              size: 13,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                report.location,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Right navigation indicator arrow
                                  const Icon(
                                    Icons.north_east_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Button Container
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 80.0), // Spacing from bottom nav bar
                child: GestureDetector(
                  onTap: _openCreateForm,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F19), // Solid black
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Buat laporan baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
}
