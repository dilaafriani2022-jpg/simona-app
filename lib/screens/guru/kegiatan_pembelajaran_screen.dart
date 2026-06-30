import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class KegiatanPembelajaranScreen extends StatefulWidget {
  final int? idGuru;
  final int? idTujuan;
  final Map<String, dynamic>? tujuanData;
  const KegiatanPembelajaranScreen({
    super.key,
    this.idGuru,
    this.idTujuan,
    this.tujuanData,
  });

  @override
  State<KegiatanPembelajaranScreen> createState() =>
      _KegiatanPembelajaranScreenState();
}

class _KegiatanPembelajaranScreenState extends State<KegiatanPembelajaranScreen>
    with SingleTickerProviderStateMixin {
  // ── Palet warna ───────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFFC17B2F);
  static const Color _primaryDark = Color(0xFFA0601A);
  static const Color _surface = Colors.white;
  static const Color _bg = Color(0xFFFDF8F3);
  static const Color _green = Color(0xFF059669);
  static const Color _red = Color(0xFFDC2626);
  static const Color _slate = Color(0xFF64748B);
  static const Color _cardBorder = Color(0xFFF0E8DF);

  // Total 18 minggu: Bulan 1-4 = 4 minggu each (1-16), Bulan 5 = 2 minggu (17-18)
  static const int _totalBulan = 5;
  static const int _mingguPerBulanDefault = 4;

  static int _weeksForBulan(int bulan) => bulan == 5 ? 2 : 4;
  static int _startWeekOfBulan(int bulan) =>
      bulan <= 1 ? 1 : (bulan - 1) * _mingguPerBulanDefault + 1;

  // ── State ─────────────────────────────────────────────────────────────────
  List<dynamic> _kegiatanList = [];
  List<dynamic> _tujuanList = [];
  bool _isLoading = true;
  int _expandedIdx = -1;
  String _searchQuery = '';
  late TextEditingController _searchCtrl;
  late TabController _tabCtrl;
  int _selectedBulan = 1;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
    _tabCtrl = TabController(length: _totalBulan, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() {
          _selectedBulan = _tabCtrl.index + 1;
          _expandedIdx = -1;
          _searchCtrl.clear();
        });
      }
    });
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LOAD DATA
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadTujuan(),
        _loadKegiatan(),
      ]);
    } catch (e) {
      debugPrint('❌ Load error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTujuan() async {
    try {
      final idGuru = widget.idGuru ?? 2;
      final res = await ApiService.fetch('manage_tujuan_pembelajaran.php?id_guru=$idGuru');
      if (res['status'] == 'success' && res['data'] is List) {
        setState(() => _tujuanList = res['data']);
      }
    } catch (e) {
      debugPrint('❌ Load tujuan error: $e');
    }
  }

  Future<void> _loadKegiatan() async {
    try {
      final idGuru = widget.idGuru ?? 2;
      final idTujuan = widget.idTujuan ?? 0;
      final query = idTujuan > 0 ? '?id_guru=$idGuru&id_tujuan=$idTujuan' : '?id_guru=$idGuru';
      final res = await ApiService.fetch('manage_kegiatan_pembelajaran.php$query');
      if (res['status'] == 'success' && res['data'] is List) {
        setState(() => _kegiatanList = res['data']);
      }
    } catch (e) {
      debugPrint('❌ Load kegiatan error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CRUD
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _saveKegiatan({required Map<String, dynamic> data}) async {
    try {
      debugPrint('💾 Saving kegiatan: $data');
      final idGuru = widget.idGuru ?? 2;
      data['id_guru'] = idGuru;

      debugPrint('✅ Final data to send: $data');
      final res = await ApiService.postData('manage_kegiatan_pembelajaran.php', data);
      debugPrint('📥 Response: $res');

      if (res['status'] == 'success') {
        await _loadKegiatan();
        _snackOk(data['action'] == 'add'
            ? 'Kegiatan pembelajaran berhasil ditambahkan'
            : 'Kegiatan pembelajaran berhasil diperbarui');
      } else {
        final message = res['message'] ?? 'Gagal menyimpan - Error tidak diketahui';
        debugPrint('❌ Error from backend: $message');
        _snackErr(message);
      }
    } catch (e) {
      debugPrint('❌ Save error: $e');
      _snackErr('Error: $e');
    }
  }

  Future<void> _deleteKegiatan(int id, String nama) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _red.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(Icons.delete_outline_rounded, color: _red, size: 28),
                  ),
                  const SizedBox(height: 10),
                  const Text('Hapus Kegiatan Pembelajaran?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.assignment_rounded, color: _primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(nama,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Tindakan ini tidak dapat dibatalkan.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          child: const Text('Batal', style: TextStyle(color: _slate, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 15),
                          label: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
      final idGuru = widget.idGuru ?? 2;
      debugPrint('🗑️ Deleting kegiatan ID: $id with guru ID: $idGuru');
      final res = await ApiService.postData('manage_kegiatan_pembelajaran.php', {
        'action': 'delete',
        'id': id,
        'id_guru': idGuru,
      });
      debugPrint('📥 Delete response: $res');
      if (res['status'] == 'success') {
        await _loadKegiatan();
        _snackOk('Kegiatan pembelajaran berhasil dihapus');
      } else {
        final message = res['message'] ?? 'Gagal menghapus - Error tidak diketahui';
        debugPrint('❌ Delete error: $message');
        _snackErr(message);
      }
    } catch (e) {
      debugPrint('❌ Delete exception: $e');
      _snackErr('Error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FILTER
  // ════════════════════════════════════════════════════════════════════════════

  List<dynamic> get _filtered => _kegiatanList.where((item) {
        final bulan = int.tryParse(item['bulan']?.toString() ?? '1') ?? 1;
        final nama = (item['nama_kegiatan'] ?? '').toString().toLowerCase();
        return bulan == _selectedBulan &&
            (_searchQuery.isEmpty || nama.contains(_searchQuery));
      }).toList();

  // ════════════════════════════════════════════════════════════════════════════
  // FORM SHEET
  // ════════════════════════════════════════════════════════════════════════════

  void _showFormSheet({Map<String, dynamic>? item}) {
    final bool isEditing = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_kegiatan'] ?? '');
    final deskCtrl = TextEditingController(text: item?['deskripsi'] ?? '');

    int? selectedTujuan;
    int selectedFormBulan = _selectedBulan;
    if (isEditing && item != null) {
      try {
        final tujuanId = item['id_tujuan'];
        if (tujuanId != null) {
          selectedTujuan = int.tryParse(tujuanId.toString());
        }
        final b = item['bulan'];
        if (b != null) {
          selectedFormBulan = int.tryParse(b.toString()) ?? _selectedBulan;
        }
      } catch (e) {
        debugPrint('Error parsing item data: $e');
      }
    } else if (!isEditing && widget.idTujuan != null) {
      selectedTujuan = widget.idTujuan;
    }
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFFFDF8F3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                // Header
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primary, _primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_rounded : Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Kegiatan Pembelajaran' : 'Tambah Kegiatan Pembelajaran',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEditing ? 'Perbarui data kegiatan' : 'Isi kegiatan pembelajaran baru',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Bulan Picker ───────────────────────────────────────────
                _fLabel('Bulan *'),
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: DropdownButton<int>(
                    value: selectedFormBulan,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: List.generate(
                      _totalBulan,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Bulan ${i + 1}'),
                        ),
                      ),
                    ),
                    onChanged: (v) => setSheet(
                        () => selectedFormBulan = v ?? _selectedBulan),
                  ),
                ),
                const SizedBox(height: 14),

                // Tujuan dropdown
                _fLabel('Tujuan Pembelajaran *'),
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: DropdownButton<int>(
                    value: selectedTujuan,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Pilih tujuan pembelajaran', style: TextStyle(fontSize: 13)),
                    ),
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: _tujuanList
                        .map((t) => DropdownMenuItem(
                              value: int.parse(t['id'].toString()),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(t['nama_tujuan'] ?? '-', style: const TextStyle(fontSize: 12)),
                                    Text(t['nama_aspek'] ?? '-', 
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setSheet(() => selectedTujuan = v),
                  ),
                ),
                const SizedBox(height: 14),

                // Nama Kegiatan
                _fLabel('Nama Kegiatan Pembelajaran *'),
                _fArea(
                  controller: namaCtrl,
                  hint: 'Contoh: Anak mampu melipat pola sederhana, menggunting, dan menempel',
                  minLines: 2,
                ),
                const SizedBox(height: 14),

                // Deskripsi
                _fLabel('Deskripsi'),
                _fArea(
                  controller: deskCtrl,
                  hint: 'Penjelasan detail tentang aktivitas kegiatan pembelajaran ini...',
                  minLines: 2,
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _primary.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Batal', style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (namaCtrl.text.trim().isEmpty) {
                                  _snackErr('Nama kegiatan wajib diisi');
                                  return;
                                }
                                if (selectedTujuan == null) {
                                  _snackErr('Pilih tujuan pembelajaran');
                                  return;
                                }

                                setSheet(() => isSaving = true);

                                final data = <String, dynamic>{
                                  'action': isEditing ? 'update' : 'add',
                                  'id_tujuan': selectedTujuan,
                                  'nama_kegiatan': namaCtrl.text.trim(),
                                  'deskripsi': deskCtrl.text.trim(),
                                  'bulan': selectedFormBulan,
                                };

                                if (isEditing) {
                                  data['id'] = item!['id'];
                                }

                                await _saveKegiatan(data: data);
                                if (mounted) Navigator.pop(ctx);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEditing ? 'Perbarui' : 'Simpan',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
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
  // CARD & WIDGETS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildKegiatanCard(dynamic item, int idx) {
    final isExpanded = _expandedIdx == idx;
    final nama = item['nama_kegiatan'].toString();
    final deskripsi = item['deskripsi']?.toString() ?? '';
    final tujuan = item['nama_tujuan']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _green, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isExpanded ? 0.08 : 0.04),
            blurRadius: isExpanded ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expandedIdx = isExpanded ? -1 : idx),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _green.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.task_alt_rounded, color: _green, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tujuan,
                                style: TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Bln ${item['bulan'] ?? _selectedBulan}',
                                style: TextStyle(fontSize: 10, color: Colors.indigo.shade600, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_rounded, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text('Edit', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_rounded, size: 16, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              const Text('Hapus', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (val) {
                        if (val == 'edit') _showFormSheet(item: item);
                        if (val == 'delete') _deleteKegiatan(int.parse(item['id'].toString()), nama);
                      },
                    ),
                  ],
                ),

                // Expand
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeInOut,
                  child: isExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(height: 1, color: Colors.grey.shade200),
                              const SizedBox(height: 10),
                              if (deskripsi.isNotEmpty) ...[
                                _label('Deskripsi'),
                                const SizedBox(height: 4),
                                Text(
                                  deskripsi,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.5),
                                  textAlign: TextAlign.justify,
                                ),
                              ],
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF1E293B),
            )),
      );

  Widget _fArea({required TextEditingController controller, required String hint, int minLines = 3}) =>
      Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
        child: TextField(
          controller: controller,
          minLines: minLines,
          maxLines: null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 12),
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: _green),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // SNACKBAR
  // ════════════════════════════════════════════════════════════════════════════

  void _snackOk(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 12))),
          ],
        ),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  void _snackErr(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12)),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

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
          'Kegiatan Pembelajaran',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          tabAlignment: TabAlignment.start,
          tabs: List.generate(_totalBulan, (i) {
            final bulanNum = i + 1;
            final startW = _startWeekOfBulan(bulanNum);
            final endW = startW + _weeksForBulan(bulanNum) - 1;
            final count = _kegiatanList
                .where((item) =>
                    (int.tryParse(item['bulan']?.toString() ?? '1') ?? 1) ==
                    bulanNum)
                .length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bulan $bulanNum (Minggu $startW-$endW)'),
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
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, _primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Bulan $_selectedBulan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_filtered.length} Kegiatan',
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Kegiatan pembelajaran per bulan untuk penilaian anak',
                  style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari kegiatan pembelajaran...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search_rounded, color: _green, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                          onPressed: _searchCtrl.clear,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),

          // Counter
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${filtered.length} Data',
                  style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _primary))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 52, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Belum ada kegiatan untuk Bulan $_selectedBulan'
                                  : 'Tidak ada hasil',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Tekan + untuk menambah',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAll,
                        color: _primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _buildKegiatanCard(filtered[i], i),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : () => _showFormSheet(),
        backgroundColor: _primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tambah Kegiatan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

