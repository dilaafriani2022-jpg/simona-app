import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<dynamic> notifications;
  final Map<String, dynamic> currentUserData;
  final VoidCallback? onTapRekap;

  const HomeTab({
    super.key,
    required this.stats,
    required this.notifications,
    required this.currentUserData,
    this.onTapRekap,
  });

  // ── Palet Warna Hangat & Elegan ─────────────────────────────────────────
  static const Color _navy       = Color(0xFF1A1F3C);
  static const Color _navyMid    = Color(0xFF2D3561);
  static const Color _gold       = Color(0xFFD4A853);
  static const Color _goldLight  = Color(0xFFF5C842);
  static const Color _cream      = Color(0xFFFBF8F3);
  static const Color _textDark   = Color(0xFF1C1C2E);
  static const Color _textMid    = Color(0xFF4A4A6A);
  static const Color _textSub    = Color(0xFF8A8AAA);
  static const Color _cardBg     = Color(0xFFFFFFFF);
  static const Color _border     = Color(0xFFEEEAE0);

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 96;
    final schoolName = stats['nama_sekolah'] ?? 'TK Negeri 2 Bengkalis';
    final taActive   = stats['tahun_ajaran_aktif'] ?? '-';
    final userName   = currentUserData['name'] ?? 'Kepala Sekolah';
    final int anak   = int.tryParse(stats['jumlah_anak']?.toString() ?? '') ?? 0;
    final int guru   = int.tryParse(stats['jumlah_guru']?.toString() ?? '') ?? 0;
    final int ortu   = int.tryParse(stats['jumlah_ortu']?.toString() ?? '') ?? 0;
    final int kelas  = int.tryParse(stats['jumlah_kelas']?.toString() ?? '') ?? 0;
    final int rapor  = int.tryParse(stats['laporan_selesai']?.toString() ?? '') ?? 0;

    return Container(
      color: _cream,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Header ──────────────────────────────────────────────
            _buildHeroHeader(userName, schoolName, taActive),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── Stat Summary Row ──────────────────────────────────
                  _buildSectionLabel('Ringkasan Sekolah', Icons.domain_rounded),
                  const SizedBox(height: 14),
                  _buildStatRow(anak, guru, ortu, kelas),

                  const SizedBox(height: 28),

                  // ── Rekap Banner ──────────────────────────────────────
                  _buildRaporBanner(rapor, anak, onTapRekap),

                  const SizedBox(height: 28),

                  // ── Notifikasi ────────────────────────────────────────
                  _buildSectionLabel('Papan Notifikasi', Icons.notifications_active_rounded),
                  const SizedBox(height: 14),
                  _buildNotificationsBoard(),

                  const SizedBox(height: 20),

                  // ── Disclaimer ────────────────────────────────────────
                  _buildDisclaimer(),
                  SizedBox(height: bottomPadding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Header ──────────────────────────────────────────────────────────
  Widget _buildHeroHeader(String userName, String schoolName, String taActive) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_navy, _navyMid, Color(0xFF3D2C6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _goldLight.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: greeting + TA badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: _gold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Selamat Datang',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      // Avatar
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_gold, _goldLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded, color: _navy, size: 24),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // School + TA info row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school_rounded, color: _gold, size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            schoolName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _gold.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'T.A. $taActive',
                            style: const TextStyle(
                              color: _goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Label ────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: _navy),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _textDark,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── Stat Row (4 cards horizontal) ────────────────────────────────────────
  Widget _buildStatRow(int anak, int guru, int ortu, int kelas) {
    return Row(
      children: [
        _statCard('Anak', anak.toString(), Icons.child_care_rounded,
            const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
        const SizedBox(width: 10),
        _statCard('Guru', guru.toString(), Icons.co_present_rounded,
            const Color(0xFF10B981), const Color(0xFFECFDF5)),
        const SizedBox(width: 10),
        _statCard('Wali', ortu.toString(), Icons.people_alt_rounded,
            const Color(0xFFD97706), const Color(0xFFFFFBEB)),
        const SizedBox(width: 10),
        _statCard('Kelas', kelas.toString(), Icons.class_rounded,
            const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _textSub,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rekap Banner ─────────────────────────────────────────────────────────
  Widget _buildRaporBanner(int completedCount, int totalCount, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF34D399)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Penilaian Hari Ini',
                    style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$completedCount dari $totalCount Anak Dinilai Hari Ini',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Ketuk untuk lihat progres detail →',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notifikasi Board ─────────────────────────────────────────────────────
  Widget _buildNotificationsBoard() {
    if (notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Icon(Icons.notifications_none_rounded, size: 40, color: _textSub.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            const Text(
              'Tidak ada notifikasi baru',
              style: TextStyle(color: _textSub, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: notifications.asMap().entries.map((entry) {
        final notif = entry.value;
        final String msg   = notif['pesan'] ?? '';
        final String level = notif['level'] ?? 'info';
        final bool isLast  = entry.key == notifications.length - 1;

        Color accent, bgColor, borderColor;
        IconData iconData;

        switch (level) {
          case 'warning':
            accent      = const Color(0xFFDC2626);
            bgColor     = const Color(0xFFFFF5F5);
            borderColor = const Color(0xFFFCA5A5).withValues(alpha: 0.5);
            iconData    = Icons.warning_amber_rounded;
            break;
          case 'success':
            accent      = const Color(0xFF059669);
            bgColor     = const Color(0xFFF0FDF9);
            borderColor = const Color(0xFF6EE7B7).withValues(alpha: 0.5);
            iconData    = Icons.check_circle_rounded;
            break;
          default:
            accent      = const Color(0xFF3B82F6);
            bgColor     = const Color(0xFFF0F7FF);
            borderColor = const Color(0xFF93C5FD).withValues(alpha: 0.5);
            iconData    = Icons.info_rounded;
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, size: 15, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      msg,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: accent.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast) const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }

  // ── Disclaimer ───────────────────────────────────────────────────────────
  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _gold.withValues(alpha: 0.85), size: 15),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Dashboard ini bersifat informatif, bukan untuk mengelola data.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}
