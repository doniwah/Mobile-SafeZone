import 'package:flutter/material.dart';
import '../../database/app_database.dart';
import '../../services/api_service.dart';
import '../onboarding/onboarding_view.dart';
import '../sos/sos_settings_view.dart';
import 'faq_help_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int _sosCount = AppDatabase.sosHistory.length;
  bool _isLoading = true;

  // Notification & Geofence Settings State
  bool _geofenceAlertSound = true;
  bool _geofenceVibration = true;
  bool _corridorAlerts = true;
  bool _sosNearbyNotification = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final reportsList = await ApiService.fetchReports();
      final sos = await ApiService.fetchSosCount();
      if (reportsList != AppDatabase.reports) {
        AppDatabase.reports.clear();
        AppDatabase.reports.addAll(reportsList);
      }
      if (mounted) {
        setState(() {
          _sosCount = sos;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: ApiService.currentUser?['name'] ?? 'Doni Wahyu');
    final emailController = TextEditingController(text: ApiService.currentUser?['email'] ?? 'doni@safezone.id');
    final phoneController = TextEditingController(text: ApiService.currentUser?['phone'] ?? '+62 812 3456 789');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(Icons.edit_note_rounded, color: Color(0xFF1E3A8A), size: 24),
              SizedBox(width: 10),
              Text(
                'Ubah Profil',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Alamat Email',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Nomor Telepon',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isNotEmpty && email.isNotEmpty) {
                  final Map<String, dynamic> updatedUser = Map.from(ApiService.currentUser ?? {});
                  updatedUser['name'] = name;
                  updatedUser['email'] = email;
                  updatedUser['phone'] = phone.isNotEmpty ? phone : '+62 812 3456 789';

                  await ApiService.saveSession(
                    ApiService.token ?? 'mock_token_xyz',
                    updatedUser,
                  );

                  if (mounted) {
                    setState(() {});
                  }
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Profil berhasil diperbarui!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: const [
                  Icon(Icons.lock_reset_rounded, color: Color(0xFF1E3A8A), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Ubah Kata Sandi',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPasswordController,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Lama',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Baru',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi Baru',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final oldPass = oldPasswordController.text;
                    final newPass = newPasswordController.text;
                    final confirmPass = confirmPasswordController.text;

                    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFFEF4444),
                          content: Text('Semua kolom kata sandi wajib diisi!'),
                        ),
                      );
                      return;
                    }
                    if (newPass.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFFEF4444),
                          content: Text('Kata sandi baru minimal 6 karakter!'),
                        ),
                      );
                      return;
                    }
                    if (newPass != confirmPass) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFFEF4444),
                          content: Text('Konfirmasi kata sandi tidak cocok!'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFF10B981),
                        content: Text('Kata sandi berhasil diperbarui!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Perbarui', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNotificationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: const [
                  Icon(Icons.notifications_active_rounded, color: Color(0xFF1E3A8A), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Pengaturan Notifikasi',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Suara Sirine Zona Merah', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Bunyikan alarm saat masuk zona rawan', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    value: _geofenceAlertSound,
                    activeColor: const Color(0xFFEF4444),
                    onChanged: (val) {
                      setDialogState(() => _geofenceAlertSound = val);
                      setState(() => _geofenceAlertSound = val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Getaran Darurat SOS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Pola getar khusus untuk peringatan darurat', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    value: _geofenceVibration,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) {
                      setDialogState(() => _geofenceVibration = val);
                      setState(() => _geofenceVibration = val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Penyimpangan Geo-Koridor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Peringatan jika melenceng >50m dari rute aman', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    value: _corridorAlerts,
                    activeColor: const Color(0xFF3B82F6),
                    onChanged: (val) {
                      setDialogState(() => _corridorAlerts = val);
                      setState(() => _corridorAlerts = val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sinyal SOS Terdekat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Notifikasi jika ada SOS dalam radius 2 km', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    value: _sosNearbyNotification,
                    activeColor: const Color(0xFFF97316),
                    onChanged: (val) {
                      setDialogState(() => _sosNearbyNotification = val);
                      setState(() => _sosNearbyNotification = val);
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun SafeZone? Sesi dan otentikasi akan diakhiri.',
          style: TextStyle(color: Color(0xFF475569), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await ApiService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const OnboardingView()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Berhasil keluar dari akun SafeZone'),
                    backgroundColor: Color(0xFFF59E0B),
                  ),
                );
              }
            },
            child: const Text('Ya, Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color iconColor = const Color(0xFF1E3A8A),
    Color textColor = const Color(0xFF1E293B),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)))
            : null,
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = ApiService.currentUser?['name'] ?? 'Doni Wahyu';
    final userEmail = ApiService.currentUser?['email'] ?? 'doni@safezone.id';
    final userPhone = ApiService.currentUser?['phone'] ?? '+62 812 3456 789';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profil Pengguna',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Color(0xFF1E3A8A)),
            tooltip: 'Edit Profil',
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile info card (Modern elevated card)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.10),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(38),
                                child: Image.asset(
                                  'assets/images/profile_avatar.png',
                                  width: 76,
                                  height: 76,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 76,
                                    height: 76,
                                    color: const Color(0xFFEDE9FE),
                                    child: Center(
                                      child: Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF8B5CF6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showEditProfileDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                userPhone,
                                style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Warga Terverifikasi (KTP Aktif)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _showEditProfileDialog,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Edit Data',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // User Statistics indicators row (Total Laporan, Verifikasi, SOS)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A)),
                                )
                              : Text(
                                  '${AppDatabase.reports.length}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                                ),
                          const SizedBox(height: 4),
                          const Text(
                            'Laporan',
                            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF97316)),
                                )
                              : Text(
                                  '${AppDatabase.reports.where((r) => r.status != 'Menunggu Verifikasi').length}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFF97316)),
                                ),
                          const SizedBox(height: 4),
                          const Text(
                            'Terverifikasi',
                            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)),
                                )
                              : Text(
                                  '$_sosCount',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                                ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sinyal SOS',
                            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section 1: Keamanan & Kontak
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'KEAMANAN & KONTAK DARURAT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2),
                ),
              ),
              _buildMenuItem(
                context,
                icon: Icons.contact_phone_rounded,
                title: 'Kontak Darurat Saya (SOS)',
                subtitle: 'Kelola nomor darurat keluarga & kepolisian',
                iconColor: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SosSettingsView()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.notifications_active_rounded,
                title: 'Pengaturan Notifikasi & Geofence',
                subtitle: 'Alarm zona merah, getaran, dan rute',
                iconColor: const Color(0xFF10B981),
                onTap: _showNotificationSettingsDialog,
              ),

              const SizedBox(height: 16),

              // Section 2: Akun & Privasi
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'AKUN & INFORMASI',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2),
                ),
              ),
              _buildMenuItem(
                context,
                icon: Icons.lock_outline_rounded,
                title: 'Ubah Kata Sandi',
                subtitle: 'Perbarui kata sandi akun secara berkala',
                onTap: _showChangePasswordDialog,
              ),
              _buildMenuItem(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Pusat Bantuan & FAQ',
                subtitle: 'Panduan penggunaan SafeZone & nomor darurat',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const FaqHelpView()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.shield_rounded,
                title: 'Tentang SafeZone Mobile',
                subtitle: 'Versi 1.0.0 • Karya Inovasi KMIPN',
                iconColor: const Color(0xFF3B82F6),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'SafeZone Mobile',
                    applicationVersion: '1.0.0 (KMIPN 2026)',
                    applicationIcon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 32),
                    ),
                    applicationLegalese: '© 2026 Tim SafeZone - KMIPN.\nPlatform Keamanan Lingkungan, Rute Bebas Bahaya, & Intervensi Kriminalitas Berbasis GIS.',
                  );
                },
              ),

              const SizedBox(height: 8),

              // Logout
              _buildMenuItem(
                context,
                icon: Icons.logout_rounded,
                title: 'Keluar Akun',
                subtitle: 'Akhiri sesi aktif Anda di perangkat ini',
                iconColor: const Color(0xFFEF4444),
                textColor: const Color(0xFFEF4444),
                onTap: _showLogoutConfirmation,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
