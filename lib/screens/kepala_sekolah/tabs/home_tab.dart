import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<dynamic> notifications;
  final Map<String, dynamic> currentUserData;

  const HomeTab({
    super.key,
    required this.stats,
    required this.notifications,
    required this.currentUserData,
  });

  @override
  Widget build(BuildContext context) {
    final schoolName = stats['nama_sekolah'] ?? 'TK Negeri 2 Bengkalis';
    final taActive = stats['tahun_ajaran_aktif'] ?? '-';
    final userName = currentUserData['name'] ?? 'Ibu Siti Rahmawati, S.Pd.';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeHeader(userName, schoolName, taActive),
          const SizedBox(height: 20),

          // Statistics Panel
          _buildStatsListPanel(),
          const SizedBox(height: 24),

          // Notifikasi Board
          _buildNotificationsSection(context),
          const SizedBox(height: 24),

          // Informative Disclaimer
          _buildInformativeDisclaimer(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(String userName, String schoolName, String taActive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF451A03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Selamat Datang,",
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "T.A. $taActive",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            userName,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.school_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  schoolName,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w400),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsListPanel() {
    final int anak = stats['jumlah_anak'] ?? 0;
    final int guru = stats['jumlah_guru'] ?? 0;
    final int ortu = stats['jumlah_ortu'] ?? 0;
    final int kelas = stats['jumlah_kelas'] ?? 0;
    final int rapor = stats['laporan_selesai'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Kondisi Sekolah",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.38,
          children: [
            _buildStatCard("👨‍🎓", "Jumlah Anak", anak.toString(), const Color(0xFF0284C7)),
            _buildStatCard("👩‍🏫", "Jumlah Guru", guru.toString(), const Color(0xFF0D9488)),
            _buildStatCard("👨‍👩‍👧", "Jumlah Orang Tua", ortu.toString(), const Color(0xFFD97706)),
            _buildStatCard("📚", "Jumlah Kelas", kelas.toString(), const Color(0xFF7C3AED)),
          ],
        ),
        const SizedBox(height: 16),
        _buildRaporBanner(rapor),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String title, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 16)),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildRaporBanner(int completedCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Rekapan Selesai",
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  "$completedCount Rekapan Anak Selesai",
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.6), size: 14),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "Papan Notifikasi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.8),
          notifications.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Tidak ada notifikasi baru.",
                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final String msg = notif['pesan'] ?? '';
                    final String level = notif['level'] ?? 'info';

                    Color cardBg, iconBg, iconColor, textColor, borderColor;
                    IconData iconData;

                    if (level == 'warning') {
                      cardBg = const Color(0xFFFEF2F2);
                      iconBg = const Color(0xFFFEE2E2);
                      iconColor = const Color(0xFFDC2626);
                      textColor = const Color(0xFF991B1B);
                      borderColor = const Color(0xFFFCA5A5).withValues(alpha: 0.4);
                      iconData = Icons.warning_amber_rounded;
                    } else if (level == 'success') {
                      cardBg = const Color(0xFFF0FDF4);
                      iconBg = const Color(0xFFDCFCE7);
                      iconColor = const Color(0xFF16A34A);
                      textColor = const Color(0xFF14532D);
                      borderColor = const Color(0xFF86EFAC).withValues(alpha: 0.4);
                      iconData = Icons.verified_rounded;
                    } else {
                      // info (e.g. Selesai menilai / Kalender)
                      cardBg = const Color(0xFFF0F9FF);
                      iconBg = const Color(0xFFE0F2FE);
                      iconColor = const Color(0xFF0284C7);
                      textColor = const Color(0xFF0C4A6E);
                      borderColor = const Color(0xFF7DD3FC).withValues(alpha: 0.4);
                      iconData = Icons.info_outline_rounded;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: iconBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              size: 16,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                msg,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildInformativeDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: const Color(0xFFD97706), size: 16),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Dashboard ini bersifat informatif, bukan untuk mengelola data.",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF78350F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
