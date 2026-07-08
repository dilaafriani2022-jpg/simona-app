import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AspekPenilaianScreen extends StatefulWidget {
  final int? idGuru;
  const AspekPenilaianScreen({super.key, this.idGuru});

  @override
  State<AspekPenilaianScreen> createState() => _AspekPenilaianScreenState();
}

class _AspekPenilaianScreenState extends State<AspekPenilaianScreen> {

  // ── Palet ────────────────────────────────────────────────────────────────
  static const Color _primary   = Color(0xFF0F766E);   // teal-700
  static const Color _primaryDk = Color(0xFF115E59);
  static const Color _primaryLt = Color(0xFF14B8A6);
  static const Color _bg        = Color(0xFFF0FDFA);
  static const Color _surface   = Colors.white;
  static const Color _border    = Color(0xFFCCFBF1);
  static const Color _slate     = Color(0xFF64748B);
  static const Color _green     = Color(0xFF059669);
  static const Color _red       = Color(0xFFDC2626);

  // Warna per kategori aspek (auto-assign berdasarkan index)
  static const List<Color> _aspekColors = [
    Color(0xFF7C3AED), // ungu
    Color(0xFF0891B2), // biru muda
    Color(0xFFD97706), // amber
    Color(0xFF059669), // hijau
    Color(0xFFE11D48), // merah muda
    Color(0xFF2563EB), // biru
    Color(0xFFF97316), // oranye
    Color(0xFF0F766E), // teal
  ];

  // ── State ────────────────────────────────────────────────────────────────
  List<dynamic> _aspekList    = [];
  List<dynamic> _filtered     = [];
  List<dynamic> _tujuanList   = [];
  List<dynamic> _kegiatanList = [];
  bool          _isLoading    = true;
  String        _searchQuery  = '';
  int           _expandedIdx  = -1;
  int? _idGuru;
  int           _selectedBulan = 1;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _idGuru = widget.idGuru ?? 2; // Default guru ID jika tidak diteruskan dari context
    _searchCtrl.addListener(() => setState(() {
      _searchQuery = _searchCtrl.text.toLowerCase();
      _applyFilter();
    }));
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  // LOAD DATA
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadAspek(),
        _loadTujuan(),
        _loadKegiatan(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAspek() async {
    try {
      final res = await ApiService.fetch('manage_aspek.php');
      if (res['status'] == 'success') {
        setState(() {
          _aspekList = List<dynamic>.from(res['data'] ?? []);
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Error loading aspek: $e');
    }
  }

  Future<void> _loadTujuan() async {
    try {
      final res = await ApiService.fetch(
        'manage_tujuan_pembelajaran.php?id_guru=${_idGuru ?? 2}',
      );
      if (res['status'] == 'success') {
        setState(() => _tujuanList = List<dynamic>.from(res['data'] ?? []));
      }
    } catch (e) {
      debugPrint('Error loading tujuan: $e');
    }
  }

  Future<void> _loadKegiatan() async {
    try {
      final res = await ApiService.fetch(
        'manage_kegiatan_pembelajaran.php?id_guru=${_idGuru ?? 2}',
      );
      if (res['status'] == 'success') {
        setState(() => _kegiatanList = List<dynamic>.from(res['data'] ?? []));
      }
    } catch (e) {
      debugPrint('Error loading kegiatan: $e');
    }
  }

  void _applyFilter() {
    _filtered = _aspekList.where((a) {
      final nama = (a['nama_aspek'] ?? '').toString().toLowerCase();
      final desk = (a['deskripsi'] ?? '').toString().toLowerCase();
      return _searchQuery.isEmpty ||
          nama.contains(_searchQuery) ||
          desk.contains(_searchQuery);
    }).toList();
  }

  Color _colorForIdx(int idx) => _aspekColors[idx % _aspekColors.length];

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Aspek Penilaian',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadAll),
        ],
      ),

      body: Column(children: [

        // ── Header ──────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _primaryDk, Color(0xFF0D6E68)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Stack(children: [
            Positioned(right: -15, bottom: -10,
              child: Opacity(opacity: 0.07,
                child: Icon(Icons.checklist_rounded,
                  size: MediaQuery.of(context).size.width * 0.38,
                  color: Colors.white))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.2))),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Panduan Penilaian',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('Gunakan aspek di bawah sebagai panduan\nsebelum memberikan penilaian pada anak.',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, height: 1.4)),
                    ])),
                  ])),
                const SizedBox(height: 12),
                // Stat chip
                Row(children: [
                  _statChip('${_aspekList.length}', 'Total Aspek', Icons.category_rounded),
                  const SizedBox(width: 8),
                  _statChip('${_filtered.length}', 'Ditampilkan', Icons.filter_list_rounded),
                ]),
              ]),
            ),
          ]),
        ),

        // ── Search ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari aspek penilaian...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: _primary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                      onPressed: _searchCtrl.clear)
                  : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          )),

        // ── Month Selector ──
        Container(
          height: 48,
          margin: const EdgeInsets.only(top: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (ctx, index) {
              final bulanNum = index + 1;
              final isSelected = _selectedBulan == bulanNum;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('Bulan $bulanNum (Minggu ${bulanNum == 5 ? 17 : (bulanNum - 1) * 4 + 1}-${bulanNum == 5 ? 18 : bulanNum * 4})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSelected ? Colors.white : _slate,
                    )),
                  selected: isSelected,
                  selectedColor: _primary,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? _primary : Colors.grey.shade200,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedBulan = bulanNum;
                      });
                    }
                  },
                ),
              );
            },
          ),
        ),

        // ── Counter ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Align(alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
              child: Text('${_filtered.length} Aspek Penilaian',
                style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 12))))),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _primary))
            : _filtered.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadAll, color: _primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      // Cari index asli di _aspekList untuk warna konsisten
                      final origIdx = _aspekList.indexOf(_filtered[i]);
                      return _buildAspekCard(_filtered[i], i, origIdx >= 0 ? origIdx : i);
                    },
                  ),
                ),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPER: Form Field
  // ════════════════════════════════════════════════════════════════════════
  Widget _formField(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        ),
        style: const TextStyle(fontSize: 11),
      ),
    ]);

  // ════════════════════════════════════════════════════════════════════════
  Widget _buildBulanDropdown(int value, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Bulan Rencana Pembelajaran',
        labelStyle: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
      items: List.generate(5, (index) {
        final b = index + 1;
        final startW = b == 1 ? 1 : (b - 1) * 4 + 1;
        final endW = b == 5 ? 18 : b * 4;
        return DropdownMenuItem<int>(
          value: b,
          child: Text('Bulan $b (Minggu $startW - $endW)', style: const TextStyle(fontSize: 12)),
        );
      }),
      onChanged: (val) {
        if (val != null) {
          onChanged(val);
        }
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPER: Save Tujuan Pembelajaran
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _saveTujuan(int idAspek, String indikator, int bulan) async {
    try {
      final payload = {
        'action': 'add',
        'id_guru': _idGuru ?? 2,
        'id_aspek': idAspek,
        'nama_tujuan': indikator,
        'deskripsi': '',
        'indikator': indikator,
        'bulan': bulan,
      };
      
      final res = await ApiService.post('manage_tujuan_pembelajaran.php', payload);
      
      if (res['status'] == 'success') {
        await _loadTujuan();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tujuan pembelajaran berhasil ditambahkan'),
            backgroundColor: _green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal menyimpan'),
            backgroundColor: _red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: _red),
      );
    }
  }

  Future<void> _saveKegiatan(int idTujuan, String nama, int bulan) async {
    try {
      final payload = {
        'action': 'add',
        'id_guru': _idGuru ?? 2,
        'id_tujuan': idTujuan,
        'nama_kegiatan': nama,
        'deskripsi': '',
        'bulan': bulan,
      };
      
      debugPrint('🔵 Saving kegiatan: $payload');
      final res = await ApiService.post('manage_kegiatan_pembelajaran.php', payload);
      debugPrint('🔵 Kegiatan response: $res');
      
      if (res['status'] == 'success') {
        await _loadKegiatan();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kegiatan pembelajaran berhasil ditambahkan'),
            backgroundColor: _green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal menyimpan: ${res.toString()}'),
            backgroundColor: _red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving kegiatan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: _red),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // DIALOG: Tambah Tujuan Pembelajaran
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _showAddTujuanDialog(int idAspek, String namaAspek) async {
    final indikatorCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int localBulan = _selectedBulan;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              contentPadding: EdgeInsets.zero,
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tambah Tujuan Pembelajaran',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text('Aspek: $namaAspek',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _formField('Indikator', indikatorCtrl, 'Cth: 1. Menunjukkan antusiasme\n2. Mengikuti instruksi', maxLines: 3),
                      const SizedBox(height: 12),
                      _buildBulanDropdown(localBulan, (val) {
                        setStateDialog(() {
                          localBulan = val;
                        });
                      }),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Batal', style: TextStyle(color: _slate, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (indikatorCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Indikator wajib diisi'), backgroundColor: _red),
                              );
                              return;
                            }
                            await _saveTujuan(idAspek, indikatorCtrl.text, localBulan);
                            if (mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // DIALOG: Tambah Kegiatan Pembelajaran
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _showAddKegiatanDialog(int idTujuan, String namaTujuan) async {
    final namaKegiatanCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int localBulan = _selectedBulan;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              contentPadding: EdgeInsets.zero,
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tambah Kegiatan Pembelajaran',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text('Tujuan: $namaTujuan',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _formField('Nama Kegiatan', namaKegiatanCtrl, 'Cth: Bermain puzzle sambil bernyanyi', maxLines: 2),
                      const SizedBox(height: 12),
                      _buildBulanDropdown(localBulan, (val) {
                        setStateDialog(() {
                          localBulan = val;
                        });
                      }),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Batal', style: TextStyle(color: _slate, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (namaKegiatanCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nama kegiatan wajib diisi'), backgroundColor: _red),
                              );
                              return;
                            }
                            await _saveKegiatan(idTujuan, namaKegiatanCtrl.text, localBulan);
                            if (mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
  // EDIT TUJUAN
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _showEditTujuanDialog(int idTujuan, int idAspek, String namaAspek, String indikatorAwal, int bulanAwal) async {
    final indikatorCtrl = TextEditingController(text: indikatorAwal);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int localBulan = bulanAwal;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              contentPadding: EdgeInsets.zero,
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Edit Tujuan Pembelajaran',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text('Aspek: $namaAspek',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _formField('Indikator', indikatorCtrl, '', maxLines: 3),
                      const SizedBox(height: 12),
                      _buildBulanDropdown(localBulan, (val) {
                        setStateDialog(() {
                          localBulan = val;
                        });
                      }),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Batal', style: TextStyle(color: _slate, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (indikatorCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Indikator wajib diisi'), backgroundColor: _red),
                              );
                              return;
                            }
                            await _updateTujuan(idTujuan, idAspek, indikatorCtrl.text, localBulan);
                            if (mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateTujuan(int idTujuan, int idAspek, String indikator, int bulan) async {
    try {
      final payload = {
        'action': 'update',
        'id': idTujuan,
        'id_guru': _idGuru ?? 2,
        'id_aspek': idAspek,
        'nama_tujuan': indikator,
        'deskripsi': '',
        'indikator': indikator,
        'bulan': bulan,
      };
      
      debugPrint('🟡 Updating tujuan: $payload');
      final res = await ApiService.post('manage_tujuan_pembelajaran.php', payload);
      debugPrint('🟡 Update tujuan response: $res');
      
      if (res['status'] == 'success') {
        await _loadTujuan();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tujuan pembelajaran berhasil diperbarui'),
            backgroundColor: _green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal memperbarui: ${res.toString()}'),
            backgroundColor: _red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating tujuan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: _red),
      );
    }
  }

  Future<void> _deleteTujuan(int idTujuan, String indikator) async {
    try {
      final payload = {
        'action': 'delete',
        'id': idTujuan,
        'id_guru': _idGuru ?? 2,
      };
      
      debugPrint('🔴 Deleting tujuan: $payload');
      final res = await ApiService.post('manage_tujuan_pembelajaran.php', payload);
      debugPrint('🔴 Delete tujuan response: $res');
      
      if (res['status'] == 'success') {
        await _loadTujuan();
        await _loadKegiatan();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tujuan pembelajaran berhasil dihapus'),
            backgroundColor: _green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal menghapus: ${res.toString()}'),
            backgroundColor: _red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error deleting tujuan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: _red),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // EDIT KEGIATAN
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _showEditKegiatanDialog(int idKegiatan, int idTujuan, String namaTujuan, String namaKegiatanAwal, int bulanAwal) async {
    final namaKegiatanCtrl = TextEditingController(text: namaKegiatanAwal);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int localBulan = bulanAwal;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              contentPadding: EdgeInsets.zero,
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Edit Kegiatan Pembelajaran',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text('Tujuan: $namaTujuan',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _formField('Nama Kegiatan', namaKegiatanCtrl, '', maxLines: 2),
                      const SizedBox(height: 12),
                      _buildBulanDropdown(localBulan, (val) {
                        setStateDialog(() {
                          localBulan = val;
                        });
                      }),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Batal', style: TextStyle(color: _slate, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (namaKegiatanCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nama kegiatan wajib diisi'), backgroundColor: _red),
                              );
                              return;
                            }
                            await _updateKegiatan(idKegiatan, idTujuan, namaKegiatanCtrl.text, localBulan);
                            if (mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateKegiatan(int idKegiatan, int idTujuan, String nama, int bulan) async {
    try {
      final payload = {
        'action': 'update',
        'id': idKegiatan,
        'id_guru': _idGuru ?? 2,
        'id_tujuan': idTujuan,
        'nama_kegiatan': nama,
        'deskripsi': '',
        'bulan': bulan,
      };
      
      debugPrint('构造 Updting kegiatan: $payload');
      final res = await ApiService.post('manage_kegiatan_pembelajaran.php', payload);
      debugPrint('构造 Update kegiatan response: $res');
      
      if (res['status'] == 'success') {
        await _loadKegiatan();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kegiatan pembelajaran berhasil diperbarui'),
            backgroundColor: _green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal memperbarui: ${res.toString()}'),
            backgroundColor: _red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating kegiatan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: _red),
      );
    }
  }



  Future<void> _deleteKegiatan(int idKegiatan, String nama) async {
    try {
      final payload = {
        'action': 'delete',
        'id': idKegiatan,
        'id_guru': _idGuru ?? 2,
      };
      
      debugPrint('🟣 Deleting kegiatan: $payload');
      final res = await ApiService.post('manage_kegiatan_pembelajaran.php', payload);
      debugPrint('🟣 Delete kegiatan response: $res');
      
      if (res['status'] == 'success') {
        await _loadKegiatan();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kegiatan pembelajaran berhasil dihapus'),
            backgroundColor: _green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal menghapus: ${res.toString()}'),
            backgroundColor: _red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error deleting kegiatan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: _red),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // SECTION: Tujuan & Kegiatan Pembelajaran
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildTujuanKegiatanSection(dynamic aspek, Color color) {
    final idAspek = int.tryParse(aspek['id']?.toString() ?? '-1') ?? -1;
    
    // Filter tujuan untuk aspek ini dan bulan terpilih
    final tujuanAspek = _tujuanList
        .where((t) =>
            int.tryParse(t['id_aspek']?.toString() ?? '-1') == idAspek &&
            (int.tryParse(t['bulan']?.toString() ?? '1') ?? 1) == _selectedBulan)
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(children: [
        Icon(Icons.flag_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Text('Tujuan Pembelajaran',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ]),
      const SizedBox(height: 8),

      // List tujuan
      if (tujuanAspek.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2))),
          child: Text(
            'Belum ada tujuan pembelajaran untuk aspek ini di Bulan $_selectedBulan',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          ),
        )
      else
        ...tujuanAspek.map((t) {
          final idTujuan = int.tryParse(t['id']?.toString() ?? '-1') ?? -1;
          final indikatorTujuan = t['indikator']?.toString() ?? '-';
          
          // Filter kegiatan untuk tujuan ini dan bulan terpilih
          final kegiatanTujuan = _kegiatanList
              .where((k) =>
                  int.tryParse(k['id_tujuan']?.toString() ?? '-1') == idTujuan &&
                  (int.tryParse(k['bulan']?.toString() ?? '1') ?? 1) == _selectedBulan)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indikator dengan edit/delete buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(indikatorTujuan,
                          style: TextStyle(fontSize: 11, color: color, height: 1.5),
                          textAlign: TextAlign.justify),
                      ]),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          final b = int.tryParse(t['bulan']?.toString() ?? '1') ?? 1;
                          _showEditTujuanDialog(idTujuan, idAspek, aspek['nama_aspek']?.toString() ?? '-', indikatorTujuan, b);
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Hapus Tujuan?'),
                              content: const Text('Apakah Anda yakin ingin menghapus tujuan pembelajaran ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _deleteTujuan(idTujuan, indikatorTujuan);
                                  },
                                  child: const Text('Hapus', style: TextStyle(color: _red)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 16, color: _primary),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, size: 16, color: _red),
                              SizedBox(width: 8),
                              Text('Hapus'),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(Icons.more_vert_rounded, size: 16, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
              
              if (kegiatanTujuan.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Kegiatan:',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    ...kegiatanTujuan.map((k) {
                      final idKegiatan = int.tryParse(k['id']?.toString() ?? '-1') ?? -1;
                      final namaKegiatan = k['nama_kegiatan']?.toString() ?? '-';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Icon(Icons.circle, size: 4, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Expanded(child: Text(
                            namaKegiatan,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                final b = int.tryParse(k['bulan']?.toString() ?? '1') ?? 1;
                                _showEditKegiatanDialog(idKegiatan, idTujuan, indikatorTujuan, namaKegiatan, b);
                              } else if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Kegiatan?'),
                                    content: const Text('Apakah Anda yakin ingin menghapus kegiatan pembelajaran ini?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _deleteKegiatan(idKegiatan, namaKegiatan);
                                        },
                                        child: const Text('Hapus', style: TextStyle(color: _red)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 14, color: _primary),
                                    SizedBox(width: 6),
                                    Text('Edit', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded, size: 14, color: _red),
                                    SizedBox(width: 6),
                                    Text('Hapus', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                            child: Icon(Icons.more_vert_rounded, size: 14, color: Colors.grey.shade300),
                          ),
                        ]),
                      );
                    }),
                  ]),
                ),
              ],
              // Button tambah kegiatan
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: SizedBox(
                  width: 200,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddKegiatanDialog(idTujuan, indikatorTujuan),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color.withOpacity(0.5), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: Icon(Icons.add_rounded, color: color, size: 14),
                    label: Text(
                      '+ Kegiatan',
                      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        }).toList(),

      // Button tambah tujuan
      const SizedBox(height: 8),
      Center(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddTujuanDialog(idAspek, aspek['nama_aspek']?.toString() ?? '-'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 9),
            ),
            icon: Icon(Icons.add_rounded, color: color, size: 16),
            label: Text(
              '+ Tambah Tujuan Pembelajaran',
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ),
        ),
      ),
    ]);
  }

  // ════════════════════════════════════════════════════════════════════════
  // ASPEK CARD  (expandable)
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildAspekCard(dynamic aspek, int listIdx, int colorIdx) {
    final nama     = aspek['nama_aspek']?.toString() ?? '-';
    final deskripsi = aspek['deskripsi']?.toString() ?? '';
    final color    = _colorForIdx(colorIdx);
    final isExpanded = _expandedIdx == listIdx;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(isExpanded ? 0.12 : 0.06),
            blurRadius: isExpanded ? 14 : 8, offset: const Offset(0, 3)),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _expandedIdx = isExpanded ? -1 : listIdx),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Baris utama
              Row(children: [
                // Nomor + ikon
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.2))),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.category_rounded, color: color, size: 20),
                  ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nama,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                ])),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: color, size: 22)),
              ]),

              // Konten expandable
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Divider(height: 1, color: Colors.grey.shade100),
                        const SizedBox(height: 12),

                        // Deskripsi
                        if (deskripsi.isNotEmpty) ...[
                          _expandLabel(Icons.info_outline_rounded, 'Deskripsi', color),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.15))),
                            child: Text(deskripsi,
                              style: TextStyle(fontSize: 12, color: const Color(0xFF334155), height: 1.6),
                              textAlign: TextAlign.justify)),
                          const SizedBox(height: 12),
                        ],

                        // Skala penilaian reminder
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade600),
                              const SizedBox(width: 5),
                              Text('Skala Penilaian',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                            ]),
                            const SizedBox(height: 8),
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              _skalaBadge('TM', 'Tidak Muncul', const Color(0xFFDC2626), const Color(0xFFFEF2F2), '😟'),
                              _skalaBadge('MM', 'Mulai Muncul', const Color(0xFFF59E0B), const Color(0xFFFFFBEB), '🙂'),
                              _skalaBadge('M',  'Muncul',       const Color(0xFF059669), const Color(0xFFD1FAE5), '🌟'),
                            ]),
                          ])),

                        // ── Tujuan Pembelajaran Section ──────────────────────
                        const SizedBox(height: 14),
                        _buildTujuanKegiatanSection(aspek, color),
                      ]))
                  : const SizedBox.shrink(),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _expandLabel(IconData icon, String label, Color color) =>
    Row(children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    ]);

  Widget _indikatorRow(int no, String text, Color color) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Center(child: Text('$no',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)))),
        const SizedBox(width: 8),
        Expanded(child: Text(text.trim(),
          style: TextStyle(fontSize: 12, color: const Color(0xFF334155), height: 1.5),
          textAlign: TextAlign.justify)),
      ]));

  Widget _skalaBadge(String code, String label, Color color, Color bg, String emoji) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Text('$code — $label',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ]));

  List<String> _parseIndikator(String raw) {
    // Coba pisah per newline, titik, atau koma
    if (raw.contains('\n')) return raw.split('\n').where((s) => s.trim().isNotEmpty).toList();
    if (raw.contains(';'))  return raw.split(';').where((s) => s.trim().isNotEmpty).toList();
    if (raw.contains(',') && raw.split(',').length > 2)
      return raw.split(',').where((s) => s.trim().isNotEmpty).toList();
    return [raw]; // satu baris
  }

  Widget _statChip(String value, String label, IconData icon) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 9)),
        ]),
      ]));

  Widget _buildEmpty() => ListView(children: [
    SizedBox(height: 280, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _primary.withOpacity(0.07), shape: BoxShape.circle),
        child: Icon(Icons.category_outlined, size: 48, color: _primary.withOpacity(0.4))),
      const SizedBox(height: 16),
      Text(_searchQuery.isEmpty ? 'Belum ada aspek penilaian' : 'Aspek tidak ditemukan',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Aspek penilaian dikelola oleh admin',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
    ]))),
  ]);
}
