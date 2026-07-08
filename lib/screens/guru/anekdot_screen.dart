import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

const List<String> kLokasiList = [
  'Ruang Kelas',
  'Area Bermain Outdoor',
  'Area Bermain Indoor',
  'Sentra Seni',
  'Sentra Balok',
  'Sentra Bahan Alam',
  'Ruang Makan',
  'Kamar Mandi / Toilet',
  'Lapangan',
  'Lainnya',
];

// ─── Warna Utama ─────────────────────────────────────────────────────────────
const kPrimary = Color(0xFFC2410C);    // burnt orange (AppBar)
const kPrimaryLight = Color(0xFFFFF7ED); // warm tint
const kBgPage = Color(0xFFFDF6EE);    // warm cream
const kCardBg = Colors.white;
const kDivider = Color(0xFFE7E5E4);
const kTextSub = Color(0xFF78716C);

// ─────────────────────────────────────────────────────────────────────────────
class AnekdotScreen extends StatefulWidget {
  final int? idGuru;
  final int? idKelas;
  final int? idAnak;
  final bool isReadOnly;
  const AnekdotScreen({super.key, this.idGuru, this.idKelas, this.idAnak, this.isReadOnly = false});

  @override
  State<AnekdotScreen> createState() => _AnekdotScreenState();
}

class _AnekdotScreenState extends State<AnekdotScreen> {
  late Future<List<dynamic>> _anekdotFuture;
  List<dynamic> _anakList = [];
  String _filterTab = 'semua'; // semua | hari_ini | minggu_ini

  // Search & Filter state variables
  String _searchQuery = '';
  DateTime? _selectedDate;
  int? _selectedMonth;

  static const List<String> _indonesianMonths = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _loadAnekdot();
    _loadAnak();
  }

  void _loadAnekdot() {
    _anekdotFuture = _getAnekdot();
  }

  Future<void> _loadAnak() async {
    try {
      final idKelas = widget.idKelas ?? 2;
      final res = await ApiService.fetch('manage_anak.php?id_kelas=$idKelas');
      if (res['status'] == 'success') {
        setState(() => _anakList = res['data'] ?? []);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<List<dynamic>> _getAnekdot() async {
    try {
      final idAnakParam = widget.idAnak != null ? '&id_anak=${widget.idAnak}' : '';
      final response = await ApiService.fetch(
        'manage_anekdot.php?id_guru=${widget.idGuru ?? 2}$idAnakParam',
      );
      if (response['status'] == 'success') return response['data'] ?? [];
      return [];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
      return [];
    }
  }

  /// Filter data berdasarkan tab aktif dan kriteria pencarian
  List<dynamic> _filterData(List<dynamic> data) {
    final now = DateTime.now();
    return data.where((item) {
      // 1. Filter Tab (semua | hari_ini | minggu_ini)
      try {
        final tgl = DateTime.parse(item['tanggal'].toString());
        if (_filterTab == 'hari_ini') {
          final isToday = tgl.year == now.year && tgl.month == now.month && tgl.day == now.day;
          if (!isToday) return false;
        } else if (_filterTab == 'minggu_ini') {
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final isThisWeek = tgl.isAfter(startOfWeek.subtract(const Duration(days: 1)));
          if (!isThisWeek) return false;
        }
      } catch (_) {
        if (_filterTab != 'semua') return false;
      }

      // 2. Pencarian Kata Kunci
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nama = (item['nama_anak'] ?? '').toString().toLowerCase();
        final aspek = (item['aspek_perkembangan'] ?? '').toString().toLowerCase();
        final peristiwa = (item['peristiwa'] ?? '').toString().toLowerCase();
        final interpretasi = (item['interpretasi'] ?? '').toString().toLowerCase();
        final tindakLanjut = (item['tindak_lanjut'] ?? '').toString().toLowerCase();
        final lokasi = (item['lokasi'] ?? '').toString().toLowerCase();

        final matches = nama.contains(query) ||
            aspek.contains(query) ||
            peristiwa.contains(query) ||
            interpretasi.contains(query) ||
            tindakLanjut.contains(query) ||
            lokasi.contains(query);

        if (!matches) return false;
      }

      // 3. Filter Tanggal Spesifik
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

      // 4. Filter Bulan
      if (_selectedMonth != null) {
        try {
          final tgl = DateTime.parse(item['tanggal'].toString());
          if (tgl.month != _selectedMonth) return false;
        } catch (_) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _addAnekdot({
    required int idAnak,
    required String peristiwa,
    required String lokasi,
  }) async {
    try {
      final now = DateTime.now();
      final response = await ApiService.post('manage_anekdot.php', {
        'action': 'add',
        'id_anak': idAnak,
        'id_guru': widget.idGuru ?? 2,
        'tanggal': DateFormat('yyyy-MM-dd').format(now),
        'waktu': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'lokasi': lokasi,
        'peristiwa': peristiwa,
      });

      if (response['status'] == 'success') {
        setState(_loadAnekdot);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catatan berhasil disimpan'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Gagal menyimpan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  Future<void> _updateAnekdot({
    required int id,
    required String peristiwa,
    required String lokasi,
  }) async {
    try {
      final response = await ApiService.post('manage_anekdot.php', {
        'action': 'update',
        'id': id,
        'lokasi': lokasi,
        'peristiwa': peristiwa,
      });

      if (response['status'] == 'success') {
        setState(_loadAnekdot);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catatan berhasil diperbarui'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Gagal memperbarui');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  void _showEditBottomSheet(Map<String, dynamic> item) {
    final id = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
    if (id == 0) return;

    String selectedLokasi = item['lokasi'] ?? '';
    final peristiwaCtrl = TextEditingController(text: item['peristiwa'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, ctrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 0),
                    decoration: BoxDecoration(color: const Color(0xFFD4CFCB), borderRadius: BorderRadius.circular(2))),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.edit_note_rounded, color: kPrimary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Catatan Anekdot',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1917))),
                            Text('Perbarui peristiwa nyata yang diamati langsung',
                                style: TextStyle(fontSize: 11, color: kTextSub)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: kDivider),

                // Scrollable body
                Expanded(
                  child: ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    children: [
                      // ── Anak
                      _formLabel('Nama Anak'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kDivider),
                        ),
                        child: Text(
                          item['nama_anak'] ?? 'Anak',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Lokasi
                      _formLabel('Tempat / Konteks Kejadian'),
                      const SizedBox(height: 6),
                      _dropdownField<String>(
                        hint: 'Pilih lokasi kejadian',
                        value: selectedLokasi.isEmpty ? null : selectedLokasi,
                        items: kLokasiList.map((l) =>
                          DropdownMenuItem<String>(value: l, child: Text(l, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setBS(() => selectedLokasi = v ?? ''),
                      ),
                      const SizedBox(height: 14),

                      // ── Peristiwa
                      _formLabel('Deskripsi Peristiwa', required: true),
                      const SizedBox(height: 4),
                      const Text('Tuliskan secara objektif dan faktual, hindari penilaian atau opini.',
                          style: TextStyle(fontSize: 10, color: kTextSub)),
                      const SizedBox(height: 6),
                      _textareaField(ctrl: peristiwaCtrl,
                          hint: 'Contoh: "Anak mengambil pensil temannya lalu menangis saat diminta mengembalikan."',
                          maxLines: 5),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),

                // ── Footer tombol
                Container(
                  padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(ctx).viewInsets.bottom + 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: kDivider)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: kDivider),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Batal', style: TextStyle(color: kTextSub, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (peristiwaCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Peristiwa tidak boleh kosong'),
                                  backgroundColor: Colors.deepOrange),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          _updateAnekdot(
                            id: id,
                            peristiwa: peristiwaCtrl.text.trim(),
                            lokasi: selectedLokasi,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simpan Perubahan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAnekdot(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Catatan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Catatan anekdot ini akan dihapus secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await ApiService.post('manage_anekdot.php', {'action': 'delete', 'id': id});
      if (response['status'] == 'success') {
        setState(_loadAnekdot);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Catatan berhasil dihapus')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Catatan Anekdot',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Kelas ${widget.idKelas ?? ""}',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(_loadAnekdot),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _anekdotFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final allData = snapshot.data ?? [];
          final filtered = _filterData(allData);

          return Column(
            children: [
              _buildHeader(allData.length),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildAddButton(),
                      const SizedBox(height: 12),
                      _buildFilterTabs(),
                      const SizedBox(height: 16),
                      _buildSearchAndFilterPanel(),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        _buildEmptyState(isFilterResult: allData.isNotEmpty)
                      else ...[
                        _buildSectionLabel('${filtered.length} Catatan'),
                        const SizedBox(height: 8),
                        ...filtered.map((item) => _buildAnekdotCard(item)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

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
    return TextField(
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      decoration: InputDecoration(
        hintText: 'Cari nama anak, kata kunci, lokasi...',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kPrimary),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
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
              color: hasActiveFilter ? kPrimary.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasActiveFilter ? kPrimary : Colors.grey.shade200,
                width: hasActiveFilter ? 1.5 : 1.0,
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: hasActiveFilter ? kPrimary : Colors.grey.shade600,
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
                color: Colors.red,
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
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 10, color: kPrimary),
                const SizedBox(width: 5),
                Text(
                  DateFormat('d MMM yyyy', 'id').format(_selectedDate!),
                  style: const TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = null;
                    });
                  },
                  child: Icon(Icons.close_rounded, size: 12, color: kPrimary.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        if (_selectedMonth != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.date_range_rounded, size: 10, color: kPrimary),
                const SizedBox(width: 5),
                Text(
                  _indonesianMonths[_selectedMonth! - 1],
                  style: const TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMonth = null;
                    });
                  },
                  child: Icon(Icons.close_rounded, size: 12, color: kPrimary.withOpacity(0.6)),
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
                        'Filter Catatan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1917)),
                      ),
                      if (hasActiveTempFilter)
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempDate = null;
                              tempMonth = null;
                            });
                          },
                          child: const Text('Reset', style: TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Specific Date
                  const Text(
                    'PILIH TANGGAL SPESIFIK',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF78716C), letterSpacing: 0.5),
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
                                primary: kPrimary,
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
                        color: tempDate != null ? kPrimary.withOpacity(0.05) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tempDate != null ? kPrimary : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: tempDate != null ? kPrimary : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tempDate == null
                                ? 'Pilih Tanggal Kalender...'
                                : DateFormat('dd MMMM yyyy', 'id').format(tempDate!),
                            style: TextStyle(
                              fontSize: 13,
                              color: tempDate != null ? kPrimary : Colors.grey.shade700,
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
                              child: const Icon(Icons.clear_rounded, size: 18, color: kPrimary),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Month Selector
                  const Text(
                    'ATAU PILIH BULAN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF78716C), letterSpacing: 0.5),
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
                              color: isSel ? kPrimary : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? Colors.transparent : Colors.grey.shade200),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _indonesianMonths[index].substring(0, 3), // Short name
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : Colors.grey.shade800,
                              ),
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
                        backgroundColor: kPrimary,
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

  // ─── Header Stats ──────────────────────────────────────────────────────────
  Widget _buildHeader(int total) {
    final today = DateTime.now();
    return Container(
      color: kPrimary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildStatItem('Total', '$total', Icons.description_outlined),
            _buildStatDivider(),
            _buildStatItem(
              'Hari Ini',
              '${_countToday(total)}',
              Icons.today_rounded,
            ),
            _buildStatDivider(),
            _buildStatItem(
              DateFormat('MMM yyyy').format(today),
              '$total',
              Icons.calendar_month_outlined,
            ),
          ],
        ),
      ),
    );
  }

  int _countToday(int total) => total; // Replace with actual filter logic

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 36, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 4));
  }

  // ─── Filter Tabs ───────────────────────────────────────────────────────────
  Widget _buildFilterTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0EB),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildTab('semua', 'Semua'),
          _buildTab('hari_ini', 'Hari Ini'),
          _buildTab('minggu_ini', 'Minggu Ini'),
        ],
      ),
    );
  }

  Widget _buildTab(String key, String label) {
    final active = _filterTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterTab = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? kPrimary : kTextSub,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Section Label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: kTextSub, letterSpacing: 0.8));
  }

  // ─── Add Button ────────────────────────────────────────────────────────────
  Widget _buildAddButton() {
    if (widget.isReadOnly) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _showAddBottomSheet(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: kPrimary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Tambah Catatan Anekdot',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.7), size: 14),
          ],
        ),
      ),
    );
  }

  // ─── Anekdot Card ──────────────────────────────────────────────────────────
  Widget _buildAnekdotCard(dynamic item) {
    final nama = item['nama_anak']?.toString() ?? 'Anak';
    final inisial = _getInisial(nama);
    final aspekStr = item['aspek_perkembangan']?.toString() ?? '';
    final aspekList = aspekStr.isNotEmpty ? aspekStr.split(',') : <String>[];
    final lokasi = item['lokasi']?.toString() ?? '';

    DateTime? tgl;
    try { tgl = DateTime.parse('${item['tanggal']} ${item['waktu']}'); } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header kartu
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBF7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(inisial),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1917))),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 11, color: kTextSub),
                          const SizedBox(width: 3),
                          Text(
                            tgl != null ? DateFormat('dd MMM yyyy, HH:mm').format(tgl) : '-',
                            style: const TextStyle(fontSize: 11, color: kTextSub),
                          ),
                        ],
                      ),
                      if (lokasi.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.place_outlined, size: 11, color: kTextSub),
                          const SizedBox(width: 3),
                          Text(lokasi, style: const TextStyle(fontSize: 11, color: kTextSub)),
                        ]),
                      ],
                    ],
                  ),
                ),
                if (!widget.isReadOnly)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: kPrimary),
                        onPressed: () => _showEditBottomSheet(item),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFD4534A)),
                        onPressed: () => _deleteAnekdot(int.parse(item['id'].toString())),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Hapus',
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: kDivider),

          // ── Isi catatan
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildField(Icons.event_note_outlined, 'Peristiwa', item['peristiwa'], kPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String inisial) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kPrimary.withOpacity(0.1),
      ),
      alignment: Alignment.center,
      child: Text(inisial,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: kPrimary)),
    );
  }

  Widget _buildField(IconData icon, String title, dynamic value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: color, letterSpacing: 0.3)),
              const SizedBox(height: 3),
              Text(
                value?.toString().isNotEmpty == true ? value.toString() : '-',
                style: const TextStyle(fontSize: 12, color: Color(0xFF44403C), height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState({bool isFilterResult = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              isFilterResult ? Icons.search_off_rounded : Icons.description_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isFilterResult ? 'Tidak ada catatan yang cocok' : 'Belum ada catatan anekdot',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 6),
            Text(
              isFilterResult ? 'Coba ubah kata kunci atau bersihkan filter' : 'Tap tombol di atas untuk mulai mencatat',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: kTextSub),
        const SizedBox(height: 12),
        Text('Gagal memuat data', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        TextButton(onPressed: () => setState(_loadAnekdot), child: const Text('Coba Lagi')),
      ]),
    );
  }

  // ─── Bottom Sheet Form ────────────────────────────────────────────────────
  void _showAddBottomSheet() {
    int? selectedAnak;
    String selectedLokasi = '';
    final periswaaCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, ctrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 0),
                    decoration: BoxDecoration(color: const Color(0xFFD4CFCB), borderRadius: BorderRadius.circular(2))),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.edit_note_rounded, color: kPrimary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tambah Catatan Anekdot',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1917))),
                            Text('Catat peristiwa nyata yang diamati langsung',
                                style: TextStyle(fontSize: 11, color: kTextSub)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: kDivider),

                // Scrollable body
                Expanded(
                  child: ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    children: [
                      // ── Anak
                      _formLabel('Nama Anak', required: true),
                      const SizedBox(height: 6),
                      _dropdownField<int>(
                        hint: 'Pilih Anak',
                        value: selectedAnak,
                        items: _anakList.map((s) {
                          final sid = int.parse(s['id'].toString());
                          final name = s['nama_anak'] ?? s['name'] ?? 'Anak';
                          return DropdownMenuItem<int>(value: sid, child: Text(name, style: const TextStyle(fontSize: 13)));
                        }).toList(),
                        onChanged: (v) => setBS(() => selectedAnak = v),
                      ),
                      const SizedBox(height: 14),

                      // ── Tanggal & Waktu
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _formLabel('Tanggal', required: true),
                          const SizedBox(height: 6),
                          _tappableField(
                            icon: Icons.calendar_today_outlined,
                            label: DateFormat('dd MMM yyyy').format(selectedDate),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (c, child) => Theme(
                                  data: Theme.of(c).copyWith(
                                    colorScheme: const ColorScheme.light(primary: kPrimary),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) setBS(() => selectedDate = picked);
                            },
                          ),
                        ])),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _formLabel('Waktu', required: true),
                          const SizedBox(height: 6),
                          _tappableField(
                            icon: Icons.access_time_rounded,
                            label: selectedTime.format(ctx),
                            onTap: () async {
                              final picked = await showTimePicker(context: ctx, initialTime: selectedTime,
                                builder: (c, child) => Theme(
                                  data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
                                  child: child!),
                              );
                              if (picked != null) setBS(() => selectedTime = picked);
                            },
                          ),
                        ])),
                      ]),
                      const SizedBox(height: 14),

                      // ── Lokasi
                      _formLabel('Tempat / Konteks Kejadian'),
                      const SizedBox(height: 6),
                      _dropdownField<String>(
                        hint: 'Pilih lokasi kejadian',
                        value: selectedLokasi.isEmpty ? null : selectedLokasi,
                        items: kLokasiList.map((l) =>
                          DropdownMenuItem<String>(value: l, child: Text(l, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setBS(() => selectedLokasi = v ?? ''),
                      ),
                      const SizedBox(height: 14),

                      // ── Peristiwa
                      _formLabel('Deskripsi Peristiwa', required: true),
                      const SizedBox(height: 4),
                      const Text('Tuliskan secara objektif dan faktual, hindari penilaian atau opini.',
                          style: TextStyle(fontSize: 10, color: kTextSub)),
                      const SizedBox(height: 6),
                      _textareaField(ctrl: periswaaCtrl,
                          hint: 'Contoh: "Anak mengambil pensil temannya lalu menangis saat diminta mengembalikan."',
                          maxLines: 3),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),

                // ── Footer tombol
                Container(
                  padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(ctx).viewInsets.bottom + 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: kDivider)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: kDivider),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Batal', style: TextStyle(color: kTextSub, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedAnak == null || periswaaCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lengkapi: anak dan peristiwa'),
                                  backgroundColor: Colors.deepOrange),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          _addAnekdot(
                            idAnak: selectedAnak!,
                            peristiwa: periswaaCtrl.text.trim(),
                            lokasi: selectedLokasi,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simpan Catatan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Form Helper Widgets ──────────────────────────────────────────────────

  Widget _formLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF57534E)),
        children: required
            ? const [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE11D48)))]
            : [],
      ),
    );
  }

  Widget _dropdownField<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF9),
        border: Border.all(color: kDivider, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true, value: value, hint: Text(hint, style: const TextStyle(fontSize: 13, color: kTextSub)),
          items: items, onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kTextSub, size: 20),
          style: const TextStyle(fontSize: 13, color: Color(0xFF1C1917)),
        ),
      ),
    );
  }

  Widget _tappableField({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAF9),
          border: Border.all(color: kDivider, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 15, color: kTextSub),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1C1917))),
        ]),
      ),
    );
  }

  Widget _textareaField({required TextEditingController ctrl, required String hint, int maxLines = 3}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, color: Color(0xFF1C1917)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: kTextSub, height: 1.5),
        filled: true,
        fillColor: const Color(0xFFFAFAF9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kDivider, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _getInisial(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }
}
