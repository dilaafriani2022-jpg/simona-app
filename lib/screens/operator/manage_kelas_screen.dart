import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class ManageKelasScreen extends StatefulWidget {
  const ManageKelasScreen({super.key});

  @override
  State<ManageKelasScreen> createState() => _ManageKelasScreenState();
}

class _ManageKelasScreenState extends State<ManageKelasScreen> {
  // ── Palette ──────────────────────────────────────────────────
  static const Color _primary   = Color(0xFF00838F);
  static const Color _navy      = Color(0xFF1E3A8A);
  static const Color _bg        = Color(0xFFF0FDFD);
  static const Color _surface   = Colors.white;
  static const Color _rose      = Color(0xFFE11D48);
  static const Color _amber     = Color(0xFFF59E0B);
  static const Color _slate     = Color(0xFF64748B);

  List<dynamic> _kelasList    = [];
  List<dynamic> _tahunList    = [];
  bool          _isLoading    = true;
  bool          _isConnected  = false;
  int           _mockIdCounter = 1000;
  String        _searchQuery  = '';

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Fetch ─────────────────────────────────────────────────────
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final resKelas = await ApiService.fetchData('manage_kelas.php', []);
      final resTahun = await ApiService.fetchData('manage_tahun_ajaran.php', []);

      setState(() {
        if (resKelas['status'] == 'success') {
          _kelasList   = List<dynamic>.from(resKelas['data']);
          _isConnected = resKelas['source'] == 'server';
        }
        if (resTahun['status'] == 'success') {
          _tahunList = List<dynamic>.from(resTahun['data']);
        }
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Filtered list ─────────────────────────────────────────────
  List<dynamic> get _filtered => _kelasList.where((k) {
    final nama  = (k['nama_kelas'] ?? '').toString().toLowerCase();
    final tahun = (k['tahun']     ?? '').toString().toLowerCase();
    return _searchQuery.isEmpty || nama.contains(_searchQuery) || tahun.contains(_searchQuery);
  }).toList();

  // ── Snackbar ──────────────────────────────────────────────────
  void _snack(String msg, {Color color = _primary}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(color == _rose ? Icons.error_rounded : Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Confirm delete dialog ─────────────────────────────────────
  Future<bool> _confirmDelete(String namaKelas) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kelas', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus kelas "$namaKelas"?\nSemua anak di kelas ini akan kehilangan data kelas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _rose, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ) ?? false;
  }

  // ── Form Sheet ────────────────────────────────────────────────
  void _showForm({Map<String, dynamic>? kelas}) {
    final isEdit       = kelas != null;
    final namaCtrl     = TextEditingController(text: kelas?['nama_kelas']?.toString() ?? '');
    String? selectedTahunId = kelas?['id_tahun_ajaran']?.toString();
    bool   isSaving    = false;

    // Kelompok & Sub-Kelompok Presets
    const kelompokPreset = ['Kelompok A', 'Kelompok B'];
    const subAPreset = ['Pattimura', 'Kartini', 'Sudirman', 'Dewantara'];
    const subBPreset = ['Diponegoro', 'Imam Bonjol', 'Teuku Umar', 'Hatta'];

    // Track selections in local scope
    String selectedKelompok = 'Kelompok A';
    String selectedSub = '';

    final currentNama = kelas?['nama_kelas']?.toString() ?? '';
    if (currentNama.isNotEmpty) {
      bool matched = false;
      for (var k in kelompokPreset) {
        if (currentNama.startsWith(k)) {
          selectedKelompok = k;
          matched = true;
          if (currentNama.contains(' - ')) {
            selectedSub = currentNama.split(' - ')[1].trim();
          }
          break;
        }
      }
      if (!matched) {
        selectedKelompok = '';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          // List of sub presets based on selected kelompok
          List<String> currentSubPresets = [];
          if (selectedKelompok == 'Kelompok A') {
            currentSubPresets = subAPreset;
          } else if (selectedKelompok == 'Kelompok B') {
            currentSubPresets = subBPreset;
          }

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // Header
              Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Column(children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20))),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(isEdit ? Icons.edit_rounded : Icons.add_rounded, color: _primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isEdit ? 'Edit Kelas' : 'Tambah Kelas',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
                      Text('Lengkapi data kelas',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                    ])),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade600),
                      ),
                    ),
                  ]),
                ]),
              ),

              // Form content
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── Nama Kelas ────────────────────────────────
                  _formSection(
                    icon: Icons.meeting_room_rounded, title: 'Nama Kelas', color: _primary,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Kelompok chips
                      _fLabel('Kelompok Usia'),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: kelompokPreset.map((k) {
                          final sel = selectedKelompok == k;
                          return GestureDetector(
                            onTap: () => setSheet(() {
                              selectedKelompok = k;
                              selectedSub = '';
                              namaCtrl.text = k;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: sel ? _primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: sel ? _primary : Colors.grey.shade200),
                              ),
                              child: Text(k, style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : _slate,
                              )),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      if (currentSubPresets.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _fLabel('Pilih Nama Kelas (Sub-Kelompok)'),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: currentSubPresets.map((sub) {
                            final sel = selectedSub == sub;
                            return GestureDetector(
                              onTap: () => setSheet(() {
                                selectedSub = sub;
                                namaCtrl.text = "$selectedKelompok - $selectedSub";
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: sel ? _amber : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: sel ? _amber : Colors.grey.shade200),
                                ),
                                child: Text(sub, style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : _slate,
                                )),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 12),
                      _fLabel('Nama Kelas Lengkap *'),
                      _fField(namaCtrl, Icons.meeting_room_rounded, 'Misal: Kelompok A - Pattimura'),
                    ]),
                  ),
                  const SizedBox(height: 12),

                // ── Tahun Ajaran ──────────────────────────────
                _formSection(
                  icon: Icons.calendar_month_rounded, title: 'Tahun Ajaran', color: _navy,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fLabel('Hubungkan ke Tahun Ajaran *'),
                    if (_tahunList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _amber.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _amber.withOpacity(0.2))),
                        child: Row(children: [
                          Icon(Icons.warning_amber_rounded, color: _amber, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Belum ada tahun ajaran. Tambahkan tahun ajaran terlebih dahulu.',
                            style: TextStyle(fontSize: 12))),
                        ]),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                          value: selectedTahunId,
                          isExpanded: true,
                          hint: Row(children: [
                            Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text('Pilih tahun ajaran', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                          ]),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: _tahunList.map((t) {
                            final isAktif = t['status']?.toString() == 'aktif';
                            return DropdownMenuItem<String>(
                              value: t['id'].toString(),
                              child: Row(children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: isAktif ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(t['tahun'] ?? '-', style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                if (isAktif) Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                  child: const Text('Aktif', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                ),
                              ]),
                            );
                          }).toList(),
                          onChanged: (v) => setSheet(() => selectedTahunId = v),
                        )),
                      ),
                  ]),
                ),
                const SizedBox(height: 20),
              ]),
            ),

            // Buttons
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(ctx).padding.bottom + 12),
              decoration: BoxDecoration(
                color: _surface,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Batal', style: GoogleFonts.poppins(color: _slate, fontWeight: FontWeight.w600)),
                )),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: isSaving ? null : () async {
                    if (namaCtrl.text.trim().isEmpty) { _snack('Nama kelas tidak boleh kosong', color: _rose); return; }
                    if (selectedTahunId == null && _tahunList.isNotEmpty) { _snack('Pilih tahun ajaran terlebih dahulu', color: _rose); return; }

                    setSheet(() => isSaving = true);

                    final data = <String, dynamic>{
                      'action'           : isEdit ? 'update' : 'add',
                      'nama_kelas'       : namaCtrl.text.trim(),
                      'id_tahun_ajaran'  : selectedTahunId ?? '',
                    };
                    if (isEdit) data['id'] = kelas!['id'];

                    // OFFLINE
                    if (!_isConnected) {
                      if (isEdit) {
                        final idx = _kelasList.indexWhere((e) => e['id'] == kelas!['id']);
                        if (idx != -1) setState(() => _kelasList[idx] = {..._kelasList[idx], ...data});
                      } else {
                        // ✅ FIX: toString() agar tidak type error
                        data['id'] = (_mockIdCounter++).toString();
                        setState(() => _kelasList.add(data));
                      }
                      if (mounted) Navigator.pop(ctx);
                      _snack(isEdit ? 'Kelas berhasil diperbarui (offline)' : 'Kelas berhasil ditambahkan (offline)');
                      setSheet(() => isSaving = false);
                      return;
                    }

                    // ONLINE
                    final res = await ApiService.postData('manage_kelas.php', data);
                    setSheet(() => isSaving = false);
                    if (res['status'] == 'success') {
                      if (mounted) Navigator.pop(ctx);
                      _fetchData();
                      _snack(res['message'] ?? 'Kelas berhasil disimpan');
                    } else {
                      _snack(res['message'] ?? 'Terjadi kesalahan', color: _rose);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.save_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(isEdit ? 'Update Kelas' : 'Simpan Kelas',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                        ]),
                )),
              ]),
            ),
            ]),
          );
        },
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────
  Future<void> _deleteKelas(Map<String, dynamic> kelas) async {
    final confirm = await _confirmDelete(kelas['nama_kelas'] ?? '-');
    if (!confirm) return;

    if (!_isConnected) {
      setState(() => _kelasList.removeWhere((e) => e['id'] == kelas['id']));
      _snack('Kelas berhasil dihapus (offline)');
      return;
    }

    final res = await ApiService.postData('manage_kelas.php', {'action': 'delete', 'id': kelas['id']});
    if (res['status'] == 'success') {
      _fetchData();
      _snack(res['message'] ?? 'Kelas berhasil dihapus');
    } else {
      _snack(res['message'] ?? 'Terjadi kesalahan', color: _rose);
    }
  }

  // ── Card ──────────────────────────────────────────────────────
  Widget _buildKelasCard(Map<String, dynamic> kelas) {
    final nama      = kelas['nama_kelas'] ?? '-';
    final tahun     = kelas['tahun']      ?? kelas['tahun_ajaran'] ?? '-';
    final jmlAnak  = int.tryParse(kelas['jumlah_anak']?.toString() ?? '0') ?? 0;
    final namaGuru  = kelas['nama_guru']?.toString() ?? '';
    final initials  = nama.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
        border: Border(left: BorderSide(color: _primary, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // Avatar
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primary, _primary.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nama, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  _infoPill(Icons.calendar_today_rounded, tahun, _navy),
                  _infoPill(
                    Icons.child_care_rounded,
                    '$jmlAnak Anak',
                    jmlAnak > 0 ? _primary : Colors.grey,
                  ),
                ]),
              ])),

              // Action
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (val) {
                  if (val == 'edit')   _showForm(kelas: kelas);
                  if (val == 'hapus')  _deleteKelas(kelas);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Row(children: [
                    Icon(Icons.edit_rounded, size: 18, color: _primary),
                    const SizedBox(width: 10),
                    const Text('Edit'),
                  ])),
                  PopupMenuItem(value: 'hapus', child: Row(children: [
                    const Icon(Icons.delete_rounded, size: 18, color: _rose),
                    const SizedBox(width: 10),
                    const Text('Hapus', style: TextStyle(color: _rose)),
                  ])),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500, size: 20),
                ),
              ),
            ]),

            // Guru pengampu row
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.person_rounded, size: 14,
                  color: namaGuru.isNotEmpty ? _primary : Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                namaGuru.isNotEmpty ? 'Guru: $namaGuru' : 'Belum ada guru pengampu',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: namaGuru.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: namaGuru.isNotEmpty ? const Color(0xFF1E293B) : Colors.grey.shade400,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  // ── Helpers ───────────────────────────────────────────────────
  Widget _formSection({required IconData icon, required String title, required Color color, required Widget child}) =>
    Container(
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border(bottom: BorderSide(color: color.withOpacity(0.1))),
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 14)),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(14), child: child),
      ]),
    );

  Widget _fLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
  );

  Widget _fField(TextEditingController c, IconData icon, String hint) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: TextField(
      controller: c,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    ),
  );

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            expandedHeight: 130,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primary.withOpacity(0.9), _primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(children: [
                  Positioned(top: -20, right: -20, child: Container(
                    width: 130, height: 130,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
                  )),
                  Positioned(left: 20, bottom: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('Kelola Kelas', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    Text('${_kelasList.length} kelas terdaftar', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ])),
                ]),
              ),
            ),
            title: Text('Kelola Kelas', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
            actions: [
              if (!_isConnected) _offlineBadge(),
              IconButton(onPressed: _fetchData, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
            ],
          ),

          // Search
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Cari kelas atau tahun ajaran...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: _primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: Icon(Icons.close, color: Colors.grey.shade400), onPressed: _searchCtrl.clear)
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          )),

          // Stats
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              _statBox('Total Kelas',  '${_kelasList.length}',
                Icons.meeting_room_rounded, _primary),
              const SizedBox(width: 10),
              _statBox('Total Anak',
                '${_kelasList.fold<int>(0, (sum, k) => sum + int.tryParse(k['jumlah_anak']?.toString() ?? '0')!)}',
                Icons.child_care_rounded, Colors.orange),
              const SizedBox(width: 10),
              _statBox('Filter', '${filtered.length}',
                Icons.filter_list_rounded, _navy),
            ]),
          )),

          // List
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _primary)))
          else if (filtered.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildKelasCard(Map<String, dynamic>.from(filtered[i])),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: _primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Tambah Kelas', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ]),
    ]),
  ));

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: _primary.withOpacity(0.07), shape: BoxShape.circle),
      child: Icon(Icons.meeting_room_rounded, size: 40, color: _primary.withOpacity(0.4))),
    const SizedBox(height: 14),
    Text('Belum ada kelas', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: const Color(0xFF1E293B))),
    const SizedBox(height: 6),
    Text('Tekan tombol + untuk menambah kelas baru', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
  ]));

  Widget _offlineBadge() => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text('Offline', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    )),
  );
}
