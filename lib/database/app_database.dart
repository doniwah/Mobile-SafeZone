import '../models/report_data.dart';
import '../models/sos_signal.dart';
import '../models/contact_data.dart';
import '../models/news_data.dart';

class AppDatabase {
  static final List<ReportData> reports = [
    ReportData(
      title: 'Penjambretan',
      chronology: 'Terjadi penjambretan tas oleh pengendara sepeda motor di kawasan Jl. Wolter Monginsidi.',
      date: '23-05-2024 16:20:33',
      location: 'Jl. Wolter Monginsidi',
      category: 'Kejahatan',
      status: 'Laporan Diproses',
      imagePath: 'assets/images/detective_crime.png',
    ),
    ReportData(
      title: 'Pembegalan',
      chronology: 'Aksi pembegalan motor pada malam hari di Jalan Kalimantan oleh pelaku bersenjata tajam.',
      date: '23-05-2024 00:20:33',
      location: 'Jalan Kalimantan',
      category: 'Kejahatan',
      status: 'Kasus Selesai',
      imagePath: 'assets/images/detective_crime.png',
    ),
  ];

  static final List<SosSignal> sosHistory = [
    SosSignal(
      time: '20-05-2024 09:20:15',
      location: 'Panjaitan Street (GPS: -8.1725, 113.6983)',
      status: 'Sinyal Terkirim',
    ),
  ];

  static final List<ContactData> emergencyContacts = [
    ContactData(name: 'Polsek Jember', phone: '+628123456789'),
    ContactData(name: 'Ibu', phone: '+6281298765432'),
  ];

  static String sosMessageTemplate = 'Saya sedang dalam keadaan darurat. Mohon bantuan segera. Lokasi saya saat ini: https://maps.google.com/?q=-8.17234,113.69834';

  static final List<NewsData> newsArticles = [
    NewsData(
      title: 'Layanan Lapor Polres Lumajang',
      summary: 'Siap melayani informasi maupun pengaduan terkait pelayanan kepolisian.',
      content: 'Polres Lumajang terus memperketat pelayanan keamanan kota melalui integrasi sistem pelaporan berbasis GIS dan pengaduan digital terpadu. Warga dapat mengunggah kejadian mencurigakan, tindak kriminalitas, dan kecelakaan jalan raya dengan melampirkan foto maupun video langsung melalui gawai Anda. Kapolres menyatakan tim reaksi cepat siaga 24 jam untuk memverifikasi dan mendatangi TKP laporan warga guna mewujudkan kota Lumajang yang kondusif.',
      date: '23 Mei 2024',
      author: 'Aipda Heri',
      imagePath: 'assets/images/news_police_banner.png',
      category: 'Keamanan',
    ),
    NewsData(
      title: 'Himbauan Pengalihan Jalan',
      summary: 'Sobat lantas sehubungan dengan adanya kegiatan Haul Akbar...',
      content: 'Sehubungan dengan diadakannya kegiatan Haul Akbar Almarhum Habib Sholeh Bin Muhsin Al Hamid ke-48 pada hari Sabtu 20 April 2024 hingga Minggu 21 April 2024, diimbau kepada seluruh pengguna jalan agar menghindari jalur sekitar lokasi kegiatan dan menggunakan jalur alternatif yang sudah disediakan demi menghindari penumpukan lalu lintas. Petugas gabungan dari Satlantas Polres Lumajang dan Dinas Perhubungan akan disiagakan di berbagai titik persimpangan.',
      date: '20 April 2024',
      author: 'Sarah Johnson',
      imagePath: 'assets/images/news_road_banner.png',
      category: 'Lalu Lintas',
    ),
  ];

  static final List<Map<String, dynamic>> redZones = [
    {
      'id': '1',
      'name': 'Rawan Begal - Jl. Kalimantan',
      'latitude': -8.1725,
      'longitude': 113.6983,
      'radius': 300.0,
    },
    {
      'id': '2',
      'name': 'Kawasan Kriminalitas Tinggi - Alun Alun',
      'latitude': -8.1331,
      'longitude': 113.2224,
      'radius': 500.0,
    },
  ];
}
