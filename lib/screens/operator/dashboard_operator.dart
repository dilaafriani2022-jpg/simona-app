import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';

import 'manage_users_screen.dart';
import 'manage_anak_screen.dart';
import 'manage_ortu_screen.dart';
import 'manage_guru_screen.dart';
import 'manage_aspek_screen.dart';
import 'manage_kelas_screen.dart';
import 'manage_tahun_ajaran_screen.dart';
import 'school_profile_screen.dart';
import 'activity_log_screen.dart';
import 'notification_panel_screen.dart';
import 'setting_operator_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class DashboardOperator extends StatefulWidget {
  const DashboardOperator({super.key});

  @override
  State<DashboardOperator> createState() => _DashboardOperatorState();
}

class _DashboardOperatorState extends State<DashboardOperator>
    with SingleTickerProviderStateMixin, RouteAware {

  // ── Warna utama ──────────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFFC17B2F);
  static const Color primaryDark  = Color(0xFFA0601A);
  static const Color scaffoldBg   = Color(0xFFFDF8F3);
  static const Color cardBorder   = Color(0xFFF0E8DF);

  // ── Info sekolah ─────────────────────────────────────────────────────────
  static const String schoolName    = "TK Negeri 2 Bengkalis";
  static const String schoolAddress = "Jl. Pendidikan No. 1, Bengkalis, Riau";


  bool _isLoading         = true;
  bool _isActivityLoading = true;   // ← loading khusus activity feed
  int  _currentIndex      = 0;
  int  _notifCount        = 0;      // ← jumlah notifikasi aktif

  late final AnimationController _pulseController;
  late final Animation<double>   _pulseAnimation;

  Map<String, dynamic> _stats = {
    "jumlah_anak"     : 0,
    "jumlah_guru"     : 0,
    "jumlah_ortu"     : 0,
    "aspek_penilaian" : 0,
    "laporan_semester": 0,
    "trend_anak"  : {"label": "Memuat...", "positive": null},
    "trend_guru"  : {"label": "Memuat...", "positive": null},
    "trend_ortu"  : {"label": "Memuat...", "positive": null},
    "trend_aspek" : {"label": "Memuat...", "positive": null},
  };

  // ── Aktivitas terbaru — diisi dari API ───────────────────────────────────
  List<Map<String, dynamic>> _activities = [];

  // ════════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchActivities();
    _fetchNotifCount();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.07, end: 0.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Refresh stats & aktivitas saat kembali dari screen lain
    _fetchStats();
    _fetchActivities();
    _fetchNotifCount();
  }

  @override
  void didPush() {}

  // ════════════════════════════════════════════════════════════════════════════
  // FETCH STATS
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _fetchStats() async {
    if (_stats['jumlah_anak'] == 0) {
      setState(() => _isLoading = true);
    }

    final result = await ApiService.getDashboardStats();

    if (!mounted) return;

    setState(() {
      if (result['status'] == 'success') {
        _stats = result['data'];
      } else {
        _stats = {
          "jumlah_anak"     : 0,
          "jumlah_guru"     : 0,
          "jumlah_ortu"     : 0,
          "aspek_penilaian" : 0,
          "laporan_semester": 0,
          "trend_anak"  : {"label": "Tidak tersedia",  "positive": null},
          "trend_guru"  : {"label": "Tidak tersedia",  "positive": null},
          "trend_ortu"  : {"label": "Tidak tersedia",  "positive": null},
          "trend_aspek" : {"label": "Tidak tersedia",  "positive": null},
        };
      }
      _isLoading = false;
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FETCH ACTIVITIES — dari ApiService.getRecentActivities()
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _fetchActivities() async {
    setState(() => _isActivityLoading = true);

    final result = await ApiService.getRecentActivities(limit: 10);

    if (!mounted) return;

    setState(() {
      if (result['status'] == 'success') {
        final raw = result['data'];
        if (raw is List) {
          _activities = raw.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
      _isActivityLoading = false;
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FETCH NOTIFICATION COUNT — jumlah peringatan integritas data
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _fetchNotifCount() async {
    final result = await ApiService.fetch('get_notifications.php');
    if (!mounted) return;
    setState(() {
      if (result['status'] == 'success') {
        final count = result['total_alerts'];
        _notifCount = (count is int) ? count : int.tryParse(count.toString()) ?? 0;
      }
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER: Konversi field 'jenis' & 'aksi' dari API → warna, ikon, badge
  // ════════════════════════════════════════════════════════════════════════════

  /// Warna dot & badge berdasarkan jenis data
  Color _dotColorForJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'anak'  : return const Color(0xFF27AE60);
      case 'guru'  : return const Color(0xFF2980B9);
      case 'ortu'  : return const Color(0xFF8E44AD);
      case 'aspek' : return const Color(0xFFE74C3C);
      case 'kelas' : return const Color(0xFF00838F);
      case 'tahun' : return const Color(0xFF2ECC71);
      case 'user'  : return const Color(0xFFF39C12);
      case 'nilai' : return const Color(0xFFEC4899);
      default      : return primaryColor;
    }
  }

  /// Warna background badge
  Color _badgeBgForJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'anak'  : return const Color(0xFFE8F5E9);
      case 'guru'  : return const Color(0xFFE3F2FD);
      case 'ortu'  : return const Color(0xFFEDE7F6);
      case 'aspek' : return const Color(0xFFFDE8E8);
      case 'kelas' : return const Color(0xFFE0F7FA);
      case 'tahun' : return const Color(0xFFE8F5E9);
      case 'user'  : return const Color(0xFFFFF8E1);
      case 'nilai' : return const Color(0xFFFCE4EC);
      default      : return const Color(0xFFFFF3E0);
    }
  }

  /// Warna teks badge
  Color _badgeTextForJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'anak'  : return const Color(0xFF1B5E20);
      case 'guru'  : return const Color(0xFF0D47A1);
      case 'ortu'  : return const Color(0xFF4A148C);
      case 'aspek' : return const Color(0xFFB71C1C);
      case 'kelas' : return const Color(0xFF006064);
      case 'tahun' : return const Color(0xFF1B5E20);
      case 'user'  : return const Color(0xFFE65100);
      case 'nilai' : return const Color(0xFF880E4F);
      default      : return const Color(0xFF633806);
    }
  }

  /// Ikon aksi
  IconData _iconForAksi(String aksi) {
    switch (aksi.toLowerCase()) {
      case 'tambah': return Icons.add_circle_outline_rounded;
      case 'edit'  : return Icons.edit_outlined;
      case 'hapus' : return Icons.delete_outline_rounded;
      case 'login' : return Icons.login_rounded;
      case 'logout': return Icons.logout_rounded;
      case 'sync'  : return Icons.sync_rounded;
      default      : return Icons.info_outline_rounded;
    }
  }

  /// Label badge berdasarkan aksi
  String _badgeLabelForAksi(String aksi) {
    switch (aksi.toLowerCase()) {
      case 'tambah': return 'Baru';
      case 'edit'  : return 'Edit';
      case 'hapus' : return 'Hapus';
      case 'login' : return 'Login';
      case 'logout': return 'Logout';
      case 'sync'  : return 'Sync';
      default      : return 'Info';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // NAVIGATOR PUSH
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _pushScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    _fetchStats();
    _fetchActivities();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final size     = MediaQuery.of(context).size;
    final sw       = size.width;
    final isSmall  = size.height < 680;
    final isTablet = sw >= 600;
    final hPad     = sw * 0.045;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          "SiMONA",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: isSmall ? 16 : 18,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => _pushScreen(const NotificationPanelScreen()),
              ),
              if (_notifCount > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B35),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$_notifCount',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(isSmall: isSmall),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          await Future.wait([_fetchStats(), _fetchActivities()]);
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryColor))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(isSmall: isSmall, sw: sw),
                    const SizedBox(height: 22),
                    _sectionLabel("Ringkasan Data", hPad: hPad, isSmall: isSmall),
                    SizedBox(height: isSmall ? 10 : 14),
                    _buildStatsGrid(hPad: hPad, isSmall: isSmall, isTablet: isTablet),
                    SizedBox(height: isSmall ? 20 : 26),
                    _sectionLabel("Menu Cepat", hPad: hPad, isSmall: isSmall),
                    SizedBox(height: isSmall ? 10 : 14),
                    _buildQuickMenu(hPad: hPad, isSmall: isSmall),
                    SizedBox(height: isSmall ? 20 : 26),
                    _sectionLabel("Aktivitas Terbaru", hPad: hPad, isSmall: isSmall),
                    SizedBox(height: isSmall ? 10 : 14),
                    _buildActivityFeed(hPad: hPad, isSmall: isSmall, isTablet: isTablet),
                    SizedBox(height: isSmall ? 16 : 24),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNav(isSmall: isSmall),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ACTIVITY FEED — dinamis dari API, responsif
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildActivityFeed({
    required double hPad,
    required bool   isSmall,
    required bool   isTablet,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Container(
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
        child: _isActivityLoading
            ? _buildActivitySkeleton(isSmall: isSmall)
            : _activities.isEmpty
                ? _buildActivityEmpty(isSmall: isSmall)
                : Column(
                    children: [
                      // ── Header dalam card ──────────────────────────────
                      _buildActivityHeader(isSmall: isSmall),
                      const Divider(height: 1, color: Color(0xFFF9F4EF)),

                      // ── Daftar aktivitas ───────────────────────────────
                      ...List.generate(_activities.length, (i) {
                        final isLast = i == _activities.length - 1;
                        return _buildActivityRow(
                          item   : _activities[i],
                          isLast : isLast,
                          isSmall: isSmall,
                          index  : i,
                        );
                      }),

                      // ── Tombol lihat semua (jika >= 5 item) ───────────
                      if (_activities.length >= 5) _buildActivityFooter(isSmall: isSmall),
                    ],
                  ),
      ),
    );
  }

  // ── Header dalam card aktivitas ───────────────────────────────────────────
  Widget _buildActivityHeader({required bool isSmall}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 14 : 18,
        vertical  : isSmall ? 12 : 14,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.history_rounded, color: primaryColor, size: isSmall ? 16 : 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Aktivitas Terbaru",
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF374151),
                  ),
                ),
                Text(
                  "${_activities.length} aktivitas tercatat",
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 9 : 10,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          // Tombol refresh kecil
          GestureDetector(
            onTap: _fetchActivities,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.refresh_rounded, color: primaryColor, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ── Satu baris aktivitas ──────────────────────────────────────────────────
  Widget _buildActivityRow({
    required Map<String, dynamic> item,
    required bool  isLast,
    required bool  isSmall,
    required int   index,
  }) {
    final jenis       = (item['jenis'] ?? 'info').toString();
    final aksi        = (item['aksi']  ?? 'info').toString();
    final judul       = (item['judul'] ?? '-').toString();
    final deskripsi   = (item['deskripsi'] ?? '').toString();
    final waktuLabel  = (item['waktu_label'] ?? '').toString();

    final dotColor    = _dotColorForJenis(jenis);
    final badgeBg     = _badgeBgForJenis(jenis);
    final badgeText   = _badgeTextForJenis(jenis);
    final badgeLabel  = _badgeLabelForAksi(aksi);
    final aksiIcon    = _iconForAksi(aksi);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 14 : 18,
        vertical  : isSmall ? 11 : 14,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF9F4EF))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Kolom kiri: garis timeline + dot ───────────────────────────
          SizedBox(
            width: isSmall ? 20 : 24,
            child: Column(
              children: [
                // Dot berwarna
                Container(
                  width: isSmall ? 10 : 12,
                  height: isSmall ? 10 : 12,
                  margin: EdgeInsets.only(top: isSmall ? 3 : 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                // Garis vertikal (kecuali baris terakhir)
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: isSmall ? 28 : 36,
                    margin: const EdgeInsets.only(top: 4),
                    color: const Color(0xFFF0E8DF),
                  ),
              ],
            ),
          ),

          SizedBox(width: isSmall ? 10 : 12),

          // ── Ikon aksi ─────────────────────────────────────────────────
          Container(
            width: isSmall ? 30 : 36,
            height: isSmall ? 30 : 36,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(aksiIcon, color: dotColor, size: isSmall ? 15 : 18),
          ),

          SizedBox(width: isSmall ? 10 : 12),

          // ── Konten teks ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (deskripsi.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    deskripsi,
                    style: GoogleFonts.poppins(
                      fontSize: isSmall ? 9 : 10,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (waktuLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 10, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                        waktuLabel,
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 9 : 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: isSmall ? 8 : 10),

          // ── Badge aksi ────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 8 : 10,
              vertical  : isSmall ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dotColor.withOpacity(0.2)),
            ),
            child: Text(
              badgeLabel,
              style: GoogleFonts.poppins(
                fontSize: isSmall ? 9 : 10,
                fontWeight: FontWeight.w700,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer "Lihat Semua" ──────────────────────────────────────────────────
  Widget _buildActivityFooter({required bool isSmall}) {
    return InkWell(
      onTap: () => _pushScreen(const ActivityLogScreen()),
      borderRadius: const BorderRadius.only(
        bottomLeft : Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: isSmall ? 12 : 14),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.04),
          border: const Border(top: BorderSide(color: Color(0xFFF9F4EF))),
          borderRadius: const BorderRadius.only(
            bottomLeft : Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Lihat semua aktivitas",
              style: GoogleFonts.poppins(
                fontSize: isSmall ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, size: 14, color: primaryColor),
          ],
        ),
      ),
    );
  }

  // ── Skeleton loading aktivitas ─────────────────────────────────────────────
  Widget _buildActivitySkeleton({required bool isSmall}) {
    return Padding(
      padding: EdgeInsets.all(isSmall ? 14 : 18),
      child: Column(
        children: List.generate(4, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              // Dot placeholder
              Container(
                width: isSmall ? 10 : 12,
                height: isSmall ? 10 : 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
              ),
              SizedBox(width: isSmall ? 10 : 12),
              // Icon placeholder
              Container(
                width: isSmall ? 30 : 36,
                height: isSmall ? 30 : 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(width: isSmall ? 10 : 12),
              // Teks placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 8,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Badge placeholder
              Container(
                width: 42,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  // ── Empty state aktivitas ──────────────────────────────────────────────────
  Widget _buildActivityEmpty({required bool isSmall}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 28 : 36, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: isSmall ? 44 : 52, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            "Belum ada aktivitas tercatat",
            style: GoogleFonts.poppins(
              fontSize: isSmall ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Aktivitas CRUD akan muncul di sini",
            style: GoogleFonts.poppins(fontSize: isSmall ? 10 : 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HERO HEADER
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildHeroHeader({required bool isSmall, required double sw}) {
    final headerHeight = isSmall ? 190.0 : 230.0;
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) {
        return Container(
          width: double.infinity,
          height: headerHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD4891A), Color(0xFFC17B2F), Color(0xFF8B5E1A)],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -20, bottom: -20,
                  child: Opacity(
                    opacity: _pulseAnimation.value,
                    child: Icon(Icons.school_rounded, size: sw * 0.55, color: Colors.white),
                  ),
                ),
                Positioned(
                  left: -16, top: -16,
                  child: Opacity(
                    opacity: _pulseAnimation.value * 0.6,
                    child: Icon(Icons.school_rounded, size: sw * 0.28, color: Colors.white),
                  ),
                ),
                Positioned(
                  right: 18, top: isSmall ? 14 : 18,
                  child: Opacity(
                    opacity: 0.08,
                    child: Text(
                      "TK\nN2\nBKS",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: sw * 0.09,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 0.95,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, isSmall ? 16 : 22, 20, isSmall ? 20 : 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_rounded, color: Color(0xFFFFE0A3), size: 13),
                            const SizedBox(width: 6),
                            Text(
                              schoolName,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFFE0A3),
                                fontSize: isSmall ? 10 : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: isSmall ? 48 : 56,
                                height: isSmall ? 48 : 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.45), width: 2),
                                ),
                                child: Icon(Icons.person_rounded, color: Colors.white, size: isSmall ? 26 : 30),
                              ),
                              Positioned(
                                bottom: -4, right: -4,
                                child: Container(
                                  width: 18, height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE0A3),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: primaryDark, width: 1.5),
                                  ),
                                  child: const Icon(Icons.school_rounded, color: Color(0xFFA0601A), size: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Selamat datang,",
                                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: isSmall ? 11 : 12),
                                ),
                                Text(
                                  "Operator SiMONA",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: isSmall ? 17 : 20,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: Colors.white60, size: 11),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        schoolAddress,
                                        style: GoogleFonts.poppins(color: Colors.white60, fontSize: isSmall ? 9 : 10),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: Color(0xFFFFE0A3), size: 12),
                            const SizedBox(width: 6),
                            Text(
                              "${_stats['semester_aktif_label'] ?? 'Semester Ganjil'} · TA ${_stats['tahun_ajaran_aktif'] ?? '2025/2026'}",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFFE0A3),
                                fontSize: isSmall ? 10 : 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION LABEL
  // ════════════════════════════════════════════════════════════════════════════
  Widget _sectionLabel(String text, {required double hPad, required bool isSmall}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        children: [
          Container(
            width: 4, height: isSmall ? 16 : 18,
            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.w700, color: const Color(0xFF374151)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STATS GRID
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid({required double hPad, required bool isSmall, required bool isTablet}) {

    _StatData makeCard({
      required String title,
      required String valueKey,
      required String trendKey,
      required IconData icon,
      required Color iconColor,
      required Color bgColor,
    }) {
      final raw      = _stats[trendKey] as Map<String, dynamic>? ?? {};
      final label    = raw['label']    as String? ?? '...';
      final positive = raw['positive'] as bool?;
      return _StatData(
        title: title,
        value: _stats[valueKey].toString(),
        icon: icon,
        iconColor: iconColor,
        bgColor: bgColor,
        trend: label,
        trendPositive: positive,
      );
    }

    final cards = [
      makeCard(title: "Data Anak", valueKey: "jumlah_anak",     trendKey: "trend_anak",
        icon: Icons.child_care_rounded,       iconColor: const Color(0xFFE67E22), bgColor: const Color(0xFFFFF3E0)),
      makeCard(title: "Data Guru", valueKey: "jumlah_guru",     trendKey: "trend_guru",
        icon: Icons.school_rounded,           iconColor: const Color(0xFF27AE60), bgColor: const Color(0xFFE8F5E9)),
      makeCard(title: "Data Ortu", valueKey: "jumlah_ortu",     trendKey: "trend_ortu",
        icon: Icons.family_restroom_rounded,  iconColor: const Color(0xFF8E44AD), bgColor: const Color(0xFFEDE7F6)),
      makeCard(title: "Aspek",     valueKey: "aspek_penilaian", trendKey: "trend_aspek",
        icon: Icons.assignment_rounded,       iconColor: const Color(0xFFE74C3C), bgColor: const Color(0xFFFDE8E8)),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 4 : 2,
          crossAxisSpacing: isSmall ? 10 : 12,
          mainAxisSpacing: isSmall ? 10 : 12,
          childAspectRatio: isSmall ? 1.05 : 1.12,
        ),
        itemCount: cards.length,
        itemBuilder: (_, i) => _buildStatCard(cards[i], isSmall: isSmall),
      ),
    );
  }

  Widget _buildStatCard(_StatData data, {required bool isSmall}) {
    final trendColor = data.trendPositive == null
        ? Colors.grey.shade400
        : data.trendPositive!
            ? const Color(0xFF27AE60)
            : const Color(0xFFE74C3C);
    final trendIcon = data.trendPositive == null
        ? Icons.remove_rounded
        : data.trendPositive!
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded;

    return InkWell(
      onTap: () => _onStatCardTap(data.title),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: isSmall ? 36 : 42,
                  height: isSmall ? 36 : 42,
                  decoration: BoxDecoration(color: data.bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(data.icon, color: data.iconColor, size: isSmall ? 18 : 22),
                ),
                Opacity(
                  opacity: 0.06,
                  child: Icon(Icons.school_rounded, size: isSmall ? 28 : 34, color: const Color(0xFFC17B2F)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    data.value,
                    key: ValueKey(data.value),
                    style: GoogleFonts.poppins(
                      fontSize: isSmall ? 22 : 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E1E),
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.title,
                  style: GoogleFonts.poppins(fontSize: isSmall ? 10 : 11, color: Colors.grey.shade500),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Row(
                    key: ValueKey(data.trend),
                    children: [
                      Icon(trendIcon, size: 11, color: trendColor),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          data.trend,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: trendColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onStatCardTap(String title) {
    final routes = <String, Widget>{
      "Data Anak": const ManageAnakScreen(),
      "Data Guru": const ManageGuruScreen(),
      "Data Ortu": const ManageOrtuScreen(),
      "Aspek"    : const ManageAspekScreen(),
    };
    if (routes.containsKey(title)) {
      _pushScreen(routes[title]!);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // QUICK MENU
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildQuickMenu({required double hPad, required bool isSmall}) {
    final items = [
      _MenuItem("Anak",    Icons.child_care_rounded,      const Color(0xFFE67E22), const Color(0xFFFFF3E0), () => const ManageAnakScreen()),
      _MenuItem("Guru",    Icons.school_rounded,           const Color(0xFF27AE60), const Color(0xFFE8F5E9), () => const ManageGuruScreen()),
      _MenuItem("Ortu",    Icons.family_restroom_rounded,  const Color(0xFF8E44AD), const Color(0xFFEDE7F6), () => const ManageOrtuScreen()),
      _MenuItem("Aspek",   Icons.assignment_rounded,       const Color(0xFFE74C3C), const Color(0xFFFDE8E8), () => const ManageAspekScreen()),
      _MenuItem("User",    Icons.manage_accounts_rounded,  const Color(0xFF2980B9), const Color(0xFFE3F2FD), () => const ManageUsersScreen()),
      _MenuItem("Kelas",   Icons.meeting_room_rounded,     const Color(0xFF00838F), const Color(0xFFE0F7FA), () => const ManageKelasScreen()),
      _MenuItem("Tahun",   Icons.calendar_month_rounded,   const Color(0xFF2ECC71), const Color(0xFFE8F5E9), () => const ManageTahunAjaranScreen()),
      _MenuItem("Sekolah", Icons.account_balance_rounded,  const Color(0xFF3F51B5), const Color(0xFFE8EAF6), () => const SchoolProfileScreen(userRole: 'operator')),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 14 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10, bottom: -10,
              child: Opacity(
                opacity: 0.04,
                child: Icon(Icons.school_rounded, size: 90, color: primaryColor),
              ),
            ),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: isSmall ? 8 : 12,
              crossAxisSpacing: isSmall ? 8 : 12,
              childAspectRatio: isSmall ? 0.70 : 0.78,
              children: items.map((item) => _buildMenuItem(item, isSmall: isSmall)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item, {required bool isSmall}) {
    return InkWell(
      onTap: () {
        if (item.pageBuilder != null) {
          final page = item.pageBuilder!();
          if (page != null) _pushScreen(page);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmall ? 44 : 52,
            height: isSmall ? 44 : 52,
            decoration: BoxDecoration(color: item.bgColor, borderRadius: BorderRadius.circular(14)),
            child: Icon(item.icon, color: item.color, size: isSmall ? 22 : 26),
          ),
          SizedBox(height: isSmall ? 6 : 8),
          Text(
            item.label,
            style: GoogleFonts.poppins(fontSize: isSmall ? 10 : 11, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildBottomNav({required bool isSmall}) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey.shade400,
      backgroundColor: Colors.white,
      elevation: 12,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
      onTap: (i) async {
        if (i == 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        setState(() => _currentIndex = i);
        if (i == 1) {
          await _pushScreen(const ManageAnakScreen());
        } else if (i == 2) {
          await _pushScreen(const ManageGuruScreen());
        } else if (i == 3) {
          await _pushScreen(SettingOperatorScreen(user: {'id': 1, 'name': 'Operator SiMONA'}));
        }
        if (mounted) {
          setState(() => _currentIndex = 0);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded),        label: "Beranda"),
        BottomNavigationBarItem(icon: Icon(Icons.child_care_rounded),  label: "Anak"),
        BottomNavigationBarItem(icon: Icon(Icons.school_rounded),      label: "Guru"),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded),    label: "Setting"),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DRAWER
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildDrawer({required bool isSmall}) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFD4891A), Color(0xFFC17B2F), Color(0xFF8B5E1A)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -10, top: -10,
                  child: Opacity(
                    opacity: 0.1,
                    child: const Icon(Icons.school_rounded, size: 100, color: Colors.white),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.45), width: 2),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text("Operator SiMONA", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text("operator@simona.com", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school_rounded, color: Color(0xFFFFE0A3), size: 12),
                          const SizedBox(width: 6),
                          Text(schoolName, style: GoogleFonts.poppins(color: const Color(0xFFFFE0A3), fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _drawerItem(Icons.dashboard_rounded,       "Dashboard"),
                _drawerItem(Icons.manage_accounts_rounded, "Kelola User"),
                _drawerItem(Icons.child_care_rounded,      "Data Anak"),
                _drawerItem(Icons.family_restroom_rounded, "Data Orang Tua"),
                _drawerItem(Icons.school_rounded,          "Data Guru"),
                _drawerItem(Icons.assignment_rounded,      "Aspek Penilaian"),
                _drawerItem(Icons.class_rounded,           "Data Kelas"),
                _drawerItem(Icons.date_range_rounded,      "Tahun Ajaran"),
                _drawerItem(Icons.account_balance_rounded, "Profil Sekolah"),
                const Divider(height: 24),
                _drawerItem(Icons.logout_rounded, "Logout", isLogout: true),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text("SiMONA v1.0 · $schoolName", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red.shade400 : Colors.grey.shade600, size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isLogout ? Colors.red.shade400 : Colors.grey.shade800,
          fontSize: 14, fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (isLogout) {
          Navigator.pushReplacementNamed(context, '/');
        } else if (title == "Profil Sekolah") {
          _pushScreen(const SchoolProfileScreen(userRole: 'operator'));
        } else if (title == "Data Anak") {
          _pushScreen(const ManageAnakScreen());
        } else if (title == "Data Orang Tua") {
          _pushScreen(const ManageOrtuScreen());
        } else if (title == "Data Guru") {
          _pushScreen(const ManageGuruScreen());
        } else if (title == "Aspek Penilaian") {
          _pushScreen(const ManageAspekScreen());
        } else if (title == "Data Kelas") {
          _pushScreen(const ManageKelasScreen());
        } else if (title == "Tahun Ajaran") {
          _pushScreen(const ManageTahunAjaranScreen());
        } else if (title == "Kelola User") {
          _pushScreen(const ManageUsersScreen());
        }
      },
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────

class _StatData {
  final String title, value, trend;
  final IconData icon;
  final Color iconColor, bgColor;
  final bool? trendPositive;

  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.trend,
    required this.trendPositive,
  });
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color, bgColor;
  final Widget? Function()? pageBuilder;

  const _MenuItem(this.label, this.icon, this.color, this.bgColor, this.pageBuilder);
}
