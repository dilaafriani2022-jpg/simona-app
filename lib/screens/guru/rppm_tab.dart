import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RppmTab extends StatefulWidget {
  final int? idGuru;
  final int? idKelas;
  final bool isReadOnly;
  const RppmTab({super.key, this.idGuru, this.idKelas, this.isReadOnly = false});

  @override
  State<RppmTab> createState() => _RppmTabState();
}

class _RppmTabState extends State<RppmTab> {
  static const Color _primary = Color(0xFFC17B2F);
  static const Color _primaryDark = Color(0xFFA0601A);
  static const Color _navy = Color(0xFF1E3A8A);
  static const Color _bg = Color(0xFFFDF8F3);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFF0E8DF);

  int _selectedSemester = 1;
  int _selectedWeek = 1;
  bool _isLoading = true;
  Map<String, dynamic>? _rppmData;
  Map<String, dynamic>? _linkedProsem;

  // Form Controllers
  final _kelompokCtrl = TextEditingController(text: 'Kelompok B (5-6 Tahun)');
  final _bulanCtrl = TextEditingController();
  final _topikCtrl = TextEditingController();
  final _subTopikCtrl = TextEditingController();
  final _tujuanCtrl = TextEditingController();
  final _seninCtrl = TextEditingController();
  final _selasaCtrl = TextEditingController();
  final _rabuCtrl = TextEditingController();
  final _kamisCtrl = TextEditingController();
  final _jumatCtrl = TextEditingController();
  final _sabtuCtrl = TextEditingController();
  final _refleksiCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWeekData();
  }

  String _getKelompokLabel(String? namaKelas) {
    if (namaKelas == null || namaKelas.isEmpty) return 'Kelompok B (5-6 Tahun)';
    return namaKelas;
  }

  Future<void> _loadWeekData() async {
    setState(() => _isLoading = true);
    final idKelas = widget.idKelas ?? 2;
    try {
      // 0. Fetch class details to set default Kelompok / Usia
      String? className;
      final classRes = await ApiService.fetch('manage_kelas.php');
      if (classRes['status'] == 'success' && classRes['data'] is List) {
        final classes = classRes['data'] as List;
        final matchingClass = classes.firstWhere(
          (c) => c['id'].toString() == idKelas.toString(),
          orElse: () => null,
        );
        if (matchingClass != null) {
          className = matchingClass['nama_kelas'];
        }
      }

      // 1. Fetch linked Prosem data
      final prosemRes = await ApiService.fetch('manage_prosem.php?id_kelas=$idKelas&semester=$_selectedSemester&minggu_ke=$_selectedWeek');
      if (prosemRes['status'] == 'success' && prosemRes['data'] != null) {
        _linkedProsem = prosemRes['data'];
        _bulanCtrl.text = _linkedProsem!['bulan'] ?? '';
        _topikCtrl.text = _linkedProsem!['topik'] ?? '';
        _subTopikCtrl.text = _linkedProsem!['sub_topik'] ?? '';
      } else {
        _linkedProsem = null;
        _bulanCtrl.clear();
        _topikCtrl.clear();
        _subTopikCtrl.clear();
      }

      // 2. Fetch RPPM data
      final rppmRes = await ApiService.fetch('manage_rpp.php?type=rppm&id_kelas=$idKelas&semester=$_selectedSemester&minggu_ke=$_selectedWeek');
      if (rppmRes['status'] == 'success' && rppmRes['data'] != null) {
        _rppmData = rppmRes['data'];
        
        // Always force kelompok to match the actual class
        _kelompokCtrl.text = _getKelompokLabel(className);

        // Prioritize Prosem over saved RPPM data for theme identity if Prosem is available
        if (_linkedProsem != null) {
          _bulanCtrl.text = _linkedProsem!['bulan'] ?? '';
          _topikCtrl.text = _linkedProsem!['topik'] ?? '';
          _subTopikCtrl.text = _linkedProsem!['sub_topik'] ?? '';
        } else {
          if (_rppmData!['bulan'] != null) _bulanCtrl.text = _rppmData!['bulan'];
          if (_rppmData!['tema'] != null) _topikCtrl.text = _rppmData!['tema'];
          if (_rppmData!['sub_tema'] != null) _subTopikCtrl.text = _rppmData!['sub_tema'];
        }

        _tujuanCtrl.text = _rppmData!['tujuan_kegiatan'] ?? '';
        _seninCtrl.text = _rppmData!['kegiatan_senin'] ?? '';
        _selasaCtrl.text = _rppmData!['kegiatan_selasa'] ?? '';
        _rabuCtrl.text = _rppmData!['kegiatan_rabu'] ?? '';
        _kamisCtrl.text = _rppmData!['kegiatan_kamis'] ?? '';
        _jumatCtrl.text = _rppmData!['kegiatan_jumat'] ?? '';
        _sabtuCtrl.text = _rppmData!['kegiatan_sabtu'] ?? '';
        _refleksiCtrl.text = _rppmData!['refleksi_guru'] ?? '';
      } else {
        _rppmData = null;
        _kelompokCtrl.text = _getKelompokLabel(className);
        _tujuanCtrl.clear();
        _seninCtrl.clear();
        _selasaCtrl.clear();
        _rabuCtrl.clear();
        _kamisCtrl.clear();
        _jumatCtrl.clear();
        _sabtuCtrl.clear();
        _refleksiCtrl.clear();
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRppm() async {
    if (widget.isReadOnly) return;
    setState(() => _isLoading = true);
    final idKelas = widget.idKelas ?? 2;
    try {
      final res = await ApiService.post('manage_rpp.php', {
        'action': 'save_rppm',
        'id_kelas': idKelas,
        'id_guru': widget.idGuru,
        'semester': _selectedSemester,
        'minggu_ke': _selectedWeek,
        'kelompok': _kelompokCtrl.text.trim(),
        'bulan': _bulanCtrl.text.trim(),
        'tema': _topikCtrl.text.trim(),
        'sub_tema': _subTopikCtrl.text.trim(),
        'tujuan_kegiatan': _tujuanCtrl.text.trim(),
        'kegiatan_senin': _seninCtrl.text.trim(),
        'kegiatan_selasa': _selasaCtrl.text.trim(),
        'kegiatan_rabu': _rabuCtrl.text.trim(),
        'kegiatan_kamis': _kamisCtrl.text.trim(),
        'kegiatan_jumat': _jumatCtrl.text.trim(),
        'kegiatan_sabtu': _sabtuCtrl.text.trim(),
        'refleksi_guru': _refleksiCtrl.text.trim(),
        'tanggal_mulai': _linkedProsem?['tanggal_mulai'] ?? '',
        'tanggal_selesai': _linkedProsem?['tanggal_selesai'] ?? '',
      });

      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RPPM Berhasil Disimpan', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
        _loadWeekData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan RPPM')),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Semester & Week Picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _surface,
            child: Row(
              children: [
                // Semester selector
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedSemester,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Semester 1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5))),
                          DropdownMenuItem(value: 2, child: Text('Semester 2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSemester = val;
                            });
                            _loadWeekData();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Week selector
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedWeek,
                        isExpanded: true,
                        items: List.generate(22, (i) => i + 1).map((w) {
                          return DropdownMenuItem<int>(
                            value: w,
                            child: Text('Minggu $w', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedWeek = val;
                            });
                            _loadWeekData();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card A: Identitas
                        _buildSectionCard(
                          title: 'A. Identitas Program',
                          icon: Icons.badge_outlined,
                          children: [
                            _buildInputField(_kelompokCtrl, 'Kelompok / Usia', widget.isReadOnly),
                            const SizedBox(height: 10),
                            _buildInputField(_bulanCtrl, 'Bulan', widget.isReadOnly, hint: 'Otomatis dari Prosem'),
                            const SizedBox(height: 10),
                            _buildInputField(_topikCtrl, 'Topik / Tema', widget.isReadOnly, hint: 'Otomatis dari Prosem'),
                            const SizedBox(height: 10),
                            _buildInputField(_subTopikCtrl, 'Subtopik', widget.isReadOnly, hint: 'Otomatis dari Prosem'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Card B: Tujuan
                        _buildSectionCard(
                          title: 'B. Tujuan Kegiatan',
                          icon: Icons.flag_outlined,
                          children: [
                            _buildInputField(
                              _tujuanCtrl,
                              'Tujuan Pembelajaran Mingguan',
                              widget.isReadOnly,
                              maxLines: 4,
                              hint: '1. Anak mampu berdoa...\n2. Anak mampu mengenal...',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Card C: Rencana Harian
                        _buildSectionCard(
                          title: 'C. Rencana Kegiatan Harian',
                          icon: Icons.view_day_outlined,
                          children: [
                            _buildInputField(_seninCtrl, 'Senin', widget.isReadOnly, maxLines: 3, hint: 'Kegiatan hari Senin'),
                            const SizedBox(height: 10),
                            _buildInputField(_selasaCtrl, 'Selasa', widget.isReadOnly, maxLines: 3, hint: 'Kegiatan hari Selasa'),
                            const SizedBox(height: 10),
                            _buildInputField(_rabuCtrl, 'Rabu', widget.isReadOnly, maxLines: 3, hint: 'Kegiatan hari Rabu'),
                            const SizedBox(height: 10),
                            _buildInputField(_kamisCtrl, 'Kamis', widget.isReadOnly, maxLines: 3, hint: 'Kegiatan hari Kamis'),
                            const SizedBox(height: 10),
                            _buildInputField(_jumatCtrl, 'Jumat', widget.isReadOnly, maxLines: 3, hint: 'Kegiatan hari Jumat'),
                            const SizedBox(height: 10),
                            _buildInputField(_sabtuCtrl, 'Sabtu (Opsional)', widget.isReadOnly, maxLines: 2, hint: 'Kegiatan hari Sabtu'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Card D: Refleksi
                        _buildSectionCard(
                          title: 'D. Refleksi Guru',
                          icon: Icons.psychology_outlined,
                          children: [
                            _buildInputField(_refleksiCtrl, 'Catatan & Rencana Evaluasi', widget.isReadOnly, maxLines: 3),
                          ],
                        ),

                        if (!widget.isReadOnly) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _saveRppm,
                              icon: const Icon(Icons.save_rounded, color: Colors.white),
                              label: const Text('Simpan Rencana Mingguan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primaryDark, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _navy)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, bool readOnly, {int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF4B5563))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
