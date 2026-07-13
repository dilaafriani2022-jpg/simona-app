import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatistikTab extends StatelessWidget {
  final Map<String, dynamic> aspekStats;
  final Map<String, dynamic> absensiStats;
  final int selectedSemester;
  final int selectedMonth;
  final int selectedKelasId;
  final List<dynamic> kelasList;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onSemesterChanged;
  final ValueChanged<int> onKelasChanged;

  const StatistikTab({
    super.key,
    required this.aspekStats,
    required this.absensiStats,
    required this.selectedSemester,
    required this.selectedMonth,
    required this.selectedKelasId,
    required this.kelasList,
    required this.onMonthChanged,
    required this.onSemesterChanged,
    required this.onKelasChanged,
  });

  // ── Palet ────────────────────────────────────────────────────────────────
  static const Color _navy    = Color(0xFF1A1F3C);
  static const Color _gold    = Color(0xFFD4A853);
  static const Color _cream   = Color(0xFFFBF8F3);
  static const Color _textDark = Color(0xFF1C1C2E);
  static const Color _border   = Color(0xFFEEEAE0);

  // Status Colors
  static const Color _colorM  = Color(0xFF10B981); // Green for Muncul
  static const Color _colorMM = Color(0xFFF59E0B); // Amber for Mulai Muncul
  static const Color _colorTM = Color(0xFFEF4444); // Red for Tidak Muncul

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 96;

    // Safely parse aspect ratings
    final Map<String, int> rAgama = _parseRatingCounts(aspekStats['agama']);
    final Map<String, int> rJati  = _parseRatingCounts(aspekStats['jati_diri']);
    final Map<String, int> rSteam = _parseRatingCounts(aspekStats['steam']);

    final int totalAgama = rAgama['M']! + rAgama['MM']! + rAgama['TM']!;
    final int totalJati  = rJati['M']! + rJati['MM']! + rJati['TM']!;
    final int totalSteam = rSteam['M']! + rSteam['MM']! + rSteam['TM']!;

    // Safely parse attendance
    final int hadir = int.tryParse(absensiStats['hadir']?.toString() ?? '0') ?? 0;
    final int sakit = int.tryParse(absensiStats['sakit']?.toString() ?? '0') ?? 0;
    final int izin  = int.tryParse(absensiStats['izin']?.toString() ?? '0') ?? 0;
    final int alpa  = int.tryParse(absensiStats['alpa']?.toString() ?? '0') ?? 0;
    final int totalAbsensi = hadir + sakit + izin + alpa;

    return Container(
      color: _cream,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildPageHeader(),

            // Filter Section (Semester & Bulan)
            _buildFilterSection(context),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Section 1: Aspek Perkembangan (TM, MM, M)
                  _buildSectionLabel('Penilaian Aspek Perkembangan', Icons.analytics_rounded, const Color(0xFF6366F1)),
                  const SizedBox(height: 12),
                  _buildAspekCard('Nilai Agama & Budi Pekerti', rAgama, totalAgama, Icons.volunteer_activism_rounded, const Color(0xFF10B981)),
                  const SizedBox(height: 16),
                  _buildAspekCard('Jati Diri', rJati, totalJati, Icons.self_improvement_rounded, const Color(0xFF3B82F6)),
                  const SizedBox(height: 16),
                  _buildAspekCard('Dasar Literasi & STEAM', rSteam, totalSteam, Icons.science_rounded, const Color(0xFFD97706)),

                  const SizedBox(height: 28),

                  // Section 2: Kehadiran
                  _buildSectionLabel('Statistik Kehadiran Anak', Icons.event_available_rounded, const Color(0xFF059669)),
                  const SizedBox(height: 12),
                  _buildKehadiranCard(hadir, sakit, izin, alpa, totalAbsensi),

                  SizedBox(height: bottomPadding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Parses counts safely
  Map<String, int> _parseRatingCounts(dynamic raw) {
    if (raw is Map) {
      return {
        'TM': int.tryParse(raw['TM']?.toString() ?? '0') ?? 0,
        'MM': int.tryParse(raw['MM']?.toString() ?? '0') ?? 0,
        'M': int.tryParse(raw['M']?.toString() ?? '0') ?? 0,
      };
    }
    // Fallback if legacy integer value is returned
    final val = int.tryParse(raw?.toString() ?? '0') ?? 0;
    return {'TM': 0, 'MM': 0, 'M': val};
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: _gold, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistik Perkembangan',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Monitoring rekap penilaian & kehadiran murid',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter Dropdowns (Semester, Bulan, & Kelas) ──────────────────────────
  Widget _buildFilterSection(BuildContext context) {
    final monthsMap = _getMonthsForSemester(selectedSemester);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Periode & Kelas Pemantauan',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Dropdown Semester
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedSemester,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      onChanged: (val) {
                        if (val != null) {
                          onSemesterChanged(val);
                          onMonthChanged(0); // Reset to all months
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Semester 1 (Ganjil)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        DropdownMenuItem(value: 2, child: Text('Semester 2 (Genap)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Dropdown Bulan
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedMonth,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      onChanged: (val) {
                        if (val != null) {
                          onMonthChanged(val);
                        }
                      },
                      items: monthsMap.entries.map((e) {
                        return DropdownMenuItem<int>(
                          value: e.key,
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Dropdown Filter Kelas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedKelasId,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down_rounded),
                onChanged: (val) {
                  if (val != null) {
                    onKelasChanged(val);
                  }
                },
                items: [
                  const DropdownMenuItem<int>(
                    value: 0,
                    child: Text('Semua Kelas (TK Keseluruhan)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  ...kelasList.map((k) {
                    final int id = int.tryParse(k['id']?.toString() ?? '') ?? 0;
                    final String name = k['nama_kelas']?.toString() ?? '-';
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text('Kelas $name', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
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
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _textDark,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── Aspek Card with Scale Breakdown (TM, MM, M) ───────────────────────────
  Widget _buildAspekCard(
    String title,
    Map<String, int> ratings,
    int total,
    IconData icon,
    Color accentColor,
  ) {
    final int countM  = ratings['M'] ?? 0;
    final int countMM = ratings['MM'] ?? 0;
    final int countTM = ratings['TM'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$total Penilaian',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scale 1: M (Muncul)
          _buildRatingProgressBar(
            label: 'Muncul (M)',
            count: countM,
            total: total,
            color: _colorM,
            desc: 'Anak menunjukkan kemampuan sesuai TP secara konsisten.',
          ),
          const SizedBox(height: 14),

          // Scale 2: MM (Mulai Muncul)
          _buildRatingProgressBar(
            label: 'Mulai Muncul (MM)',
            count: countMM,
            total: total,
            color: _colorMM,
            desc: 'Anak mulai memperlihatkan tanda perkembangan awal TP.',
          ),
          const SizedBox(height: 14),

          // Scale 3: TM (Tidak Muncul)
          _buildRatingProgressBar(
            label: 'Tidak Muncul (TM)',
            count: countTM,
            total: total,
            color: _colorTM,
            desc: 'Anak belum memperlihatkan perilaku sesuai TP.',
          ),
        ],
      ),
    );
  }

  // Single rating progress bar
  Widget _buildRatingProgressBar({
    required String label,
    required int count,
    required int total,
    required Color color,
    required String desc,
  }) {
    final double pct = total > 0 ? (count / total) : 0.0;
    final int pctInt = (pct * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
            Text(
              '$count kali  •  $pctInt%',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          textAlign: TextAlign.justify,
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            color: Colors.grey.shade500,
            height: 1.3,
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
                Expanded(
                  child: Text(
                    'Total Kehadiran Anak',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '$hadir',
                  style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark),
              ),
            ),
            Text(
              '$count Hari  •  $pctInt%',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: color),
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

  // ── Helper Month Map ─────────────────────────────────────────────────────
  Map<int, String> _getMonthsForSemester(int semester) {
    if (semester == 1) {
      return {
        0: 'Semua Bulan (Semester Ganjil)',
        7: 'Juli',
        8: 'Agustus',
        9: 'September',
        10: 'Oktober',
        11: 'November',
        12: 'Desember',
      };
    } else {
      return {
        0: 'Semua Bulan (Semester Genap)',
        1: 'Januari',
        2: 'Februari',
        3: 'Maret',
        4: 'April',
        5: 'Mei',
        6: 'Juni',
      };
    }
  }
}

// Helper Extension to fix whitee70 compile check
extension _ColorUtils on BuildContext {
  Color whitee70() => Colors.white.withValues(alpha: 0.7);
}
