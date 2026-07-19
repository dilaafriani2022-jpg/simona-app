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
  static const Color _primary = Color(0xFF0891B2);
  static const Color _primaryDark = Color(0xFF0E7490);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _surface = Colors.white;
  static const Color _green = Color(0xFF059669);
  static const Color _red = Color(0xFFDC2626);
  static const Color _redSoft = Color(0xFFFEF2F2);
  static const Color _amber = Color(0xFFD97706);
  static const Color _slate = Color(0xFF64748B);
  static const Color _slateDark = Color(0xFF334155);
  static const Color _border = Color(0xFFE2E8F0);

  List<dynamic> _anakEkstraList = [];
  List<dynamic> _anakList = [];
  List<String> _suggestedNames = ['Pramuka', 'Tari', 'Lukis', 'Musik', 'Futsal', 'Keagamaan'];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadSuggestions(), _loadAnakEkstra(), _loadAnak()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSuggestions() async {
    try {
      final res = await ApiService.fetch('manage_ekstrakurikuler.php?type=list');
      if (res['status'] == 'success') {
        final List<dynamic> list = res['data'] ?? [];
        final names = list.map((e) => e['nama'].toString()).where((n) => n.isNotEmpty).toList();
        if (names.isNotEmpty) {
          setState(() {
            // merge default suggestions with DB suggestions (unique)
            final merged = {..._suggestedNames, ...names}.toList();
            _suggestedNames = merged;
          });
        }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // DIALOG: TAMBAH & EDIT DATA EKSTRAKURIKULER ANAK
  // ---------------------------------------------------------------------
  void _showEkskulDialog({dynamic item}) {
    final isEdit = item != null;
    int? selectedAnak = isEdit ? int.tryParse(item['id_anak']?.toString() ?? '') : null;
    final namaCtrl = TextEditingController(text: isEdit ? item['nama_ekstrakurikuler'] : '');
    final catatanCtrl = TextEditingController(text: isEdit ? (item['catatan'] ?? '') : '');
    int selectedSemester = isEdit ? int.tryParse(item['semester']?.toString() ?? '1') ?? 1 : 1;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final screenHeight = MediaQuery.of(ctx).size.height;
          final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
          final maxDialogHeight = screenHeight - keyboardHeight - 50;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: AnimatedPadding(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              duration: const Duration(milliseconds: 100),
              curve: Curves.decelerate,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxDialogHeight > 620 ? 620 : (maxDialogHeight > 300 ? maxDialogHeight : 300),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(isEdit ? Icons.edit_note_rounded : Icons.emoji_events_rounded, color: _amber, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Edit Data Ekskul' : 'Tambah Partisipasi Ekskul',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _slateDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEdit
                                      ? 'Perbarui catatan kegiatan ekstrakurikuler anak'
                                      : 'Catat keikutsertaan anak pada program ekstrakurikuler',
                                  style: const TextStyle(fontSize: 11, color: _slate),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Form Fields (Scrollable)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Anak Didik'),
                              const SizedBox(height: 6),
                              isEdit
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _bg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _border),
                                      ),
                                      child: Text(
                                        item['nama_anak'] ?? '-',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: _slateDark),
                                      ),
                                    )
                                  : DropdownButtonFormField<String>(
                                      value: selectedAnak?.toString(),
                                      hint: Text('Pilih anak didik', style: TextStyle(color: _slate.withOpacity(0.6), fontSize: 14)),
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

                              _FieldLabel('Nama Ekstrakurikuler'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: namaCtrl,
                                decoration: _inputDecoration(hint: 'Contoh: Pramuka, Futsal, Tari, Mewarnai'),
                                onChanged: (val) {
                                  setStateDialog(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                              // Suggestion Chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _suggestedNames.take(6).map((name) {
                                  return ChoiceChip(
                                    label: Text(name, style: const TextStyle(fontSize: 11.5)),
                                    selected: namaCtrl.text.trim().toLowerCase() == name.toLowerCase(),
                                    selectedColor: _primary.withOpacity(0.2),
                                    backgroundColor: _bg,
                                    labelStyle: TextStyle(
                                      color: namaCtrl.text.trim().toLowerCase() == name.toLowerCase() ? _primaryDark : _slateDark,
                                      fontWeight: namaCtrl.text.trim().toLowerCase() == name.toLowerCase() ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: namaCtrl.text.trim().toLowerCase() == name.toLowerCase() ? _primary : _border),
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setStateDialog(() {
                                          namaCtrl.text = name;
                                        });
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              _FieldLabel('Semester'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                value: selectedSemester,
                                decoration: _inputDecoration(),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('Semester 1')),
                                  DropdownMenuItem(value: 2, child: Text('Semester 2')),
                                ],
                                onChanged: (v) => setStateDialog(() => selectedSemester = v ?? 1),
                              ),
                              const SizedBox(height: 16),

                              _FieldLabel('Deskripsi/Catatan Perkembangan', optional: true),
                              const SizedBox(height: 6),
                              TextField(
                                controller: catatanCtrl,
                                maxLines: 3,
                                decoration: _inputDecoration(hint: 'Contoh: Anak aktif mengikuti latihan dan menguasai gerakan dasar tari daerah dengan baik.'),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actions
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
                                      if (selectedAnak == null) {
                                        _showSnack('Pilih anak didik terlebih dahulu', isError: true);
                                        return;
                                      }
                                      if (namaCtrl.text.trim().isEmpty) {
                                        _showSnack('Nama ekstrakurikuler wajib diisi', isError: true);
                                        return;
                                      }

                                      setStateDialog(() => isSaving = true);

                                      final payload = {
                                        'action': 'add_anak_ekstra',
                                        'id': isEdit ? item['id'] : null,
                                        'id_anak': selectedAnak,
                                        'id_guru': widget.idGuru ?? 2,
                                        'nama_ekstrakurikuler': namaCtrl.text.trim(),
                                        'semester': selectedSemester,
                                        'prestasi': '',
                                        'catatan': catatanCtrl.text.trim(),
                                      };

                                      try {
                                        final res = await ApiService.post('manage_ekstrakurikuler.php', payload);
                                        if (!mounted) return;
                                        if (res['status'] == 'success') {
                                          await _loadAnakEkstra();
                                          await _loadSuggestions();
                                          Navigator.pop(ctx);
                                          _showSnack(isEdit ? 'Data berhasil diperbarui' : 'Data berhasil ditambahkan');
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
          'Partisipasi "${se['nama_anak'] ?? '-'}" pada kegiatan "${se['nama_ekstrakurikuler'] ?? '-'}" akan dihapus secara permanen.',
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
    // filter list based on search query
    final filteredList = _anakEkstraList.where((se) {
      final nAnak = (se['nama_anak'] ?? '').toString().toLowerCase();
      final nEks = (se['nama_ekstrakurikuler'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return nAnak.contains(q) || nEks.contains(q);
    }).toList();

    // calculate unique activities
    final uniqueActivities = _anakEkstraList.map((e) => e['nama_ekstrakurikuler'].toString().trim().toLowerCase()).toSet().length;

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
                  _buildHeaderCard(uniqueActivities),
                  const SizedBox(height: 20),
                  // Search Bar
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari nama anak atau kegiatan ekskul...',
                      prefixIcon: const Icon(Icons.search_rounded, color: _slate, size: 20),
                      fillColor: _surface,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Daftar Partisipasi & Catatan Anak', Icons.groups_rounded),
                  const SizedBox(height: 12),
                  filteredList.isEmpty
                      ? _buildEmptyState(_searchQuery.isNotEmpty ? 'Pencarian tidak ditemukan' : 'Belum ada data partisipasi anak')
                      : _buildAnakEkstraList(filteredList),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEkskulDialog(),
        label: const Text('Tambah Data', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        backgroundColor: _primary,
        elevation: 3,
      ),
    );
  }

  Widget _buildHeaderCard(int uniqueCount) {
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
          const Row(
            children: [
              Icon(Icons.stadium_rounded, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kegiatan Ekstrakurikuler',
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
                  icon: Icons.groups_rounded,
                  value: '${_anakEkstraList.length}',
                  label: 'Partisipasi Anak',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatPill(
                  icon: Icons.sports_basketball_rounded,
                  value: '$uniqueCount',
                  label: 'Jenis Kegiatan',
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

  Widget _buildAnakEkstraList(List<dynamic> list) {
    return Column(
      children: list.map((se) {
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
                                '${se['nama_ekstrakurikuler'] ?? '-'} (Semester ${se['semester'] ?? '1'})',
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
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: _slate.withOpacity(0.6), size: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (c) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: _slateDark),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(color: _slateDark, fontSize: 13)),
                          ],
                        ),
                      ),
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
                      if (v == 'edit') {
                        _showEkskulDialog(item: se);
                      } else if (v == 'delete') {
                        _confirmDelete(se);
                      }
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
                        const Text('Catatan Perkembangan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _slateDark)),
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
                            style: const TextStyle(fontSize: 13, color: _slateDark, height: 1.6),
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
