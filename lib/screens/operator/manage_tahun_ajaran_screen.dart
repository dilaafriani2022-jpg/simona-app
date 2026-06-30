import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class ManageTahunAjaranScreen extends StatefulWidget {
  const ManageTahunAjaranScreen({super.key});

  @override
  State<ManageTahunAjaranScreen> createState() => _ManageTahunAjaranScreenState();
}

class _ManageTahunAjaranScreenState extends State<ManageTahunAjaranScreen> {
  // ── Palette ──────────────────────────────────────────────────
  static const Color _primary  = Color(0xFF059669);
  static const Color _navy     = Color(0xFF1E3A8A);
  static const Color _bg       = Color(0xFFF0FDF4);
  static const Color _surface  = Colors.white;
  static const Color _rose     = Color(0xFFE11D48);
  static const Color _amber    = Color(0xFFF59E0B);
  static const Color _slate    = Color(0xFF64748B);

  List<dynamic> _tahunList     = [];
  bool          _isLoading     = true;
  bool          _isConnected   = false;
  int           _mockIdCounter = 1000;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // ── Fetch ─────────────────────────────────────────────────────
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.fetchData('manage_tahun_ajaran.php', []);
      if (res['status'] == 'success') {
        setState(() {
          _tahunList   = List<dynamic>.from(res['data']);
          _isConnected = res['source'] == 'server';
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  // ── Confirm delete ────────────────────────────────────────────
  Future<bool> _confirmDelete(String tahun) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tahun Ajaran', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus tahun ajaran "$tahun"?\nSemua kelas yang terhubung akan kehilangan relasi tahun ajaran.'),
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

  // ── Set Aktif ─────────────────────────────────────────────────
  Future<void> _setAktif(Map<String, dynamic> tahun) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Aktifkan Tahun Ajaran', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Jadikan "${tahun['tahun']}" sebagai tahun ajaran aktif?\nTahun ajaran lain akan otomatis dinonaktifkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Aktifkan'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    if (!_isConnected) {
      setState(() {
        for (var t in _tahunList) t['status'] = 'nonaktif';
        final idx = _tahunList.indexWhere((e) => e['id'] == tahun['id']);
        if (idx != -1) _tahunList[idx]['status'] = 'aktif';
      });
      _snack('Tahun ajaran "${tahun['tahun']}" diaktifkan (offline)');
      return;
    }

    final res = await ApiService.postData('manage_tahun_ajaran.php', {
      'action': 'set_aktif',
      'id'    : tahun['id'],
    });
    if (res['status'] == 'success') {
      _fetchData();
      _snack('Tahun ajaran "${tahun['tahun']}" berhasil diaktifkan');
    } else {
      _snack(res['message'] ?? 'Terjadi kesalahan', color: _rose);
    }
  }

  // ── Form Sheet ────────────────────────────────────────────────
  void _showForm({Map<String, dynamic>? tahun}) {
    final isEdit       = tahun != null;
    final tahunCtrl    = TextEditingController(text: tahun?['tahun']?.toString() ?? '');
    String statusValue = tahun?['status']?.toString() ?? 'nonaktif';
    bool   isSaving    = false;

    // Preset tahun
    final now   = DateTime.now();
    final presets = List.generate(3, (i) {
      final y = now.year + i;
      return '$y/${y + 1}';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
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
                    Text(isEdit ? 'Edit Tahun Ajaran' : 'Tambah Tahun Ajaran',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
                    Text('Lengkapi data tahun ajaran',
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

            // Form
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Tahun ─────────────────────────────────────
                _formSection(
                  icon: Icons.calendar_month_rounded, title: 'Periode Tahun Ajaran', color: _primary,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Preset chips
                    _fLabel('Pilih Cepat'),
                    Wrap(spacing: 8, runSpacing: 8, children: presets.map((p) {
                      final sel = tahunCtrl.text == p;
                      return GestureDetector(
                        onTap: () => setSheet(() => tahunCtrl.text = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? _primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? _primary : Colors.grey.shade200),
                          ),
                          child: Text(p, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : _slate)),
                        ),
                      );
                    }).toList()),
                    const SizedBox(height: 12),
                    _fLabel('Tahun Ajaran *'),
                    _fField(tahunCtrl, Icons.calendar_today_rounded, 'Misal: 2025/2026'),
                    const SizedBox(height: 4),
                    Text('Format: TAHUN_MULAI/TAHUN_SELESAI', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Status ────────────────────────────────────
                _formSection(
                  icon: Icons.toggle_on_rounded, title: 'Status Tahun Ajaran', color: _navy,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Info
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _amber.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _amber.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded, color: _amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          'Hanya 1 tahun ajaran yang boleh berstatus Aktif. Mengaktifkan tahun ajaran ini akan menonaktifkan yang lain.',
                          style: TextStyle(fontSize: 11, color: _amber.withOpacity(0.9)),
                        )),
                      ]),
                    ),
                    Row(children: [
                      Expanded(child: _statusOption('aktif', 'Aktif', Icons.check_circle_rounded, Colors.green, statusValue, (v) => setSheet(() => statusValue = v))),
                      const SizedBox(width: 10),
                      Expanded(child: _statusOption('nonaktif', 'Non-Aktif', Icons.cancel_rounded, Colors.grey, statusValue, (v) => setSheet(() => statusValue = v))),
                    ]),
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
                    if (tahunCtrl.text.trim().isEmpty) { _snack('Tahun ajaran tidak boleh kosong', color: _rose); return; }

                    // Validasi format YYYY/YYYY
                    final pattern = RegExp(r'^\d{4}\/\d{4}$');
                    if (!pattern.hasMatch(tahunCtrl.text.trim())) {
                      _snack('Format harus TAHUN/TAHUN, misal: 2025/2026', color: _rose);
                      return;
                    }

                    setSheet(() => isSaving = true);

                    final data = <String, dynamic>{
                      'action': isEdit ? 'update' : 'add',
                      'tahun' : tahunCtrl.text.trim(),
                      'status': statusValue,
                    };
                    if (isEdit) data['id'] = tahun!['id'];

                    // OFFLINE
                    if (!_isConnected) {
                      if (isEdit) {
                        final idx = _tahunList.indexWhere((e) => e['id'] == tahun!['id']);
                        if (idx != -1) setState(() => _tahunList[idx] = {..._tahunList[idx], ...data});
                      } else {
                        // ✅ FIX: toString() agar tidak type error
                        data['id'] = (_mockIdCounter++).toString();
                        setState(() => _tahunList.add(data));
                      }
                      if (mounted) Navigator.pop(ctx);
                      _snack(isEdit ? 'Tahun ajaran berhasil diperbarui (offline)' : 'Tahun ajaran berhasil ditambahkan (offline)');
                      setSheet(() => isSaving = false);
                      return;
                    }

                    // ONLINE
                    final res = await ApiService.postData('manage_tahun_ajaran.php', data);
                    setSheet(() => isSaving = false);
                    if (res['status'] == 'success') {
                      if (mounted) Navigator.pop(ctx);
                      _fetchData();
                      _snack(res['message'] ?? 'Tahun ajaran berhasil disimpan');
                    } else {
                      _snack(res['message'] ?? 'Terjadi kesalahan', color: _rose);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.save_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(isEdit ? 'Update Tahun' : 'Simpan Tahun',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                        ]),
                )),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statusOption(String value, String label, IconData icon, Color color,
      String current, ValueChanged<String> onChanged) {
    final sel = current == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? color : Colors.grey.shade200, width: sel ? 1.5 : 1),
        ),
        child: Row(children: [
          Icon(icon, color: sel ? color : Colors.grey.shade400, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: sel ? color : Colors.grey.shade500)),
          const Spacer(),
          if (sel) Icon(Icons.check_circle_rounded, color: color, size: 16),
        ]),
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────
  Future<void> _deleteTahun(Map<String, dynamic> tahun) async {
    final confirm = await _confirmDelete(tahun['tahun'] ?? '-');
    if (!confirm) return;

    if (!_isConnected) {
      setState(() => _tahunList.removeWhere((e) => e['id'] == tahun['id']));
      _snack('Tahun ajaran berhasil dihapus (offline)');
      return;
    }

    final res = await ApiService.postData('manage_tahun_ajaran.php', {'action': 'delete', 'id': tahun['id']});
    if (res['status'] == 'success') {
      _fetchData();
      _snack(res['message'] ?? 'Tahun ajaran berhasil dihapus');
    } else {
      _snack(res['message'] ?? 'Terjadi kesalahan', color: _rose);
    }
  }

  // ── Card ──────────────────────────────────────────────────────
  Widget _buildTahunCard(Map<String, dynamic> tahun, int index) {
    final isAktif    = tahun['status']?.toString() == 'aktif';
    final statusColor = isAktif ? Colors.green : Colors.grey;
    final now         = DateTime.now().year;
    final parts       = (tahun['tahun'] ?? '').toString().split('/');
    final isCurrent   = parts.isNotEmpty && parts[0] == now.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
        border: Border(left: BorderSide(color: isAktif ? Colors.green : Colors.grey.shade300, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            // Icon container
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isAktif ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.calendar_month_rounded, color: isAktif ? Colors.green : Colors.grey, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(tahun['tahun'] ?? '-',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1E293B))),
                const SizedBox(width: 6),
                if (isCurrent) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _navy.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text('Tahun Ini', style: TextStyle(fontSize: 9, color: _navy, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(isAktif ? 'Aktif' : 'Non-Aktif',
                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ])),

            // Actions
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (val) {
                if (val == 'edit')       _showForm(tahun: tahun);
                if (val == 'aktifkan')   _setAktif(tahun);
                if (val == 'hapus')      _deleteTahun(tahun);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Row(children: [
                  Icon(Icons.edit_rounded, size: 18, color: _primary),
                  const SizedBox(width: 10),
                  const Text('Edit'),
                ])),
                if (!isAktif) PopupMenuItem(value: 'aktifkan', child: Row(children: [
                  const Icon(Icons.check_circle_rounded, size: 18, color: Colors.green),
                  const SizedBox(width: 10),
                  const Text('Jadikan Aktif', style: TextStyle(color: Colors.green)),
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

          // Tombol aktifkan cepat (jika non-aktif)
          if (!isAktif) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _setAktif(tahun),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.green.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 16),
                label: const Text('Jadikan Tahun Ajaran Aktif', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

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
    final aktif    = _tahunList.where((t) => t['status'] == 'aktif').toList();
    final nonAktif = _tahunList.where((t) => t['status'] != 'aktif').toList();

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
                  gradient: LinearGradient(colors: [_primary.withOpacity(0.85), _primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(children: [
                  Positioned(top: -20, right: -20, child: Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
                  )),
                  Positioned(left: 20, bottom: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('Tahun Ajaran', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    Text('${_tahunList.length} tahun ajaran terdaftar', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ])),
                ]),
              ),
            ),
            title: Text('Kelola Tahun Ajaran', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
            actions: [
              if (!_isConnected) _offlineBadge(),
              IconButton(onPressed: _fetchData, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
            ],
          ),

          // Stats
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              _statBox('Total',    '${_tahunList.length}', Icons.calendar_month_rounded, _primary),
              const SizedBox(width: 10),
              _statBox('Aktif',    '${aktif.length}',      Icons.check_circle_rounded,   Colors.green),
              const SizedBox(width: 10),
              _statBox('Non-Aktif','${nonAktif.length}',   Icons.cancel_rounded,         Colors.grey),
            ]),
          )),

          // List
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _primary)))
          else if (_tahunList.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildTahunCard(Map<String, dynamic>.from(_tahunList[i]), i),
                  childCount: _tahunList.length,
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
        label: Text('Tambah Tahun', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
    ]),
  ));

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: _primary.withOpacity(0.07), shape: BoxShape.circle),
      child: Icon(Icons.calendar_month_rounded, size: 40, color: _primary.withOpacity(0.4))),
    const SizedBox(height: 14),
    Text('Belum ada tahun ajaran', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: const Color(0xFF1E293B))),
    const SizedBox(height: 6),
    Text('Tekan tombol + untuk menambah tahun ajaran', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
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
