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

  Future<void> _showEditForm(int mingguKe, dynamic existingData) async {
    if (widget.isReadOnly) return;

    final bulanCtrl = TextEditingController(text: existingData?['bulan'] ?? '');
    final tglMulaiCtrl = TextEditingController(text: existingData?['tanggal_mulai'] ?? '');
    final tglSelesaiCtrl = TextEditingController(text: existingData?['tanggal_selesai'] ?? '');
    final topikCtrl = TextEditingController(text: existingData?['topik'] ?? '');
    final subTopikCtrl = TextEditingController(text: existingData?['sub_topik'] ?? '');
    final subSubTopikCtrl = TextEditingController(text: existingData?['sub_sub_topik'] ?? '');
    final catatanCtrl = TextEditingController(text: existingData?['catatan'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
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
                        Text(
                          'Edit Prosem - Minggu $mingguKe',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _navy),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    
                    _buildTextField(bulanCtrl, 'Bulan', 'Misal: Juli, Agustus', Icons.calendar_month),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(tglMulaiCtrl, 'Tanggal Mulai', 'YYYY-MM-DD', Icons.date_range)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(tglSelesaiCtrl, 'Tanggal Selesai', 'YYYY-MM-DD', Icons.date_range)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(topikCtrl, 'Topik / Tema Utama', 'Misal: Aku senang ke sekolah', Icons.topic),
                    const SizedBox(height: 12),
                    _buildTextField(subTopikCtrl, 'Sub Topik / Sub Tema', 'Gunakan baris baru untuk memisahkan sub topik', Icons.subdirectory_arrow_right, maxLines: 3),
                    const SizedBox(height: 12),
                    _buildTextField(subSubTopikCtrl, 'Sub-Sub Topik', 'Detail sub-sub topik', Icons.subject, maxLines: 4),
                    const SizedBox(height: 12),
                    _buildTextField(catatanCtrl, 'Catatan Khusus', 'Catatan jika ada', Icons.note, maxLines: 2),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final idKelas = widget.idKelas ?? 2;
                          final res = await ApiService.post('manage_prosem.php', {
                            'action': 'save',
                            'id_kelas': idKelas,
                            'id_guru': widget.idGuru,
                            'semester': 1,
                            'tahun_ajaran': '2025/2026',
                            'bulan': bulanCtrl.text.trim(),
                            'minggu_ke': mingguKe,
                            'tanggal_mulai': tglMulaiCtrl.text.trim(),
                            'tanggal_selesai': tglSelesaiCtrl.text.trim(),
                            'topik': topikCtrl.text.trim(),
                            'sub_topik': subTopikCtrl.text.trim(),
                            'sub_sub_topik': subSubTopikCtrl.text.trim(),
                            'catatan': catatanCtrl.text.trim(),
                          });

                          if (res['status'] == 'success') {
                            Navigator.pop(ctx);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Prosem berhasil disimpan', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan prosem')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
