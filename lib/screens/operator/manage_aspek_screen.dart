import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageAspekScreen extends StatefulWidget {
  const ManageAspekScreen({super.key});

  @override
  State<ManageAspekScreen> createState() => _ManageAspekScreenState();
}

class _ManageAspekScreenState extends State<ManageAspekScreen>
    with SingleTickerProviderStateMixin {

  // ── Palet warna hangat & elegan ────────────────────────────────────────────
  static const Color _primary     = Color(0xFFC17B2F);
  static const Color _primaryDark = Color(0xFFA0601A);
  static const Color _bg          = Color(0xFFFDF8F3);
  static const Color _cardBorder  = Color(0xFFF0E8DF);
  static const Color _red         = Color(0xFFDC2626);

  static const List<Color> _aspekColors = [
    Color(0xFFE67E22), Color(0xFF27AE60), Color(0xFF8E44AD), Color(0xFFE74C3C),
    Color(0xFF2980B9), Color(0xFF00838F), Color(0xFFF39C12), Color(0xFFEC4899),
  ];

  static const List<Color> _aspekBgColors = [
    Color(0xFFFFF3E0), Color(0xFFE8F5E9), Color(0xFFEDE7F6), Color(0xFFFDE8E8),
    Color(0xFFE3F2FD), Color(0xFFE0F7FA), Color(0xFFFFF8E1), Color(0xFFFCE4EC),
  ];

  final List<Map<String, dynamic>> _mockAspek = [
    {'id': 1, 'nama_aspek': 'Agama & Moral',  'deskripsi': 'Perkembangan nilai agama dan moral anak'},
    {'id': 2, 'nama_aspek': 'Fisik Motorik',  'deskripsi': 'Kemampuan gerak kasar dan halus'},
    {'id': 3, 'nama_aspek': 'Kognitif',       'deskripsi': 'Kemampuan berpikir dan memecahkan masalah'},
  ];

  List<dynamic> _items         = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading    = true;
  bool _isConnected  = false;
  int  _mockIdCounter = 1000;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final AnimationController _headerAnim;

  // ════════════════════════════════════════════════════════════════════════════
  // ICON MAPPING — Sesuaikan ikon berdasarkan nama aspek
  // ════════════════════════════════════════════════════════════════════════════

  /// Mengembalikan [IconData] yang paling sesuai dengan nama aspek.
  /// Pencocokan dilakukan berdasarkan kata kunci dalam nama aspek (case-insensitive).
  /// Jika tidak ada kata kunci yang cocok, dikembalikan ikon default.
  IconData _getIconForAspek(String nama) {
    final n = nama.toLowerCase();

    // Agama / Moral / Spiritual
    if (n.contains('agama') || n.contains('moral') || n.contains('religi') ||
        n.contains('spiritual') || n.contains('ibadah') || n.contains('akhlak')) {
      return Icons.auto_awesome_rounded;
    }
    // Fisik / Motorik / Gerak
    if (n.contains('fisik') || n.contains('motorik') || n.contains('gerak') ||
        n.contains('tubuh') || n.contains('olahraga') || n.contains('jasmani')) {
      return Icons.directions_run_rounded;
    }
    // Kognitif / Pikir / Berpikir / Logika
    if (n.contains('kognitif') || n.contains('pikir') || n.contains('logika') ||
        n.contains('matematika') || n.contains('sains') || n.contains('ilmu') ||
        n.contains('analisis') || n.contains('problem')) {
      return Icons.psychology_rounded;
    }
    // Bahasa / Komunikasi / Bicara / Literasi
    if (n.contains('bahasa') || n.contains('komunikasi') || n.contains('bicara') ||
        n.contains('literasi') || n.contains('membaca') || n.contains('menulis') ||
        n.contains('bercerita') || n.contains('verbal')) {
      return Icons.record_voice_over_rounded;
    }
    // Sosial / Emosi / Perasaan / Karakter
    if (n.contains('sosial') || n.contains('emosi') || n.contains('perasaan') ||
        n.contains('karakter') || n.contains('empati') || n.contains('interaksi') ||
        n.contains('hubungan')) {
      return Icons.emoji_emotions_rounded;
    }
    // Seni / Kreativitas / Musik / Menggambar
    if (n.contains('seni') || n.contains('kreatif') || n.contains('kreativitas') ||
        n.contains('musik') || n.contains('gambar') || n.contains('melukis') ||
        n.contains('menari') || n.contains('drama') || n.contains('estetika')) {
      return Icons.brush_rounded;
    }
    // Kemandirian / Diri Sendiri / Personal
    if (n.contains('mandiri') || n.contains('kemandirian') || n.contains('diri') ||
        n.contains('personal') || n.contains('disiplin') || n.contains('tanggung')) {
      return Icons.person_rounded;
    }
    // Teknologi / Digital / Komputer
    if (n.contains('teknologi') || n.contains('digital') || n.contains('komputer') ||
        n.contains('ipa') || n.contains('science')) {
      return Icons.science_rounded;
    }
    // Kesehatan / Gizi / Nutrisi
    if (n.contains('kesehatan') || n.contains('gizi') || n.contains('nutrisi') ||
        n.contains('makan') || n.contains('sehat')) {
      return Icons.favorite_rounded;
    }
    // Kelompok / Tim / Sosial-Kelompok
    if (n.contains('kelompok') || n.contains('tim') || n.contains('teman') ||
        n.contains('bermain') || n.contains('kerjasama') || n.contains('kolaborasi')) {
      return Icons.groups_rounded;
    }
    // Membaca / Literasi / Buku
    if (n.contains('buku') || n.contains('baca') || n.contains('cerita') ||
        n.contains('dongeng') || n.contains('pustaka')) {
      return Icons.menu_book_rounded;
    }

    // ── Default fallback ──────────────────────────────────────────────────
    return Icons.assignment_rounded;
  }

  /// Mengembalikan warna berdasarkan index (tetap konsisten per urutan tampil).
  Color _getColorForIndex(int index) => _aspekColors[index % _aspekColors.length];
  Color _getBgColorForIndex(int index) => _aspekBgColors[index % _aspekBgColors.length];

  // ════════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _fetchData();
    _searchController.addListener(() {
      setState(() { _searchQuery = _searchController.text.toLowerCase(); _applyFilter(); });
    });
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DATA
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final result = await ApiService.fetchData('manage_aspek.php', []);
    if (result['status'] == 'success') {
      setState(() {
        _items       = List<dynamic>.from(result['data']);
        _isConnected = result['source'] == 'server';
        _applyFilter();
      });
    }
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    _filteredItems = _searchQuery.isEmpty ? List.from(_items) : _items.where((item) {
      final nama = (item['nama_aspek'] ?? '').toString().toLowerCase();
      final desk = (item['deskripsi']  ?? '').toString().toLowerCase();
      return nama.contains(_searchQuery) || desk.contains(_searchQuery);
    }).toList();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SNACKBAR
  // ════════════════════════════════════════════════════════════════════════════

  void _snackOk(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18), const SizedBox(width: 8), Expanded(child: Text(msg))]),
    backgroundColor: const Color(0xFF27AE60), behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  void _snackErr(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: _red, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  // ════════════════════════════════════════════════════════════════════════════
  // FORM SHEET
  // ════════════════════════════════════════════════════════════════════════════

  void _showFormSheet({Map<String, dynamic>? item}) {
    final bool isEditing = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_aspek'] ?? '');
    final deskCtrl = TextEditingController(text: item?['deskripsi']  ?? '');
    bool isSaving  = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(color: Color(0xFFFDF8F3), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 44, height: 4, margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: _primary.withOpacity(0.25), borderRadius: BorderRadius.circular(4)))),

              // Header gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primary, _primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                    child: Icon(isEditing ? Icons.edit_rounded : Icons.playlist_add_rounded, color: Colors.white, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isEditing ? 'Edit Aspek Penilaian' : 'Tambah Aspek Baru',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(isEditing ? 'Perbarui informasi aspek' : 'Isi data aspek penilaian baru',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  ])),
                ]),
              ),
              const SizedBox(height: 24),

              // Field Nama
              _fLabel('Nama Aspek *'),
              _fField(controller: namaCtrl, icon: Icons.assignment_rounded, hint: 'Contoh: Fisik Motorik'),
              const SizedBox(height: 18),

              // Field Deskripsi
              _fLabel('Deskripsi'),
              _fArea(controller: deskCtrl, hint: 'Penjelasan singkat tentang aspek penilaian ini...'),
              const SizedBox(height: 28),

              // Tombol
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: _primary.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text('Batal', style: TextStyle(color: _primary, fontWeight: FontWeight.w600)))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                  onPressed: isSaving ? null : () async {
                    if (namaCtrl.text.trim().isEmpty) { _snackErr('Nama aspek wajib diisi'); return; }
                    setSheet(() => isSaving = true);

                    final data = <String, dynamic>{
                      'action'     : isEditing ? 'update' : 'add',
                      'nama_aspek' : namaCtrl.text.trim(),
                      'deskripsi'  : deskCtrl.text.trim(),
                    };
                    if (isEditing) data['id'] = item!['id'];

                    if (!_isConnected) {
                      if (isEditing) {
                        final idx = _items.indexWhere((e) => e['id'] == item!['id']);
                        if (idx != -1) setState(() => _items[idx] = {..._items[idx], ...data});
                      } else { setState(() => _items.add({...data, 'id': _mockIdCounter++})); }
                      _applyFilter();
                      if (mounted) Navigator.pop(ctx);
                      return;
                    }

                    final res = await ApiService.postData('manage_aspek.php', data);
                    setSheet(() => isSaving = false);

                    if (res['status'] == 'success') {
                      if (mounted) { Navigator.pop(ctx); _fetchData(); _snackOk(isEditing ? 'Aspek berhasil diperbarui' : 'Aspek berhasil ditambahkan'); }
                    } else { _snackErr(res['message'] ?? 'Gagal menyimpan'); }
                  },
                  child: isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(isEditing ? Icons.save_rounded : Icons.check_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(isEditing ? 'Perbarui' : 'Simpan Aspek', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ]))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DELETE
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: const BoxDecoration(color: Color(0xFFFEF2F2), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(children: [
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _red.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(Icons.delete_outline_rounded, color: _red, size: 32)),
              const SizedBox(height: 12),
              const Text('Hapus Aspek?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B))),
            ])),
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), child: Column(children: [
            Container(width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFDF8F3), borderRadius: BorderRadius.circular(12), border: Border.all(color: _cardBorder)),
              child: Row(children: [
                Icon(Icons.assignment_rounded, color: _primary, size: 18), const SizedBox(width: 10),
                Expanded(child: Text(item['nama_aspek'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              ])),
            const SizedBox(height: 12),
            Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0),
                icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 16),
                label: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ]),
          ])),
        ]),
      ),
    );

    if (confirmed != true || !mounted) return;

    if (!_isConnected) {
      setState(() { _items.removeWhere((e) => e['id'] == item['id']); _applyFilter(); });
      _snackOk('Aspek dihapus'); return;
    }

    final res = await ApiService.postData('manage_aspek.php', {'action': 'delete', 'id': item['id']});
    if (res['status'] == 'success') { _fetchData(); _snackOk(res['message'] ?? 'Aspek berhasil dihapus'); }
    else _snackErr(res['message'] ?? 'Gagal menghapus aspek');
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CARD ASPEK
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildAspekCard(Map<String, dynamic> item, int index) {
    final nama    = item['nama_aspek']?.toString() ?? '-';
    final desk    = item['deskripsi']?.toString()  ?? '';

    // ── Ikon ditentukan dari NAMA aspek, bukan dari urutan ─────────────────
    final icon    = _getIconForAspek(nama);

    // ── Warna tetap berdasarkan urutan tampil (konsisten di layar) ──────────
    final color   = _getColorForIndex(index);
    final bgColor = _getBgColorForIndex(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Material(color: Colors.transparent, child: InkWell(
        onTap: () => _showFormSheet(item: item), borderRadius: BorderRadius.circular(20),
        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          // Avatar
          Container(width: 52, height: 52,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2), width: 1.5)),
            child: Icon(icon, color: color, size: 26)),
          const SizedBox(width: 14),
          // Konten
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (desk.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(desk, 
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.6),
                textAlign: TextAlign.justify,
                overflow: TextOverflow.visible),
            ],
          ])),
          // Menu titik tiga
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Row(children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.edit_rounded, color: Colors.blue.shade600, size: 16)),
                const SizedBox(width: 12),
                const Text('Edit Aspek', style: TextStyle(fontWeight: FontWeight.w600)),
              ])),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'delete', child: Row(children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 16)),
                const SizedBox(width: 12),
                Text('Hapus', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade600)),
              ])),
            ],
            onSelected: (val) {
              if (val == 'edit')   _showFormSheet(item: item);
              if (val == 'delete') _confirmDelete(item);
            },
          ),
        ])),
      )),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FORM HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _fLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))));

  Widget _fField({required TextEditingController controller, required IconData icon, required String hint}) =>
    Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _cardBorder),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))]),
      child: TextField(controller: controller, decoration: InputDecoration(
        border: InputBorder.none, hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: _primary, size: 20), contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16))));

  Widget _fArea({required TextEditingController controller, required String hint}) =>
    Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _cardBorder),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))]),
      child: TextField(controller: controller, maxLines: 4, decoration: InputDecoration(
        border: InputBorder.none, hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13), contentPadding: const EdgeInsets.all(16))));

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('Aspek Penilaian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchData)],
      ),
      body: Column(children: [

        // ── Header gradient ────────────────────────────────────────────────
        AnimatedBuilder(animation: _headerAnim, builder: (_, __) => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_primary, _primaryDark, const Color(0xFF8B5E1A)], stops: const [0.0, 0.5, 1.0]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          child: Stack(children: [
            Positioned(right: -20, bottom: -20, child: Opacity(opacity: 0.07 + _headerAnim.value * 0.05,
              child: Icon(Icons.assignment_rounded, size: sw * 0.5, color: Colors.white))),
            Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Aspek Penilaian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 4),
              Text('Kelola aspek penilaian tumbuh kembang anak', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
              const SizedBox(height: 18),
              _statChip(icon: Icons.assignment_rounded, label: 'Total Aspek', value: '${_items.length}'),
            ])),
          ]),
        )),

        // ── Search bar ────────────────────────────────────────────────────
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
          child: TextField(controller: _searchController, decoration: InputDecoration(
            hintText: 'Cari nama atau deskripsi aspek...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: _primary, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(icon: Icon(Icons.close_rounded, color: Colors.grey.shade400), onPressed: _searchController.clear)
                : null,
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14),
          )),
        )),

        // ── Counter ───────────────────────────────────────────────────────
        if (!_isLoading)
          Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 2), child: Align(alignment: Alignment.centerLeft,
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('${_filteredItems.length} Aspek Penilaian',
                style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 12))))),

        // ── List ──────────────────────────────────────────────────────────
        Expanded(child: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(onRefresh: _fetchData, color: _primary,
              child: _filteredItems.isEmpty
                ? ListView(children: [SizedBox(height: 300, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.list_alt_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 12),
                    Text(_searchQuery.isEmpty ? 'Belum ada aspek penilaian' : 'Aspek tidak ditemukan',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500)),
                    if (_searchQuery.isEmpty) ...[const SizedBox(height: 8), Text('Tekan + untuk menambahkan', style: TextStyle(color: Colors.grey.shade400, fontSize: 12))],
                  ])))])
                : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 10, 16, 100), itemCount: _filteredItems.length,
                    itemBuilder: (_, i) => _buildAspekCard(Map<String, dynamic>.from(_filteredItems[i]), i)))),
      ]),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormSheet(), backgroundColor: _primary, elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tambah Aspek', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Stat chip header ──────────────────────────────────────────────────────
  Widget _statChip({required IconData icon, required String label, required String value}) =>
    Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFFFFE0A3), size: 14)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
        ]),
      ]));
}
