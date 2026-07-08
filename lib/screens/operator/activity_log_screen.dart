import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  static const Color _primary   = Color(0xFFC17B2F);
  static const Color _primaryDk = Color(0xFFA0601A);
  static const Color _bg        = Color(0xFFFDF8F3);
  static const Color _surface   = Colors.white;
  static const Color _border    = Color(0xFFF0E8DF);

  // ── Filter ─────────────────────────────────────────────────────────────────
  String _filterJenis = 'Semua';
  String _filterAksi  = 'Semua';

  final _jenisOptions = ['Semua', 'anak', 'guru', 'ortu', 'aspek', 'kelas', 'tahun', 'user'];
  final _aksiOptions  = ['Semua', 'tambah', 'edit', 'hapus', 'sync'];

  List<Map<String, dynamic>> _allActivities = [];
  List<Map<String, dynamic>> _filtered      = [];

  bool _isLoading   = true;
  int  _page        = 1;
  bool _hasMore     = true;
  bool _isFetching  = false;
  static const int _perPage = 20;

  final ScrollController _scrollCtrl = ScrollController();

  // ── Label maps ─────────────────────────────────────────────────────────────
  final Map<String, String> _jenisLabel = {
    'anak': 'Anak', 'guru': 'Guru', 'ortu': 'Ortu',
    'aspek': 'Aspek', 'kelas': 'Kelas', 'tahun': 'T. Ajaran',
    'user': 'User', 'nilai': 'Nilai',
  };
  final Map<String, String> _aksiLabel = {
    'tambah': 'Tambah', 'edit': 'Edit', 'hapus': 'Hapus',
    'sync': 'Sync', 'info': 'Info',
  };

  @override
  void initState() {
    super.initState();
    _loadPage(reset: true);
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 120 &&
          !_isFetching && _hasMore) {
        _loadPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Load from API ──────────────────────────────────────────────────────────
  Future<void> _loadPage({bool reset = false}) async {
    if (_isFetching) return;
    setState(() => _isFetching = true);

    if (reset) {
      _page = 1;
      _hasMore = true;
    }

    final limit  = _perPage;
    final offset = (_page - 1) * _perPage;
    final result = await ApiService.fetch(
      'get_recent_activities.php?limit=$limit&offset=$offset',
    );

    if (!mounted) return;

    final raw = result['status'] == 'success'
        ? (result['data'] as List? ?? [])
        : <dynamic>[];

    final newItems = raw.map((e) => Map<String, dynamic>.from(e)).toList();

    setState(() {
      if (reset) _allActivities = newItems;
      else       _allActivities.addAll(newItems);

      _hasMore   = newItems.length >= _perPage;
      _isLoading = false;
      _isFetching = false;
      _page++;
      _applyFilter();
    });

    // Auto-load halaman berikutnya jika hasil filter terlalu sedikit
    // (kurang dari 10 item) dan masih ada data lagi di server.
    // Ini mencegah spinner berputar selamanya karena daftar tidak bisa di-scroll.
    if (_hasMore && _filtered.length < 10 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPage();
      });
    }
  }

  void _applyFilter() {
    _filtered = _allActivities.where((a) {
      final jenis = (a['jenis'] ?? '').toString();
      final aksi  = (a['aksi']  ?? '').toString();
      final matchJ = _filterJenis == 'Semua' || jenis == _filterJenis;
      final matchA = _filterAksi  == 'Semua' || aksi  == _filterAksi;
      return matchJ && matchA;
    }).toList();
  }

  // ── Colors ─────────────────────────────────────────────────────────────────
  Color _dotColor(String jenis) {
    switch (jenis) {
      case 'anak':  return const Color(0xFF27AE60);
      case 'guru':  return const Color(0xFF2980B9);
      case 'ortu':  return const Color(0xFF8E44AD);
      case 'aspek': return const Color(0xFFE74C3C);
      case 'kelas': return const Color(0xFF00838F);
      case 'tahun': return const Color(0xFF2ECC71);
      case 'user':  return const Color(0xFFF39C12);
      default:      return _primary;
    }
  }

  Color _bgColor(String jenis) {
    switch (jenis) {
      case 'anak':  return const Color(0xFFE8F5E9);
      case 'guru':  return const Color(0xFFE3F2FD);
      case 'ortu':  return const Color(0xFFEDE7F6);
      case 'aspek': return const Color(0xFFFDE8E8);
      case 'kelas': return const Color(0xFFE0F7FA);
      case 'tahun': return const Color(0xFFE8F5E9);
      case 'user':  return const Color(0xFFFFF8E1);
      default:      return const Color(0xFFFFF3E0);
    }
  }

  IconData _aksiIcon(String aksi) {
    switch (aksi) {
      case 'tambah': return Icons.add_circle_outline_rounded;
      case 'edit':   return Icons.edit_outlined;
      case 'hapus':  return Icons.delete_outline_rounded;
      case 'sync':   return Icons.sync_rounded;
      default:       return Icons.info_outline_rounded;
    }
  }

  Color _aksiColor(String aksi) {
    switch (aksi) {
      case 'tambah': return const Color(0xFF27AE60);
      case 'edit':   return const Color(0xFF2980B9);
      case 'hapus':  return const Color(0xFFE74C3C);
      case 'sync':   return const Color(0xFF8E44AD);
      default:       return Colors.grey;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Log Aktivitas Lengkap',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadPage(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildCountBadge(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          // Jenis filter
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _jenisOptions.map((j) => _filterChip(
                label    : j == 'Semua' ? 'Semua Jenis' : (_jenisLabel[j] ?? j),
                selected : _filterJenis == j,
                onTap    : () => setState(() { _filterJenis = j; _applyFilter(); }),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Aksi filter
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _aksiOptions.map((a) => _filterChip(
                label    : a == 'Semua' ? 'Semua Aksi' : (_aksiLabel[a] ?? a),
                selected : _filterAksi == a,
                accent   : a != 'Semua' ? _aksiColor(a) : null,
                onTap    : () => setState(() { _filterAksi = a; _applyFilter(); }),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? accent,
  }) {
    final c = accent ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : Colors.white.withOpacity(0.35),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? (accent != null ? Colors.white : _primaryDk) : Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Count badge ────────────────────────────────────────────────────────────
  Widget _buildCountBadge() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filtered.length} aktivitas',
              style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w700, color: _primaryDk),
            ),
          ),
          const SizedBox(width: 8),
          if (_filterJenis != 'Semua' || _filterAksi != 'Semua')
            GestureDetector(
              onTap: () => setState(() {
                _filterJenis = 'Semua'; _filterAksi = 'Semua'; _applyFilter();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.close_rounded, size: 12, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Text('Reset Filter',
                    style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: Colors.red.shade400)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────
  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Belum ada aktivitas',
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade400,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Coba ubah filter di atas',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400)),
        ]),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: () => _loadPage(reset: true),
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _filtered.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == _filtered.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: _primary)),
            );
          }
          return _buildCard(_filtered[i]);
        },
      ),
    );
  }

  // ── Activity card ──────────────────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> item) {
    final jenis      = (item['jenis']       ?? 'info').toString();
    final aksi       = (item['aksi']        ?? 'info').toString();
    final judul      = (item['judul']       ?? '-').toString();
    final deskripsi  = (item['deskripsi']   ?? '').toString();
    final waktu      = (item['waktu_label'] ?? '').toString();

    final dotC  = _dotColor(jenis);
    final bgC   = _bgColor(jenis);
    final aksiC = _aksiColor(aksi);

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Icon aksi
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: bgC, borderRadius: BorderRadius.circular(12)),
            child: Icon(_aksiIcon(aksi), color: dotC, size: 20),
          ),
          const SizedBox(width: 12),
          // Konten
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(judul,
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B))),
            if (deskripsi.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(deskripsi,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 6),
            Row(children: [
              // Badge jenis
              _smallBadge(_jenisLabel[jenis] ?? jenis, dotC, bgC),
              const SizedBox(width: 6),
              // Badge aksi
              _smallBadge(_aksiLabel[aksi] ?? aksi, aksiC, aksiC.withOpacity(0.1)),
              const Spacer(),
              // Waktu
              if (waktu.isNotEmpty) Row(children: [
                Icon(Icons.access_time_rounded, size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text(waktu,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade400)),
              ]),
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _smallBadge(String label, Color textColor, Color bgColor) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(label,
        style: GoogleFonts.poppins(
          fontSize: 10, fontWeight: FontWeight.w700, color: textColor)),
    );
}

