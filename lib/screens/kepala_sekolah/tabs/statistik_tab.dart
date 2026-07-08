import 'package:flutter/material.dart';

class StatistikTab extends StatelessWidget {
  final Map<String, dynamic> aspekStats;
  final Map<String, dynamic> absensiStats;

  const StatistikTab({
    super.key,
    required this.aspekStats,
    required this.absensiStats,
  });

  // ── Palet ────────────────────────────────────────────────────────────────
  static const Color _navy    = Color(0xFF1A1F3C);
  static const Color _gold    = Color(0xFFD4A853);
  static const Color _cream   = Color(0xFFFBF8F3);
  static const Color _textDark = Color(0xFF1C1C2E);
  static const Color _textSub  = Color(0xFF8A8AAA);
  static const Color _border   = Color(0xFFEEEAE0);

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 96;
    final int agama = int.tryParse(aspekStats['agama']?.toString() ?? '') ?? 0;
    final int jati  = int.tryParse(aspekStats['jati_diri']?.toString() ?? '') ?? 0;
    final int steam = int.tryParse(aspekStats['steam']?.toString() ?? '') ?? 0;
    final int avg   = ((agama + jati + steam) / 3).round();

    final int hadir  = int.tryParse(absensiStats['hadir']?.toString() ?? '') ?? 0;
    final int sakit  = int.tryParse(absensiStats['sakit']?.toString() ?? '') ?? 0;
    final int izin   = int.tryParse(absensiStats['izin']?.toString() ?? '') ?? 0;
    final int alpa   = int.tryParse(absensiStats['alpa']?.toString() ?? '') ?? 0;
    final int total  = hadir + sakit + izin + alpa;

    return Container(
      color: _cream,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Header ───────────────────────────────────────────────
            _buildPageHeader(),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Aspek Perkembangan ────────────────────────────────
                  _buildSectionLabel('Perkembangan Aspek Anak',
                      Icons.trending_up_rounded, const Color(0xFF6366F1)),
                  const SizedBox(height: 14),
                  _buildAspekCard(agama, jati, steam, avg),

                  const SizedBox(height: 28),

                  // ── Kehadiran ─────────────────────────────────────────
                  _buildSectionLabel('Statistik Kehadiran Anak',
                      Icons.event_available_rounded, const Color(0xFF059669)),
                  const SizedBox(height: 14),
                  _buildKehadiranCard(hadir, sakit, izin, alpa, total),

                  SizedBox(height: bottomPadding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page Header (gradient) ────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_navy, Color(0xFF2D3561)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: _gold, size: 22),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistik Sekolah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ringkasan data perkembangan & kehadiran',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 15, color: color),
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

  // ── Aspek Card ────────────────────────────────────────────────────────────
  Widget _buildAspekCard(int agama, int jati, int steam, int avg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Rata-rata banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Rata-rata Perkembangan Anak',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '$avg',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _aspectBar('Nilai Agama & Budi Pekerti', agama,
              const Color(0xFF10B981), Icons.volunteer_activism_rounded),
          const SizedBox(height: 16),
          _aspectBar('Jati Diri', jati,
              const Color(0xFF3B82F6), Icons.self_improvement_rounded),
          const SizedBox(height: 16),
          _aspectBar('Dasar Literasi & STEAM', steam,
              const Color(0xFFD97706), Icons.science_rounded),
        ],
      ),
    );
  }

  Widget _aspectBar(String title, int score, Color color, IconData icon) {
    final double val = (score / 100).clamp(0.04, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: val,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ── Kehadiran Card ────────────────────────────────────────────────────────
  Widget _buildKehadiranCard(int hadir, int sakit, int izin, int alpa, int total) {
    final pctHadir = total > 0 ? (hadir / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Hadir banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Total Kehadiran Anak',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '$hadir',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$pctHadir%',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Summary row
          Row(
            children: [
              _kehadiranPill('Hadir', hadir, const Color(0xFF059669)),
              const SizedBox(width: 8),
              _kehadiranPill('Sakit', sakit, const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _kehadiranPill('Izin', izin, const Color(0xFFD97706)),
              const SizedBox(width: 8),
              _kehadiranPill('Alpa', alpa, const Color(0xFFDC2626)),
            ],
          ),
          const SizedBox(height: 20),
          _absensiBar('Hadir',  hadir,  total, const Color(0xFF059669), Icons.check_circle_rounded),
          const SizedBox(height: 14),
          _absensiBar('Sakit',  sakit,  total, const Color(0xFF3B82F6), Icons.medical_services_rounded),
          const SizedBox(height: 14),
          _absensiBar('Izin',   izin,   total, const Color(0xFFD97706), Icons.event_note_rounded),
          const SizedBox(height: 14),
          _absensiBar('Alpa',   alpa,   total, const Color(0xFFDC2626), Icons.cancel_rounded),
        ],
      ),
    );
  }

  Widget _kehadiranPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _absensiBar(String label, int count, int total, Color color, IconData icon) {
    final double pct = total > 0 ? (count / total) : 0.0;
    final int pctInt = (pct * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark),
              ),
            ),
            Text(
              '$count Hari  •  $pctInt%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
