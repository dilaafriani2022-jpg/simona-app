import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProsemTab extends StatefulWidget {
  final int? idGuru;
  final int? idKelas;
  final bool isReadOnly;
  const ProsemTab({super.key, this.idGuru, this.idKelas, this.isReadOnly = false});

  @override
  State<ProsemTab> createState() => _ProsemTabState();
}

class _ProsemTabState extends State<ProsemTab> {
  static const Color _primary = Color(0xFFC17B2F);
  static const Color _primaryDark = Color(0xFFA0601A);
  static const Color _navy = Color(0xFF1E3A8A);
  static const Color _bg = Color(0xFFFDF8F3);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFF0E8DF);

  bool _isLoading = true;
  List<dynamic> _prosemList = [];
  final int _totalWeeks = 20;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final idKelas = widget.idKelas ?? 2;
      final res = await ApiService.fetch('manage_prosem.php?id_kelas=$idKelas&semester=1');
      if (res['status'] == 'success') {
        _prosemList = List<dynamic>.from(res['data'] ?? []);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<int, dynamic> _getProsemMap() {
    final map = <int, dynamic>{};
    for (var item in _prosemList) {
      final w = int.tryParse(item['minggu_ke']?.toString() ?? '');
      if (w != null) map[w] = item;
    }
    return map;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  static const List<String> _bulanList = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const List<int> _tahunList = [2023, 2024, 2025, 2026, 2027, 2028];

  // Parse YYYY-MM-DD → {day, month, year} or null
  Map<String, int>? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.length < 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return {'year': y, 'month': m, 'day': d};
  }

  String _buildDate(int day, int month, int year) =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  int _daysInMonth(int month, int year) {
    if (month == 2) return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
  }

  Future<void> _showEditForm(int mingguKe, dynamic existingData) async {
    if (widget.isReadOnly) return;

    // ── Initial values ──────────────────────────────────────────────────
    final parsedMulai  = _parseDate(existingData?['tanggal_mulai'] ?? '');
    final parsedSelesai = _parseDate(existingData?['tanggal_selesai'] ?? '');
    final now = DateTime.now();

    String? selBulan = (existingData?['bulan'] != null &&
            _bulanList.contains(existingData!['bulan']))
        ? existingData['bulan']
        : null;

    int mulaiDay   = parsedMulai?['day']   ?? 1;
    int mulaiMonth = parsedMulai?['month'] ?? now.month;
    int mulaiYear  = parsedMulai?['year']  ?? now.year;

    int selDay   = parsedSelesai?['day']   ?? 1;
    int selMonth = parsedSelesai?['month'] ?? now.month;
    int selYear  = parsedSelesai?['year']  ?? now.year;

    final topikCtrl      = TextEditingController(text: existingData?['topik'] ?? '');
    final subTopikCtrl   = TextEditingController(text: existingData?['sub_topik'] ?? '');
    final subSubTopikCtrl = TextEditingController(text: existingData?['sub_sub_topik'] ?? '');
    final catatanCtrl    = TextEditingController(text: existingData?['catatan'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.90,
        maxChildSize: 0.97,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              // ── Bulan Dropdown ────────────────────────────────────────
              Widget bulanDropdown = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bulan',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selBulan,
                        hint: const Text('Pilih Bulan', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
                        items: _bulanList.map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(b, style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            final idx = _bulanList.indexOf(v) + 1;
                            setSheetState(() {
                              selBulan = v;
                              mulaiMonth = idx;
                              selMonth = idx;
                              final maxMulai = _daysInMonth(mulaiMonth, mulaiYear);
                              mulaiDay = mulaiDay.clamp(1, maxMulai);
                              final maxSelesai = _daysInMonth(selMonth, selYear);
                              selDay = selDay.clamp(1, maxSelesai);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );

              // ── Date Row Builder ──────────────────────────────────────
              Widget dateRow(
                String label,
                int day, int month, int year,
                void Function(int d, int m, int y) onChanged,
              ) {
                final maxDay = _daysInMonth(month, year);
                final safeDay = day.clamp(1, maxDay);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 15, color: _primary),
                      const SizedBox(width: 6),
                      Text(label, style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      // ── Tanggal ──
                      Expanded(
                        flex: 2,
                        child: _dateDropdown(
                          label: 'Tgl',
                          value: safeDay,
                          items: List.generate(maxDay, (i) => i + 1),
                          display: (v) => v.toString().padLeft(2, '0'),
                          onChanged: (v) => onChanged(v, month, year),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ── Bulan ──
                      Expanded(
                        flex: 3,
                        child: _dateDropdown(
                          label: 'Bulan',
                          value: month,
                          items: List.generate(12, (i) => i + 1),
                          display: (v) => _bulanList[v - 1].substring(0, 3),
                          onChanged: (v) {
                            final newMaxDay = _daysInMonth(v, year);
                            onChanged(day.clamp(1, newMaxDay), v, year);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ── Tahun ──
                      Expanded(
                        flex: 3,
                        child: _dateDropdown(
                          label: 'Tahun',
                          value: _tahunList.contains(year) ? year : _tahunList.first,
                          items: _tahunList,
                          display: (v) => v.toString(),
                          onChanged: (v) {
                            final newMaxDay = _daysInMonth(month, v);
                            onChanged(day.clamp(1, newMaxDay), month, v);
                          },
                        ),
                      ),
                    ]),
                  ],
                );
              }

              return SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  32 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Edit Prosem - Minggu $mingguKe',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17, color: _navy)),
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // ── Bulan ────────────────────────────────────────────
                    bulanDropdown,
                    const SizedBox(height: 16),

                    // ── Tanggal Mulai ─────────────────────────────────────
                    dateRow(
                      'Tanggal Mulai',
                      mulaiDay, mulaiMonth, mulaiYear,
                      (d, m, y) => setSheetState(() {
                        mulaiDay = d; mulaiMonth = m; mulaiYear = y;
                        if (mulaiMonth >= 1 && mulaiMonth <= 12) {
                          selBulan = _bulanList[mulaiMonth - 1];
                        }
                      }),
                    ),
                    const SizedBox(height: 16),

                    // ── Tanggal Selesai ────────────────────────────────────
                    dateRow(
                      'Tanggal Selesai',
                      selDay, selMonth, selYear,
                      (d, m, y) => setSheetState(() {
                        selDay = d; selMonth = m; selYear = y;
                      }),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(topikCtrl, 'Topik / Tema Utama',
                        'Misal: Aku senang ke sekolah', Icons.topic),
                    const SizedBox(height: 12),
                    _buildTextField(subTopikCtrl, 'Sub Topik / Sub Tema',
                        'Gunakan baris baru untuk memisahkan sub topik',
                        Icons.subdirectory_arrow_right, maxLines: 3),
                    const SizedBox(height: 12),
                    _buildTextField(subSubTopikCtrl, 'Sub-Sub Topik',
                        'Detail sub-sub topik', Icons.subject, maxLines: 4),
                    const SizedBox(height: 12),
                    _buildTextField(catatanCtrl, 'Catatan Khusus',
                        'Catatan jika ada', Icons.note, maxLines: 2),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selBulan == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pilih bulan terlebih dahulu')),
                            );
                            return;
                          }
                          final idKelas = widget.idKelas ?? 2;
                          final res = await ApiService.post('manage_prosem.php', {
                            'action': 'save',
                            'id_kelas': idKelas,
                            'id_guru': widget.idGuru,
                            'semester': 1,
                            'tahun_ajaran': '2025/2026',
                            'bulan': selBulan,
                            'minggu_ke': mingguKe,
                            'tanggal_mulai':
                                _buildDate(mulaiDay, mulaiMonth, mulaiYear),
                            'tanggal_selesai':
                                _buildDate(selDay, selMonth, selYear),
                            'topik': topikCtrl.text.trim(),
                            'sub_topik': subTopikCtrl.text.trim(),
                            'sub_sub_topik': subSubTopikCtrl.text.trim(),
                            'catatan': catatanCtrl.text.trim(),
                          });

                          if (res['status'] == 'success') {
                            Navigator.pop(ctx);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Prosem berhasil disimpan',
                                    style: TextStyle(color: Colors.white)),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(res['message'] ?? 'Gagal menyimpan prosem')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Simpan Perubahan',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Generic date-part dropdown ────────────────────────────────────────────
  Widget _dateDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) display,
    required void Function(T) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _primary),
              items: items
                  .map((v) => DropdownMenuItem<T>(
                        value: v,
                        child: Text(display(v),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
              onChanged: (v) { if (v != null) onChanged(v); },
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            prefixIcon: Icon(icon, color: _primary, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    final prosemMap = _getProsemMap();

    return Scaffold(
      backgroundColor: _bg,
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _totalWeeks,
        itemBuilder: (ctx, index) {
          final mingguKe = index + 1;
          final item = prosemMap[mingguKe];

          final String bulan = item?['bulan'] ?? '-';
          final String tglMulai = item?['tanggal_mulai'] ?? '';
          final String tglSelesai = item?['tanggal_selesai'] ?? '';
          final String rentangTgl = (tglMulai.isNotEmpty && tglSelesai.isNotEmpty) ? '$tglMulai s/d $tglSelesai' : '-';
          final String topik = item?['topik'] ?? 'Belum Diisi';
          final String subTopik = item?['sub_topik'] ?? '-';
          final String subSubTopik = item?['sub_sub_topik'] ?? '-';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'W$mingguKe',
                      style: const TextStyle(color: _primaryDark, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                title: Text(
                  topik,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: topik == 'Belum Diisi' ? Colors.grey.shade400 : _navy,
                  ),
                ),
                subtitle: Text(
                  'Bulan: $bulan ($rentangTgl)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: widget.isReadOnly
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: _primary),
                        onPressed: () => _showEditForm(mingguKe, item),
                      ),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(height: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Sub Topik / Tema:', subTopik),
                        const SizedBox(height: 10),
                        _buildDetailRow('Sub-Sub Topik:', subSubTopik),
                        if (item?['catatan'] != null && item['catatan'].toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildDetailRow('Catatan Khusus:', item['catatan']),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: _navy),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
        ),
      ],
    );
  }
}
