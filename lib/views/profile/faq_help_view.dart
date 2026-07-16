import 'package:flutter/material.dart';
import '../../widgets/desktop_frame.dart';

class FaqHelpView extends StatelessWidget {
  const FaqHelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return DesktopFrame(
      child: const Scaffold(
        backgroundColor: Colors.white,
        body: FaqHelpContent(),
      ),
    );
  }
}

class FaqHelpContent extends StatelessWidget {
  const FaqHelpContent({super.key});

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          iconColor: const Color(0xFF1E3A8A),
          collapsedIconColor: const Color(0xFF94A3B8),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Text(
                answer, 
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5, fontWeight: FontWeight.w500),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
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
            const Text(
              'Pusat Bantuan',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Temukan jawaban atas kendala operasional aplikasi GeoCrime di sini.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.4),
            ),
            const SizedBox(height: 28),

            // FAQ accordion
            _buildFaqItem(
              'Bagaimana cara melaporkan kejadian?',
              'Anda dapat masuk ke tab Lapor (Bilah navigasi bawah kedua), tekan link "Buat di sini" atau tombol "Buat Laporan Baru", lalu lengkapi kolom judul, kronologi kejadian, dan waktu sebelum menekan tombol Kirim.',
            ),
            _buildFaqItem(
              'Apakah identitas pelapor terjamin aman?',
              'Tentu. Seluruh data identitas pribadi dan laporan Anda dienkripsi serta diproses secara rahasia oleh kepolisian Polres Lumajang/Jember untuk menjamin privasi pelapor.',
            ),
            _buildFaqItem(
              'Bagaimana cara kerja tombol SOS?',
              'Tombol SOS di tengah bilah navigasi akan memicu hitung mundur 5 detik. Jika tidak dibatalkan, lokasi GPS terkini Anda akan dikirim ke kontak darurat, serta menampilkan Polsek terdekat.',
            ),
            const SizedBox(height: 28), 

            // Hotline numbers section
            const Text(
              'Nomor Telepon Darurat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
            ),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                      child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFEF4444), size: 18),
                    ),
                    title: const Text('Polisi Darurat Jember', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('110 / +628123456789', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Memulai panggilan ke Polisi...')),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: const Color(0xFFE2E8F0).withOpacity(0.5), height: 1),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFFFFEDD5), shape: BoxShape.circle),
                      child: const Icon(Icons.fire_truck_rounded, color: Color(0xFFF97316), size: 18),
                    ),
                    title: const Text('Pemadam Kebakaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('113', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Memulai panggilan ke Pemadam Kebakaran...')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
