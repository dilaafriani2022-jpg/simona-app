import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/api_service.dart';

class PenilaianChecklistScreen extends StatefulWidget {
  final int? idGuru;
  final int? idKelas;
  final int? idAnak;
  final bool isReadOnly;
  const PenilaianChecklistScreen({super.key, this.idGuru, this.idKelas, this.idAnak, this.isReadOnly = false});

  @override
  State<PenilaianChecklistScreen> createState() =>
      _PenilaianChecklistScreenState();
}

class _PenilaianChecklistScreenState extends State<PenilaianChecklistScreen>
    with TickerProviderStateMixin {
  // ── Palet warna hangat & elegan ───────────────────────────────────────────
  static const Color _primary = Color(0xFFC17B2F);
  static const Color _primaryDark = Color(0xFFA0601A);
  static const Color _navy = Color(0xFF1E3A8A);
  static const Color _bg = Color(0xFFFDF8F3);
  static const Color _cardBorder = Color(0xFFF0E8DF);
  static const Color _surface = Colors.white;
  static const Color _slate = Color(0xFF64748B);
  static const Color _red = Color(0xFFDC2626);
  static const Color _green = Color(0xFF059669);
  static const Color _teal = Color(0xFF0891B2);
  static const Color _amber = Color(0xFFF59E0B);

  // ── Konfigurasi status penilaian (TM / MM / M) ───────────────────────────
  static const Map<String, _StatusCfg> _statusCfg = {
    'TM': _StatusCfg(
      'Tidak Muncul',
      Color(0xFFDC2626),
      Color(0xFFFEF2F2),
      '😟',
    ),
    'MM': _StatusCfg(
      'Mulai Muncul',
      Color(0xFFF59E0B),
      Color(0xFFFFFBEB),
      '🙂',
    ),
    'M': _StatusCfg('Muncul', Color(0xFF059669), Color(0xFFD1FAE5), '🌟'),
  };

  // ── State ─────────────────────────────────────────────────────────────────
  late TabController _bulanTabCtrl;
  late TabController _mingguTabCtrl;
  List<dynamic> _penilaianList = [];
  List<dynamic> _aspekList = [];
  List<dynamic> _anakList = [];
  List<dynamic> _tujuanList = [];
  List<dynamic> _kegiatanList = [];
  List<dynamic> _prosemList = [];

  // Total 18 minggu: Bulan 1-4 = 4 minggu each (1-16), Bulan 5 = 2 minggu (17-18)
  static const int _totalBulan = 5;
  static const int _mingguPerBulanDefault = 4;

  /// Jumlah minggu per bulan (Bulan 5 hanya 2 minggu)
  static int _weeksForBulan(int bulan) => bulan == 5 ? 2 : 4;

  /// Minggu absolut pertama dalam sebuah bulan
  static int _startWeekOfBulan(int bulan) =>
      bulan <= 1 ? 1 : (bulan - 1) * _mingguPerBulanDefault + 1;

  int _selectedBulan = 1; // 1-based
  int _selectedMingguIdx = 0; // 0-based (0=Minggu 1, 1=Minggu 2, ...)

  bool _isLoading = true;
  String _filterStatus = 'Semua';
  String _filterAspek = '';
  String _searchQuery = '';

  final _searchCtrl = TextEditingController();

  // ════════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    // Bulan tab (1..._totalBulan)
    _bulanTabCtrl = TabController(length: _totalBulan, vsync: this);
    _bulanTabCtrl.addListener(() {
      if (!_bulanTabCtrl.indexIsChanging) {
        final newBulan = _bulanTabCtrl.index + 1;
        _rebuildMingguTab(newBulan);
        setState(() {
          _selectedBulan = newBulan;
          _selectedMingguIdx = 0;
          _filterAspek = '';
          _searchQuery = '';
          _searchCtrl.clear();
        });
      }
    });
    // Minggu tab — panjangnya dinamis tergantung bulan
    _mingguTabCtrl = TabController(
        length: _weeksForBulan(_selectedBulan), vsync: this);
    _mingguTabCtrl.addListener(() {
      if (!_mingguTabCtrl.indexIsChanging) {
        setState(() => _selectedMingguIdx = _mingguTabCtrl.index);
      }
    });
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );
    _loadAll();
  }

  @override
  void dispose() {
    _bulanTabCtrl.dispose();
    _mingguTabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DATA LOADING
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadPenilaian(), _loadAspek(), _loadAnak(), _loadTujuan(), _loadKegiatan(), _loadProsemList()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadPenilaian() async {
    try {
      final idAnakParam = widget.idAnak != null ? '&id_anak=${widget.idAnak}' : '';
      final res = await ApiService.fetch(
        'manage_penilaian.php?id_guru=${widget.idGuru ?? 2}$idAnakParam',
      );
      if (res['status'] == 'success') {
        _penilaianList = List<dynamic>.from(res['data'] ?? []);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadAspek() async {
    try {
      final res = await ApiService.fetch('manage_aspek.php');
      if (res['status'] == 'success') {
        _aspekList = List<dynamic>.from(res['data'] ?? []);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadAnak() async {
    try {
      final idKelas = widget.idKelas ?? 2;
      final res = await ApiService.fetch('manage_anak.php?id_kelas=$idKelas');
      if (res['status'] == 'success') {
        _anakList = List<dynamic>.from(res['data'] ?? []);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadTujuan() async {
    try {
      final res = await ApiService.fetch(
        'manage_tujuan_pembelajaran.php?id_guru=${widget.idGuru ?? 2}',
      );
      if (res['status'] == 'success') {
        _tujuanList = List<dynamic>.from(res['data'] ?? []);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadKegiatan() async {
    try {
      final res = await ApiService.fetch(
        'manage_kegiatan_pembelajaran.php?id_guru=${widget.idGuru ?? 2}',
      );
      if (res['status'] == 'success') {
        _kegiatanList = List<dynamic>.from(res['data'] ?? []);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadProsemList() async {
    try {
      final idKelas = widget.idKelas ?? 2;
      final res1 = await ApiService.fetch('manage_prosem.php?id_kelas=$idKelas&semester=1');
      final res2 = await ApiService.fetch('manage_prosem.php?id_kelas=$idKelas&semester=2');
      List<dynamic> combined = [];
      if (res1['status'] == 'success' && res1['data'] != null) {
        combined.addAll(res1['data']);
      }
      if (res2['status'] == 'success' && res2['data'] != null) {
        combined.addAll(res2['data']);
      }
      _prosemList = combined;
    } catch (e) {
      debugPrint("Error loading prosem list: $e");
    }
  }

  dynamic _findProsemWeekByDate(String dateStr) {
    if (_prosemList.isEmpty || dateStr.isEmpty) return null;
    try {
      final date = DateTime.parse(dateStr);
      for (final prosem in _prosemList) {
        final startStr = prosem['tanggal_mulai']?.toString() ?? '';
        final endStr = prosem['tanggal_selesai']?.toString() ?? '';
        if (startStr.isNotEmpty && endStr.isNotEmpty) {
          final start = DateTime.parse(startStr);
          final end = DateTime.parse(endStr);
          final compareDate = DateTime(date.year, date.month, date.day);
          final compareStart = DateTime(start.year, start.month, start.day);
          final compareEnd = DateTime(end.year, end.month, end.day);
          
          if ((compareDate.isAfter(compareStart) || compareDate.isAtSameMomentAs(compareStart)) &&
              (compareDate.isBefore(compareEnd) || compareDate.isAtSameMomentAs(compareEnd))) {
            return prosem;
          }
        }
      }
    } catch (e) {
      debugPrint("Error finding prosem week: $e");
    }
    return null;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CRUD
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _savePenilaian(Map<String, dynamic> payload) async {
    try {
      final requestPayload = {
        'action': 'add',
        'id_guru': widget.idGuru ?? 2,
        ...payload,
      };
      debugPrint('📤 SAVE REQUEST: $requestPayload');
      final res = await ApiService.post('manage_penilaian.php', requestPayload);
      debugPrint('📥 SAVE RESPONSE: $res');
      if (!mounted) return;
      if (res['status'] == 'success') {
        await _loadAll();
        _snackOk('Penilaian berhasil ditambahkan');
      } else {
        _snackErr(res['message'] ?? 'Gagal menyimpan');
      }
    } catch (e) {
      debugPrint('❌ SAVE ERROR: $e');
      if (mounted) _snackErr('Error: $e');
    }
  }

  Future<void> _updatePenilaian(int id, Map<String, dynamic> payload) async {
    try {
      final requestPayload = {'action': 'update', 'id': id, ...payload};
      debugPrint('📤 UPDATE REQUEST: $requestPayload');
      final res = await ApiService.post('manage_penilaian.php', requestPayload);
      debugPrint('📥 UPDATE RESPONSE: $res');
      if (!mounted) return;
      if (res['status'] == 'success') {
        await _loadAll();
        _snackOk('Penilaian berhasil diperbarui');
      } else {
        _snackErr(res['message'] ?? 'Gagal memperbarui');
      }
    } catch (e) {
      debugPrint('❌ UPDATE ERROR: $e');
      if (mounted) _snackErr('Error: $e');
    }
  }

  Future<void> _deletePenilaian(int id, String namaAnak) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: _red,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Hapus Penilaian?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF8F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              color: _primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              namaAnak,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tindakan ini tidak dapat dibatalkan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  color: _slate,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: const Text(
                                'Hapus',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );

    if (confirmed != true || !mounted) return;
    try {
      final res = await ApiService.post('manage_penilaian.php', {
        'action': 'delete',
        'id': id,
      });
      if (!mounted) return;
      if (res['status'] == 'success') {
        await _loadAll();
        _snackOk('Penilaian berhasil dihapus');
      } else {
        _snackErr(res['message'] ?? 'Gagal menghapus');
      }
    } catch (e) {
      if (mounted) _snackErr('Error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SNACKBAR
  // ════════════════════════════════════════════════════════════════════════════

  void _snackOk(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor: _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  void _snackErr(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // ════════════════════════════════════════════════════════════════════════════
  // FILTER
  // ════════════════════════════════════════════════════════════════════════════

  // Compute absolute minggu number from selected bulan + minggu index within bulan
  /// Rebuild _mingguTabCtrl sesuai jumlah minggu bulan yang dipilih
  void _rebuildMingguTab(int bulan) {
    final oldCtrl = _mingguTabCtrl;
    _mingguTabCtrl = TabController(
        length: _weeksForBulan(bulan), vsync: this);
    _mingguTabCtrl.addListener(() {
      if (!_mingguTabCtrl.indexIsChanging) {
        setState(() => _selectedMingguIdx = _mingguTabCtrl.index);
      }
    });
    oldCtrl.dispose();
  }

  int get _currentMinggu =>
      _startWeekOfBulan(_selectedBulan) + _selectedMingguIdx;

  List<dynamic> get _filtered =>
      _penilaianList.where((item) {
        final mingguAbs =
            int.tryParse(item['minggu_ke']?.toString() ?? '0') ?? 0;
        // Tentukan bulan berdasarkan tabel minggu absolut
        // Bulan 1-4: 4 minggu each; Bulan 5: 2 minggu
        int itemBulan;
        if (mingguAbs >= 17) {
          itemBulan = 5;
        } else if (mingguAbs > 0) {
          itemBulan = ((mingguAbs - 1) ~/ 4) + 1;
        } else {
          itemBulan = 1;
        }
        final startW = _startWeekOfBulan(itemBulan);
        final itemMingguDalamBulan = mingguAbs - startW + 1;
        final nama = (item['nama_anak'] ?? '').toString().toLowerCase();
        final aspek = (item['nama_aspek'] ?? '').toString().toLowerCase();
        final status = item['status']?.toString() ?? '';
        final matchBulan = itemBulan == _selectedBulan;
        final matchMinggu =
            itemMingguDalamBulan == (_selectedMingguIdx + 1);
        final matchQ =
            _searchQuery.isEmpty ||
            nama.contains(_searchQuery) ||
            aspek.contains(_searchQuery);
        final matchS =
            _filterStatus == 'Semua' || status == _filterStatus;
        final matchA =
            _filterAspek.isEmpty ||
            item['id_aspek'].toString() == _filterAspek;
        return matchBulan && matchMinggu && matchQ && matchS && matchA;
      }).toList();

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Penilaian Checklist',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _bulanTabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: List.generate(_totalBulan, (i) {
            final bulanNum = i + 1;
            final startMinggu = _startWeekOfBulan(bulanNum);
            final endMinggu = startMinggu + _weeksForBulan(bulanNum) - 1;
            final count = _penilaianList.where((item) {
              final mg =
                  int.tryParse(item['minggu_ke']?.toString() ?? '0') ?? 0;
              return mg >= startMinggu && mg <= endMinggu;
            }).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bulan $bulanNum (Minggu $startMinggu-$endMinggu)'),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$count',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      ),

      body: Column(
        children: [
          // ── Sub-header: Stat chips + Minggu tabs ─────────────────────────
          Container(
            color: _primaryDark,
            child: Column(
              children: [
                // Stat chips row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      _statChip(
                        '${_penilaianList.length}',
                        'Total',
                        Icons.assignment_rounded,
                        const Color(0xFFFFE0A3),
                      ),
                      const SizedBox(width: 8),
                      ..._statusCfg.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _statChip(
                            '${_penilaianList.where((item) => item['status'] == e.key).length}',
                            e.key,
                            null,
                            e.value.color,
                            emoji: e.value.emoji,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Minggu tabs within selected bulan
                TabBar(
                  controller: _mingguTabCtrl,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: List.generate(_weeksForBulan(_selectedBulan), (i) {
                    final mingguAbs = _startWeekOfBulan(_selectedBulan) + i;
                    final count = _penilaianList.where((item) {
                      final mg = int.tryParse(
                              item['minggu_ke']?.toString() ?? '0') ??
                          0;
                      return mg == mingguAbs;
                    }).length;
                    return Tab(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Minggu $mingguAbs'),
                          if (count > 0)
                            Text('($count)',
                                style: const TextStyle(fontSize: 9)),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // ── Info bar: Bulan N • Minggu M overall ──────────────────────────
          Container(
            color: const Color(0xFFF5EEE6),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: _primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Bulan $_selectedBulan  •  Minggu $_currentMinggu',
                  style: TextStyle(
                      fontSize: 12,
                      color: _primary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // ── Search ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nama anak atau aspek...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _primary,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: Colors.grey.shade400),
                          onPressed: _searchCtrl.clear,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ── Status filter chips (Semua/TM/MM/M) ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _statusFilterChip('Semua'),
                  ..._statusCfg.entries.map(
                    (e) => _statusFilterChip(e.key, emoji: e.value.emoji),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),

          // ── Aspek filter chips ────────────────────────────────────────────
          if (_aspekList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 0, 0),
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('Semua Aspek', ''),
                    ..._aspekList.map(
                      (a) => _filterChip(
                        a['nama_aspek'] ?? '-',
                        a['id'].toString(),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),

          // ── Counter ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${filtered.length} Data Penilaian',
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _primary))
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    color: _primary,
                    child: filtered.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: 260,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 64,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'Belum ada penilaian untuk\nBulan $_selectedBulan · Minggu ${_selectedMingguIdx + 1}'
                                            : 'Data tidak ditemukan',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_searchQuery.isEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tekan + untuk menambah penilaian',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _buildCard(filtered[i]),
                          ),
                  ),
          ),
        ],
      ),

      floatingActionButton: widget.isReadOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: _isLoading ? null : () => _showFormSheet(),
              backgroundColor: _primary,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Tambah Penilaian',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CARD PENILAIAN
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildCard(dynamic item) {
    final statusKey = item['status']?.toString() ?? 'TM';
    final cfg = _statusCfg[statusKey] ?? _statusCfg['TM']!;
    final nama = item['nama_anak']?.toString() ?? '-';
    final initials =
        nama.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: cfg.color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailSheet(item),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Avatar + info + menu
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: cfg.bgColor,
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: cfg.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.category_rounded,
                                size: 12,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item['nama_aspek'] ?? '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: Colors.grey.shade400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      itemBuilder:
                          (_) => [
                            _popItem(
                              'detail',
                              Icons.visibility_rounded,
                              'Lihat Detail',
                              _navy.withOpacity(0.08),
                              _navy,
                            ),
                            _popItem(
                              'edit',
                              Icons.edit_rounded,
                              'Edit',
                              Colors.blue.shade50,
                              Colors.blue.shade600,
                            ),
                            const PopupMenuDivider(),
                            _popItem(
                              'delete',
                              Icons.delete_outline_rounded,
                              'Hapus',
                              Colors.red.shade50,
                              _red,
                              isRed: true,
                            ),
                          ],
                      onSelected: (val) {
                        if (val == 'detail') _showDetailSheet(item);
                        if (val == 'edit') _showFormSheet(item: item);
                        if (val == 'delete')
                          _deletePenilaian(
                            int.parse(item['id'].toString()),
                            nama,
                          );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 10),

                // Row 2: Status + tanggal + semester
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: cfg.bgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cfg.color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cfg.emoji, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(
                            statusKey,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: cfg.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: _slate,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _fmtTgl(item['tanggal']),
                            style: TextStyle(
                              fontSize: 11,
                              color: _slate,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item['semester'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _navy.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Sem ${item['semester']} · Mg ${item['minggu_ke'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 10,
                            color: _navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                // Kegiatan Pembelajaran & Catatan
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.gps_fixed_rounded, size: 13, color: const Color(0xFF8B5E3C)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.35),
                                children: [
                                  const TextSpan(text: 'Tujuan: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: item['nama_tujuan']?.toString() ?? '-'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.play_lesson_rounded, size: 13, color: _primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.35),
                                children: [
                                  const TextSpan(text: 'Kegiatan: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: item['nama_kegiatan']?.toString() ?? '-'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((item['catatan'] ?? '').toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.comment_rounded, size: 13, color: _slate),
                            const SizedBox(width: 6),
                            Expanded(
                              child: RichText(
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
                                  children: [
                                    const TextSpan(text: 'Catatan Pembelajaran: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: item['catatan'].toString()),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Row 3: Konteks / Hasil (preview)
                if ((item['konteks'] ?? '').toString().isNotEmpty ||
                    (item['hasil'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((item['konteks'] ?? '').toString().isNotEmpty)
                          _previewRow(
                            Icons.info_outline_rounded,
                            'Konteks',
                            item['konteks'].toString(),
                          ),
                        if ((item['hasil'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _previewRow(
                            Icons.check_circle_outline_rounded,
                            'Hasil',
                            item['hasil'].toString(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Row 4: Label status lengkap
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cfg.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_rounded, size: 11, color: cfg.color),
                      const SizedBox(width: 4),
                      Text(
                        cfg.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: cfg.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewRow(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 12, color: _primary),
      const SizedBox(width: 6),
      Text(
        '$label: ',
        style: TextStyle(
          fontSize: 11,
          color: _primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  // ════════════════════════════════════════════════════════════════════════════
  // DETAIL SHEET
  // ════════════════════════════════════════════════════════════════════════════

  void _showDetailSheet(dynamic item) {
    final statusKey = item['status']?.toString() ?? 'TM';
    final cfg = _statusCfg[statusKey] ?? _statusCfg['TM']!;
    final nama = item['nama_anak']?.toString() ?? '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.92,
            builder:
                (ctx2, scroll) => Container(
                  decoration: const BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cfg.color, cfg.color.withOpacity(0.75)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(
                                  cfg.emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nama,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['nama_aspek'] ?? '-',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$statusKey — ${cfg.label}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        _sectionTitle('Tujuan Pembelajaran (TP)'),
                        const SizedBox(height: 8),
                        _textBox(item['nama_tujuan']?.toString() ?? '-', const Color(0xFF8B5E3C)),
                        const SizedBox(height: 14),

                        _sectionTitle('Kegiatan Pembelajaran (KP)'),
                        const SizedBox(height: 8),
                        _textBox(item['nama_kegiatan']?.toString() ?? '-', _primary),
                        const SizedBox(height: 14),

                        _sectionTitle('Informasi Penilaian'),
                        const SizedBox(height: 10),
                        _detailCard(
                          children: [
                            _dRow(
                              Icons.calendar_today_rounded,
                              'Tanggal',
                              _fmtTgl(item['tanggal']),
                            ),
                            _dRow(
                              Icons.school_rounded,
                              'Semester',
                              'Semester ${item['semester'] ?? '-'}',
                            ),
                            _dRow(
                              Icons.view_week_rounded,
                              'Minggu ke',
                              '${item['minggu_ke'] ?? '-'}',
                            ),
                            _dRow(
                              Icons.person_rounded,
                              'Dicatat oleh',
                              item['nama_guru'] ?? '-',
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        if ((item['konteks'] ?? '').toString().isNotEmpty) ...[
                          _sectionTitle('Konteks / Situasi'),
                          const SizedBox(height: 8),
                          _textBox(item['konteks'].toString(), _primary),
                          const SizedBox(height: 14),
                        ],

                        if ((item['hasil'] ?? '').toString().isNotEmpty) ...[
                          _sectionTitle('Hasil Penilaian (CP)'),
                          const SizedBox(height: 8),
                          _textBox(item['hasil'].toString(), _green),
                          const SizedBox(height: 14),
                        ],

                        if ((item['kejadian'] ?? '').toString().isNotEmpty) ...[
                          _sectionTitle('Kejadian / Cerita Anak'),
                          const SizedBox(height: 8),
                          _textBox(
                            item['kejadian'].toString(),
                            const Color(0xFF7C3AED),
                          ),
                          const SizedBox(height: 14),
                        ],

                        _sectionTitle('Catatan Pembelajaran'),
                        const SizedBox(height: 8),
                        _textBox(
                          (item['catatan'] ?? '').toString().trim().isNotEmpty
                              ? item['catatan'].toString()
                              : 'Tidak ada catatan pembelajaran tambahan.',
                          _slate,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Tutup',
                                  style: TextStyle(color: _slate),
                                ),
                              ),
                            ),
                            if (!widget.isReadOnly) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showFormSheet(item: item);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FORM SHEET — Tambah & Edit
  // ════════════════════════════════════════════════════════════════════════════

  void _showFormSheet({dynamic item}) {
    final bool isEditing = item != null;

    int? selectedAnak =
        isEditing ? int.tryParse(item['id_anak'].toString()) : null;
    int? selectedAspek =
        isEditing ? int.tryParse(item['id_aspek'].toString()) : null;
    int? selectedTujuan =
        isEditing ? int.tryParse(item['id_tujuan'].toString()) : null;
    int? selectedKegiatan =
        isEditing ? int.tryParse(item['id_kegiatan'].toString()) : null;
    String selectedStatus =
        isEditing ? (item['status']?.toString() ?? 'TM') : 'TM';
    String selectedSem =
        isEditing ? (item['semester']?.toString() ?? '1') : '1';
    String selectedMinggu =
        isEditing
            ? (item['minggu_ke']?.toString() ?? '1')
            : _currentMinggu.toString();
    String tanggal =
        isEditing
            ? (item['tanggal']?.toString() ??
                DateFormat('yyyy-MM-dd').format(DateTime.now()))
            : DateFormat('yyyy-MM-dd').format(DateTime.now());

    final konteksCtrl = TextEditingController(
      text: isEditing ? (item['konteks'] ?? '') : '',
    );
    final hasilCtrl = TextEditingController(
      text: isEditing ? (item['hasil'] ?? '') : '',
    );
    final kejadianCtrl = TextEditingController(
      text: isEditing ? (item['kejadian'] ?? '') : '',
    );
    final catatanCtrl = TextEditingController(
      text: isEditing ? (item['catatan'] ?? '') : '',
    );

    bool isSaving = false;
    int step = 0;

    const stepTitles = [
      'Pilih Anak & Aspek',
      'Tujuan Pembelajaran',
      'Kegiatan Pembelajaran',
      'Waktu Penilaian',
      'Status Penilaian',
      'Narasi & Catatan',
    ];
    const stepIcons = [
      Icons.person_rounded,
      Icons.gps_fixed_rounded,
      Icons.assignment_rounded,
      Icons.calendar_today_rounded,
      Icons.bar_chart_rounded,
      Icons.notes_rounded,
    ];
    final stepColors = [_navy, const Color(0xFF8B5E3C), _green, _primary, _amber, _teal];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setSheet) {
              final mingguInt = int.tryParse(selectedMinggu) ?? 1;
              final formBulan = mingguInt >= 17 ? 5 : ((mingguInt - 1) ~/ 4) + 1;
              final formMinggu = mingguInt - _startWeekOfBulan(formBulan) + 1;

              // ── Step 0: Anak & Aspek ────────────────────────────────────────
              Widget buildStep0() {
                // Auto-select aspek jika hanya ada 1
                if (_aspekList.isNotEmpty && 
                    _aspekList.length == 1 && 
                    selectedAspek == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setSheet(() {
                      selectedAspek = int.tryParse(_aspekList[0]['id'].toString());
                    });
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fLabel('Pilih Anak *'),
                    _fDrop(
                      value: selectedAnak?.toString(),
                      hint: 'Cari dan pilih anak...',
                      icon: Icons.child_care_rounded,
                      items:
                          _anakList
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s['id'].toString(),
                                  child: Text(
                                    s['nama_anak'] ?? s['name'] ?? '-',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (v) => setSheet(
                            () => selectedAnak = int.tryParse(v ?? ''),
                          ),
                    ),
                    const SizedBox(height: 16),
                    _fLabel('Aspek Penilaian *'),
                    _fDrop(
                      value: selectedAspek?.toString(),
                      hint: 'Pilih aspek penilaian',
                      icon: Icons.category_rounded,
                      items:
                          _aspekList
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a['id'].toString(),
                                  child: Text(
                                    a['nama_aspek'] ?? '-',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (v) => setSheet(
                            () {
                              selectedAspek = int.tryParse(v ?? '');
                              selectedTujuan = null;
                              selectedKegiatan = null;
                            },
                          ),
                    ),
                    if (selectedAnak != null) ...[
                      const SizedBox(height: 14),
                      Builder(
                        builder: (_) {
                          final s = _anakList.firstWhere(
                            (e) => e['id'].toString() == selectedAnak.toString(),
                            orElse: () => null,
                          );
                          if (s == null) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _green.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _green.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                backgroundColor: _green.withOpacity(0.15),
                                child: Text(
                                  (s['nama_anak'] ?? 'S')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: _green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s['nama_anak'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'NISN: ${s['nisn'] ?? '-'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.check_circle_rounded,
                                color: _green,
                                size: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              );
              }

              // ── Step 1: Tujuan Pembelajaran ────────────────────────────────
              Widget buildStep1() {
                final mingguInt = int.tryParse(selectedMinggu) ?? 1;
                final formBulan = mingguInt >= 17 ? 5 : ((mingguInt - 1) ~/ 4) + 1;

                final tujuanForAspek = selectedAspek == null
                    ? []
                    : _tujuanList
                        .where((t) =>
                            t['id_aspek'].toString() == selectedAspek.toString() &&
                            (int.tryParse(t['bulan']?.toString() ?? '1') ?? 1) == formBulan)
                        .toList();

                // Auto-select jika hanya ada 1 tujuan
                if (tujuanForAspek.isNotEmpty &&
                    tujuanForAspek.length == 1 &&
                    selectedTujuan == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setSheet(() {
                      selectedTujuan = int.tryParse(tujuanForAspek[0]['id'].toString());
                    });
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fLabel('Tujuan Pembelajaran *'),
                    if (tujuanForAspek.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Belum ada tujuan untuk aspek ini di Bulan $formBulan',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _fDrop(
                        value: selectedTujuan?.toString(),
                        hint: 'Pilih tujuan pembelajaran',
                        icon: Icons.gps_fixed_rounded,
                        items: tujuanForAspek
                            .map(
                              (t) => DropdownMenuItem(
                                value: t['id'].toString(),
                                child: Text(
                                  t['nama_tujuan'] ?? '-',
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setSheet(() {
                            selectedTujuan = int.tryParse(v ?? '');
                            selectedKegiatan = null; // Reset kegiatan selection
                          });
                        },
                      ),
                    if (selectedTujuan != null) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (_) {
                          final t = tujuanForAspek.firstWhere(
                            (e) =>
                                e['id'].toString() ==
                                selectedTujuan.toString(),
                            orElse: () => null,
                          );
                          if (t == null) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5E3C).withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF8B5E3C).withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5E3C)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.gps_fixed_rounded,
                                        color: const Color(0xFF8B5E3C),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        t['nama_tujuan'] ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if ((t['indikator'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Indikator:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t['indikator'] ?? '-',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                );
              }

              // ── Step 2: Kegiatan Pembelajaran ───────────────────────────────
              Widget buildStep2() {
                final mingguInt = int.tryParse(selectedMinggu) ?? 1;
                final formBulan = mingguInt >= 17 ? 5 : ((mingguInt - 1) ~/ 4) + 1;

                // Filter kegiatan berdasarkan tujuan yang dipilih dan bulan terpilih
                final kegiatanForTujuan = selectedTujuan == null
                    ? []
                    : _kegiatanList
                        .where((k) =>
                            k['id_tujuan'].toString() == selectedTujuan.toString() &&
                            (int.tryParse(k['bulan']?.toString() ?? '1') ?? 1) == formBulan)
                        .toList();

                // Auto-select jika hanya ada 1 kegiatan
                if (kegiatanForTujuan.isNotEmpty &&
                    kegiatanForTujuan.length == 1 &&
                    selectedKegiatan == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setSheet(() {
                      selectedKegiatan = int.tryParse(kegiatanForTujuan[0]['id'].toString());
                    });
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fLabel('Kegiatan Pembelajaran *'),
                    if (kegiatanForTujuan.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Belum ada kegiatan untuk tujuan ini di Bulan $formBulan',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _fDrop(
                        value: selectedKegiatan?.toString(),
                        hint: 'Pilih kegiatan pembelajaran',
                        icon: Icons.assignment_rounded,
                        items:
                            kegiatanForTujuan
                                .map(
                                  (k) => DropdownMenuItem(
                                    value: k['id'].toString(),
                                    child: Tooltip(
                                      message: k['nama_kegiatan'] ?? '-',
                                      child: Text(
                                        k['nama_kegiatan'] ?? '-',
                                        style: const TextStyle(fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) => setSheet(
                              () => selectedKegiatan = int.tryParse(v ?? ''),
                            ),
                      ),
                    if (selectedKegiatan != null) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (_) {
                          final k = kegiatanForTujuan.firstWhere(
                            (e) =>
                                e['id'].toString() ==
                                selectedKegiatan.toString(),
                            orElse: () => null,
                          );
                          if (k == null) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _teal.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _teal.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _teal.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.check_box_rounded,
                                    color: _teal,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        k['nama_kegiatan'] ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (k['deskripsi'] != null &&
                                          k['deskripsi']
                                              .toString()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          k['deskripsi'] ?? '-',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                );
              }

              // ── Step 3: Waktu ───────────────────────────────────────────────
              Widget buildStep3() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fLabel('Tanggal Penilaian'),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate:
                            DateTime.tryParse(tanggal) ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        builder:
                            (c, child) => Theme(
                              data: Theme.of(c).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: _primary,
                                ),
                              ),
                              child: child!,
                            ),
                      );
                      if (picked != null) {
                        final dateFormatted = DateFormat('yyyy-MM-dd').format(picked);
                        final matched = _findProsemWeekByDate(dateFormatted);
                        setSheet(() {
                          tanggal = dateFormatted;
                          if (matched != null) {
                            selectedSem = matched['semester']?.toString() ?? '1';
                            selectedMinggu = matched['minggu_ke']?.toString() ?? '1';
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: _primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, dd MMMM yyyy', 'id').format(
                                DateTime.tryParse(tanggal) ?? DateTime.now(),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.edit_calendar_rounded,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fLabel('Semester *'),
                            _fDrop(
                              value: selectedSem,
                              hint: 'Semester',
                              icon: Icons.school_rounded,
                              items:
                                  ['1', '2']
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            'Semester $s',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setSheet(() => selectedSem = v ?? '1'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fLabel('Bulan *'),
                            _fDrop(
                              value: formBulan.toString(),
                              hint: 'Bulan',
                              icon: Icons.calendar_month_rounded,
                              items: List.generate(
                                _totalBulan,
                                (i) => DropdownMenuItem(
                                  value: '${i + 1}',
                                  child: Text(
                                    'Bulan ${i + 1}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                              onChanged: (v) {
                                final newBulan = int.tryParse(v ?? '') ?? 1;
                                setSheet(() {
                                  selectedMinggu = (_startWeekOfBulan(newBulan) + formMinggu - 1).toString();
                                  selectedTujuan = null;
                                  selectedKegiatan = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fLabel('Minggu ke- *'),
                            _fDrop(
                              value: formMinggu.toString(),
                              hint: 'Minggu',
                              icon: Icons.view_week_rounded,
                              items: List.generate(
                                _weeksForBulan(formBulan),
                                (i) => DropdownMenuItem(
                                  value: '${i + 1}',
                                  child: Text(
                                    'Minggu ${i + 1}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                              onChanged: (v) {
                                final newMinggu = int.tryParse(v ?? '') ?? 1;
                                setSheet(() {
                                  selectedMinggu = (_startWeekOfBulan(formBulan) + newMinggu - 1).toString();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );

              // ── Step 4: Status TM / MM / M ───────────────────────────────────
              Widget buildStep4() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grid 3 kolom (karena hanya 3 status)
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.78,
                    children:
                        _statusCfg.entries.map((e) {
                          final key = e.key;
                          final cfg = e.value;
                          final sel = selectedStatus == key;
                          return GestureDetector(
                            onTap: () => setSheet(() => selectedStatus = key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? cfg.color : cfg.bgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      sel
                                          ? cfg.color
                                          : cfg.color.withOpacity(0.3),
                                  width: sel ? 2 : 1,
                                ),
                                boxShadow:
                                    sel
                                        ? [
                                          BoxShadow(
                                            color: cfg.color.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                        : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        cfg.emoji,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                      const Spacer(),
                                      if (sel)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    key,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: sel ? Colors.white : cfg.color,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cfg.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          sel
                                              ? Colors.white70
                                              : cfg.color.withOpacity(0.7),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // Deskripsi status terpilih
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(selectedStatus),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _statusCfg[selectedStatus]!.bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _statusCfg[selectedStatus]!.color.withOpacity(
                            0.25,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusCfg[selectedStatus]!.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _statusCfg[selectedStatus]!.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _statusCfg[selectedStatus]!.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _statusDesc(selectedStatus),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _statusCfg[selectedStatus]!.color
                                        .withOpacity(0.8),
                                    height: 1.4,
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
              );

              // ── Step 5: Narasi & Catatan ─────────────────────────────────
              Widget buildStep5() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fLabel('Konteks / Situasi'),
                  _fArea(
                    ctrl: konteksCtrl,
                    hint:
                        'Deskripsikan situasi/konteks saat penilaian dilakukan...\nContoh: Saat bermain bebas di taman, anak terlihat...',
                  ),
                  const SizedBox(height: 16),
                  _fLabel('Hasil Penilaian (CP)'),
                  _fArea(
                    ctrl: hasilCtrl,
                    hint:
                        'Tuliskan capaian pembelajaran yang dicapai anak...\nContoh: Anak mampu menyebutkan nama-nama hewan...',
                  ),
                  const SizedBox(height: 16),
                  _fLabel('Kejadian / Cerita Anak'),
                  _fArea(
                    ctrl: kejadianCtrl,
                    hint:
                        'Ceritakan kejadian atau peristiwa yang terjadi...\nContoh: Ketika diminta menggambar, anak dengan antusias...',
                  ),
                  const SizedBox(height: 16),
                  _fLabel('Catatan Pembelajaran (Opsional)'),
                  _fArea(
                    ctrl: catatanCtrl,
                    hint: 'Catatan tambahan perkembangan anak pada aspek ini...',
                    maxLines: 3,
                  ),
                ],
              );

              // ── Validasi ─────────────────────────────────────────────────────
              String? validate() {
                if (step == 0) {
                  if (selectedAnak == null)
                    return 'Pilih anak terlebih dahulu';
                  if (selectedAspek == null) return 'Pilih aspek penilaian';
                }
                if (step == 1) {
                  if (selectedTujuan == null)
                    return 'Pilih tujuan pembelajaran';
                }
                if (step == 2) {
                  if (selectedKegiatan == null)
                    return 'Pilih kegiatan pembelajaran';
                }
                return null;
              }

              final mq = MediaQuery.of(ctx);
              return Container(
                height: mq.size.height * 0.93,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDF8F3),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    // ── Header ─────────────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  stepColors[step],
                                  stepColors[step].withOpacity(0.75),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: stepColors[step].withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    stepIcons[step],
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEditing
                                            ? 'Edit Penilaian'
                                            : 'Tambah Penilaian',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        'Langkah ${step + 1} dari ${stepTitles.length} — ${stepTitles[step]}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(ctx),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Progress bar
                          Row(
                            children: List.generate(stepTitles.length, (i) {
                              final done = i < step;
                              final act = i == step;
                              return Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color:
                                              done || act
                                                  ? stepColors[i]
                                                  : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (i < stepTitles.length - 1)
                                      const SizedBox(width: 4),
                                  ],
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(stepTitles.length, (i) {
                              final done = i < step;
                              final act = i == step;
                              return Expanded(
                                child: Center(
                                  child: Text(
                                    stepTitles[i],
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight:
                                          act
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          done || act
                                              ? stepColors[i]
                                              : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // ── Content ─────────────────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, mq.viewInsets.bottom + 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (step == 0) buildStep0(),
                              if (step == 1) buildStep1(),
                              if (step == 2) buildStep2(),
                              if (step == 3) buildStep3(),
                              if (step == 4) buildStep4(),
                              if (step == 5) buildStep5(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Bottom nav ──────────────────────────────────────────────
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        MediaQuery.of(ctx).padding.bottom + 12,
                      ),
                      decoration: BoxDecoration(
                        color: _surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child:
                                step > 0
                                    ? OutlinedButton.icon(
                                      onPressed: () => setSheet(() => step--),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: _primary.withOpacity(0.4),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.arrow_back_rounded,
                                        size: 17,
                                        color: _primary,
                                      ),
                                      label: Text(
                                        'Kembali',
                                        style: TextStyle(
                                          color: _primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                    : OutlinedButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: _primary.withOpacity(0.4),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                        ),
                                      ),
                                      child: Text(
                                        'Batal',
                                        style: TextStyle(
                                          color: _primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    step == stepTitles.length - 1
                                        ? _green
                                        : stepColors[step],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                elevation: 0,
                              ),
                              onPressed:
                                  isSaving
                                      ? null
                                      : () async {
                                        final err = validate();
                                        if (err != null) {
                                          _snackErr(err);
                                          return;
                                        }

                                        if (step < stepTitles.length - 1) {
                                          setSheet(() => step++);
                                          return;
                                        }

                                        setSheet(() => isSaving = true);

                                        final payload = {
                                          'id_anak': selectedAnak,
                                          'id_aspek': selectedAspek,
                                          'id_tujuan': selectedTujuan,
                                          'id_kegiatan': selectedKegiatan,
                                          'tanggal': tanggal,
                                          'semester': selectedSem,
                                          'minggu_ke': selectedMinggu,
                                          'status': selectedStatus,
                                          'konteks': konteksCtrl.text.trim(),
                                          'hasil': hasilCtrl.text.trim(),
                                          'kejadian': kejadianCtrl.text.trim(),
                                          'catatan': catatanCtrl.text.trim(),
                                        };

                                        if (isEditing) {
                                          await _updatePenilaian(
                                            int.parse(item['id'].toString()),
                                            payload,
                                          );
                                        } else {
                                          await _savePenilaian(payload);
                                        }

                                        setSheet(() => isSaving = false);
                                        if (mounted) Navigator.pop(ctx);
                                      },
                              child:
                                  isSaving
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            step < stepTitles.length - 1
                                                ? Icons.arrow_forward_rounded
                                                : Icons.save_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            step < stepTitles.length - 1
                                                ? 'Lanjut'
                                                : (isEditing
                                                    ? 'Perbarui'
                                                    : 'Simpan'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
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

  // ════════════════════════════════════════════════════════════════════════════
  // WIDGET HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _statChip(
    String value,
    String label,
    IconData? icon,
    Color color, {
    String? emoji,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (emoji != null)
          Text(emoji, style: const TextStyle(fontSize: 12))
        else
          Icon(icon!, color: const Color(0xFFFFE0A3), size: 12),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _filterChip(String label, String value) {
    final sel = _filterAspek == value;
    return GestureDetector(
      onTap: () => setState(() => _filterAspek = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? _primary : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _primary : Colors.grey.shade200),
          boxShadow:
              sel
                  ? [BoxShadow(color: _primary.withOpacity(0.2), blurRadius: 8)]
                  : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : _slate,
          ),
        ),
      ),
    );
  }

  Widget _statusFilterChip(String status, {String? emoji}) {
    final sel = _filterStatus == status;
    final color = status == 'Semua'
        ? _primary
        : _statusCfg[status]?.color ?? _primary;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? color : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? color : Colors.grey.shade200),
          boxShadow: sel
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
            ],
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : _slate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF334155),
      ),
    ),
  );

  Widget _fDrop({
    required String? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFFDF8F3),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        hint: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text(
              hint,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: _primary,
          size: 20,
        ),
        items: items,
        onChanged: onChanged,
      ),
    ),
  );

  Widget _fArea({
    required TextEditingController ctrl,
    required String hint,
    int maxLines = 4,
  }) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFDF8F3),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _cardBorder),
    ),
    child: TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
          height: 1.5,
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
    ),
  );

  Widget _sectionTitle(String text) => Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
      color: Colors.grey.shade800,
    ),
  );

  Widget _textBox(String text, Color color) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF334155),
        height: 1.5,
      ),
    ),
  );

  Widget _detailCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(children: children),
  );

  Widget _dRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (!isLast)
        Divider(
          height: 1,
          color: Colors.grey.shade200,
          indent: 16,
          endIndent: 16,
        ),
    ],
  );

  PopupMenuItem<String> _popItem(
    String val,
    IconData icon,
    String label,
    Color bg,
    Color fg, {
    bool isRed = false,
  }) => PopupMenuItem(
    value: val,
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: fg, size: 15),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isRed ? _red : null,
          ),
        ),
      ],
    ),
  );

  String _fmtTgl(dynamic raw) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw?.toString() ?? '-';
    }
  }

  String _statusDesc(String key) {
    switch (key) {
      case 'TM':
        return 'Anak belum memperlihatkan tanda-tanda perilaku yang dimaksud dalam indikator penilaian.';
      case 'MM':
        return 'Anak sudah mulai memperlihatkan tanda-tanda awal perilaku yang dimaksud namun belum konsisten.';
      case 'M':
        return 'Anak sudah memperlihatkan perilaku yang diharapkan secara konsisten sesuai indikator.';
      default:
        return '';
    }
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────
class _StatusCfg {
  final String label, emoji;
  final Color color, bgColor;
  const _StatusCfg(this.label, this.color, this.bgColor, this.emoji);
}

