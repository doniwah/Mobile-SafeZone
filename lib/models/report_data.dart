class ReportData {
  final String title;
  final String chronology;
  final String date;
  final String location;
  final String category;
  String status; // Menunggu Verifikasi, Laporan Diproses, Ditindaklanjuti, Kasus Selesai, Ditolak
  final String imagePath;

  ReportData({
    required this.title,
    required this.chronology,
    required this.date,
    required this.location,
    required this.category,
    required this.status,
    required this.imagePath,
  });
}
