import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EkstrakurikulerScreen extends StatefulWidget {
  final int? idGuru;
  final int? idKelas;

  const EkstrakurikulerScreen({super.key, this.idGuru, this.idKelas});

  @override
  State<EkstrakurikulerScreen> createState() => _EkstrakurikulerScreenState();
}

class _EkstrakurikulerScreenState extends State<EkstrakurikulerScreen> {
  // ---------------------------------------------------------------------
  // PALET WARNA — dihangatkan sedikit, tetap dalam keluarga cyan/teal
  // agar konsisten dengan brand, tapi dengan aksen amber untuk kehangatan.
  // ---------------------------------------------------------------------
  static const Color _primary = Color(0xFF0891B2); // cyan lebih dalam, lebih elegan
  static const Color _primaryDark = Color(0xFF0E7490);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _surface = Colors.white;
  static const Color _green = Color(0xFF059669);
  static const Color _greenSoft = Color(0xFFECFDF5);
  static const Color _red = Color(0xFFDC2626);
  static const Color _redSoft = Color(0xFFFEF2F2);
  static const Color _amber = Color(0xFFD97706); // aksen hangat untuk prestasi
  static const Color _amberSoft = Color(0xFFFFFBEB);
  static const Color _slate = Color(0xFF64748B);
  static const Color _slateDark = Color(0xFF334155);
  static const Color _border = Color(0xFFE2E8F0);

  List<dynamic> _ekstraList = [];
  List<dynamic> _anakEkstraList = [];
  List<dynamic> _anakList = [];
  bool _isLoading = true;
  int? _expandedIdx = -1;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadEkstra(), _loadAnakEkstra(), _loadAnak()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadEkstra() async {
    try {
      final res = await ApiService.fetch('manage_ekstrakurikuler.php?type=list');
      if (res['status'] == 'success') {
        setState(() => _ekstraList = List<dynamic>.from(res['data'] ?? []));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _loadAnakEkstra() async {
    try {
      final res = await ApiService.fetch(
        'manage_ekstrakurikuler.php?type=anak-ekstra&id_guru=${widget.idGuru ?? 2}',
      );
      if (res['status'] == 'success') {
        setState(() => _anakEkstraList = List<dynamic>.from(res['data'] ?? []));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _loadAnak() async {
    try {
      final idKelas = widget.idKelas ?? 2;
      final res = await ApiService.fetch('manage_anak.php?id_kelas=$idKelas');
      if (res['status'] == 'success') {
        setState(() => _anakList = List<dynamic>.from(res['data'] ?? []));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? _red : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // FORM: Tambah / Edit Program Ekstrakurikuler
  // ---------------------------------------------------------------------
  void _showFormDialog({dynamic item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: isEdit ? item['nama'] : '');
    final deskCtrl = TextEditingController(text: isEdit ? (item['deskripsi'] ?? '') : '');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon header — memberi kesan ramah, bukan sekadar form kaku
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isEdit ? Icons.edit_rounded : Icons.sports_basketball_rounded,
                    color: _primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEdit ? 'Edit Program' : 'Tambah Program Baru',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _slateDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lengkapi informasi ekstrakurikuler di bawah ini',
                  style: TextStyle(fontSize: 12.5, color: _slate),
                ),
                const SizedBox(height: 22),

                _FieldLabel('Nama Ekstrakurikuler'),
                const SizedBox(height: 6),
                TextField(
                  controller: namaCtrl,
                  decoration: _inputDecoration(hint: 'Contoh: Pramuka, Futsal, Paduan Suara'),
                ),
                const SizedBox(height: 16),

                _FieldLabel('Deskripsi', optional: true),
                const SizedBox(height: 6),
                TextField(
                  controller: deskCtrl,
                  maxLines: 3,
                  decoration: _inputDecoration(hint: 'Ceritakan singkat tentang program ini...'),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaving ? null : () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(color: _border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Batal', style: TextStyle(color: _slate, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (namaCtrl.text.trim().isEmpty) {
                                  _showSnack('Nama ekstrakurikuler wajib diisi', isError: true);
                                  return;
                                }

                                setStateDialog(() => isSaving = true);

                                final payload = {
                                  'action': 'add_ekstra',
                                  'nama': namaCtrl.text.trim(),
                                  'deskripsi': deskCtrl.text.trim(),
                                };

                                try {
                                  final res = await ApiService.post('manage_ekstrakurikuler.php', payload);
                                  if (!mounted) return;
                                  if (res['status'] == 'success') {
                                    await _loadEkstra();
                                    Navigator.pop(ctx);
                                    _showSnack('Program berhasil disimpan');
                                  } else {
                                    setStateDialog(() => isSaving = false);
                                    _showSnack(res['message'] ?? 'Gagal menyimpan data', isError: true);
                                  }
                                } catch (e) {
                                  setStateDialog(() => isSaving = false);
                                  _showSnack('Terjadi kesalahan: $e', isError: true);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                              )
                            : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

  // ---------------------------------------------------------------------
  // FORM: Tambah Partisipasi Anak
  // ---------------------------------------------------------------------
  void _showAnakDialog() {
    int? selectedAnak;
    int? selectedEkstra;
    final catatanCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: _amber, size: 26),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tambah Partisipasi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _slateDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catat keikutsertaan anak pada program ekstrakurikuler',
                      style: TextStyle(fontSize: 12.5, color: _slate),
                    ),
                    const SizedBox(height: 22),

                    _FieldLabel('Anak'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedAnak?.toString(),
                      hint: Text('Pilih anak', style: TextStyle(color: _slate.withOpacity(0.6), fontSize: 14)),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _slate),
                      decoration: _inputDecoration(),
                      items: _anakList
                          .map<DropdownMenuItem<String>>((s) => DropdownMenuItem(
                                value: s['id'].toString(),
                                child: Text(s['nama_anak'] ?? '-'),
                              ))
                          .toList(),
                      onChanged: (v) => setStateDialog(() => selectedAnak = int.tryParse(v ?? '')),
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel('Ekstrakurikuler'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedEkstra?.toString(),
                      hint: Text('Pilih program', style: TextStyle(color: _slate.withOpacity(0.6), fontSize: 14)),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _slate),
                      decoration: _inputDecoration(),
                      items: _ekstraList
                          .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                                value: e['id'].toString(),
                                child: Text(e['nama'] ?? '-'),
                              ))
                          .toList(),
                      onChanged: (v) => setStateDialog(() => selectedEkstra = int.tryParse(v ?? '')),
                    ),
                    const SizedBox(height: 16),



                    _FieldLabel('Catatan', optional: true),
                    const SizedBox(height: 6),
                    TextField(
                      controller: catatanCtrl,
                      maxLines: 2,
                      decoration: _inputDecoration(hint: 'Catatan tambahan dari pembimbing...'),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(color: _border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Batal', style: TextStyle(color: _slate, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (selectedAnak == null || selectedEkstra == null) {
                                      _showSnack('Pilih anak dan ekstrakurikuler terlebih dahulu', isError: true);
                                      return;
                                    }

                                    setStateDialog(() => isSaving = true);

                                    final payload = {
                                      'action': 'add_anak_ekstra',
                                      'id_anak': selectedAnak,
                                      'id_guru': widget.idGuru ?? 2,
                                      'id_ekstrakurikuler': selectedEkstra,
                                      'semester': 1,
                                      'prestasi': '',
                                      'catatan': catatanCtrl.text.trim(),
                                    };

                                    try {
                                      final res = await ApiService.post('manage_ekstrakurikuler.php', payload);
                                      if (!mounted) return;
                                      if (res['status'] == 'success') {
                                        await _loadAnakEkstra();
                                        Navigator.pop(ctx);
                                        _showSnack('Partisipasi berhasil ditambahkan');
                                      } else {
                                        setStateDialog(() => isSaving = false);
                                        _showSnack(res['message'] ?? 'Gagal menambahkan data', isError: true);
                                      }
                                    } catch (e) {
                                      setStateDialog(() => isSaving = false);
                                      _showSnack('Terjadi kesalahan: $e', isError: true);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                  )
                                : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(dynamic se) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _redSoft, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_outline_rounded, color: _red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Hapus Data?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Partisipasi "${se['nama_anak'] ?? '-'}" pada "${se['nama_ekstrakurikuler'] ?? '-'}" akan dihapus secara permanen.',
          style: const TextStyle(fontSize: 13.5, color: _slate, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: _slate)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await ApiService.post('manage_ekstrakurikuler.php', {
        'action': 'delete_anak_ekstra',
        'id': se['id'],
      });
      if (!mounted) return;
      if (res['status'] == 'success') {
        await _loadAnakEkstra();
        _showSnack('Data berhasil dihapus');
      } else {
        _showSnack(res['message'] ?? 'Gagal menghapus data', isError: true);
      }
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e', isError: true);
    }
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _slate.withOpacity(0.55), fontSize: 13.5),
      filled: true,
      fillColor: _bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ekstrakurikuler',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: 0.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              color: _primary,
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Daftar Ekstrakurikuler', Icons.sports_basketball_rounded),
                  const SizedBox(height: 12),
                  _ekstraList.isEmpty ? _buildEmptyState('Belum ada program ekstrakurikuler') : _buildEkstraList(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Partisipasi Anak', Icons.groups_rounded),
                  const SizedBox(height: 12),
                  _anakEkstraList.isEmpty
                      ? _buildEmptyState('Belum ada data partisipasi anak')
                      : _buildAnakEkstraList(),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _showAnakDialog,
            label: const Text('Tambah Partisipasi', style: TextStyle(fontWeight: FontWeight.w600)),
            icon: const Icon(Icons.person_add_rounded),
            backgroundColor: _amber,
            heroTag: 'add_anak',
            elevation: 2,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () => _showFormDialog(),
            label: const Text('Tambah Program', style: TextStyle(fontWeight: FontWeight.w600)),
            icon: const Icon(Icons.add_rounded),
            backgroundColor: _primary,
            heroTag: 'add_ekstra',
            elevation: 2,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // HEADER — gradient hangat dengan ringkasan statistik
  // ---------------------------------------------------------------------
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.stadium_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Program Ekstrakurikuler',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  icon: Icons.sports_basketball_rounded,
                  value: '${_ekstraList.length}',
                  label: 'Program',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatPill(
                  icon: Icons.groups_rounded,
                  value: '${_anakEkstraList.length}',
                  label: 'Partisipasi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _slate),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: _slateDark, letterSpacing: 0.1),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 36, color: _slate.withOpacity(0.3)),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: _slate.withOpacity(0.7), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEkstraList() {
    return Column(
      children: _ekstraList.asMap().entries.map((e) {
        int idx = e.key;
        var ekstra = e.value;
        bool isExpanded = _expandedIdx == idx;
        bool hasDesc = (ekstra['deskripsi'] ?? '').toString().trim().isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expandedIdx = isExpanded ? -1 : idx),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.sports_basketball_rounded, color: _primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ekstra['nama'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: _slateDark),
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          color: _slate,
                        ),
                      ],
                    ),
                    if (isExpanded && hasDesc) ...[
                      const SizedBox(height: 12),
                      Container(height: 1, color: _border),
                      const SizedBox(height: 12),
                      Text(
                        ekstra['deskripsi'] ?? '',
                        style: TextStyle(fontSize: 13, color: _slate.withOpacity(0.9), height: 1.45),
                      ),
                    ] else if (isExpanded && !hasDesc) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada deskripsi untuk program ini.',
                        style: TextStyle(fontSize: 12.5, color: _slate.withOpacity(0.5), fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnakEkstraList() {
    return Column(
      children: _anakEkstraList.map((se) {
        final namaAnak = (se['nama_anak'] ?? 'S').toString();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showDetailDialog(se),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _primary.withOpacity(0.1),
                    child: Text(
                      namaAnak.isNotEmpty ? namaAnak[0].toUpperCase() : 'S',
                      style: const TextStyle(color: _primary, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaAnak,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: _slateDark),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.sports_basketball_rounded, size: 12, color: _slate.withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                se['nama_ekstrakurikuler'] ?? '-',
                                style: TextStyle(fontSize: 12, color: _slate.withOpacity(0.8)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert_rounded, color: _slate.withOpacity(0.6), size: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (c) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: _red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: _red, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') _confirmDelete(se);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showDetailDialog(dynamic anakEkstra) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primary, _primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  anakEkstra['nama_anak'] ?? '-',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  anakEkstra['nama_ekstrakurikuler'] ?? '-',
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Catatan
                      if ((anakEkstra['catatan'] ?? '').toString().isNotEmpty) ...[
                        const Text('Catatan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _slateDark)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _slate.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border),
                          ),
                          child: Text(
                            anakEkstra['catatan'] ?? '-',
                            style: TextStyle(fontSize: 13, color: _slateDark, height: 1.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Info Semester
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text('Semester', style: TextStyle(fontSize: 11, color: _slate.withOpacity(0.7))),
                                const SizedBox(height: 4),
                                Text(
                                  '${anakEkstra['semester'] ?? '-'}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primary),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 35, color: _border),
                            Column(
                              children: [
                                Text('Input Tanggal', style: TextStyle(fontSize: 11, color: _slate.withOpacity(0.7))),
                                const SizedBox(height: 4),
                                Text(
                                  anakEkstra['tanggal_input'] ?? '-',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _slateDark),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Close Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// WIDGET PEMBANTU
// ---------------------------------------------------------------------

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatPill({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool optional;

  const _FieldLabel(this.text, {this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text(
            '(opsional)',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}
