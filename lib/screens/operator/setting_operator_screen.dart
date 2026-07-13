import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'school_profile_screen.dart';
import 'activity_log_screen.dart';
import '../about_system_screen.dart';


class SettingOperatorScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const SettingOperatorScreen({super.key, required this.user});

  @override
  State<SettingOperatorScreen> createState() => _SettingOperatorScreenState();
}

class _SettingOperatorScreenState extends State<SettingOperatorScreen> {
  static const Color _primary   = Color(0xFFC17B2F);
  static const Color _primaryDk = Color(0xFFA0601A);
  static const Color _bg        = Color(0xFFFDF8F3);
  static const Color _border    = Color(0xFFF0E8DF);

  // ── Password fields ────────────────────────────────────────────────────────
  final _oldPassCtrl  = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _confPassCtrl = TextEditingController();
  bool _showOld  = false;
  bool _showNew  = false;
  bool _showConf = false;
  bool _isSavingPass = false;

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  // ── Ganti password ─────────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final old   = _oldPassCtrl.text.trim();
    final newP  = _newPassCtrl.text.trim();
    final confP = _confPassCtrl.text.trim();

    if (old.isEmpty || newP.isEmpty || confP.isEmpty) {
      _snack('Semua kolom password wajib diisi', isError: true); return;
    }
    if (newP.length < 6) {
      _snack('Password baru minimal 6 karakter', isError: true); return;
    }
    if (newP != confP) {
      _snack('Konfirmasi password tidak cocok', isError: true); return;
    }

    setState(() => _isSavingPass = true);

    final id = int.tryParse(widget.user['id'].toString()) ?? 0;
    final result = await ApiService.postData('change_password.php', {
      'id'          : id,
      'old_password': old,
      'new_password': newP,
    });

    if (!mounted) return;
    setState(() => _isSavingPass = false);

    if (result['status'] == 'success') {
      _oldPassCtrl.clear(); _newPassCtrl.clear(); _confPassCtrl.clear();
      _snack('Password berhasil diperbarui ✓');
    } else {
      _snack(result['message'] ?? 'Gagal mengubah password', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Keluar Akun', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Apakah Anda yakin ingin keluar dari SiMONA?',
          style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/');
            },
            child: Text('Keluar', style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final name = widget.user['name']?.toString() ?? 'Operator';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Pengaturan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Profil Card ────────────────────────────────────────────────────
          _buildProfileCard(name),
          const SizedBox(height: 20),

          // ── Ganti Password ─────────────────────────────────────────────────
          _sectionTitle('Keamanan Akun', Icons.lock_outline_rounded),
          const SizedBox(height: 12),
          _buildPasswordCard(),
          const SizedBox(height: 20),

          // ── Menu Cepat ─────────────────────────────────────────────────────
          _sectionTitle('Menu Cepat', Icons.apps_rounded),
          const SizedBox(height: 12),
          _buildQuickMenuCard(),
          const SizedBox(height: 20),

          // ── Tentang Aplikasi ───────────────────────────────────────────────
          _sectionTitle('Tentang Aplikasi', Icons.info_outline_rounded),
          const SizedBox(height: 12),
          _buildAboutCard(),
          const SizedBox(height: 20),

          // ── Logout ─────────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmLogout,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(Icons.logout_rounded, color: Colors.red.shade500),
              label: Text('Keluar Akun',
                style: GoogleFonts.poppins(
                  color: Colors.red.shade500, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  // ── Profil card ────────────────────────────────────────────────────────────
  Widget _buildProfileCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4891A), Color(0xFFC17B2F), Color(0xFF8B5E1A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
            style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('Operator SiMONA',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('TK Negeri 2 Bengkalis',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFFE0A3), fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ])),
      ]),
    );
  }

  // ── Password card ──────────────────────────────────────────────────────────
  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        _passwordField('Password Lama', _oldPassCtrl, _showOld,
          () => setState(() => _showOld = !_showOld)),
        const SizedBox(height: 12),
        _passwordField('Password Baru', _newPassCtrl, _showNew,
          () => setState(() => _showNew = !_showNew)),
        const SizedBox(height: 12),
        _passwordField('Konfirmasi Password Baru', _confPassCtrl, _showConf,
          () => setState(() => _showConf = !_showConf)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSavingPass ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              disabledBackgroundColor: _primary.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSavingPass
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Simpan Password Baru',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _passwordField(String label, TextEditingController ctrl, bool show, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: !show,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
        filled: true,
        fillColor: const Color(0xFFFDF8F3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: Colors.grey.shade400, size: 20),
          onPressed: toggle,
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
    );
  }

  // ── Quick menu card ────────────────────────────────────────────────────────
  Widget _buildQuickMenuCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        _menuRow(
          icon: Icons.account_balance_rounded,
          color: _primary,
          title: 'Profil Sekolah',
          subtitle: 'Kelola data dan informasi sekolah',
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SchoolProfileScreen(userRole: 'operator'))),
        ),
        _divider(),
        _menuRow(
          icon: Icons.history_rounded,
          color: const Color(0xFF2980B9),
          title: 'Log Aktivitas',
          subtitle: 'Riwayat seluruh aktivitas sistem',
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ActivityLogScreen())),
        ),
        _divider(),
        _menuRow(
          icon: Icons.info_outline_rounded,
          color: const Color(0xFF8E44AD),
          title: 'Tentang SiMONA',
          subtitle: 'Versi aplikasi dan informasi sistem',
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AboutSystemScreen(
              primaryColor: _primary,
              primaryDark: _primaryDk,
              backgroundColor: _bg,
              borderColor: _border,
            ))),
        ),
      ]),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600,
          color: const Color(0xFF374151))),
      subtitle: Text(subtitle,
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
    );
  }

  // ── About card ─────────────────────────────────────────────────────────────
  Widget _buildAboutCard() {
    final infos = [
      ['Nama Aplikasi', 'SiMONA'],
      ['Versi', '1.0.0'],
      ['Platform', 'Flutter (Android & Windows)'],
      ['Backend', 'PHP + MySQL (XAMPP)'],
      ['Sekolah', 'TK Negeri 2 Bengkalis'],
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: infos.asMap().entries.map((e) {
          final isLast = e.key == infos.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Text(e.value[0],
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                const Spacer(),
                Text(e.value[1],
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151))),
              ]),
            ),
            if (!isLast) Divider(height: 1, color: _border, indent: 16, endIndent: 16),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: _border, indent: 16, endIndent: 16);

  Widget _sectionTitle(String text, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: _primary, size: 16),
      ),
      const SizedBox(width: 10),
      Text(text,
        style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF374151))),
    ]);
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFD4891A), Color(0xFF8B5E1A)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 14),
          Text('SiMONA', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: _primaryDk)),
          Text('Sistem Informasi Monitoring Penilaian Perkembangan Anak',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('v1.0.0', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400)),
          const SizedBox(height: 16),
          Text('TK Negeri 2 Bengkalis\nJl. Pendidikan No.1, Bengkalis, Riau',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, height: 1.5)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(ctx),
              child: Text('Tutup', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
