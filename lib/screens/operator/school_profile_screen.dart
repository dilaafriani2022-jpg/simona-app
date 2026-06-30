import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import 'edit_school_profile_screen.dart';

class SchoolProfileScreen extends StatefulWidget {
  final String userRole;
  const SchoolProfileScreen({super.key, required this.userRole});

  @override
  State<SchoolProfileScreen> createState() => _SchoolProfileScreenState();
}

class _SchoolProfileScreenState extends State<SchoolProfileScreen> {
  static const Color primaryColor = Color(0xFFC17B2F);
  static const Color primaryDark  = Color(0xFFA0601A);
  static const Color scaffoldBg   = Color(0xFFFDF8F3);
  static const Color cardBorder   = Color(0xFFF0E8DF);

  bool _isLoading = true;
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getSchoolProfile();
    setState(() {
      if (result['status'] == 'success') {
        _profile = Map<String, dynamic>.from(result['data']);
      }
      _isLoading = false;
    });
  }

  // Helper aman membaca nilai dari _profile
  String _val(String key, [String fallback = '-']) =>
      (_profile[key] ?? fallback).toString();

  @override
  Widget build(BuildContext context) {
    final size    = MediaQuery.of(context).size;
    final isSmall = size.height < 680;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : CustomScrollView(
              slivers: [
                // ── SliverAppBar ──────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: isSmall ? 200 : 240,
                  pinned: true,
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    "Profil Sekolah",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  // Tombol Edit hanya untuk operator
                  actions: [
                    if (widget.userRole == 'operator')
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: "Edit Profil Sekolah",
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditSchoolProfileScreen(
                                profileData: _profile,
                              ),
                            ),
                          );
                          if (updated == true) _loadProfile();
                        },
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeroSection(isSmall: isSmall),
                  ),
                ),

                // ── Konten ────────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isSmall ? 14 : 18),
                    child: Column(
                      children: [
                        // Badge status
                        _buildBadgeRow(isSmall: isSmall),
                        SizedBox(height: isSmall ? 16 : 20),

                        // Identitas
                        _buildSection(
                          title: "Identitas Sekolah",
                          icon: Icons.account_balance_rounded,
                          isSmall: isSmall,
                          children: [
                            _infoRow("NPSN",          _val('npsn'),         Icons.badge_rounded),
                            _infoRow("Bentuk",        _val('jenjang'),       Icons.school_rounded),
                            _infoRow("Status",        _val('status'),        Icons.verified_rounded),
                            _infoRow("Akreditasi",    _val('akreditasi'),    Icons.star_rounded),
                            _infoRow("Tahun Berdiri", _val('tahun_berdiri'), Icons.history_edu_rounded),
                          ],
                        ),
                        SizedBox(height: isSmall ? 14 : 18),

                        // Kontak
                        _buildSection(
                          title: "Kontak",
                          icon: Icons.contact_phone_rounded,
                          isSmall: isSmall,
                          children: [
                            _infoRow("Email",   _val('email'),   Icons.email_rounded),
                            _infoRow("Telepon", _val('no_telp'), Icons.phone_rounded),
                            _infoRow("Website", _val('website'), Icons.language_rounded),
                          ],
                        ),
                        SizedBox(height: isSmall ? 14 : 18),

                        // Alamat
                        _buildSection(
                          title: "Alamat",
                          icon: Icons.location_on_rounded,
                          isSmall: isSmall,
                          children: [
                            _infoRow("Jalan",     _val('alamat'),    Icons.signpost_rounded),
                            _infoRow("Kelurahan", _val('kelurahan'), Icons.map_rounded),
                            _infoRow("Kecamatan", _val('kecamatan'), Icons.map_rounded),
                            _infoRow("Kabupaten", _val('kabupaten'), Icons.location_city_rounded),
                            _infoRow("Provinsi",  _val('provinsi'),  Icons.flag_rounded),
                            _infoRow("Kode Pos",  _val('kode_pos'),  Icons.local_post_office_rounded),
                          ],
                        ),
                        SizedBox(height: isSmall ? 14 : 18),

                        // SDM
                        _buildSection(
                          title: "Sumber Daya Manusia",
                          icon: Icons.people_rounded,
                          isSmall: isSmall,
                          children: [
                            _infoRow("Kepala Sekolah",   _val('kepala_sekolah'), Icons.person_rounded),
                            _infoRow("NIP Kepala Sekolah", _val('nip_kepala_sekolah'), Icons.badge_rounded),
                            _infoRow("Operator Sekolah", _val('operator_nama'),  Icons.manage_accounts_rounded),
                          ],
                        ),
                        SizedBox(height: isSmall ? 14 : 18),

                        // Statistik
                        _buildStatsRow(isSmall: isSmall),
                        SizedBox(height: isSmall ? 14 : 18),

                        // Grafik Statistik
                        _buildStatisticsChart(isSmall: isSmall),
                        SizedBox(height: isSmall ? 14 : 18),

                        // Visi Misi
                        _buildVisiMisi(isSmall: isSmall),
                        SizedBox(height: isSmall ? 20 : 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HERO SECTION dengan watermark
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection({required bool isSmall}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4891A), Color(0xFFC17B2F), Color(0xFF8B5E1A)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Watermark besar
          Positioned(
            right: -30,
            bottom: -30,
            child: Opacity(
              opacity: 0.08,
              child: Icon(Icons.school_rounded, size: 180, color: Colors.white),
            ),
          ),
          // Watermark kecil
          Positioned(
            left: -20,
            top: -20,
            child: Opacity(
              opacity: 0.05,
              child: Icon(Icons.school_rounded, size: 120, color: Colors.white),
            ),
          ),

          // Konten hero
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Logo lingkaran
                Container(
                  width: isSmall ? 72 : 86,
                  height: isSmall ? 72 : 86,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.45),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: isSmall ? 36 : 44,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _val('nama_sekolah', 'TK Negeri 2 Bengkalis'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isSmall ? 15 : 17,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _val('alamat', 'Bengkalis, Riau'),
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: isSmall ? 10 : 11,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmall ? 14 : 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BADGE ROW
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildBadgeRow({required bool isSmall}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _badge(
          "Sekolah ${_val('status', 'Negeri')}",
          Icons.verified_rounded,
          const Color(0xFF1565C0),
          const Color(0xFFE3F2FD),
        ),
        _badge(
          "Akreditasi ${_val('akreditasi', 'A')}",
          Icons.star_rounded,
          const Color(0xFFE65100),
          const Color(0xFFFFF3E0),
        ),
        _badge(
          "Aktif",
          Icons.check_circle_rounded,
          const Color(0xFF2E7D32),
          const Color(0xFFE8F5E9),
        ),
      ],
    );
  }

  Widget _badge(
    String label,
    IconData icon,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION CARD
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildSection({
    required String title,
    required IconData icon,
    required bool isSmall,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 14 : 18,
              vertical: isSmall ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: cardBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 14 : 18,
              vertical: 4,
            ),
            child: Column(children: children),
          ),
          SizedBox(height: isSmall ? 8 : 10),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // INFO ROW
  // ════════════════════════════════════════════════════════════════════════════
  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: primaryColor.withOpacity(0.7)),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STATISTIK RINGKAS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildStatsRow({required bool isSmall}) {
    final jumlahAnak = _profile['jumlah_anak'] ?? 0;
    final jumlahGuru = _profile['jumlah_guru'] ?? 0;
    final jumlahOrtu = _profile['jumlah_ortu'] ?? 0;

    final stats = [
      _QuickStat(
        jumlahAnak.toString(),
        "Murid",
        Icons.child_care_rounded,
        const Color(0xFFE67E22),
        const Color(0xFFFFF3E0),
      ),
      _QuickStat(
        jumlahGuru.toString(),
        "Guru",
        Icons.school_rounded,
        const Color(0xFF27AE60),
        const Color(0xFFE8F5E9),
      ),
      _QuickStat(
        jumlahOrtu.toString(),
        "Ortu",
        Icons.family_restroom_rounded,
        const Color(0xFF8E44AD),
        const Color(0xFFEDE7F6),
      ),
      _QuickStat(
        _val('tahun_berdiri', '1969'),
        "Berdiri",
        Icons.history_edu_rounded,
        const Color(0xFF2980B9),
        const Color(0xFFE3F2FD),
      ),
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < stats.length - 1 ? 10 : 0),
            padding: EdgeInsets.symmetric(
              vertical: isSmall ? 12 : 16,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: s.bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: s.color.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Icon(s.icon, color: s.color, size: isSmall ? 20 : 24),
                SizedBox(height: isSmall ? 6 : 8),
                Text(
                  s.value,
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 13 : 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF374151),
                  ),
                ),
                Text(
                  s.label,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // VISI MISI
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildVisiMisi({required bool isSmall}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4891A), Color(0xFFA0601A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Watermark
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.07,
                child: Icon(Icons.school_rounded, size: 130, color: Colors.white),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isSmall ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visi
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_rounded, color: Color(0xFFFFE0A3), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Visi",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFFE0A3),
                          fontSize: isSmall ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _val('visi', 'Mewujudkan generasi penerus bangsa yang cerdas, berkarakter, beriman, dan berwawasan luas sejak usia dini.'),
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isSmall ? 11 : 12,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: isSmall ? 14 : 18),
                  Divider(color: Colors.white.withOpacity(0.2)),
                  SizedBox(height: isSmall ? 10 : 14),

                  // Misi
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: Color(0xFFFFE0A3), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Misi",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFFE0A3),
                          fontSize: isSmall ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _val('misi', 'Memberikan pelayanan pendidikan yang berkualitas dan menyenangkan bagi seluruh peserta didik.'),
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: isSmall ? 11 : 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CHART STATISTIK
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildStatisticsChart({required bool isSmall}) {
    final jumlahAnak = (_profile['jumlah_anak'] ?? 0).toDouble();
    final jumlahGuru = (_profile['jumlah_guru'] ?? 0).toDouble();
    final jumlahOrtu = (_profile['jumlah_ortu'] ?? 0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 14 : 18,
              vertical: isSmall ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: cardBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.bar_chart_rounded, color: primaryColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  "Grafik Jumlah Data",
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          // Chart
          Padding(
            padding: EdgeInsets.all(isSmall ? 16 : 20),
            child: SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValue([jumlahAnak, jumlahGuru, jumlahOrtu]) * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['Murid', 'Guru', 'Ortu'];
                          if (value.toInt() >= 0 && value.toInt() < titles.length) {
                            return Text(
                              titles[value.toInt()],
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: jumlahAnak,
                          color: const Color(0xFFE67E22),
                          width: 40,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: jumlahGuru,
                          color: const Color(0xFF27AE60),
                          width: 40,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: jumlahOrtu,
                          color: const Color(0xFF8E44AD),
                          width: 40,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
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

  double _getMaxValue(List<double> values) {
    return values.isEmpty ? 10 : values.reduce((a, b) => a > b ? a : b);
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────
class _QuickStat {
  final String value, label;
  final IconData icon;
  final Color color, bgColor;
  const _QuickStat(this.value, this.label, this.icon, this.color, this.bgColor);
}
