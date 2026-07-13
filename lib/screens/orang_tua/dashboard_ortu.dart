import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../profil_sekolah_screen.dart';

// Import modular tab widgets
import 'tabs/home_tab.dart';
import 'tabs/perkembangan_tab.dart';
import 'tabs/kehadiran_tab.dart';
import 'tabs/rencana_belajar_tab.dart';
import 'tabs/laporan_tab.dart';
import 'tabs/profil_tab.dart';

// Import public subpages & colors
import 'ekstrakurikuler_page.dart';
import 'refleksi_ortu_page.dart';
import '../../theme/colors.dart';

class DashboardOrtu extends StatefulWidget {
  final Map<String, dynamic> user;
  const DashboardOrtu({super.key, required this.user});

  @override
  State<DashboardOrtu> createState() => _DashboardOrtuState();
}

class _DashboardOrtuState extends State<DashboardOrtu>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  // ── Palette ──────────────────────────────────────────────────
  static const Color _orange900 = AppColors.orange900;
  static const Color _orange700 = AppColors.orange700;
  static const Color _orange500 = AppColors.orange500;
  static const Color _bg        = AppColors.bg;
  static const Color _surface   = AppColors.surface;
  static const Color _green     = AppColors.green;
  static const Color _blue      = AppColors.blue;
  static const Color _purple    = AppColors.purple;
  static const Color _rose      = AppColors.rose;
  static const Color _amber     = AppColors.amber;
  static const Color _teal      = AppColors.teal;
  static const Color _slate     = AppColors.slate;

  late AnimationController _fadeCtrl;
  late Animation<double>    _fadeAnim;

  // Data state
  List<dynamic> _anakList = [];
  Map<String, dynamic>? _selectedAnak;
  bool _isLoading = false;

  List<dynamic> _kehadiranList = [];
  Map<String, dynamic> _kehadiranStats = {'Hadir': 0, 'Sakit': 0, 'Izin': 0, 'Alpa': 0};
  int _selectedKehadiranBulan = DateTime.now().month;
  int _selectedKehadiranTahun = DateTime.now().year;
  List<dynamic> _penilaianList = [];       // checklist detail
  List<dynamic> _penilaianSummary = [];    // per-aspek summary
  int _checklistBulan = 1;
  int _checklistMingguIdx = 0;
  String _checklistFilterStatus = 'Semua';

  List<dynamic> _anekdotList = [];
  List<dynamic> _karyaList = [];
  List<dynamic> _ekstraList = [];
  List<dynamic> _refleksiGuruList = [];
  List<dynamic> _refleksiOrtuList = [];


  // Halaman Laporan: Detil Rekap Penilaian State
  int _selectedBulanLaporan = 1;
  int _semesterLaporan = 1;
  bool _isLoadingMonthlyRecap = false;
  Map<String, dynamic> _narasiDataLaporan = {};
  Map<String, dynamic> _kehadiranStatsLaporan = {'Hadir': 0, 'Sakit': 0, 'Izin': 0, 'Alpa': 0};
  List<dynamic> _ekskulListLaporan = [];
  List<dynamic> _rekapKegiatanList = []; // Rekap kegiatan pembelajaran bulanan


  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _initData();
  }

  void _initData() {
    _anakList = widget.user['anak'] ?? [];
    if (_anakList.isNotEmpty) {
      final loginNisn = widget.user['login_nisn']?.toString();
      final match = _anakList.firstWhere(
        (s) => s['nisn']?.toString() == loginNisn,
        orElse: () => null,
      );
      _selectedAnak = match ?? _anakList[0];
      _fetchDataForSelectedAnak();
    }
    _refreshAnakList();
  }

  Future<void> _refreshAnakList() async {
    final userId = widget.user['id'];
    if (userId == null) return;
    try {
      final res = await ApiService.getAnakByOrtu(int.tryParse(userId.toString()) ?? 0);
      if (res['status'] == 'success') {
        final list = res['data'] ?? [];
        if (mounted) {
          setState(() {
            _anakList = list;
            if (_selectedAnak == null && _anakList.isNotEmpty) {
              final loginNisn = widget.user['login_nisn']?.toString();
              final match = _anakList.firstWhere(
                (s) => s['nisn']?.toString() == loginNisn,
                orElse: () => null,
              );
              _selectedAnak = match ?? _anakList[0];
              _fetchDataForSelectedAnak();
            } else if (_selectedAnak != null) {
              final match = _anakList.firstWhere(
                (s) => s['id'].toString() == _selectedAnak!['id'].toString(),
                orElse: () => null,
              );
              if (match != null) _selectedAnak = match;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error refreshing anak: $e');
    }
  }

  Future<void> _fetchDataForSelectedAnak() async {
    if (_selectedAnak == null) return;
    final sId    = int.tryParse(_selectedAnak!['id'].toString()) ?? 0;
    final kelasId = int.tryParse(_selectedAnak!['id_kelas']?.toString() ?? '0') ?? 0;
    if (sId == 0) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      // Kehadiran
      final khRes = await ApiService.getKehadiranOrtu(
        sId,
        bulan: _selectedKehadiranBulan,
        tahun: _selectedKehadiranTahun,
      );
      if (khRes['status'] == 'success') {
        _kehadiranList  = khRes['data'] ?? [];
        _kehadiranStats = khRes['stats'] ?? {'Hadir': 0, 'Sakit': 0, 'Izin': 0, 'Alpa': 0};
      }

      // Checklist penilaian
      final pcRes = await ApiService.getPenilaianOrtu(sId);
      if (pcRes['status'] == 'success') {
        _penilaianList    = pcRes['data']    ?? [];
        _penilaianSummary = pcRes['summary'] ?? [];
      }

      // Anekdot
      final anRes = await ApiService.getAnekdotOrtu(sId);
      if (anRes['status'] == 'success') _anekdotList = anRes['data'] ?? [];

      // Karya
      final karyaRes = await ApiService.getKaryaAnak(sId);
      if (karyaRes['status'] == 'success') _karyaList = karyaRes['data'] ?? [];

      // Ekstrakurikuler
      final ekRes = await ApiService.getEkstrakurikulerAnak(sId);
      if (ekRes['status'] == 'success') _ekstraList = ekRes['data'] ?? [];

      // Refleksi guru (by kelas & anak)
      if (kelasId > 0) {
        final rgRes = await ApiService.getRefleksiGuru(kelasId, idAnak: sId);
        if (rgRes['status'] == 'success') _refleksiGuruList = rgRes['data'] ?? [];
      }

      // Refleksi ortu
      final roRes = await ApiService.getRefleksiOrtu(sId,
          idOrtu: int.tryParse(widget.user['id'].toString()));
      if (roRes['status'] == 'success') _refleksiOrtuList = roRes['data'] ?? [];



      // Load monthly recap details
      await _loadMonthlyRecapForParent();


    } catch (e) {
      debugPrint('Error loading child data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _loadMonthlyRecapForParent() async {
    if (_selectedAnak == null) return;
    final sId = int.tryParse(_selectedAnak!['id'].toString()) ?? 0;
    if (sId == 0) return;

    if (mounted) setState(() => _isLoadingMonthlyRecap = true);

    try {
      final narasiRes = await ApiService.fetch(
        'manage_rekap_bulanan.php?type=narasi_aspek&id_anak=$sId&bulan=$_selectedBulanLaporan&semester=$_semesterLaporan',
      );
      if (narasiRes['status'] == 'success') {
        _narasiDataLaporan = narasiRes['data'] ?? {};
      }

      final kehadiranRes = await ApiService.fetch(
        'get_kehadiran_ortu.php?id_anak=$sId&bulan=$_selectedBulanLaporan&semester=$_semesterLaporan',
      );
      if (kehadiranRes['status'] == 'success') {
        _kehadiranStatsLaporan = Map<String, dynamic>.from(kehadiranRes['stats'] ?? {
          'Hadir': 0,
          'Sakit': 0,
          'Izin': 0,
          'Alpa': 0,
        });
      }

      final ekskulRes = await ApiService.fetch(
        'manage_ekstrakurikuler.php?type=anak-ekstra&id_anak=$sId&semester=$_semesterLaporan',
      );
      if (ekskulRes['status'] == 'success') {
        _ekskulListLaporan = List<dynamic>.from(ekskulRes['data'] ?? []);
      }

      // Rekap kegiatan pembelajaran yang sudah disimpan guru
      final rekapKegRes = await ApiService.fetch(
        'manage_rekap_bulanan.php?type=rekap_kegiatan_ortu&id_anak=$sId&bulan=$_selectedBulanLaporan&semester=$_semesterLaporan',
      );
      if (rekapKegRes['status'] == 'success') {
        _rekapKegiatanList = List<dynamic>.from(rekapKegRes['data'] ?? []);
      } else {
        _rekapKegiatanList = [];
      }

    } catch (e) {
      debugPrint("Error loading parent monthly recap: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMonthlyRecap = false);
    }
  }

  void _showAnakSwitcher() {
    if (_anakList.length <= 1) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pilih Anak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Flexible(child: ListView.builder(
            shrinkWrap: true,
            itemCount: _anakList.length,
            itemBuilder: (_, idx) {
              final s = _anakList[idx];
              final isSelected = _selectedAnak?['id'].toString() == s['id'].toString();
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: isSelected ? _orange500 : Colors.grey.shade200,
                  child: Text(
                    s['nama_anak']?.substring(0, 1).toUpperCase() ?? '?',
                    style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(s['nama_anak'] ?? '',
                    style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF1E293B))),
                subtitle: Text('Kelas: ${s['nama_kelas'] ?? ''} | NISN: ${s['nisn'] ?? ''}'),
                trailing: isSelected ? const Icon(Icons.check_circle, color: _green) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (!isSelected) {
                    setState(() => _selectedAnak = s);
                    _fetchDataForSelectedAnak();
                  }
                },
              );
            },
          )),
        ]),
      ),
    );
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
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(opacity: _fadeAnim, child: _buildBody()),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.home_outlined,             Icons.home_rounded,             'Beranda'),
      _NavItem(Icons.auto_graph_outlined,        Icons.auto_graph_rounded,       'Perkembangan'),
      _NavItem(Icons.calendar_month_outlined,    Icons.calendar_month_rounded,   'Kehadiran'),
      _NavItem(Icons.description_outlined,       Icons.description_rounded,      'Laporan'),
      _NavItem(Icons.person_outline,             Icons.person_rounded,           'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == _currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive ? _orange500.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(isActive ? item.activeIcon : item.icon,
                          color: isActive ? _orange700 : _slate, size: 22),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(item.label, style: TextStyle(
                          fontSize: 9,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? _orange700 : _slate,
                        )),
                      ),
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
    switch (_currentIndex) {
      case 0:
        return HomeTab(
          user: widget.user,
          selectedAnak: _selectedAnak,
          anakList: _anakList,
          kehadiranStats: _kehadiranStats,
          penilaianSummary: _penilaianSummary,
          anekdotList: _anekdotList,
          ekstraList: _ekstraList,
          isLoading: _isLoading,
          onRefresh: _fetchDataForSelectedAnak,
          onMenuTap: _onTabTap,
          onAnakSwitcherTap: _showAnakSwitcher,
          onEkstraTap: _openEkstrakurikuler,
          onRefleksiTap: _openRefleksiOrtu,
        );
      case 1:
        return PerkembanganTab(
          selectedAnak: _selectedAnak,
          checklistBulan: _checklistBulan,
          checklistMingguIdx: _checklistMingguIdx,
          checklistFilterStatus: _checklistFilterStatus,
          checklistList: _penilaianList,
          anekdotList: _anekdotList,
          karyaList: _karyaList,
          isLoading: _isLoading,
          onRefresh: _fetchDataForSelectedAnak,
          onBulanSelected: (b) {
            setState(() {
              _checklistBulan = b;
              _checklistMingguIdx = 0;
            });
          },
          onMingguIdxSelected: (w) {
            setState(() {
              _checklistMingguIdx = w;
            });
          },
          onStatusFilterSelected: (s) {
            setState(() {
              _checklistFilterStatus = s;
            });
          },
        );
      case 2:
        return KehadiranTab(
          selectedAnak: _selectedAnak,
          selectedKehadiranBulan: _selectedKehadiranBulan,
          selectedKehadiranTahun: _selectedKehadiranTahun,
          kehadiranStats: _kehadiranStats,
          kehadiranList: _kehadiranList,
          isLoading: _isLoading,
          onMonthPrev: () {
            setState(() {
              if (_selectedKehadiranBulan == 1) {
                _selectedKehadiranBulan = 12;
                _selectedKehadiranTahun--;
              } else {
                _selectedKehadiranBulan--;
              }
            });
            _fetchKehadiranOnly();
          },
          onMonthNext: () {
            setState(() {
              if (_selectedKehadiranBulan == 12) {
                _selectedKehadiranBulan = 1;
                _selectedKehadiranTahun++;
              } else {
                _selectedKehadiranBulan++;
              }
            });
            _fetchKehadiranOnly();
          },
          onMonthPickerTap: _showMonthYearPicker,
        );
      case 3:
        return LaporanTab(
          anak: _selectedAnak,
          selectedBulan: _selectedBulanLaporan,
          semester: _semesterLaporan,
          narasiData: _narasiDataLaporan,
          kehadiranStats: _kehadiranStatsLaporan,
          ekskulList: _ekskulListLaporan,
          checklistRingkasan: _penilaianSummary,
          anekdotList: _anekdotList,
          karyaList: _karyaList,
          rekapKegiatanList: _rekapKegiatanList,
          isLoading: _isLoading,
          isLoadingMonthlyRecap: _isLoadingMonthlyRecap,
          onRefresh: _fetchDataForSelectedAnak,
          onSemesterSelected: (sem) {
            setState(() {
              _semesterLaporan = sem;
              _selectedBulanLaporan = 1;
              _rekapKegiatanList = [];
            });
            _loadMonthlyRecapForParent();
          },
          onBulanSelected: (b) {
            setState(() {
              _selectedBulanLaporan = b;
              _rekapKegiatanList = [];
            });
            _loadMonthlyRecapForParent();
          },
        );
      case 4:
        return ProfilTab(
          user: widget.user,
          anakList: _anakList,
          onLogout: _handleLogout,
          onChangePasswordTap: _showChangePasswordBottomSheet,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  HALAMAN PROFIL (tab 5) helpers & actions
  // ═══════════════════════════════════════════════════════════════
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _rose,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordBottomSheet() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confPassCtrl = TextEditingController();
    
    bool showOld = false;
    bool showNew = false;
    bool showConf = false;
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Ganti Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Silakan masukkan password lama Anda dan password baru yang ingin digunakan.',
                        style: TextStyle(
                          fontSize: 13,
                          color: _slate,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Password Lama
                      TextFormField(
                        controller: oldPassCtrl,
                        obscureText: !showOld,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Password Lama',
                          labelStyle: const TextStyle(color: _slate, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: _orange700),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showOld ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: _slate,
                              size: 20,
                            ),
                            onPressed: () => setModalState(() => showOld = !showOld),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _orange700, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Password lama wajib diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password Baru
                      TextFormField(
                        controller: newPassCtrl,
                        obscureText: !showNew,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Password Baru',
                          labelStyle: const TextStyle(color: _slate, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: _orange700),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: _slate,
                              size: 20,
                            ),
                            onPressed: () => setModalState(() => showNew = !showNew),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _orange700, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Password baru wajib diisi';
                          if (v.trim().length < 6) return 'Password baru minimal 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Konfirmasi Password
                      TextFormField(
                        controller: confPassCtrl,
                        obscureText: !showConf,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password Baru',
                          labelStyle: const TextStyle(color: _slate, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: _orange700),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showConf ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: _slate,
                              size: 20,
                            ),
                            onPressed: () => setModalState(() => showConf = !showConf),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _orange700, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Konfirmasi password wajib diisi';
                          if (v.trim() != newPassCtrl.text.trim()) return 'Konfirmasi password tidak cocok';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Tombol Simpan
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSaving = true);
                            try {
                              final id = int.tryParse(widget.user['id'].toString()) ?? 0;
                              final res = await ApiService.postData('change_password.php', {
                                'id': id,
                                'old_password': oldPassCtrl.text.trim(),
                                'new_password': newPassCtrl.text.trim(),
                              });

                              if (!mounted) return;

                              if (res['status'] == 'success') {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Password berhasil diperbarui ✓'),
                                    backgroundColor: _green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              } else {
                                setModalState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Gagal mengubah password'),
                                    backgroundColor: _rose,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: _rose,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Perbarui Password',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      oldPassCtrl.dispose();
      newPassCtrl.dispose();
      confPassCtrl.dispose();
    });
  }

  Future<void> _fetchKehadiranOnly() async {
    if (_selectedAnak == null) return;
    final sId = int.tryParse(_selectedAnak!['id'].toString()) ?? 0;
    if (sId == 0) return;
    try {
      final khRes = await ApiService.getKehadiranOrtu(
        sId,
        bulan: _selectedKehadiranBulan,
        tahun: _selectedKehadiranTahun,
      );
      if (khRes['status'] == 'success') {
        if (mounted) {
          setState(() {
            _kehadiranList  = khRes['data'] ?? [];
            _kehadiranStats = khRes['stats'] ?? {'Hadir': 0, 'Sakit': 0, 'Izin': 0, 'Alpa': 0};
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching kehadiran: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  SUB-HALAMAN: Ekstrakurikuler
  // ═══════════════════════════════════════════════════════════════
  void _openEkstrakurikuler() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EkstrakurikulerPage(
        anakName: _selectedAnak?['nama_anak'] ?? '-',
        ekstraList: _ekstraList,
        onRefresh: _fetchDataForSelectedAnak,
      )),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SUB-HALAMAN: Refleksi Orang Tua
  // ═══════════════════════════════════════════════════════════════
  void _openRefleksiOrtu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RefleksiOrtuPage(
        user: widget.user,
        selectedAnak: _selectedAnak,
        refleksiGuruList: _refleksiGuruList,
        refleksiOrtuList: _refleksiOrtuList,
        semester: _semesterLaporan,
        onRefresh: _fetchDataForSelectedAnak,
      )),
    );
  }

  void _showMonthYearPicker() {
    int tempBulan = _selectedKehadiranBulan;
    int tempTahun = _selectedKehadiranTahun;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih Bulan & Tahun',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tahun',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _slate),
                        ),
                        DropdownButton<int>(
                          value: tempTahun,
                          dropdownColor: _surface,
                          items: List.generate(5, (index) => DateTime.now().year - 3 + index)
                              .map((y) => DropdownMenuItem(
                                    value: y,
                                    child: Text('$y', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => tempTahun = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1.5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final bulanNum = index + 1;
                        final isSelected = tempBulan == bulanNum;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => tempBulan = bulanNum);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? _orange700 : _orange500.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _orange700 : Colors.grey.shade200,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _namaBulanShort(bulanNum),
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedKehadiranBulan = tempBulan;
                            _selectedKehadiranTahun = tempTahun;
                          });
                          _fetchKehadiranOnly();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Terapkan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _namaBulanShort(int n) {
    switch (n) {
      case 1: return 'Jan';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Apr';
      case 5: return 'Mei';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Agt';
      case 9: return 'Sep';
      case 10: return 'Okt';
      case 11: return 'Nov';
      case 12: return 'Des';
      default: return '-';
    }
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

