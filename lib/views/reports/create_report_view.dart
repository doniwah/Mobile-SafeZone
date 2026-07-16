import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/report_data.dart';
import '../../database/app_database.dart';
import '../../services/api_service.dart';
import '../../widgets/desktop_frame.dart';

class CreateReportView extends StatelessWidget {
  final VoidCallback onReportAdded;
  const CreateReportView({super.key, required this.onReportAdded});

  @override
  Widget build(BuildContext context) {
    return DesktopFrame(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CreateReportViewContent(onReportAdded: onReportAdded),
      ),
    );
  }
}

class CreateReportViewContent extends StatefulWidget {
  final VoidCallback onReportAdded;
  const CreateReportViewContent({super.key, required this.onReportAdded});

  @override
  State<CreateReportViewContent> createState() => _CreateReportViewContentState();
}

class _CreateReportViewContentState extends State<CreateReportViewContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _chronologyController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _selectedCategory = 'Kejahatan';
  double _uploadProgress = 0.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Default current time
    final now = DateTime.now();
    _dateController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _chronologyController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _uploadProgress = 0.0;
      });

      // Simulate file upload progress bar
      Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        setState(() {
          _uploadProgress += 0.1;
        });

        if (_uploadProgress >= 1.0) {
          timer.cancel();
          
          final success = await ApiService.submitReport(
            title: _titleController.text,
            description: _chronologyController.text,
            category: _selectedCategory,
          );

          if (success) {
            AppDatabase.reports.insert(
              0,
              ReportData(
                title: _titleController.text,
                chronology: _chronologyController.text,
                date: _dateController.text,
                location: 'Panjaitan Street (Jember)',
                category: _selectedCategory,
                status: 'Menunggu Verifikasi',
                imagePath: 'assets/images/detective_crime.png',
              ),
            );

            widget.onReportAdded();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Laporan Berhasil Dikirim ke Administrator!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Gagal mengirim laporan. Coba lagi.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            }
          }
          
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
            Navigator.of(context).pop();
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button Row
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Buat Laporan',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Laporkan kejadian kriminalitas atau kecelakaan di sekitar Anda dengan menyertakan detail kronologis.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.4),
                  ),
                  const SizedBox(height: 28),

                  // Title Field
                  const Text(
                    'Judul Laporan *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Judul wajib diisi' : null,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: 'Contoh: Pencurian sepeda motor',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Chronology Field
                  const Text(
                    'Kronologi Kejadian *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _chronologyController,
                    maxLines: 4,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Kronologi wajib diisi' : null,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: 'Jelaskan kronologi detail kejadian, ciri pelaku, kerugian, dll...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date & Time Field
                  const Text(
                    'Tanggal & Waktu *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      suffixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF64748B)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Dropdown Field
                  const Text(
                    'Kategori *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                        items: <String>['Kejahatan', 'Kecelakaan', 'Gangguan keamanan', 'Lainnya']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Kirim Button
                  GestureDetector(
                    onTap: _submitForm,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'KIRIM LAPORAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),

        // OVERLAY FOR SUBMISSION LOADER & FILE UPLOAD SIMULATOR
        if (_isSubmitting)
          Container(
            color: Colors.black.withOpacity(0.55),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF2563EB)),
                    const SizedBox(height: 24),
                    const Text(
                      'Mengirim Laporan...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Mohon tunggu sejenak, mengunggah bukti ke database.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        color: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFFF1F5F9),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toInt()}% Terunggah',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
