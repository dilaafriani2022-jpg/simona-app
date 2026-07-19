import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ModulAjarTab extends StatefulWidget {
  final int? idGuru;
  final int? idKelas;
  final bool isReadOnly;
  const ModulAjarTab({super.key, this.idGuru, this.idKelas, this.isReadOnly = false});

  @override
  State<ModulAjarTab> createState() => _ModulAjarTabState();
}

class _ModulAjarTabState extends State<ModulAjarTab> {
  static const Color _primary = Color(0xFFC17B2F);
  static const Color _primaryDark = Color(0xFFA0601A);
  static const Color _navy = Color(0xFF1E3A8A);
  static const Color _bg = Color(0xFFFDF8F3);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFF0E8DF);

  int _selectedSemester = 1;
  int _selectedWeek = 1;
  bool _isLoading = true;
  Map<String, dynamic>? _modulData;
  Map<String, dynamic>? _linkedProsem;

  // Form Controllers - Informasi Umum
  final _kelompokCtrl = TextEditingController(text: 'Kelompok B');
  final _jenjangCtrl = TextEditingController(text: 'TK');
  final _sekolahCtrl = TextEditingController(text: 'TK Negeri 2 Bengkalis');
  final _alokasiCtrl = TextEditingController(text: '7.30 - 10.40 WIB');
  final _siswaCtrl = TextEditingController(text: '17 Anak');
  final _modelCtrl = TextEditingController(text: 'Tatap Muka');
  final _faseCtrl = TextEditingController(text: 'Fondasi');
  final _topikCtrl = TextEditingController();
  final _subTopikCtrl = TextEditingController();
  final _subSubTopikCtrl = TextEditingController();
  final _atpCtrl = TextEditingController();
  final _cpCtrl = TextEditingController();
  final _kataKunciCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _alatBahanCtrl = TextEditingController();
  final _saranaCtrl = TextEditingController();

  // Form Controllers - Komponen Inti
  final _curahIdeCtrl = TextEditingController();
  final _pembiasaanCtrl = TextEditingController(text: 'Upacara bendera hari Senin, Mengucapkan salam, Berdo\'a sebelum belajar, Menyanyi (Indonesia Raya), Mengaji surah pendek, Memeriksa kehadiran, motorik kasar, dll.');
  final _seninCtrl = TextEditingController();
  final _selasaCtrl = TextEditingController();
  final _rabuCtrl = TextEditingController();
  final _kamisCtrl = TextEditingController();
  final _jumatCtrl = TextEditingController();
  final _sabtuCtrl = TextEditingController();
  final _penutupCtrl = TextEditingController(text: 'Refleksi dan evaluasi, Menguatkan konsep, Menanyakan perasaan, Doa pulang.');
  final _asesmenCtrl = TextEditingController(text: 'Catatan Observasi');

  @override
  void initState() {
    super.initState();
    _loadWeekData();
  }

  String _getKelompokLabel(String? namaKelas) {
    if (namaKelas == null || namaKelas.isEmpty) return 'Kelompok B';
    return namaKelas;
  }

  Future<void> _loadWeekData() async {
    setState(() => _isLoading = true);
    final idKelas = widget.idKelas ?? 2;
    try {
      // 0. Fetch class details to set default Kelompok
      String? className;
      int? studentCount;
      final classRes = await ApiService.fetch('manage_kelas.php');
      if (classRes['status'] == 'success' && classRes['data'] is List) {
        final classes = classRes['data'] as List;
        final matchingClass = classes.firstWhere(
          (c) => c['id'].toString() == idKelas.toString(),
          orElse: () => null,
        );
        if (matchingClass != null) {
          className = matchingClass['nama_kelas'];
          studentCount = int.tryParse(matchingClass['jumlah_anak']?.toString() ?? '');
        }
      }

      // 1. Fetch linked Prosem data
      final prosemRes = await ApiService.fetch('manage_prosem.php?id_kelas=$idKelas&semester=$_selectedSemester&minggu_ke=$_selectedWeek');
      if (prosemRes['status'] == 'success' && prosemRes['data'] != null) {
        _linkedProsem = prosemRes['data'];
        _topikCtrl.text = _linkedProsem!['topik'] ?? '';
        _subTopikCtrl.text = _linkedProsem!['sub_topik'] ?? '';
        _subSubTopikCtrl.text = _linkedProsem!['sub_sub_topik'] ?? '';
      } else {
        _linkedProsem = null;
        _topikCtrl.clear();
        _subTopikCtrl.clear();
        _subSubTopikCtrl.clear();
      }

      // 2. Fetch Modul Ajar data
      final modulRes = await ApiService.fetch('manage_modul_ajar.php?id_kelas=$idKelas&semester=$_selectedSemester&minggu_ke=$_selectedWeek');
      if (modulRes['status'] == 'success' && modulRes['data'] != null) {
        _modulData = modulRes['data'];
        
        // Always force kelompok to match the actual class
        _kelompokCtrl.text = _getKelompokLabel(className);
        _jenjangCtrl.text = _modulData!['jenjang'] ?? 'TK';
        _sekolahCtrl.text = _modulData!['nama_sekolah'] ?? 'TK Negeri 2 Bengkalis';
        _alokasiCtrl.text = _modulData!['durasi'] ?? '7.30 - 10.40 WIB';
        _siswaCtrl.text = (_modulData!['jumlah_anak'] != null && _modulData!['jumlah_anak'].toString().isNotEmpty)
            ? _modulData!['jumlah_anak']
            : (studentCount != null ? '$studentCount Anak' : '0 Anak');
        _modelCtrl.text = _modulData!['model_pembelajaran'] ?? 'Tatap Muka';

        // Prioritize Prosem over saved Modul Ajar data for topic identity if Prosem is available
        if (_linkedProsem != null) {
          _topikCtrl.text = _linkedProsem!['topik'] ?? '';
          _subTopikCtrl.text = _linkedProsem!['sub_topik'] ?? '';
          _subSubTopikCtrl.text = _linkedProsem!['sub_sub_topik'] ?? '';
        } else {
          if (_modulData!['topik'] != null) _topikCtrl.text = _modulData!['topik'];
          if (_modulData!['sub_topik'] != null) _subTopikCtrl.text = _modulData!['sub_topik'];
          if (_modulData!['sub_sub_topik'] != null) _subSubTopikCtrl.text = _modulData!['sub_sub_topik'];
        }

        _atpCtrl.text = _modulData!['atp'] ?? '';
        _cpCtrl.text = _modulData!['elemen_cp'] ?? '';
        _kataKunciCtrl.text = _modulData!['kata_kunci'] ?? '';
        _deskripsiCtrl.text = _modulData!['deskripsi_umum'] ?? '';
        _alatBahanCtrl.text = _modulData!['alat_bahan'] ?? '';
        _saranaCtrl.text = _modulData!['dialog_sarana'] ?? '';
        _curahIdeCtrl.text = _modulData!['curah_ide'] ?? '';
        _pembiasaanCtrl.text = _modulData!['pembiasaan'] ?? '';
        _seninCtrl.text = _modulData!['kegiatan_senin'] ?? '';
        _selasaCtrl.text = _modulData!['kegiatan_selasa'] ?? '';
        _rabuCtrl.text = _modulData!['kegiatan_rabu'] ?? '';
        _kamisCtrl.text = _modulData!['kegiatan_kamis'] ?? '';
        _jumatCtrl.text = _jumatCtrl.text = _modulData!['kegiatan_jumat'] ?? '';
        _sabtuCtrl.text = _modulData!['kegiatan_sabtu'] ?? '';
        _penutupCtrl.text = _modulData!['kegiatan_penutup'] ?? '';
        _asesmenCtrl.text = _modulData!['teknik_asesmen'] ?? '';
      } else {
        _modulData = null;
        _kelompokCtrl.text = _getKelompokLabel(className);
        _siswaCtrl.text = studentCount != null ? '$studentCount Anak' : '0 Anak';
        _atpCtrl.clear();
        _cpCtrl.clear();
        _kataKunciCtrl.clear();
        _deskripsiCtrl.clear();
        _alatBahanCtrl.clear();
        _saranaCtrl.clear();
        _curahIdeCtrl.clear();
        _seninCtrl.clear();
        _selasaCtrl.clear();
        _rabuCtrl.clear();
        _kamisCtrl.clear();
        _jumatCtrl.clear();
        _sabtuCtrl.clear();
        _pembiasaanCtrl.text = 'Upacara bendera hari Senin, Mengucapkan salam, Berdo\'a sebelum belajar, Menyanyi (Indonesia Raya), Mengaji surah pendek, Memeriksa kehadiran, motorik kasar, dll.';
        _penutupCtrl.text = 'Refleksi dan evaluasi, Menguatkan konsep, Menanyakan perasaan, Doa pulang.';
        _asesmenCtrl.text = 'Catatan Observasi';
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveModul() async {
    if (widget.isReadOnly) return;
    setState(() => _isLoading = true);
    final idKelas = widget.idKelas ?? 2;
    try {
      final res = await ApiService.post('manage_modul_ajar.php', {
        'action': 'save',
        'id_kelas': idKelas,
        'id_guru': widget.idGuru,
        'semester': _selectedSemester,
        'minggu_ke': _selectedWeek,
        'kelompok': _kelompokCtrl.text.trim(),
        'jenjang': _jenjangCtrl.text.trim(),
        'nama_sekolah': _sekolahCtrl.text.trim(),
        'durasi': _alokasiCtrl.text.trim(),
        'jumlah_anak': _siswaCtrl.text.trim(),
        'model_pembelajaran': _modelCtrl.text.trim(),
        'topik': _topikCtrl.text.trim(),
        'sub_topik': _subTopikCtrl.text.trim(),
        'sub_sub_topik': _subSubTopikCtrl.text.trim(),
        'atp': _atpCtrl.text.trim(),
        'elemen_cp': _cpCtrl.text.trim(),
        'kata_kunci': _kataKunciCtrl.text.trim(),
        'deskripsi_umum': _deskripsiCtrl.text.trim(),
        'alat_bahan': _alatBahanCtrl.text.trim(),
        'dialog_sarana': _saranaCtrl.text.trim(),
        'curah_ide': _curahIdeCtrl.text.trim(),
        'pembiasaan': _pembiasaanCtrl.text.trim(),
        'kegiatan_senin': _seninCtrl.text.trim(),
        'kegiatan_selasa': _selasaCtrl.text.trim(),
        'kegiatan_rabu': _rabuCtrl.text.trim(),
        'kegiatan_kamis': _kamisCtrl.text.trim(),
        'kegiatan_jumat': _jumatCtrl.text.trim(),
        'kegiatan_sabtu': _sabtuCtrl.text.trim(),
        'kegiatan_penutup': _penutupCtrl.text.trim(),
        'teknik_asesmen': _asesmenCtrl.text.trim(),
        'tanggal_mulai': _linkedProsem?['tanggal_mulai'] ?? '',
        'tanggal_selesai': _linkedProsem?['tanggal_selesai'] ?? '',
      });

      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modul Ajar (RPPH) Berhasil Disimpan', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
        _loadWeekData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan Modul Ajar')),
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
                        // A. INFORMASI UMUM
                        _buildSectionCard(
                          title: 'A. Informasi Umum',
                          icon: Icons.info_outline,
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildInputField(_kelompokCtrl, 'Nama Kelompok', widget.isReadOnly)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildInputField(_jenjangCtrl, 'Jenjang Kelas', widget.isReadOnly)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildInputField(_sekolahCtrl, 'Asal Sekolah', widget.isReadOnly),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildInputField(_alokasiCtrl, 'Alokasi Waktu', widget.isReadOnly)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildInputField(_siswaCtrl, 'Jumlah Siswa', widget.isReadOnly)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildInputField(_modelCtrl, 'Model Pembelajaran', widget.isReadOnly)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildInputField(_faseCtrl, 'Fase', widget.isReadOnly)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildInputField(_topikCtrl, 'Topik Utama', widget.isReadOnly, hint: 'Otomatis dari Prosem'),
                            const SizedBox(height: 10),
                            _buildInputField(_subTopikCtrl, 'Sub Topik', widget.isReadOnly, hint: 'Otomatis dari Prosem'),
                            const SizedBox(height: 10),
                            _buildInputField(_subSubTopikCtrl, 'Sub-Sub Topik', widget.isReadOnly, hint: 'Otomatis dari Prosem'),
                            const SizedBox(height: 10),
                            _buildInputField(_atpCtrl, 'Alur Tujuan Pembelajaran (ATP)', widget.isReadOnly, maxLines: 4, hint: 'Tujuan terperinci...'),
                            const SizedBox(height: 10),
                            _buildInputField(_cpCtrl, 'Elemen Capaian Pembelajaran', widget.isReadOnly, maxLines: 4),
                            const SizedBox(height: 10),
                            _buildInputField(_kataKunciCtrl, 'Kata Kunci', widget.isReadOnly, hint: 'Contoh: Nama sekolah, halaman'),
                            const SizedBox(height: 10),
                            _buildInputField(_deskripsiCtrl, 'Deskripsi Umum', widget.isReadOnly, maxLines: 3),
                            const SizedBox(height: 10),
                            _buildInputField(_alatBahanCtrl, 'Alat dan Bahan', widget.isReadOnly, maxLines: 3, hint: 'Origami, Buku, dll.'),
                            const SizedBox(height: 10),
                            _buildInputField(_saranaCtrl, 'Sarana Prasarana', widget.isReadOnly, hint: 'Ruang kelas dan halaman'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // B. KOMPONEN INTI
                        _buildSectionCard(
                          title: 'B. Komponen Inti',
                          icon: Icons.auto_awesome_outlined,
                          children: [
                            _buildInputField(_curahIdeCtrl, 'Curah Ide Kegiatan', widget.isReadOnly, maxLines: 3, hint: 'Tanya jawab, dll.'),
                            const SizedBox(height: 10),
                            _buildInputField(_pembiasaanCtrl, 'Pembiasaan (± 45 menit)', widget.isReadOnly, maxLines: 4),
                            const SizedBox(height: 12),
                            const Text('Kegiatan Inti Harian (150 menit)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: _navy)),
                            const SizedBox(height: 8),
                            _buildInputField(_seninCtrl, 'Senin', widget.isReadOnly, maxLines: 3),
                            const SizedBox(height: 10),
                            _buildInputField(_selasaCtrl, 'Selasa', widget.isReadOnly, maxLines: 3),
                            const SizedBox(height: 10),
                            _buildInputField(_rabuCtrl, 'Rabu', widget.isReadOnly, maxLines: 3),
                            const SizedBox(height: 10),
                            _buildInputField(_kamisCtrl, 'Kamis', widget.isReadOnly, maxLines: 3),
                            const SizedBox(height: 10),
                            _buildInputField(_jumatCtrl, 'Jumat', widget.isReadOnly, maxLines: 3),
                            const SizedBox(height: 10),
                            _buildInputField(_sabtuCtrl, 'Sabtu', widget.isReadOnly, maxLines: 2),
                            const SizedBox(height: 12),
                            _buildInputField(_penutupCtrl, 'Penutup (± 20 menit)', widget.isReadOnly, maxLines: 3),
                            const SizedBox(height: 10),
                            _buildInputField(_asesmenCtrl, 'Asesmen', widget.isReadOnly, maxLines: 2),
                          ],
                        ),

                        if (!widget.isReadOnly) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _saveModul,
                              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                              label: const Text('Simpan Modul Ajar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
