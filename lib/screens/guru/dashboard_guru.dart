import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'penilaian_checklist_screen.dart';
import 'absensi_screen.dart';
import 'anekdot_screen.dart';
import 'rencana_belajar_screen.dart';
import 'karya_screen.dart';
import 'data_anak_screen.dart';
import 'aspek_penilaian_screen.dart';
import 'ekstrakurikuler_screen.dart';
import 'refleksi_guru_screen.dart';
import 'rekap_raport_screen.dart';
import '../profil_sekolah_screen.dart';
import '../operator/activity_log_screen.dart';
import '../about_system_screen.dart';

class DashboardGuru extends StatefulWidget {
  final Map<String, dynamic> user;
  const DashboardGuru({super.key, required this.user});

  @override
  State<DashboardGuru> createState() => _DashboardGuruState();
}

class _DashboardGuruState extends State<DashboardGuru>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _green900 = Color(0xFF14532D);
  static const Color _green700 = Color(0xFF15803D);
  static const Color _green500 = Color(0xFF22C55E);
  static const Color _green100 = Color(0xFFDCFCE7);
  static const Color _bg       = Color(0xFFF0FDF4);
  static const Color _surface  = Colors.white;
  static const Color _navy     = Color(0xFF1E3A8A);
  static const Color _amber    = Color(0xFFF59E0B);
  static const Color _rose     = Color(0xFFE11D48);
  static const Color _purple   = Color(0xFF7C3AED);
  static const Color _teal     = Color(0xFF0891B2);
  static const Color _tealDark = Color(0xFF0F766E);
  static const Color _slate    = Color(0xFF64748B);

  late AnimationController _fadeCtrl;
  late Animation<double>    _fadeAnim;

  // ── Dynamic State ─────────────────────────────────────────────────────────
  bool   _isLoading       = true;
  List<dynamic> _anakList      = [];
  List<String>  _belumHadirList = [];
  List<dynamic> _activitiesList = [];
  int    _totalAnak      = 0;
  int    _hadirCount      = 0;
  int    _izinCount       = 0;
  int    _alfaCount       = 0;
  // Guru activity stats (real)
  int    _checklistCount  = 0;
  int    _anekdotCount    = 0;
  int    _karyaCount      = 0;
  int    _absensiCount    = 0;
  int    _rencanaCount    = 0;

  // Notifications
  List<dynamic> _notifications = [];
  String _tahunAjaran = 'TA 2024/2025';


  // Local copy of user data (can be edited)
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.user);
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final idGuru  = widget.user['id'];
      final idKelas = widget.user['id_kelas'];

      // Load anak & absensi
      List<dynamic> students = [];
      if (idKelas != null) {
        try {
          final kelasRes = await ApiService.fetch('manage_kelas.php');
          if (kelasRes['status'] == 'success') {
            final kelasList = kelasRes['data'] as List? ?? [];
            final myKelas = kelasList.firstWhere(
              (k) => int.tryParse(k['id'].toString()) == int.tryParse(idKelas.toString()),
              orElse: () => null,
            );
            if (myKelas != null && myKelas['tahun'] != null) {
              _tahunAjaran = 'TA ${myKelas['tahun']}';
            }
          }
        } catch (e) {
          debugPrint("Error loading class academic year: $e");
        }

        final anakRes = await ApiService.fetch('manage_anak.php?id_kelas=$idKelas');
        if (anakRes['status'] == 'success') students = anakRes['data'] as List? ?? [];

        final todayStr = DateTime.now().toString().substring(0, 10);
        final absRes   = await ApiService.fetch('manage_absensi.php?id_kelas=$idKelas&tanggal=$todayStr');
        List<dynamic> absensi = [];
        if (absRes['status'] == 'success') absensi = absRes['data'] as List? ?? [];

        final Map<int, String> statusMap = {};
        for (var abs in absensi) {
          final sid = int.tryParse(abs['id_anak'].toString());
          if (sid != null) statusMap[sid] = abs['status'] ?? 'Hadir';
        }

        int hadir = 0, izin = 0, alfa = 0;
        List<String> belumHadir = [];
        for (var s in students) {
          final sid  = int.tryParse(s['id'].toString());
          final name = s['nama_anak'] ?? 'Anak';
          if (sid != null) {
            final status = statusMap[sid];
            if (status == null)                              { belumHadir.add(name); }
            else if (status == 'Hadir')                     { hadir++; }
            else if (status == 'Izin' || status == 'Sakit') { izin++; }
            else if (status == 'Alpa')                      { alfa++; belumHadir.add(name); }
          }
        }
        setState(() {
          _anakList      = students;
          _totalAnak     = students.length;
          _hadirCount     = hadir;
          _izinCount      = izin;
          _alfaCount      = alfa;
          _belumHadirList = belumHadir;
        });
      } else {
        setState(() {
          _anakList = []; _totalAnak = 0;
          _hadirCount = 0; _izinCount = 0; _alfaCount = 0;
          _belumHadirList = [];
        });
      }

      // Load aktivitas terbaru dari backend
      final actRes = await ApiService.getRecentActivities(limit: 5);
      if (actRes['status'] == 'success') {
        final acts = actRes['data'] as List? ?? [];
        setState(() => _activitiesList = acts);
      }

      // Load guru stats (checklist, anekdot, karya, absensi, jadwal)
      if (idGuru != null && idKelas != null) {
        final checkRes  = await ApiService.fetch('manage_penilaian.php?id_guru=$idGuru&count=1');
        final anekdotRes = await ApiService.fetch('manage_anekdot.php?id_guru=$idGuru&count=1');
        final karyaRes  = await ApiService.fetch('manage_karya.php?id_kelas=$idKelas');
        final absensiAllRes = await ApiService.fetch('manage_absensi.php?id_kelas=$idKelas&count=1');
        final rppmRes = await ApiService.fetch('manage_rpp.php?type=rppm&id_kelas=$idKelas');

        setState(() {
          _checklistCount = (checkRes['total']  ?? (checkRes['data'] as List?)?.length  ?? 0) is int
              ? checkRes['total'] ?? (checkRes['data'] as List?)?.length ?? 0
              : int.tryParse(checkRes['total']?.toString() ?? '0') ?? 0;
          _anekdotCount = (anekdotRes['total']  ?? (anekdotRes['data'] as List?)?.length  ?? 0) is int
              ? anekdotRes['total'] ?? (anekdotRes['data'] as List?)?.length ?? 0
              : int.tryParse(anekdotRes['total']?.toString() ?? '0') ?? 0;
          _karyaCount = (karyaRes['total']  ?? (karyaRes['data'] as List?)?.length  ?? 0) is int
              ? karyaRes['total'] ?? (karyaRes['data'] as List?)?.length ?? 0
              : int.tryParse(karyaRes['total']?.toString() ?? '0') ?? 0;
          _absensiCount = (absensiAllRes['total'] ?? (absensiAllRes['data'] as List?)?.length ?? 0) is int
              ? absensiAllRes['total'] ?? (absensiAllRes['data'] as List?)?.length ?? 0
              : int.tryParse(absensiAllRes['total']?.toString() ?? '0') ?? 0;
          _rencanaCount = (rppmRes['data'] as List?)?.length ?? 0;
        });
      }

      // Load Notifications
      if (idGuru != null && idKelas != null) {
        final notifRes = await ApiService.fetch('get_notifications.php?role=guru&id_guru=$idGuru&id_kelas=$idKelas');
        if (notifRes['status'] == 'success') {
          setState(() => _notifications = notifRes['data'] as List? ?? []);
        }
      }


    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onTabTap(int i) {
  if (i == _currentIndex) return;
  _fadeCtrl.reset();
  setState(() => _currentIndex = i);
  _fadeCtrl.forward();
  if (i == 0 || i == 3) {
    _loadDashboardData();
  }
}

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(opacity: _fadeAnim, child: _buildBody()),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.home_rounded,        Icons.home_rounded,       'Beranda'),
      _NavItem(Icons.edit_note_outlined,  Icons.edit_note_rounded,  'Checklist'),
      _NavItem(Icons.how_to_reg_outlined, Icons.how_to_reg_rounded, 'Absensi'),
      _NavItem(Icons.person_outline,      Icons.person_rounded,     'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final item     = items[i];
              final isActive = i == _currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? _green700.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(isActive ? item.activeIcon : item.icon,
                        color: isActive ? _green700 : _slate, size: 24),
                      const SizedBox(height: 4),
                      Text(item.label, style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? _green700 : _slate)),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final idGuru  = int.tryParse(widget.user['id'].toString());
    final idKelas = int.tryParse(widget.user['id_kelas'].toString());
    switch (_currentIndex) {
      case 0:  return _buildHome();
      case 1:  return PenilaianChecklistScreen(idGuru: idGuru, idKelas: idKelas);
      case 2:  return AbsensiScreen(idGuru: idGuru, idKelas: idKelas);
      case 3:  return _buildProfilePage();
      default: return _buildHome();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOME
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHome() {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _green700)));
    }
    return CustomScrollView(
      slivers: [
        // ── SliverAppBar ────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          collapsedHeight: 70,
          pinned: true,
          backgroundColor: _green700,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _buildHeroBanner(),
          ),
          title: const Text('SiMONA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
              color: Colors.white, letterSpacing: 1.5)),
          actions: [
            Stack(alignment: Alignment.topRight, children: [
              IconButton(
                onPressed: _showNotifications,
                icon: const Icon(Icons.notifications_outlined, color: Colors.white)),
              if (_notifications.isNotEmpty)
                Positioned(top: 8, right: 8,
                  child: Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: _rose, shape: BoxShape.circle, border: Border.all(color: _green700, width: 2)))),
            ]),
            const SizedBox(width: 4),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              _buildDateBadge(),
              const SizedBox(height: 20),

              _buildStatRow(),
              const SizedBox(height: 24),

              // ── Agenda ────────────────────────────────────────────────
              _buildSectionHeader('Agenda Hari Ini', Icons.today_rounded, _amber),
              const SizedBox(height: 12),
              _buildAgendaCard(),
              const SizedBox(height: 24),

              // ── Menu Utama ──────────────────────────────
              _buildSectionHeader('Menu Utama', Icons.grid_view_rounded, _green700),
              const SizedBox(height: 14),
              _buildRekapFeaturedCard(),
              const SizedBox(height: 14),
              _buildMenuGrid(),
              const SizedBox(height: 24),

              // ── Belum Hadir ────────────────────────────────────────────
              _buildSectionHeader('Belum Hadir Hari Ini', Icons.warning_amber_rounded, _rose),
              const SizedBox(height: 12),
              _buildAbsenWarning(),
              const SizedBox(height: 24),

              // ── Aktivitas ─────────────────────────────────────────────
              _buildSectionHeader('Aktivitas Terbaru', Icons.history_rounded, _teal),
              const SizedBox(height: 12),
              _buildRecentActivity(),
            ]),
          ),
        ),
      ],
    );
  }



  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pemberitahuan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Tidak ada pemberitahuan baru', style: TextStyle(color: Colors.grey))),
              )
            else
              ..._notifications.map((n) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: n['level'] == 'warning' ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: n['level'] == 'warning' ? Colors.orange.withOpacity(0.3) : Colors.blue.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(
                    n['level'] == 'warning' ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                    color: n['level'] == 'warning' ? Colors.orange : Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n['judul'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(n['pesan'] ?? '', style: const TextStyle(fontSize: 11)),
                    ],
                  )),
                ]),
              )),
          ],
        ),
      ),
    );
  }

  // ── Hero Banner ───────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    final namaGuru  = widget.user['name']       ?? 'Guru';
    final namaKelas = widget.user['nama_kelas'] ?? 'Kelompok A';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_green900, _green700],
          begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Stack(children: [
        Positioned(top: -20, right: -20,
          child: Container(width: 140, height: 140,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle))),
        Positioned(bottom: -30, right: 60,
          child: Container(width: 90, height: 90,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), shape: BoxShape.circle))),
        Positioned(left: 20, right: 20, bottom: 20, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Selamat Datang,',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
                Text(namaGuru,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text('TK Negeri 2 Bengkalis — $namaKelas',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
              ])),
          ])),
      ]),
    );
  }

  // ── Date Badge ────────────────────────────────────────────────────────────
  Widget _buildDateBadge() {
    final now    = DateTime.now();
    final days   = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _green100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _green500.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today_rounded, size: 14, color: _green700),
          const SizedBox(width: 6),
          Text('${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}',
            style: const TextStyle(fontSize: 12, color: _green700, fontWeight: FontWeight.w600)),
        ])),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: _navy.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.access_time_rounded, size: 14, color: _navy),
          const SizedBox(width: 6),
          Text(_tahunAjaran, style: const TextStyle(fontSize: 12, color: _navy, fontWeight: FontWeight.w600)),
        ])),
    ]);
  }

  // ── Stat Row ──────────────────────────────────────────────────────  // ── Agenda Card ─────────────────────────────────────────────────────────
  Widget _buildAgendaCard() {
    final blocks = [
      _AgendaBlock('07.30', 'Pembiasaan & Penyambutan', Icons.wb_sunny_rounded, _green700,
        ['Berbaris bersama']),
      _AgendaBlock('08.00', 'Kegiatan Inti Pembelajaran', Icons.menu_book_rounded, _navy, []),
      _AgendaBlock('09.30', 'Istirahat', Icons.lunch_dining_rounded, _amber,
        ['Makan', 'Bermain di luar kelas']),
      _AgendaBlock('10.15', 'Evaluasi & Penutup', Icons.checklist_rounded, _teal,
        ['10.15 - 10.40: Evaluasi & Penutup', '10.40: Pulang']),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks.asMap().entries.map((e) {
          final i = e.key; final b = e.value;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Baris judul besar
            Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, b.subItems.isEmpty ? 14 : 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                // Badge waktu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: b.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(b.time,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: b.color),
                    textAlign: TextAlign.center)),
                const SizedBox(width: 12),
                // Garis vertikal
                Container(width: 3, height: 30,
                  decoration: BoxDecoration(color: b.color, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 12),
                // Judul
                Expanded(child: Text(b.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                // Ikon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: b.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: Icon(b.icon, size: 15, color: b.color)),
              ])),

            // ── Sub-item
            if (b.subItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 84, right: 16, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: b.subItems.map((sub) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5, right: 6),
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          color: b.color.withOpacity(0.55),
                          shape: BoxShape.circle)),
                      Expanded(child: Text(sub,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.45))),
                    ]),
                  )).toList(),
                )),

            if (i < blocks.length - 1)
              Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
          ]);
        }).toList()),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      );

  Widget _buildStatRow() {
    return Row(
      children: [
        Expanded(child: _statBox('Total Anak', '$_totalAnak', _navy)),
        const SizedBox(width: 8),
        Expanded(child: _statBox('Hadir', '$_hadirCount', _green700)),
        const SizedBox(width: 8),
        Expanded(child: _statBox('Izin', '$_izinCount', _amber)),
        const SizedBox(width: 8),
        Expanded(child: _statBox('Alpa', '$_alfaCount', _rose)),
      ],
    );
  }

  // ── Menu Grid — 8 menu ────────────────────────────────────────────────────
  Widget _buildMenuGrid() {
    final idGuru  = int.tryParse(widget.user['id'].toString());
    final idKelas = int.tryParse(widget.user['id_kelas'].toString());

    // 9 menu utama (3×3 grid, genap sempurna)
    final menus = [
      // ── Baris 1 ──────────────────────────────────────────────────────
      _MenuData(
        label: 'Checklist',
        icon:  Icons.edit_note_rounded,
        color: const Color(0xFFF97316),
        badge: null,
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
            PenilaianChecklistScreen(idGuru: idGuru, idKelas: idKelas))).then((_) => _loadDashboardData()),
      ),
      _MenuData(
        label: 'Absensi',
        icon:  Icons.how_to_reg_rounded,
        color: _rose,
        badge: _belumHadirList.isNotEmpty ? '${_belumHadirList.length}' : null,
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
            AbsensiScreen(idGuru: idGuru, idKelas: idKelas))).then((_) => _loadDashboardData()),
      ),
      _MenuData(
        label: 'Anekdot',
        icon:  Icons.description_rounded,
        color: _purple,
        badge: null,
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
            AnekdotScreen(idGuru: idGuru, idKelas: idKelas))).then((_) => _loadDashboardData()),
      ),
      // ── Baris 2 ──────────────────────────────────────────────────────
      _MenuData(
        label: 'Karya Anak',
        icon:  Icons.palette_rounded,
        color: _green700,
        badge: null,
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
            KaryaScreen(idGuru: idGuru, idKelas: idKelas))).then((_) => _loadDashboardData()),
      ),
      _MenuData(
        label: 'Data Anak',
        icon:  Icons.child_care_rounded,
        color: const Color(0xFF7C3AED),
        badge: '$_totalAnak',
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
            DataAnakScreen(idKelas: idKelas))),
      ),
      _MenuData(
        label: 'Aspek Nilai',
        icon:  Icons.checklist_rounded,
        color: _tealDark,
        badge: null,
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
            AspekPenilaianScreen(idGuru: idGuru))),
      ),
      // ── Baris 3 ──────────────────────────────────────────────────────
      _MenuData(
        label: 'Rencana Belajar',
        icon:  Icons.assignment_rounded,
        color: _navy,
        badge: null,
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
            RencanaBelajarScreen(idGuru: idGuru, idKelas: idKelas))),
      ),
      _MenuData(
        label: 'Ekstrakurikuler',
        icon:  Icons.sports_soccer_rounded,
        color: const Color(0xFF06B6D4),
        badge: null,
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
            EkstrakurikulerScreen(idGuru: idGuru, idKelas: idKelas))).then((_) => _loadDashboardData()),
      ),
      _MenuData(
        label: 'Refleksi Guru',
        icon:  Icons.assessment_rounded,
        color: const Color(0xFF7C3AED),
        badge: null,
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
            RefleksiGuruScreen(idGuru: idGuru, idKelas: idKelas))).then((_) => _loadDashboardData()),
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.74,
      children: menus.map((m) => _buildMenuCard(m)).toList(),
    );
  }

  // ── Featured Card: Rekap & Rapor (full-width, premium) ───────────────────
  Widget _buildRekapFeaturedCard() {
    final idGuru  = int.tryParse(widget.user['id'].toString());
    final idKelas = int.tryParse(widget.user['id_kelas'].toString());
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) =>
          RekapRaportScreen(idGuru: idGuru, idKelas: idKelas)))
        .then((_) => _loadDashboardData()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFBBF24)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Lingkaran dekoratif background
            Positioned(
              right: -18, top: -18,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 30, bottom: -30,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Konten
            Row(
              children: [
                // Ikon besar
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.summarize_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                // Teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Rekap & Rapor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rekap penilaian bulanan & rapor akhir semester seluruh anak',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Panah
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(_MenuData m) {
    return GestureDetector(
      onTap: m.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: m.color.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3)),
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4),
          ],
        ),
        child: Stack(children: [
          // Konten tengah
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [m.color, m.color.withOpacity(0.75)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(13)),
                child: Icon(m.icon, color: Colors.white, size: 24)),
              const SizedBox(height: 8),
              Text(m.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 11,
                  color: Colors.grey.shade800),
                textAlign: TextAlign.center,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          )),
          // Badge notif (pojok kanan atas)
          if (m.badge != null)
            Positioned(top: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: m.color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: m.color.withOpacity(0.4), blurRadius: 4)]),
                child: Text(m.badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
        ]),
      ),
    );
  }

  // ── Absen Warning ─────────────────────────────────────────────────────────
  Widget _buildAbsenWarning() {
    if (_belumHadirList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _green100, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _green500.withOpacity(0.3))),
        child: const Row(children: [
          Icon(Icons.check_circle_rounded, color: _green700, size: 20),
          SizedBox(width: 10),
          Text('Data absensi hari ini sudah lengkap 🎉',
            style: TextStyle(color: _green700, fontWeight: FontWeight.w600, fontSize: 13)),
        ]));
    }
    return Container(
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _rose.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: _belumHadirList.asMap().entries.map((e) {
        final i    = e.key; final nama = e.value;
        final init = nama.trim().split(' ').map((s) => s[0]).take(2).join().toUpperCase();
        return Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              CircleAvatar(radius: 18, backgroundColor: _rose.withOpacity(0.1),
                child: Text(init, style: const TextStyle(color: _rose, fontWeight: FontWeight.bold, fontSize: 11))),
              const SizedBox(width: 12),
              Expanded(child: Text(nama, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _rose.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: const Text('Belum Hadir', style: TextStyle(fontSize: 10, color: _rose, fontWeight: FontWeight.bold))),
            ])),
          if (i < _belumHadirList.length - 1)
            Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14),
        ]);
      }).toList()),
    );
  }

  // ── Recent Activity ───────────────────────────────────────────────────────
  Widget _buildRecentActivity() {
    if (_activitiesList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))]),
        child: const Center(
          child: Text('Belum ada aktivitas tercatat',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        ),
      );
    }

    // Peta jenis → icon & warna
    IconData _actIcon(String jenis, String aksi) {
      switch (jenis) {
        case 'anak':  return Icons.child_care_rounded;
        case 'guru':  return Icons.school_rounded;
        case 'ortu':  return Icons.family_restroom_rounded;
        case 'aspek': return Icons.checklist_rounded;
        case 'kelas': return Icons.class_rounded;
        case 'nilai': return Icons.edit_note_rounded;
        default:      return Icons.history_rounded;
      }
    }
    Color _actColor(String aksi) {
      switch (aksi) {
        case 'tambah': return _green700;
        case 'edit':   return _teal;
        case 'hapus':  return _rose;
        default:       return _purple;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))]),
      child: Column(children: [
        ..._activitiesList.asMap().entries.map((e) {
          final i   = e.key;
          final act = e.value as Map<String, dynamic>;
          final jenis = act['jenis']?.toString() ?? '';
          final aksi  = act['aksi']?.toString() ?? '';
          final icon  = _actIcon(jenis, aksi);
          final color = _actColor(aksi);
          return Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(act['judul'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text(act['waktu_label'] ?? act['deskripsi'] ?? '',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text(aksi, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold))),
              ])),
            if (i < _activitiesList.length - 1)
              Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14),
          ]);
        }).toList(),
        if (_activitiesList.length >= 5) ...[
          const Divider(height: 1, color: Color(0xFFF9F4EF)),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ActivityLogScreen()),
              );
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.04),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Lihat semua aktivitas",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _teal,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: _teal),
                ],
              ),
            ),
          ),
        ],
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFIL
  // ═══════════════════════════════════════════════════════════════════════════
  // ────────────────────────────────────────────────────────────────────────
  // EDIT PROFILE SHEET
  // ────────────────────────────────────────────────────────────────────────
  void _showEditProfileSheet() {
    final nameCtrl      = TextEditingController(text: _userData['name'] ?? '');
    final nipCtrl       = TextEditingController(text: _userData['nip'] ?? '');
    final nikCtrl       = TextEditingController(text: _userData['nik'] ?? '');
    final noTelpCtrl    = TextEditingController(text: _userData['no_telp'] ?? '');
    final emailCtrl     = TextEditingController(text: _userData['email_guru'] ?? '');
    final ttlCtrl       = TextEditingController(text: _userData['tempat_lahir'] ?? '');
    final tglLahirCtrl  = TextEditingController(text: _userData['tanggal_lahir'] ?? '');
    final jabatanCtrl   = TextEditingController(text: _userData['jabatan'] ?? '');
    final jurusanCtrl   = TextEditingController(text: _userData['jurusan'] ?? '');
    final alamatCtrl    = TextEditingController(text: _userData['alamat'] ?? '');

    String? agama       = _userData['agama'];
    String? jk          = _userData['jenis_kelamin'];
    String? statusNikah = _userData['status_nikah'];
    String? statusKepeg = _userData['status_kepeg'];
    String? pendidikan  = _userData['pendidikan'];

    bool isSaving = false;

    InputDecoration _fieldDecor(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: _green700),
      filled: true,
      fillColor: const Color(0xFFF0FDF4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green700, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final mq = MediaQuery.of(ctx);
          return Container(
            height: mq.size.height * 0.92,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(child: Text('Edit Profil Guru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF14532D)))),
                    TextButton.icon(
                      onPressed: isSaving ? null : () async {
                        setLocal(() => isSaving = true);
                        final id = int.tryParse(_userData['id'].toString()) ?? 0;
                        final res = await ApiService.post('manage_guru.php', {
                          'action': 'update',
                          'id': id,
                          'name': nameCtrl.text.trim(),
                          'nip': nipCtrl.text.trim(),
                          'nik': nikCtrl.text.trim(),
                          'no_telp': noTelpCtrl.text.trim(),
                          'email_guru': emailCtrl.text.trim(),
                          'tempat_lahir': ttlCtrl.text.trim(),
                          'tanggal_lahir': tglLahirCtrl.text.trim(),
                          'jabatan': jabatanCtrl.text.trim(),
                          'jurusan': jurusanCtrl.text.trim(),
                          'alamat': alamatCtrl.text.trim(),
                          'agama': agama ?? '',
                          'jenis_kelamin': jk ?? '',
                          'status_nikah': statusNikah ?? '',
                          'status_kepeg': statusKepeg ?? '',
                          'pendidikan': pendidikan ?? '',
                          'id_kelas': _userData['id_kelas'] ?? '',
                        });
                        setLocal(() => isSaving = false);
                        if (res['status'] == 'success') {
                          setState(() {
                            _userData['name']         = nameCtrl.text.trim();
                            _userData['nip']          = nipCtrl.text.trim();
                            _userData['nik']          = nikCtrl.text.trim();
                            _userData['no_telp']      = noTelpCtrl.text.trim();
                            _userData['email_guru']   = emailCtrl.text.trim();
                            _userData['tempat_lahir'] = ttlCtrl.text.trim();
                            _userData['tanggal_lahir']= tglLahirCtrl.text.trim();
                            _userData['jabatan']      = jabatanCtrl.text.trim();
                            _userData['jurusan']      = jurusanCtrl.text.trim();
                            _userData['alamat']       = alamatCtrl.text.trim();
                            _userData['agama']        = agama;
                            _userData['jenis_kelamin']= jk;
                            _userData['status_nikah'] = statusNikah;
                            _userData['status_kepeg'] = statusKepeg;
                            _userData['pendidikan']   = pendidikan;
                          });
                          if (mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil berhasil diperbarui'), backgroundColor: Colors.green));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan'), backgroundColor: Colors.red));
                        }
                      },
                      icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _green700))
                        : const Icon(Icons.save_rounded, color: _green700, size: 18),
                      label: const Text('Simpan', style: TextStyle(color: _green700, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, mq.viewInsets.bottom + 16),
                  children: [
                    const _SectionLabel('Data Pribadi'),
                    const SizedBox(height: 10),
                    TextField(controller: nameCtrl, decoration: _fieldDecor('Nama Lengkap', Icons.badge_rounded)),
                    const SizedBox(height: 12),
                    TextField(controller: nipCtrl, decoration: _fieldDecor('NIP', Icons.credit_card_rounded)),
                    const SizedBox(height: 12),
                    TextField(controller: nikCtrl, decoration: _fieldDecor('NIK', Icons.credit_card_outlined)),
                    const SizedBox(height: 12),
                    TextField(controller: ttlCtrl, decoration: _fieldDecor('Tempat Lahir', Icons.location_city_rounded)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tglLahirCtrl,
                      readOnly: true,
                      decoration: _fieldDecor('Tanggal Lahir (YYYY-MM-DD)', Icons.cake_rounded),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.tryParse(tglLahirCtrl.text) ?? DateTime(1990),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          tglLahirCtrl.text = picked.toIso8601String().substring(0, 10);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: jk,
                      decoration: _fieldDecor('Jenis Kelamin', Icons.wc_rounded),
                      items: const [
                        DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                        DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                      ],
                      onChanged: (v) => setLocal(() => jk = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: agama,
                      decoration: _fieldDecor('Agama', Icons.mosque_rounded),
                      items: ['Islam','Kristen','Katolik','Hindu','Buddha','Konghucu']
                        .map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (v) => setLocal(() => agama = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: statusNikah,
                      decoration: _fieldDecor('Status Nikah', Icons.favorite_rounded),
                      items: ['Belum Menikah','Menikah','Cerai']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setLocal(() => statusNikah = v),
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Data Kepegawaian'),
                    const SizedBox(height: 10),
                    TextField(controller: jabatanCtrl, decoration: _fieldDecor('Jabatan', Icons.work_rounded)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: statusKepeg,
                      decoration: _fieldDecor('Status Kepegawaian', Icons.badge_outlined),
                      items: ['PNS','PPPK','Honorer','GTT','PTT']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setLocal(() => statusKepeg = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: pendidikan,
                      decoration: _fieldDecor('Pendidikan Terakhir', Icons.school_rounded),
                      items: ['SMA/SMK','D3','S1','S2','S3']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setLocal(() => pendidikan = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: jurusanCtrl, decoration: _fieldDecor('Jurusan', Icons.menu_book_rounded)),
                    const SizedBox(height: 20),
                    const _SectionLabel('Kontak & Alamat'),
                    const SizedBox(height: 10),
                    TextField(controller: noTelpCtrl, keyboardType: TextInputType.phone, decoration: _fieldDecor('No. HP / WhatsApp', Icons.phone_rounded)),
                    const SizedBox(height: 12),
                    TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: _fieldDecor('Email', Icons.email_rounded)),
                    const SizedBox(height: 12),
                    TextField(controller: alamatCtrl, maxLines: 3, decoration: _fieldDecor('Alamat Lengkap', Icons.home_rounded)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  }

  Widget _buildProfilePage() {
    return CustomScrollView(slivers: [
      SliverAppBar(
        expandedHeight: 220, pinned: true,
        backgroundColor: _green700, elevation: 0,
        flexibleSpace: FlexibleSpaceBar(
          collapseMode: CollapseMode.parallax,
          background: _buildProfileHero()),
        title: const Text('Profil Guru',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            tooltip: 'Edit Profil',
            onPressed: _showEditProfileSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          _profileSection(
            title: 'Informasi Pribadi', icon: Icons.person_rounded, color: _green700,
            children: [
              _profileRow(Icons.badge_rounded,      'Nama Lengkap', _userData['name']    ?? 'Guru'),
              _profileRow(Icons.credit_card_rounded, 'NIP',         _userData['nip']     ?? '-'),
              _profileRow(Icons.credit_card_outlined,'NIK',         _userData['nik']     ?? '-'),
              _profileRow(Icons.school_rounded,      'Pendidikan',  _userData['pendidikan'] != null ? '${_userData['pendidikan']}${_userData['jurusan'] != null ? ' - ${_userData['jurusan']}' : ''}' : '-'),
              _profileRow(Icons.cake_rounded,        'TTL',         (_userData['tempat_lahir'] != null || _userData['tanggal_lahir'] != null) ? '${_userData['tempat_lahir'] ?? ''}, ${_userData['tanggal_lahir'] ?? ''}' : '-'),
              _profileRow(Icons.phone_rounded,       'No. HP',      _userData['no_telp'] ?? '-'),
              _profileRow(Icons.email_rounded,       'Email',       _userData['email_guru'] ?? '-'),
              _profileRow(Icons.mosque_rounded,      'Agama',       _userData['agama'] ?? '-'),
              _profileRow(Icons.wc_rounded,          'Jenis Kelamin', _userData['jenis_kelamin'] == 'L' ? 'Laki-laki' : (_userData['jenis_kelamin'] == 'P' ? 'Perempuan' : '-')),
              _profileRow(Icons.favorite_rounded,    'Status Nikah', _userData['status_nikah'] ?? '-'),
              _profileRow(Icons.work_rounded,        'Status Kepegawaian', _userData['status_kepeg'] ?? '-'),
              _profileRow(Icons.badge_rounded,       'Jabatan',     _userData['jabatan'] ?? '-', isLast: true),
            ]),
          const SizedBox(height: 16),

          if ((_userData['alamat'] ?? '').toString().isNotEmpty) ...[
            _profileSection(
              title: 'Alamat Lengkap', icon: Icons.home_rounded, color: _navy,
              children: [
                _profileRow(Icons.location_on_rounded, 'Alamat',    _userData['alamat'] ?? '-', isLast: true),
              ]),
            const SizedBox(height: 16),
          ] else ...[
            // Jika alamat kosong, tampilkan hint untuk mengisi
            GestureDetector(
              onTap: _showEditProfileSheet,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('Alamat belum diisi. Ketuk untuk melengkapi profil.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
                  Icon(Icons.chevron_right_rounded, color: Color(0xFFF59E0B), size: 18),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _profileSection(
            title: 'Informasi Mengajar', icon: Icons.school_rounded, color: _navy,
            children: [
              _profileRow(Icons.location_city_rounded,  'Sekolah',      'TK Negeri 2 Bengkalis'),
              _profileRow(Icons.meeting_room_rounded,   'Kelas',        _userData['nama_kelas'] ?? 'Kelompok A'),
              _profileRow(Icons.calendar_month_rounded, 'Tahun Ajaran', '2024/2025'),
              _profileRow(Icons.child_care_rounded,     'Jumlah Anak',  '$_totalAnak Anak', isLast: true),
            ]),
          const SizedBox(height: 16),

          // ── Profil Sekolah ───────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) =>
                const ProfilSekolahScreen(primaryColor: _green700))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _green700.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.account_balance_rounded, color: _green700, size: 22)),
                const SizedBox(width: 14),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Profil Sekolah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                  SizedBox(height: 2),
                  Text('Lihat informasi lengkap sekolah', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ])),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
              ])),
          ),
          const SizedBox(height: 16),

          // ── Tentang SiMONA ───────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) =>
                const AboutSystemScreen(
                  primaryColor: _green700,
                  primaryDark: _green900,
                  backgroundColor: _surface,
                  borderColor: Color(0xFFE2E8F0),
                ))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _green700.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.info_outline_rounded, color: _green700, size: 22)),
                const SizedBox(width: 14),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tentang SiMONA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                  SizedBox(height: 2),
                  Text('Informasi detail dan alur jalannya sistem', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ])),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
              ])),
          ),
          const SizedBox(height: 16),

          _profileSection(
            title: 'Ringkasan Aktivitas', icon: Icons.bar_chart_rounded, color: _teal,
            children: [
              Padding(padding: const EdgeInsets.all(14),
                child: GridView.count(
                  crossAxisCount: 3, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.95,
                  children: [
                    _statBox('Anak',      '$_totalAnak',   _green700),
                    _statBox('Checklist', '$_checklistCount', const Color(0xFFF97316)),
                    _statBox('Anekdot',   '$_anekdotCount',  _purple),
                    _statBox('Karya',     '$_karyaCount',    _teal),
                    _statBox('Absensi',   '$_absensiCount',  _rose),
                    _statBox('Rencana',    '$_rencanaCount',   _navy),
                  ],
                )),
            ]),
          const SizedBox(height: 24),

          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Keluar Akun'),
                  content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                      },
                      child: const Text('Keluar',
                        style: TextStyle(color: _rose, fontWeight: FontWeight.bold))),
                  ])),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _rose.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.logout_rounded, color: _rose, size: 18),
              label: const Text('Keluar Akun',
                style: TextStyle(color: _rose, fontWeight: FontWeight.bold)))),
        ]),
      )),
    ]);
  }

  Widget _buildProfileHero() {
    final namaGuru  = _userData['name']       ?? 'Guru';
    final namaKelas = _userData['nama_kelas'] ?? 'Kelompok A';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_green900, _green700],
          begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Stack(children: [
        Positioned(top: -30, right: -30,
          child: Container(width: 160, height: 160,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle))),
        Align(alignment: Alignment.center,
          child: Padding(padding: const EdgeInsets.only(top: 30),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20)]),
                child: const Icon(Icons.person_rounded, size: 48, color: _green700)),
              const SizedBox(height: 12),
              Text(namaGuru,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('Guru Kelas — $namaKelas',
                  style: const TextStyle(color: Colors.white, fontSize: 12))),
            ]))),
      ]),
    );
  }

  Widget _profileSection({required String title, required IconData icon,
      required Color color, required List<Widget> children}) =>
    Container(
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border(bottom: BorderSide(color: color.withOpacity(0.1)))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16)),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ])),
        ...children,
      ]));

  Widget _profileRow(IconData icon, String label, String value, {bool isLast = false}) =>
    Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(icon, size: 18, color: _green700), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ])),
        ])),
      if (!isLast) Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
    ]);

  Widget _statBox(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.15))),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center),
    ]));
}

// ── Helper Widget ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF14532D)));
}

// ── Data Models ───────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _StatData {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.value, this.icon, this.color);
}

class _AgendaBlock {
  final String time, title;
  final IconData icon;
  final Color color;
  final List<String> subItems;
  const _AgendaBlock(this.time, this.title, this.icon, this.color, this.subItems);
}

class _MenuData {
  final String label;
  final String? badge;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MenuData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });
}

class _ActivityData {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  const _ActivityData(this.icon, this.color, this.title, this.subtitle);
}
