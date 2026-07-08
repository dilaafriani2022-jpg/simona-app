import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/api_service.dart';

class AbsensiScreen extends StatefulWidget {
  final int? idGuru;
  final int? idKelas;
  const AbsensiScreen({super.key, this.idGuru, this.idKelas});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen>
    with SingleTickerProviderStateMixin {

  // ── Palet Warna ──────────────────────────────────────────────────────────
  static const Color _teal       = Color(0xFF0F6B6B);
  static const Color _tealLight  = Color(0xFF178C8C);
  static const Color _tealDark   = Color(0xFF094F4F);
  static const Color _amber      = Color(0xFFD97706);
  static const Color _bg         = Color(0xFFF0F7F7);
  static const Color _surface    = Colors.white;
  static const Color _slate      = Color(0xFF475569);
  static const Color _border     = Color(0xFFD4EAEA);

  static const Map<String, _StatusCfg> _statusCfg = {
    'Hadir': _StatusCfg(
      label: 'Hadir',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF059669),
      bgColor: Color(0xFFD1FAE5),
      emoji: '✅',
    ),
    'Sakit': _StatusCfg(
      label: 'Sakit',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFD97706),
      bgColor: Color(0xFFFEF3C7),
      emoji: '🤒',
    ),
    'Izin': _StatusCfg(
      label: 'Izin',
      icon: Icons.assignment_rounded,
      color: Color(0xFF2563EB),
      bgColor: Color(0xFFDBEAFE),
      emoji: '📋',
    ),
    'Alpa': _StatusCfg(
      label: 'Alpa',
      icon: Icons.cancel_rounded,
      color: Color(0xFFDC2626),
      bgColor: Color(0xFFFEE2E2),
      emoji: '❌',
    ),
  };

  // ── State ────────────────────────────────────────────────────────────────
  late Future<List<dynamic>> _combinedFuture;
  List<dynamic> _anakList = [];
  DateTime _selectedDate = DateTime.now();
  final Map<int, String>   _absensiStatus  = {};
  final Map<int, String>   _keterangan     = {};
  final Map<int, bool>     _savingMap      = {};
  final Map<int, TextEditingController> _keteranganControllers = {};
  bool _isSavingAll = false;

  // ── Ringkasan cepat ──────────────────────────────────────────────────────
  Map<String, int> get _summary {
    final m = <String, int>{'Hadir': 0, 'Sakit': 0, 'Izin': 0, 'Alpa': 0};
    for (final v in _absensiStatus.values) {
      if (m.containsKey(v)) m[v] = m[v]! + 1;
    }
    return m;
  }

  // ════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _keteranganControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadData() {
    _combinedFuture = Future.wait([_getAnak(), _getAbsensi()]).then((results) {
      if (mounted) {
        setState(() {
          _anakList = results[0] as List<dynamic>? ?? [];
        });
      }
      return results;
    });
  }

  void _refreshData() {
    _absensiStatus.clear();
    _keterangan.clear();
    setState(() {
      _loadData();
    });
  }

  Future<List<dynamic>> _getAnak() async {
    try {
      final idKelas = widget.idKelas ?? 2;
      final res = await ApiService.fetch('manage_anak.php?id_kelas=$idKelas');
      if (res['status'] == 'success') return res['data'] as List? ?? [];
      return [];
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  Future<List<dynamic>> _getAbsensi() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final idKelas = widget.idKelas ?? 2;
      final res = await ApiService.fetch(
        'manage_absensi.php?tanggal=$dateStr&id_guru=${widget.idGuru ?? 2}&id_kelas=$idKelas',
      );
      if (res['status'] == 'success') {
        final data = res['data'] as List? ?? [];
        for (final item in data) {
          final sid = int.tryParse(item['id_anak'].toString());
          if (sid != null) {
            _absensiStatus[sid] = item['status'] ?? 'Hadir';
            final ket = item['keterangan'] ?? '';
            _keterangan[sid] = ket;
            // Sync controller text without recreating it
            if (_keteranganControllers.containsKey(sid)) {
              _keteranganControllers[sid]!.text = ket;
            }
          }
        }
        return data;
      }
      return [];
    } catch (e) {
      _snackErr('Gagal memuat absensi: $e');
      return [];
    }
  }

  Future<void> _saveAbsensi(int idAnak, String status, String ket) async {
    setState(() => _savingMap[idAnak] = true);
    try {
      final res = await ApiService.post('manage_absensi.php', {
        'action'     : 'add',
        'id_anak'   : idAnak,
        'id_guru'    : widget.idGuru ?? 2,
        'tanggal'    : DateFormat('yyyy-MM-dd').format(_selectedDate),
        'status'     : status,
        'keterangan' : ket,
      });
      if (res['status'] == 'success') {
        _refreshData();
      } else {
        _snackErr(res['message'] ?? 'Gagal menyimpan');
      }
    } catch (e) {
      _snackErr('Error: $e');
    } finally {
      if (mounted) setState(() => _savingMap[idAnak] = false);
    }
  }

  /// Tandai semua anak sebagai Hadir sekaligus
  Future<void> _markAllHadir(List<dynamic> anakList) async {
    setState(() => _isSavingAll = true);
    for (final s in anakList) {
      final id = int.tryParse(s['id'].toString());
      if (id == null) continue;
      _absensiStatus[id] = 'Hadir';
      _keterangan[id]    = '';
    }
    setState(() {});
    for (final s in anakList) {
      final id = int.tryParse(s['id'].toString());
      if (id == null) continue;
      await _saveAbsensi(id, 'Hadir', '');
    }
    if (mounted) {
      setState(() => _isSavingAll = false);
      _snackOk('Semua anak ditandai Hadir');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // SNACKBAR
  // ════════════════════════════════════════════════════════════════════════

  void _snackOk(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Text(msg),
    ]),
    backgroundColor: const Color(0xFF059669),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  void _snackErr(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: const Color(0xFFDC2626),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Absensi Anak',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _combinedFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final anakList = _anakList;

          return Column(children: [

            // ── Header gradient ──────────────────────────────────────────
            _buildHeader(anakList),

            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: isLoading
                ? const Center(child: CircularProgressIndicator(color: _teal))
                : snapshot.hasError
                  ? _buildError(snapshot.error)
                  : anakList.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: _teal,
                        onRefresh: () async {
                          _refreshData();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: anakList.length,
                          itemBuilder: (_, i) {
                            final s  = anakList[i];
                            final id = int.parse(s['id'].toString());
                            return _buildCard(
                              index     : i,
                              idAnak   : id,
                              nama      : s['nama_anak']?.toString() ?? '-',
                              status    : _absensiStatus[id] ?? 'Hadir',
                              keterangan: _keterangan[id]   ?? '',
                            );
                          },
                        ),
                      ),
            ),
          ]);
        },
      ),

      // ── FAB: Tandai semua hadir ────────────────────────────────────────
      floatingActionButton: FutureBuilder<List<dynamic>>(
        future: _combinedFuture,
        builder: (ctx, snap) {
          final anakList = _anakList;
          return FloatingActionButton.extended(
            onPressed: _isSavingAll || anakList.isEmpty
                ? null
                : () => _markAllHadir(anakList),
            backgroundColor: _teal,
            elevation: 4,
            icon: _isSavingAll
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.done_all_rounded, color: Colors.white),
            label: Text(
              _isSavingAll ? 'Menyimpan...' : 'Tandai Semua Hadir',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // HEADER
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(List<dynamic> anakList) {
    final summary = _summary;
    final total   = anakList.length;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_teal, _tealLight, Color(0xFF1AA8A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(children: [
        // Dekorasi bulat latar
        Positioned(right: -30, top: -20,
          child: Opacity(opacity: 0.07,
            child: Container(width: 160, height: 160,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))),
        Positioned(left: -20, bottom: -30,
          child: Opacity(opacity: 0.05,
            child: Container(width: 120, height: 120,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Date Row ──────────────────────────────────────────────
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'id').format(_selectedDate),
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text('Ubah',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 14),

            // ── Summary chips ─────────────────────────────────────────
             SingleChildScrollView(
               scrollDirection: Axis.horizontal,
               physics: const BouncingScrollPhysics(),
               child: Row(children: [
                 _summaryChip('$total', 'Anak', Icons.people_rounded),
                 const SizedBox(width: 8),
                 ..._statusCfg.entries.map((e) => Padding(
                   padding: const EdgeInsets.only(right: 8),
                   child: _summaryChip(
                     '${summary[e.key] ?? 0}',
                     e.key,
                     e.value.icon,
                     color: e.value.color,
                   ),
                 )),
               ]),
             ),
          ]),
        ),
      ]),
    );
  }

  Widget _summaryChip(String value, String label, IconData icon, {Color? color}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color != null ? Colors.white : const Color(0xFFB2DFDF)),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1)),
          Text(label, style: TextStyle(
            color: Colors.white.withOpacity(0.75), fontSize: 9)),
        ]),
      ]),
    );

  // ════════════════════════════════════════════════════════════════════════
  // ABSENSI CARD
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildCard({
    required int index,
    required int idAnak,
    required String nama,
    required String status,
    required String keterangan,
  }) {
    final cfg     = _statusCfg[status] ?? _statusCfg['Hadir']!;
    final isSaving = _savingMap[idAnak] ?? false;
    final initials = nama.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: cfg.color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: cfg.color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Baris atas: avatar + nama + badge status ─────────────────
          Row(children: [
            // Avatar
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: cfg.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: isSaving
                  ? SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: cfg.color, strokeWidth: 2))
                  : Text(initials,
                      style: TextStyle(
                        color: cfg.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),

            // Nama + nomor urut
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${index + 1}',
                    style: const TextStyle(
                      fontSize: 10, color: _teal, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 7),
                Expanded(child: Text(nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 4),
              // Badge status saat ini
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: cfg.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cfg.color.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(cfg.emoji, style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text(status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: cfg.color)),
                ]),
              ),
            ])),
          ]),

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),

          // ── Tombol status (Hadir / Sakit / Izin / Alpa) ──────────────
          Row(
            children: _statusCfg.entries.map((e) {
              final key    = e.key;
              final sCfg   = e.value;
              final isSelected = status == key;
              return Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: isSaving ? null : () {
                    setState(() => _absensiStatus[idAnak] = key);
                    _saveAbsensi(idAnak, key, _keterangan[idAnak] ?? '');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? sCfg.color : sCfg.bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? sCfg.color : sCfg.color.withOpacity(0.25),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                        ? [BoxShadow(
                            color: sCfg.color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))]
                        : [],
                    ),
                    child: Column(children: [
                      Icon(sCfg.icon,
                        size: 18,
                        color: isSelected ? Colors.white : sCfg.color),
                      const SizedBox(height: 3),
                      Text(key,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : sCfg.color)),
                    ]),
                  ),
                ),
              ));
            }).toList(),
          ),

          // ── Keterangan (muncul jika bukan Hadir) ─────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: status != 'Hadir'
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cfg.bgColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cfg.color.withOpacity(0.2)),
                    ),
                    child: TextField(
                      // Use persistent controller per student
                      controller: _keteranganControllers.putIfAbsent(
                        idAnak,
                        () => TextEditingController(text: keterangan),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Keterangan ${cfg.label}... (Tekan Enter/Centang untuk simpan)',
                        hintStyle: TextStyle(
                          color: cfg.color.withOpacity(0.5), fontSize: 10),
                        prefixIcon: Icon(Icons.notes_rounded, color: cfg.color, size: 16),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.check_circle_rounded, color: cfg.color, size: 20),
                          tooltip: 'Simpan Keterangan',
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            final ket = _keteranganControllers[idAnak]?.text ?? '';
                            _keterangan[idAnak] = ket;
                            _saveAbsensi(idAnak, status, ket);
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      ),
                      style: TextStyle(fontSize: 13, color: cfg.color),
                      maxLines: 1,
                      onChanged: (v) {
                        _keterangan[idAnak] = v;
                      },
                      onSubmitted: (v) {
                        _keterangan[idAnak] = v;
                        _saveAbsensi(idAnak, status, v);
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // EMPTY & ERROR
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildEmpty() => ListView(children: [
    SizedBox(height: 280, child: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.07),
            shape: BoxShape.circle),
          child: Icon(Icons.people_outline_rounded, size: 48, color: _teal.withOpacity(0.4))),
        const SizedBox(height: 16),
        Text('Belum ada data anak',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Anak belum terdaftar di kelas ini',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
      ],
    ))),
  ]);

  Widget _buildError(Object? err) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
      const SizedBox(height: 12),
      Text('Terjadi kesalahan', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: _refreshData,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Coba lagi'),
        style: TextButton.styleFrom(foregroundColor: _teal),
      ),
    ],
  ));

  // ════════════════════════════════════════════════════════════════════════
  // DATE PICKER
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _teal,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        for (final c in _keteranganControllers.values) c.dispose();
        _keteranganControllers.clear();
      });
      _refreshData();
    }
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────
class _StatusCfg {
  final String  label, emoji;
  final IconData icon;
  final Color   color, bgColor;
  const _StatusCfg({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.emoji,
  });
}
