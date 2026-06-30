import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';

import '../operator/dashboard_operator.dart';
import '../guru/dashboard_guru.dart';
import '../orang_tua/dashboard_ortu.dart';
import '../kepala_sekolah/dashboard_kepsek.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color primaryColor = Color(0xFF1A3A6B);

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua field")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.login(identifier, password);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['status'] == 'success') {
      final user = result['user'];
      final role = user['role'];

      Widget nextScreen;

      switch (role) {
        case 'operator':
          nextScreen = const DashboardOperator();
          break;
        case 'guru':
          nextScreen = DashboardGuru(user: user);
          break;
        case 'orang_tua':
          nextScreen = DashboardOrtu(user: user);
          break;
        case 'kepsek':
          nextScreen = DashboardKepsek(user: user);
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Role tidak ditemukan")),
          );
          return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil ukuran layar untuk responsivitas
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Tentukan apakah layar kecil (HP kecil) atau besar (tablet/HP besar)
    final bool isSmallScreen = screenHeight < 680;
    final bool isTablet = screenWidth >= 600;

    // Lebar card maksimal: tablet pakai 420, HP pakai full width - padding
    final double cardMaxWidth = isTablet ? 420 : double.infinity;

    // Ukuran logo menyesuaikan tinggi layar
    final double logoSize = isSmallScreen ? 56 : 72;
    final double logoIconSize = isSmallScreen ? 28 : 36;
    final double logoRadius = isSmallScreen ? 16 : 20;

    // Ukuran teks menyesuaikan layar
    final double appNameSize = isSmallScreen ? 22 : 28;
    final double subtitleSize = isSmallScreen ? 11 : 13;
    final double headingSize = isSmallScreen ? 17 : 20;

    // Jarak antar elemen menyesuaikan tinggi layar
    final double verticalPadding = isSmallScreen ? 16 : 32;
    final double headerToCardGap = isSmallScreen ? 18 : 28;
    final double fieldGap = isSmallScreen ? 12 : 16;
    final double cardPaddingV = isSmallScreen ? 20 : 28;
    final double cardPaddingH = isSmallScreen ? 20 : 24;

    // Tinggi tombol menyesuaikan layar
    final double buttonHeight = isSmallScreen ? 46 : 52;

    return Scaffold(
      // Agar konten tidak terdorong saat keyboard muncul
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D2B55),
                  Color(0xFF1A3A6B),
                  Color(0xFF1E5799),
                ],
              ),
            ),
          ),

          // Lingkaran dekoratif — ukuran menyesuaikan layar
          Positioned(
            top: -screenWidth * 0.2,
            right: -screenWidth * 0.2,
            child: Container(
              width: screenWidth * 0.65,
              height: screenWidth * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -screenWidth * 0.25,
            left: -screenWidth * 0.15,
            child: Container(
              width: screenWidth * 0.75,
              height: screenWidth * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // Konten utama
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                // Padding horizontal: tablet pakai fixed, HP pakai proporsional
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet
                      ? (screenWidth - cardMaxWidth) / 2
                      : screenWidth * 0.06,
                  vertical: verticalPadding,
                ),
                child: Column(
                  children: [
                    // Header (logo + nama app)
                    _buildHeader(
                      logoSize: logoSize,
                      logoIconSize: logoIconSize,
                      logoRadius: logoRadius,
                      appNameSize: appNameSize,
                      subtitleSize: subtitleSize,
                      isSmallScreen: isSmallScreen,
                    ),

                    SizedBox(height: headerToCardGap),

                    // Card form login
                    SizedBox(
                      width: cardMaxWidth,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              cardPaddingH,
                              cardPaddingV,
                              cardPaddingH,
                              cardPaddingV - 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Judul form
                                Text(
                                  "Selamat datang",
                                  style: GoogleFonts.poppins(
                                    fontSize: headingSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A3A6B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Masuk untuk melanjutkan",
                                  style: GoogleFonts.poppins(
                                    fontSize: subtitleSize,
                                    color: Colors.grey.shade500,
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 18 : 24),

                                // Field username
                                _buildLabel("NIP / NISN / Username"),
                                const SizedBox(height: 6),
                                _buildTextField(
                                  controller: _identifierController,
                                  hint: "Masukkan username Anda",
                                  icon: Icons.person_outline_rounded,
                                  isSmallScreen: isSmallScreen,
                                ),

                                SizedBox(height: fieldGap),

                                // Field password
                                _buildLabel("Password"),
                                const SizedBox(height: 6),
                                _buildTextField(
                                  controller: _passwordController,
                                  hint: "Masukkan password Anda",
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  isSmallScreen: isSmallScreen,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),

                                // Lupa password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      _showForgotPasswordDialog(context);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 0,
                                      ),
                                    ),
                                    child: Text(
                                      "Lupa password?",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 2 : 4),

                                // Tombol masuk
                                SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: _isLoading
                                        ? const SizedBox.shrink()
                                        : const Icon(
                                            Icons.login_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                    label: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            "Masuk",
                                            style: GoogleFonts.poppins(
                                              fontSize: isSmallScreen
                                                  ? 14
                                                  : 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 16 : 24),

                                // Footer
                                const Divider(height: 1),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.business_rounded,
                                      size: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "TK Negeri 2 Bengkalis",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

  Widget _buildHeader({
    required double logoSize,
    required double logoIconSize,
    required double logoRadius,
    required double appNameSize,
    required double subtitleSize,
    required bool isSmallScreen,
  }) {
    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(logoRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: Icon(
            Icons.school_rounded,
            size: logoIconSize,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 10 : 14),
        Text(
          "SIMONA",
          style: GoogleFonts.poppins(
            fontSize: appNameSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 6),
        Text(
          "Sistem Informasi Monitoring\nPenilaian Perkembangan Anak",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: subtitleSize,
            color: Colors.white.withOpacity(0.7),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isSmallScreen,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.poppins(fontSize: isSmallScreen ? 13 : 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade400,
          fontSize: isSmallScreen ? 12 : 13,
        ),
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isSmallScreen ? 12 : 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: primaryColor, size: 28),
            const SizedBox(width: 10),
            Text(
              "Lupa Password",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryColor,
              ),
            ),
          ],
        ),
        content: Text(
          "Untuk melakukan reset password akun Anda (Guru / Orang Tua / Kepala Sekolah), silakan hubungi Operator Sekolah / Administrator SIMONA di Kantor Tata Usaha TK Negeri 2 Bengkalis agar password Anda dapat diatur ulang secara langsung.",
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.6,
            color: const Color(0xFF4B5563),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Tutup",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
