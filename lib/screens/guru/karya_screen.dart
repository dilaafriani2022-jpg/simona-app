import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/api_service.dart';

// ─────────────────────────────────────────────────────────────
// Model Kategori
// ─────────────────────────────────────────────────────────────
class KategoriKarya {
  final String key, label, emoji;
  final Color color, bg;
  final IconData icon;
  const KategoriKarya(
      this.key, this.label, this.emoji, this.color, this.bg, this.icon);
}

const List<KategoriKarya> kKategoriList = [
  KategoriKarya('Seni Rupa', 'Seni Rupa', '🎨', Color(0xFF6D28D9),
      Color(0xFFEDE9FE), Icons.brush_rounded),
  KategoriKarya('Kerajinan', 'Kerajinan', '✂️', Color(0xFFB45309),
      Color(0xFFFEF3C7), Icons.handyman_rounded),
  KategoriKarya('Menulis', 'Menulis', '✏️', Color(0xFF1D4ED8),
      Color(0xFFDBEAFE), Icons.edit_rounded),
  KategoriKarya('Konstruksi', 'Konstruksi', '🏗️', Color(0xFF15803D),
      Color(0xFFDCFCE7), Icons.foundation_rounded),
  KategoriKarya('Musik / Gerak', 'Musik / Gerak', '🎵', Color(0xFFBE185D),
      Color(0xFFFCE7F3), Icons.music_note_rounded),
  KategoriKarya('Lainnya', 'Lainnya', '📦', Color(0xFF57534E),
      Color(0xFFF5F0EB), Icons.category_rounded),
];

const kWaktuList = ['Pagi', 'Siang', 'Sore'];

// ─────────────────────────────────────────────────────────────
// Konstanta Warna
// ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFFC17B2F);
const _kPrimaryDk = Color(0xFFA0601A);
const _kBg = Color(0xFFFDF8F2);
const _kSurface = Colors.white;
const _kBorder = Color(0xFFEDE8E0);
const _kSlate = Color(0xFF64748B);
const _kTextMain = Color(0xFF1C1917);
const _kTextSub = Color(0xFF78716C);
const _kGreen = Color(0xFF059669);
const _kRed = Color(0xFFDC2626);

// ─────────────────────────────────────────────────────────────
// Screen Utama
// ─────────────────────────────────────────────────────────────
class KaryaScreen extends StatefulWidget {
  final int? idGuru;
  final int? idKelas;
  final bool isReadOnly;
  const KaryaScreen({super.key, this.idGuru, this.idKelas, this.isReadOnly = false});

  @override
  State<KaryaScreen> createState() => _KaryaScreenState();
}

class _KaryaScreenState extends State<KaryaScreen> {
  late Future<List<dynamic>> _karyaFuture;
  List<dynamic> _anakList = [];
  String _filterTab = 'semua';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  DateTime? _selectedDate;
  int? _selectedMonth;

  static const List<String> _indonesianMonths = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
    _loadKarya();
    _loadAnak();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadKarya() => _karyaFuture = _getKarya();

  // ── Data Fetching ──────────────────────────────────────────

  Future<void> _loadAnak() async {
    try {
      final res = await ApiService.fetch(
          'manage_anak.php?id_kelas=${widget.idKelas ?? 2}');
      if (res['status'] == 'success') {
        setState(() => _anakList = res['data'] ?? []);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<List<dynamic>> _getKarya() async {
    try {
      final res = await ApiService.fetch(
          'manage_karya.php?id_guru=${widget.idGuru ?? 2}');
      if (res['status'] == 'success') return res['data'] ?? [];
      return [];
    } catch (e) {
      _snackErr('Gagal memuat: $e');
      return [];
    }
  }

  // ── Filter & Search ────────────────────────────────────────

  List<dynamic> _applyFilter(List<dynamic> data) {
    final now = DateTime.now();
    return data.where((item) {
      bool matchTime = true;
      try {
        final tgl = DateTime.parse(item['tanggal'].toString());
        if (_filterTab == 'hari_ini') {
          matchTime = tgl.year == now.year &&
              tgl.month == now.month &&
              tgl.day == now.day;
        } else if (_filterTab == 'minggu_ini') {
          final start = now.subtract(Duration(days: now.weekday - 1));
          matchTime =
              !tgl.isBefore(DateTime(start.year, start.month, start.day));
        }
      } catch (_) {}
      if (!matchTime) return false;

      // Filter Tanggal Spesifik
      if (_selectedDate != null) {
        try {
          final tgl = DateTime.parse(item['tanggal'].toString());
          final matchDate = tgl.year == _selectedDate!.year &&
              tgl.month == _selectedDate!.month &&
              tgl.day == _selectedDate!.day;
          if (!matchDate) return false;
        } catch (_) {
          return false;
        }
      }

      // Filter Bulan
      if (_selectedMonth != null) {
        try {
          final tgl = DateTime.parse(item['tanggal'].toString());
          if (tgl.month != _selectedMonth) return false;
        } catch (_) {
          return false;
        }
      }

      final nama = (item['nama_anak'] ?? '').toString().toLowerCase();
      final judul = (item['judul'] ?? '').toString().toLowerCase();
      final kat = (item['kategori'] ?? '').toString().toLowerCase();
      final matchQ = _searchQuery.isEmpty ||
          nama.contains(_searchQuery) ||
          judul.contains(_searchQuery) ||
          kat.contains(_searchQuery);
      return matchQ;
    }).toList();
  }

  // ── CRUD ───────────────────────────────────────────────────

  Future<void> _addKarya(Map<String, dynamic> payload) async {
    try {
      final res = await ApiService.post('manage_karya.php', {
        'action': 'add',
        'id_guru': widget.idGuru ?? 2,
        ...payload,
      });
      if (res['status'] == 'success') {
        setState(_loadKarya);
        _snackOk('Karya berhasil disimpan');
      } else {
        _snackErr(res['message'] ?? 'Gagal menyimpan');
      }
    } catch (e) {
      _snackErr('Error: $e');
    }
  }

  Future<void> _deleteKarya(int id, String namaAnak) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header merah
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.12),
                    shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded,
                    color: _kRed, size: 32),
              ),
              const SizedBox(height: 10),
              const Text('Hapus Karya?',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: _kTextMain)),
            ]),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(children: [
                  const Icon(Icons.child_care_rounded,
                      color: _kPrimary, size: 18),
                  const SizedBox(width: 10),
                  Text(namaAnak,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
              ),
              const SizedBox(height: 10),
              Text('Karya ini akan dihapus permanen.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(
                            color: _kSlate,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.delete_rounded,
                        color: Colors.white, size: 16),
                    label: const Text('Hapus',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      final res = await ApiService.post(
          'manage_karya.php', {'action': 'delete', 'id': id});
      if (res['status'] == 'success') {
        setState(_loadKarya);
        _snackOk('Karya dihapus');
      } else {
        _snackErr(res['message'] ?? 'Gagal menghapus');
      }
    } catch (e) {
      _snackErr('Error: $e');
    }
  }

  // ── Snackbar Helpers ───────────────────────────────────────

  void _snackOk(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(msg),
          ]),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  void _snackErr(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Karya Anak',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                letterSpacing: 0.2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(_loadKarya),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _karyaFuture,
        builder: (ctx, snap) {
          final isLoading = snap.connectionState == ConnectionState.waiting;
          final allData = snap.data ?? [];
          final filtered = _applyFilter(allData);
          final now = DateTime.now();

          final mingguIni = allData.where((d) {
            try {
              final tgl = DateTime.parse(d['tanggal'].toString());
              final start = now.subtract(Duration(days: now.weekday - 1));
              return !tgl
                  .isBefore(DateTime(start.year, start.month, start.day));
            } catch (_) {
              return false;
            }
          }).length;

          final anakAktif =
              allData.map((d) => d['id_anak']).toSet().length;

          return Column(children: [
            _buildHeader(allData.length, mingguIni, anakAktif),
            // Search & Filter Panel
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _buildSearchAndFilterPanel(),
            ),
            // Filter Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildFilterTabs(),
            ),
            // Count Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${filtered.length} Karya',
                      style: const TextStyle(
                          color: _kPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ),
            ),
            // List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary))
                  : snap.hasError
                      ? _buildError()
                      : RefreshIndicator(
                          color: _kPrimary,
                          onRefresh: () async => setState(_loadKarya),
                          child: filtered.isEmpty
                              ? _buildEmpty()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 4, 16, 100),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) =>
                                      _buildCard(filtered[i]),
                                ),
                        ),
            ),
          ]);
        },
      ),
      floatingActionButton: widget.isReadOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: _showFormSheet,
              backgroundColor: _kPrimary,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Tambah Karya',
                  style:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(int total, int mingguIni, int anakAktif) =>
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kPrimary, _kPrimaryDk, Color(0xFF8B5E1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Stack(children: [
          Positioned(
            right: -20,
            bottom: -10,
            child: Opacity(
              opacity: 0.07,
              child: Icon(Icons.palette_rounded,
                  size: MediaQuery.of(context).size.width * 0.4,
                  color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
            child: Row(children: [
              _hStat('$total', 'Total Karya', Icons.collections_rounded),
              const SizedBox(width: 8),
              _hStat('$mingguIni', 'Minggu Ini', Icons.date_range_rounded),
              const SizedBox(width: 8),
              _hStat(
                  '$anakAktif', 'Anak Aktif', Icons.child_care_rounded),
            ]),
          ),
        ]),
      );

  Widget _hStat(String v, String l, IconData icon) =>
      Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Column(children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 5),
            Text(v,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    height: 1)),
            const SizedBox(height: 2),
            Text(l,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 9),
                textAlign: TextAlign.center),
          ]),
        ),
      );

  Widget _buildFilterTabs() {
    final tabs = [
      ('semua', 'Semua', Icons.grid_view_rounded),
      ('hari_ini', 'Hari Ini', Icons.today_rounded),
      ('minggu_ini', 'Minggu Ini', Icons.date_range_rounded),
    ];
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: tabs.map((t) {
          final active = _filterTab == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filterTab = t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? _kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: _kPrimary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.$3,
                        size: 13,
                        color: active ? Colors.white : _kSlate),
                    const SizedBox(width: 5),
                    Text(t.$2,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : _kSlate)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(dynamic item) {
    final nama =
        item['nama_anak']?.toString() ?? 'Anak';
    final judul = item['judul']?.toString() ?? 'Tanpa Judul';
    final katKey = item['kategori']?.toString() ?? 'Lainnya';
    final bahan = item['bahan']?.toString() ?? '';
    final catatan = item['catatan_guru']?.toString() ?? '';
    final waktu = item['waktu_kegiatan']?.toString() ?? '';
    final deskripsi = item['deskripsi']?.toString() ?? '';

    final kat = kKategoriList.firstWhere(
      (k) => k.key == katKey,
      orElse: () => kKategoriList.last,
    );

    DateTime? tgl;
    try {
      tgl = DateTime.parse(item['tanggal'].toString());
    } catch (_) {}

    final initials = nama
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: kat.color, width: 4)),
        boxShadow: [
          BoxShadow(
              color: kat.color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
          BoxShadow(
              color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Row: avatar + info + delete
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kat.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kat.color.withOpacity(0.25)),
              ),
              child: Center(
                  child: Text(kat.emoji,
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: _kPrimary.withOpacity(0.1),
                    child: Text(initials,
                        style: TextStyle(
                            color: _kPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 9)),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _kTextMain),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 5),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  _chip(kat.emoji, kat.label, kat.color, kat.bg),
                  if (waktu.isNotEmpty)
                    _chipIcon(
                        Icons.access_time_rounded, waktu, _kSlate),
                  if (tgl != null)
                    _chipIcon(
                        Icons.calendar_today_rounded,
                        DateFormat('dd MMM yyyy', 'id').format(tgl),
                        _kSlate),
                ]),
              ]),
            ),
            // Tombol hapus
            if (!widget.isReadOnly)
              GestureDetector(
                onTap: () => _deleteKarya(
                  int.parse(item['id'].toString()),
                  nama,
                ),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 17, color: _kRed),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),
          // Judul karya
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: kat.bg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: kat.color.withOpacity(0.15)),
            ),
            child: Row(children: [
              Icon(Icons.format_quote_rounded,
                  size: 14, color: kat.color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(judul,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: kat.color)),
              ),
            ]),
          ),
          // Detail rows
          if (deskripsi.isNotEmpty) ...[
            const SizedBox(height: 10),
            _detailRow(Icons.description_rounded, 'Deskripsi',
                deskripsi, _kPrimary),
          ],
          if (bahan.isNotEmpty) ...[
            const SizedBox(height: 8),
            _detailRow(Icons.science_rounded, 'Bahan / Media', bahan,
                const Color(0xFF1D4ED8)),
          ],
          if (catatan.isNotEmpty) ...[
            const SizedBox(height: 8),
            _detailRow(Icons.comment_rounded, 'Catatan Guru', catatan,
                _kGreen),
          ],
        ]),
      ),
    );
  }

  Widget _chip(
          String emoji, String label, Color color, Color bg) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      );

  Widget _chipIcon(IconData icon, String label, Color color) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ]),
      );

  Widget _detailRow(
          IconData icon, String label, String value, Color color) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.2)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF44403C),
                    height: 1.5)),
          ]),
        ),
      ]);

  Widget _buildSearchAndFilterPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSearchBar()),
            const SizedBox(width: 10),
            _buildFilterButton(),
          ],
        ),
        if (_selectedDate != null || _selectedMonth != null) ...[
          const SizedBox(height: 10),
          _buildActiveFiltersRow(),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Cari nama anak, judul, kategori...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _kPrimary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                  onPressed: _searchCtrl.clear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasActiveFilter = _selectedDate != null || _selectedMonth != null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _showFilterBottomSheet(),
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: hasActiveFilter ? _kPrimary.withOpacity(0.1) : _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasActiveFilter ? _kPrimary : _kBorder,
                width: hasActiveFilter ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Icon(
              Icons.tune_rounded,
              color: hasActiveFilter ? _kPrimary : _kSlate,
              size: 20,
            ),
          ),
        ),
        if (hasActiveFilter)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: _kRed,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveFiltersRow() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (_selectedDate != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kPrimary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 10, color: _kPrimary),
                const SizedBox(width: 5),
                Text(
                  DateFormat('d MMM yyyy', 'id').format(_selectedDate!),
                  style: const TextStyle(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = null;
                    });
                  },
                  child: Icon(Icons.close_rounded, size: 12, color: _kPrimary.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        if (_selectedMonth != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kPrimary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.date_range_rounded, size: 10, color: _kPrimary),
                const SizedBox(width: 5),
                Text(
                  _indonesianMonths[_selectedMonth! - 1],
                  style: const TextStyle(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMonth = null;
                    });
                  },
                  child: Icon(Icons.close_rounded, size: 12, color: _kPrimary.withOpacity(0.6)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    DateTime? tempDate = _selectedDate;
    int? tempMonth = _selectedMonth;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final hasActiveTempFilter = tempDate != null || tempMonth != null;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pull handler
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Karya',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kTextMain),
                      ),
                      if (hasActiveTempFilter)
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempDate = null;
                              tempMonth = null;
                            });
                          },
                          child: const Text('Reset', style: TextStyle(color: _kRed, fontSize: 13)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Specific Date
                  const Text(
                    'PILIH TANGGAL SPESIFIK',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kTextSub, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: _kPrimary,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setSheetState(() {
                          tempDate = picked;
                          tempMonth = null; // Mutually exclusive
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: tempDate != null ? _kPrimary.withOpacity(0.05) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tempDate != null ? _kPrimary : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: tempDate != null ? _kPrimary : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tempDate == null
                                ? 'Pilih Tanggal Kalender...'
                                : DateFormat('dd MMMM yyyy', 'id').format(tempDate!),
                            style: TextStyle(
                              fontSize: 13,
                              color: tempDate != null ? _kPrimary : Colors.grey.shade700,
                              fontWeight: tempDate != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (tempDate != null)
                            GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  tempDate = null;
                                });
                              },
                              child: const Icon(Icons.clear_rounded, size: 18, color: _kPrimary),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Month Selector
                  const Text(
                    'ATAU PILIH BULAN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kTextSub, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 160,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 2.0,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final monthNum = index + 1;
                        final isSel = tempMonth == monthNum;
                        return InkWell(
                          onTap: () {
                            setSheetState(() {
                              tempMonth = monthNum;
                              tempDate = null; // Mutually exclusive
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSel ? _kPrimary : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? Colors.transparent : Colors.grey.shade200),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _indonesianMonths[index].substring(0, 3), // Short name
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? Colors.white : Colors.grey.shade800),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate = tempDate;
                          _selectedMonth = tempMonth;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty() {
    final hasActiveFilter = _selectedDate != null || _selectedMonth != null || _searchQuery.isNotEmpty;
    return ListView(children: [
      SizedBox(
        height: 280,
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasActiveFilter ? Icons.search_off_rounded : Icons.palette_outlined,
                size: 52,
                color: _kPrimary.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasActiveFilter ? 'Tidak ada karya yang cocok' : 'Belum ada karya anak',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTextSub),
            ),
            const SizedBox(height: 6),
            Text(
              hasActiveFilter
                  ? 'Coba ubah kata kunci atau bersihkan filter'
                  : 'Tap + untuk mendokumentasikan karya',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFA8A29E)),
            ),
            if (hasActiveFilter) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchCtrl.clear();
                    _searchQuery = '';
                    _selectedDate = null;
                    _selectedMonth = null;
                  });
                },
                child: const Text('Reset Filter', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.bold)),
              ),
            ],
          ]),
        ),
      ),
    ]);
  }

  Widget _buildError() =>
      Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Gagal memuat data',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(_loadKarya),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
            style: TextButton.styleFrom(foregroundColor: _kPrimary),
          ),
        ]),
      );

  // ─────────────────────────────────────────────────────────────
  // FORM BOTTOM SHEET
  // ─────────────────────────────────────────────────────────────

  void _showFormSheet() {
    int? selectedAnak;
    String selectedKategori = '';
    String selectedWaktu = 'Pagi';
    DateTime selectedTgl = DateTime.now();
    int step = 0;
    bool isSaving = false;

    final judulCtrl = TextEditingController();
    final deskCtrl = TextEditingController();
    final bahanCtrl = TextEditingController();
    final catatanCtrl = TextEditingController();

    const stepTitles = ['Pilih Anak & Kategori', 'Detail Karya'];
    const stepColors = [_kPrimary, _kGreen];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) {
          // ── Step 0: Pilih Anak & Kategori ──────────────────
          Widget buildStep0() =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fLabel('Nama Anak *'),
                const SizedBox(height: 6),
                _fDrop<int>(
                  hint: 'Pilih anak...',
                  value: selectedAnak,
                  icon: Icons.child_care_rounded,
                  items: _anakList
                      .map((s) => DropdownMenuItem<int>(
                            value: int.parse(s['id'].toString()),
                            child: Text(s['nama_anak'] ?? '-',
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setBS(() => selectedAnak = v),
                ),
                // Preview anak terpilih
                if (selectedAnak != null) ...[
                  const SizedBox(height: 10),
                  Builder(builder: (_) {
                    // FIX: ganti orElse: () => null → pakai where + firstOrNull
                    final matches = _anakList.where(
                        (e) => e['id'].toString() == selectedAnak.toString());
                    if (matches.isEmpty) return const SizedBox.shrink();
                    final s = matches.first;
                    return Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _kGreen.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _kGreen.withOpacity(0.12),
                          child: Text(
                            (s['nama_anak'] as String? ?? 'A')
                                .isNotEmpty
                                ? (s['nama_anak'] as String)[0]
                                    .toUpperCase()
                                : 'A',
                            style: TextStyle(
                                color: _kGreen,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text(s['nama_anak'] ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            Text('NISN: ${s['nisn'] ?? '-'}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                          ]),
                        ),
                        const Icon(Icons.check_circle_rounded,
                            color: _kGreen, size: 20),
                      ]),
                    );
                  }),
                ],
                const SizedBox(height: 18),
                _fLabel('Kategori Karya *'),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.55,
                  children: kKategoriList.map((k) {
                    final sel = selectedKategori == k.key;
                    return GestureDetector(
                      onTap: () =>
                          setBS(() => selectedKategori = k.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: sel ? k.color : k.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel
                                  ? k.color
                                  : k.color.withOpacity(0.3),
                              width: sel ? 2 : 1),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                      color: k.color.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ]
                              : [],
                        ),
                        child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                          Text(k.emoji,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            k.label.split('/').first.trim(),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: sel ? Colors.white : k.color),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ]);

          // ── Step 1: Detail Karya ────────────────────────────
          Widget buildStep1() =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  // Tanggal
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _fLabel('Tanggal *'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final p = await showDatePicker(
                            context: ctx,
                            initialDate: selectedTgl,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (c, child) => Theme(
                              data: Theme.of(c).copyWith(
                                colorScheme:
                                    const ColorScheme.light(
                                        primary: _kPrimary),
                              ),
                              child: child!,
                            ),
                          );
                          if (p != null) setBS(() => selectedTgl = p);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kBorder),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: _kPrimary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd MMM yyyy', 'id')
                                  .format(selectedTgl),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  // Waktu
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _fLabel('Waktu'),
                      const SizedBox(height: 6),
                      _fDrop<String>(
                        hint: 'Waktu',
                        value: selectedWaktu,
                        icon: Icons.access_time_rounded,
                        items: kWaktuList
                            .map((w) => DropdownMenuItem<String>(
                                  value: w,
                                  child: Text(w,
                                      style: const TextStyle(
                                          fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setBS(() => selectedWaktu = v ?? 'Pagi'),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),
                _fLabel('Judul / Nama Karya *'),
                const SizedBox(height: 6),
                _fInput(
                    ctrl: judulCtrl,
                    hint: 'Contoh: Rumahku di Tepi Sawah'),
                const SizedBox(height: 14),
                _fLabel('Deskripsi Karya'),
                const SizedBox(height: 4),
                Text('Ceritakan singkat apa yang dibuat anak.',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade400)),
                const SizedBox(height: 6),
                _fArea(
                    ctrl: deskCtrl,
                    hint:
                        'Contoh: Anak menggambar rumah dengan pohon menggunakan krayon.'),
                const SizedBox(height: 14),
                _fLabel('Bahan / Media'),
                const SizedBox(height: 4),
                Text('Pisahkan dengan koma jika lebih dari satu.',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade400)),
                const SizedBox(height: 6),
                _fInput(
                    ctrl: bahanCtrl,
                    hint: 'Contoh: Krayon, kertas A4, lem'),
                const SizedBox(height: 14),
                _fLabel('Catatan Guru'),
                const SizedBox(height: 6),
                _fArea(
                    ctrl: catatanCtrl,
                    hint:
                        'Kemampuan / perkembangan yang terlihat dari karya ini.',
                    maxLines: 3),
              ]);

          // ── Validasi ────────────────────────────────────────
          String? validate() {
            if (step == 0) {
              if (selectedAnak == null)
                return 'Pilih nama anak terlebih dahulu';
              if (selectedKategori.isEmpty) return 'Pilih kategori karya';
            }
            if (step == 1 && judulCtrl.text.trim().isEmpty)
              return 'Judul karya wajib diisi';
            return null;
          }

          // ── Sheet Layout ────────────────────────────────────
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.92,
            decoration: const BoxDecoration(
              color: _kBg,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(children: [
              // Header sheet
              Container(
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                padding:
                    const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Title banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          stepColors[step],
                          stepColors[step].withOpacity(0.75)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: stepColors[step].withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.palette_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          const Text('Tambah Karya Anak',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(
                            'Langkah ${step + 1} dari 2 — ${stepTitles[step]}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11),
                          ),
                        ]),
                      ),
                      // Tombol tutup
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  Row(
                    children: List.generate(2, (i) {
                      final done = i < step;
                      final act = i == step;
                      return Expanded(
                        child: Row(children: [
                          Expanded(
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 250),
                              height: 4,
                              decoration: BoxDecoration(
                                color: done || act
                                    ? stepColors[i]
                                    : Colors.grey.shade200,
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          if (i == 0) const SizedBox(width: 4),
                        ]),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
              // Body step
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _kBorder),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child:
                        step == 0 ? buildStep0() : buildStep1(),
                  ),
                ),
              ),
              // Action buttons
              Container(
                padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    MediaQuery.of(ctx).padding.bottom + 12),
                decoration: BoxDecoration(
                  color: _kSurface,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -4))
                  ],
                ),
                child: Row(children: [
                  // Kembali / Batal
                  Expanded(
                    child: step > 0
                        ? OutlinedButton.icon(
                            onPressed: () =>
                                setBS(() => step--),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color:
                                      _kPrimary.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(13)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 13),
                            ),
                            icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 16,
                                color: _kPrimary),
                            label: const Text('Kembali',
                                style: TextStyle(
                                    color: _kPrimary,
                                    fontWeight: FontWeight.w600)),
                          )
                        : OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color:
                                      _kPrimary.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(13)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 13),
                            ),
                            child: const Text('Batal',
                                style: TextStyle(
                                    color: _kPrimary,
                                    fontWeight: FontWeight.w600)),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Lanjut / Simpan
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            step == 1 ? _kGreen : _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(13)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 13),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final err = validate();
                              if (err != null) {
                                _snackErr(err);
                                return;
                              }
                              if (step == 0) {
                                setBS(() => step = 1);
                                return;
                              }
                              setBS(() => isSaving = true);
                              await _addKarya({
                                'id_anak': selectedAnak,
                                'judul': judulCtrl.text.trim(),
                                'deskripsi': deskCtrl.text.trim(),
                                'kategori': selectedKategori,
                                'bahan': bahanCtrl.text.trim(),
                                'catatan_guru':
                                    catatanCtrl.text.trim(),
                                'waktu_kegiatan': selectedWaktu,
                                'tanggal': DateFormat('yyyy-MM-dd')
                                    .format(selectedTgl),
                              });
                              setBS(() => isSaving = false);
                              if (mounted) Navigator.pop(ctx);
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  step == 0
                                      ? Icons.arrow_forward_rounded
                                      : Icons.save_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  step == 0
                                      ? 'Lanjut'
                                      : 'Simpan Karya',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                    ),
                  ),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FORM FIELD HELPERS
  // ─────────────────────────────────────────────────────────────

  Widget _fLabel(String text) => RichText(
        text: TextSpan(
          text: text.replaceAll(' *', ''),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF57534E)),
          children: text.endsWith('*')
              ? const [
                  TextSpan(
                      text: ' *', style: TextStyle(color: _kRed))
                ]
              : [],
        ),
      );

  Widget _fDrop<T>({
    required String hint,
    required T? value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4)
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            value: value,
            hint: Row(children: [
              Icon(icon, size: 15, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(hint,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade400)),
            ]),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: _kPrimary, size: 20),
            items: items,
            onChanged: onChanged,
          ),
        ),
      );

  Widget _fInput({
    required TextEditingController ctrl,
    required String hint,
  }) =>
      TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 13, color: _kTextMain),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(fontSize: 12, color: Colors.grey.shade400),
          filled: true,
          fillColor: _kBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _kBorder, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  Widget _fArea({
    required TextEditingController ctrl,
    required String hint,
    int maxLines = 4,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13, color: _kTextMain),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              height: 1.5),
          filled: true,
          fillColor: _kBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _kBorder, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
