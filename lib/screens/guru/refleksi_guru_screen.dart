import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class RefleksiGuruScreen extends StatefulWidget {
  final int? idGuru;
  final int? idKelas;

  const RefleksiGuruScreen({super.key, this.idGuru, this.idKelas});

  @override
  State<RefleksiGuruScreen> createState() => _RefleksiGuruScreenState();
}

class _RefleksiGuruScreenState extends State<RefleksiGuruScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary   = Color(0xFF7C3AED);
  static const Color _primaryDk = Color(0xFF6D28D9);
  static const Color _orange    = Color(0xFFEA580C);
  static const Color _bg        = Color(0xFFFAF7FF);
  static const Color _surface   = Colors.white;
  static const Color _green     = Color(0xFF059669);
  static const Color _greenSoft = Color(0xFFECFDF5);
  static const Color _red       = Color(0xFFDC2626);
  static const Color _redSoft   = Color(0xFFFEF2F2);
  static const Color _amber     = Color(0xFFD97706);
  static const Color _amberSoft = Color(0xFFFFFBEB);
  static const Color _slate     = Color(0xFF64748B);
  static const Color _slateDark = Color(0xFF334155);
  static const Color _border    = Color(0xFFE9E3F5);

  late TabController _tabCtrl;
  List<dynamic> _refleksiList     = [];
  List<dynamic> _refleksiOrtuList = [];
  List<dynamic> _kelasList        = [];
  int? _selectedKelasId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _selectedKelasId = widget.idKelas;
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadRefleksi(), _loadKelas(), _loadRefleksiOrtu()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadRefleksi() async {
    try {
      final res = await ApiService.fetch(
        'manage_refleksi_guru.php?id_guru=${widget.idGuru ?? 2}',
      );
      if (res['status'] == 'success') {
        setState(() => _refleksiList = List<dynamic>.from(res['data'] ?? []));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _loadRefleksiOrtu() async {
    final idKelas = _selectedKelasId;
    if (idKelas == null) return;
    try {
      final res = await ApiService.getRefleksiOrtuByKelas(idKelas);
      if (res['status'] == 'success') {
        setState(() => _refleksiOrtuList = List<dynamic>.from(res['data'] ?? []));
      }
    } catch (e) {
      debugPrint('Error load refleksi ortu: $e');
    }
  }

  Future<void> _loadKelas() async {
    try {
      final res = await ApiService.fetch('manage_kelas.php');
      if (res['status'] == 'success') {
        final list = List<dynamic>.from(res['data'] ?? []);
        setState(() {
          _kelasList = list;
          if (_selectedKelasId == null && list.isNotEmpty) {
            _selectedKelasId = int.tryParse(list[0]['id'].toString());
            // Trigger load reflections for the resolved first class
            _loadRefleksiOrtu();
          }
        });
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

  // =====================================================================
  // FORM TAMBAH / EDIT — dipecah menjadi langkah bertahap (stepper ringan)
  // agar tidak terasa seperti satu form raksasa yang melelahkan.
  // =====================================================================
  void _showFormDialog({dynamic item}) {
    final isEdit = item != null;
    final pencapaianCtrl = TextEditingController(text: isEdit ? (item['pencapaian'] ?? '') : '');
    final hambatanCtrl = TextEditingController(text: isEdit ? (item['hambatan'] ?? '') : '');
    final solusiCtrl = TextEditingController(text: isEdit ? (item['solusi'] ?? '') : '');
    final rencanaCtrl = TextEditingController(text: isEdit ? (item['rencana_tindak_lanjut'] ?? '') : '');
    final perilakuCtrl = TextEditingController(text: isEdit ? (item['catatan_perilaku'] ?? '') : '');
    final belajarCtrl = TextEditingController(text: isEdit ? (item['catatan_pembelajaran'] ?? '') : '');
    final sosialCtrl = TextEditingController(text: isEdit ? (item['catatan_sosial'] ?? '') : '');

    int? selectedKelas = isEdit ? int.tryParse(item['id_kelas'].toString()) : (widget.idKelas);
    int? selectedAnak = isEdit ? int.tryParse(item['id_anak']?.toString() ?? '') : null;
    List<dynamic> dialogAnakList = [];
    bool isAnakLoading = false;
    bool hasLoadedAnak = false;

    int semester = isEdit ? intval(item['semester'] ?? 1) : 1;
    int mingguKe = isEdit ? intval(item['minggu_ke'] ?? 1) : 1;
    String tanggal = isEdit
        ? (item['tanggal'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()))
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    bool isSaving = false;
    int currentStep = 0; // 0: Info Dasar, 1: Refleksi, 2: Observasi

    const stepTitles = ['Info Dasar', 'Refleksi', 'Observasi'];
    const stepIcons = [
      Icons.calendar_month_rounded,
      Icons.lightbulb_outline_rounded,
      Icons.visibility_outlined,
    ];

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          Future<void> fetchAnak(int classId) async {
            setStateDialog(() => isAnakLoading = true);
            try {
              final res = await ApiService.fetch('manage_anak.php?id_kelas=$classId');
              if (res['status'] == 'success') {
                setStateDialog(() {
                  dialogAnakList = List<dynamic>.from(res['data'] ?? []);
                  isAnakLoading = false;
                  hasLoadedAnak = true;
                });
              } else {
                setStateDialog(() {
                  isAnakLoading = false;
                  hasLoadedAnak = true;
                });
              }
            } catch (e) {
              setStateDialog(() {
                isAnakLoading = false;
                hasLoadedAnak = true;
              });
            }
          }

          if (selectedKelas != null && !hasLoadedAnak && !isAnakLoading) {
            Future.microtask(() => fetchAnak(selectedKelas!));
          }

          Future<void> submit() async {
            if (selectedKelas == null) {
              _showSnack('Pilih kelas terlebih dahulu', isError: true);
              setStateDialog(() => currentStep = 0);
              return;
            }
            if (selectedAnak == null) {
              _showSnack('Pilih murid terlebih dahulu', isError: true);
              setStateDialog(() => currentStep = 0);
              return;
            }

            setStateDialog(() => isSaving = true);

            final payload = {
              'action': isEdit ? 'update' : 'add',
              if (isEdit) 'id': item['id'],
              'id_guru': widget.idGuru ?? 2,
              'id_kelas': selectedKelas,
              'id_anak': selectedAnak,
              'semester': semester,
              'minggu_ke': mingguKe,
              'tanggal': tanggal,
              'pencapaian': pencapaianCtrl.text.trim(),
              'hambatan': hambatanCtrl.text.trim(),
              'solusi': solusiCtrl.text.trim(),
              'rencana_tindak_lanjut': rencanaCtrl.text.trim(),
              'catatan_perilaku': perilakuCtrl.text.trim(),
              'catatan_pembelajaran': belajarCtrl.text.trim(),
              'catatan_sosial': sosialCtrl.text.trim(),
              'kinerja_guru': 'baik',
              'kesiapan_materi': 'siap',
              'kehadiran_guru': 100,
            };

            try {
              final res = await ApiService.post('manage_refleksi_guru.php', payload);
              if (!mounted) return;
              if (res['status'] == 'success') {
                await _loadRefleksi();
                Navigator.pop(ctx);
                _showSnack(isEdit ? 'Refleksi berhasil diperbarui' : 'Refleksi berhasil disimpan');
              } else {
                setStateDialog(() => isSaving = false);
                _showSnack(res['message'] ?? 'Gagal menyimpan data', isError: true);
              }
            } catch (e) {
              setStateDialog(() => isSaving = false);
              _showSnack('Terjadi kesalahan: $e', isError: true);
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header gradient dengan judul + progres step
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primary, _primaryDk],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEdit ? 'Edit Refleksi Guru' : 'Refleksi Guru Mingguan',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5),
                                  ),
                                  Text(
                                    'Langkah ${currentStep + 1} dari 3 \u2022 ${stepTitles[currentStep]}',
                                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Indikator step
                        Row(
                          children: List.generate(3, (i) {
                            final active = i <= currentStep;
                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                                height: 5,
                                decoration: BoxDecoration(
                                  color: active ? Colors.white : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  // Konten step
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildStepContent(
                          ctx: ctx,
                          step: currentStep,
                          setStateDialog: setStateDialog,
                          selectedKelas: selectedKelas,
                          onKelasChanged: (v) {
                            selectedKelas = v;
                            selectedAnak = null;
                            dialogAnakList.clear();
                            hasLoadedAnak = false;
                            if (v != null) {
                              fetchAnak(v);
                            }
                          },
                          selectedAnak: selectedAnak,
                          onAnakChanged: (v) => selectedAnak = v,
                          anakList: dialogAnakList,
                          isAnakLoading: isAnakLoading,
                          semester: semester,
                          onSemesterChanged: (v) => semester = v,
                          mingguKe: mingguKe,
                          onMingguChanged: (v) => mingguKe = v,
                          tanggal: tanggal,
                          onTanggalChanged: (v) => tanggal = v,
                          pencapaianCtrl: pencapaianCtrl,
                          hambatanCtrl: hambatanCtrl,
                          solusiCtrl: solusiCtrl,
                          rencanaCtrl: rencanaCtrl,
                          perilakuCtrl: perilakuCtrl,
                          belajarCtrl: belajarCtrl,
                          sosialCtrl: sosialCtrl,
                        ),
                      ),
                    ),
                  ),

                  // Footer navigasi
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: _border)),
                    ),
                    child: Row(
                      children: [
                        if (currentStep > 0)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isSaving ? null : () => setStateDialog(() => currentStep -= 1),
                              icon: const Icon(Icons.arrow_back_rounded, size: 16),
                              label: const Text('Kembali'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(color: _border),
                                foregroundColor: _slate,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving ? null : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(color: _border),
                                foregroundColor: _slate,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () {
                                    if (currentStep < 2) {
                                      setStateDialog(() => currentStep += 1);
                                    } else {
                                      submit();
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox.shrink()
                                : Icon(currentStep < 2 ? Icons.arrow_forward_rounded : Icons.check_rounded, size: 17),
                            label: isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                  )
                                : Text(
                                    currentStep < 2 ? 'Lanjut' : (isEdit ? 'Perbarui' : 'Simpan'),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
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

  // ---------------------------------------------------------------------
  // Konten tiap step form
  // ---------------------------------------------------------------------
  Widget _buildStepContent({
    required BuildContext ctx,
    required int step,
    required StateSetter setStateDialog,
    required int? selectedKelas,
    required ValueChanged<int?> onKelasChanged,
    required int? selectedAnak,
    required ValueChanged<int?> onAnakChanged,
    required List<dynamic> anakList,
    required bool isAnakLoading,
    required int semester,
    required ValueChanged<int> onSemesterChanged,
    required int mingguKe,
    required ValueChanged<int> onMingguChanged,
    required String tanggal,
    required ValueChanged<String> onTanggalChanged,
    required TextEditingController pencapaianCtrl,
    required TextEditingController hambatanCtrl,
    required TextEditingController solusiCtrl,
    required TextEditingController rencanaCtrl,
    required TextEditingController perilakuCtrl,
    required TextEditingController belajarCtrl,
    required TextEditingController sosialCtrl,
  }) {
    switch (step) {
      case 0:
        return Column(
          key: const ValueKey('step0'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIntro(
              icon: Icons.calendar_month_rounded,
              title: 'Informasi Dasar',
              subtitle: 'Tentukan kelas, periode, dan tanggal refleksi ini',
              color: _primary,
            ),
            const SizedBox(height: 18),
            _FieldLabel('Kelas'),
            const SizedBox(height: 6),
            widget.idKelas != null
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: _slate.withOpacity(0.05),
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.class_rounded, color: _slate, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _kelasList.firstWhere(
                            (k) => k['id'].toString() == selectedKelas?.toString(),
                            orElse: () => {'nama_kelas': '-'},
                          )['nama_kelas'] ?? '-',
                          style: const TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: selectedKelas?.toString(),
                    hint: Text('Pilih kelas', style: TextStyle(color: _slate.withOpacity(0.55), fontSize: 13.5)),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _slate),
                    decoration: _inputDecoration(),
                    items: _kelasList
                        .map<DropdownMenuItem<String>>((k) => DropdownMenuItem(
                              value: k['id'].toString(),
                              child: Text(k['nama_kelas'] ?? '-'),
                            ))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => onKelasChanged(int.tryParse(v ?? ''))),
                  ),
            if (selectedKelas != null) ...[
              const SizedBox(height: 16),
              _FieldLabel('Pilih Murid'),
              const SizedBox(height: 6),
              isAnakLoading
                  ? const SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _primary)),
                    )
                  : DropdownButtonFormField<String>(
                      value: selectedAnak?.toString(),
                      hint: Text('Pilih murid', style: TextStyle(color: _slate.withOpacity(0.55), fontSize: 13.5)),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _slate),
                      decoration: _inputDecoration(),
                      items: anakList
                          .map<DropdownMenuItem<String>>((s) => DropdownMenuItem(
                                value: s['id'].toString(),
                                child: Text(s['nama_anak'] ?? s['nama_anak'] ?? '-'),
                              ))
                          .toList(),
                      onChanged: (v) => setStateDialog(() => onAnakChanged(int.tryParse(v ?? ''))),
                      validator: (v) => v == null ? 'Pilih murid terlebih dahulu' : null,
                    ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Semester'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: semester.toString(),
                        decoration: _inputDecoration(),
                        items: [1, 2].map((s) => DropdownMenuItem(value: s.toString(), child: Text('Semester $s'))).toList(),
                        onChanged: (v) => setStateDialog(() => onSemesterChanged(int.tryParse(v ?? '1') ?? 1)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Minggu ke-'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: mingguKe.toString(),
                        decoration: _inputDecoration(),
                        items: List.generate(20, (i) => DropdownMenuItem(value: '${i + 1}', child: Text('Minggu ${i + 1}'))).toList(),
                        onChanged: (v) => setStateDialog(() => onMingguChanged(int.tryParse(v ?? '1') ?? 1)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FieldLabel('Tanggal'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.tryParse(tanggal) ?? DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  setStateDialog(() => onTanggalChanged(DateFormat('yyyy-MM-dd').format(picked)));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _bg,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: _primary, size: 17),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.tryParse(tanggal) ?? DateTime.now()),
                      style: const TextStyle(fontSize: 13.5, color: _slateDark, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Icon(Icons.edit_calendar_rounded, color: _slate.withOpacity(0.5), size: 16),
                  ],
                ),
              ),
            ),
          ],
        );

      case 1:
        return Column(
          key: const ValueKey('step1'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIntro(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Refleksi Pembelajaran',
              subtitle: 'Ceritakan bagaimana pembelajaran minggu ini berjalan',
              color: _primary,
            ),
            const SizedBox(height: 18),
            _buildTextField('Pencapaian', pencapaianCtrl, 'Apa yang sudah tercapai minggu ini?', 3),
            const SizedBox(height: 14),
            _buildTextField('Hambatan', hambatanCtrl, 'Apa hambatan yang dihadapi?', 3),
            const SizedBox(height: 14),
            _buildTextField('Solusi', solusiCtrl, 'Bagaimana solusi yang sudah/akan dilakukan?', 3),
            const SizedBox(height: 14),
            _buildTextField('Rencana Tindak Lanjut', rencanaCtrl, 'Apa rencana untuk minggu depan?', 3),
          ],
        );

      case 2:
      default:
        return Column(
          key: const ValueKey('step2'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIntro(
              icon: Icons.visibility_outlined,
              title: 'Catatan Observasi',
              subtitle: 'Catatan singkat mengenai perkembangan anak didik',
              color: _primary,
            ),
            const SizedBox(height: 18),
            _buildTextField('Perilaku', perilakuCtrl, 'Catatan perilaku anak selama minggu ini...', 2),
            const SizedBox(height: 14),
            _buildTextField('Pembelajaran', belajarCtrl, 'Catatan capaian pembelajaran anak...', 2),
            const SizedBox(height: 14),
            _buildTextField('Sosial', sosialCtrl, 'Catatan interaksi sosial anak...', 2),
          ],
        );
    }
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint, int maxLines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13.5, color: _slateDark),
          decoration: _inputDecoration(hint: hint),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12.5, color: _slate.withOpacity(0.55)),
      filled: true,
      fillColor: _bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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

  String _humanize(String key) {
    return key.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  int intval(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _confirmDelete(dynamic ref) async {
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
            const Text('Hapus Refleksi?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          ref['nama_anak'] != null
              ? 'Refleksi untuk murid "${ref['nama_anak']}" (${ref['nama_kelas'] ?? '-'}) minggu ke-${ref['minggu_ke'] ?? '-'} akan dihapus secara permanen.'
              : 'Refleksi untuk "${ref['nama_kelas'] ?? '-'}" minggu ke-${ref['minggu_ke'] ?? '-'} akan dihapus secara permanen.',
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
      final res = await ApiService.post('manage_refleksi_guru.php', {
        'action': 'delete',
        'id': ref['id'],
      });
      if (!mounted) return;
      if (res['status'] == 'success') {
        await _loadRefleksi();
        _showSnack('Refleksi berhasil dihapus');
      } else {
        _showSnack(res['message'] ?? 'Gagal menghapus data', isError: true);
      }
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e', isError: true);
    }
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
          'Refleksi',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: 0.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorWeight: 3,
          tabs: [
            const Tab(icon: Icon(Icons.assignment_rounded, size: 18), text: 'Refleksi Saya'),
            Tab(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.family_restroom_rounded, size: 18),
                  if (_refleksiOrtuList.isNotEmpty)
                    Positioned(
                      top: -4, right: -6,
                      child: Container(
                        width: 14, height: 14,
                        decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            _refleksiOrtuList.length > 9 ? '9+' : '${_refleksiOrtuList.length}',
                            style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              text: 'Refleksi Ortu',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Tab 0: Refleksi Guru ──────────────────────────────
                RefreshIndicator(
                  color: _primary,
                  onRefresh: _loadAll,
                  child: _refleksiList.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            const SizedBox(height: 16),
                            _buildIntroCard(),
                            SizedBox(
                              height: 360,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: _primary.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.note_alt_outlined, size: 44,
                                          color: _primary.withValues(alpha: 0.6)),
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'Belum ada refleksi',
                                      style: TextStyle(color: _slateDark, fontSize: 15.5, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Mulai dokumentasikan perjalanan mengajar Anda\nsetiap minggu di sini',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: _slate.withValues(alpha: 0.7), fontSize: 12.5, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _refleksiList.length + 1,
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildIntroCard(),
                              );
                            }
                            final ref = _refleksiList[i - 1];
                            return _buildRefleksiCard(ref);
                          },
                        ),
                ),
                // ── Tab 1: Refleksi Orang Tua ─────────────────────────
                RefreshIndicator(
                  color: _orange,
                  onRefresh: _loadAll,
                  child: _buildRefleksiOrtuTab(),
                ),
              ],
            ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabCtrl,
        builder: (_, __) => _tabCtrl.index == 0
            ? FloatingActionButton.extended(
                onPressed: () => _showFormDialog(),
                label: const Text('Tambah Refleksi', style: TextStyle(fontWeight: FontWeight.w600)),
                icon: const Icon(Icons.add_rounded),
                backgroundColor: _primary,
                elevation: 2,
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 7)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jurnal Mengajar Mingguan',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_refleksiList.length} refleksi telah dicatat',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassFilter() {
    if (_kelasList.isEmpty) return const SizedBox.shrink();

    if (widget.idKelas != null) {
      final myClass = _kelasList.firstWhere(
        (k) => k['id'].toString() == widget.idKelas.toString(),
        orElse: () => <String, dynamic>{},
      );
      if (myClass.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _orange.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _orange.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.class_rounded, color: _orange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelas Bimbingan Anda',
                    style: TextStyle(fontSize: 11, color: _slate, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    myClass['nama_kelas'] ?? '-',
                    style: const TextStyle(fontSize: 14, color: _slateDark, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedKelasId?.toString(),
          isExpanded: true,
          hint: const Text(
            'Pilih Kelas untuk Refleksi Ortu',
            style: TextStyle(color: _slate, fontSize: 13.5),
          ),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.class_rounded, color: _orange, size: 20),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          items: _kelasList.map<DropdownMenuItem<String>>((k) {
            return DropdownMenuItem(
              value: k['id'].toString(),
              child: Text(
                k['nama_kelas'] ?? '-',
                style: const TextStyle(fontSize: 14, color: _slateDark, fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedKelasId = int.tryParse(val);
              });
              _loadRefleksiOrtu();
            }
          },
        ),
      ),
    );
  }

  // ── Refleksi Orang Tua Tab ─────────────────────────────────────────────
  Widget _buildRefleksiOrtuTab() {
    return Column(
      children: [
        _buildClassFilter(),
        // List
        Expanded(
          child: _refleksiOrtuList.isEmpty
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_orange, Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                              color: _orange.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 7)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Refleksi Orang Tua',
                                    style: TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
                                SizedBox(height: 3),
                                Text('Belum ada refleksi dari orang tua',
                                    style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _orange.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.family_restroom_outlined, size: 44, color: _orange.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(height: 18),
                          const Text('Belum ada refleksi orang tua',
                              style: TextStyle(color: _slateDark, fontSize: 15.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(
                            'Refleksi orang tua untuk kelas Anda\nakan tampil di sini',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _slate.withValues(alpha: 0.7), fontSize: 12.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _refleksiOrtuList.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_orange, Color(0xFFDC2626)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                  color: _orange.withValues(alpha: 0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 7)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Refleksi Orang Tua',
                                        style: TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${_refleksiOrtuList.length} refleksi dari orang tua',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final item = _refleksiOrtuList[i - 1];
                    final namaOrtu  = (item['nama_ortu']  ?? item['nama_anak'] ?? '-').toString();
                    final namaAnak = (item['nama_anak'] ?? '-').toString();
                    final judul     = (item['judul'] ?? '').toString();
                    final isi       = (item['isi']   ?? '-').toString();
                    final createdAt = (item['created_at'] ?? '').toString();
                    final dateStr   = createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _orange.withValues(alpha: 0.15)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.person_rounded, color: _orange, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        namaOrtu,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: _slateDark),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.child_care_rounded, size: 11,
                                              color: _slate.withValues(alpha: 0.6)),
                                          const SizedBox(width: 4),
                                          Text(namaAnak,
                                              style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: _slate.withValues(alpha: 0.8))),
                                          const SizedBox(width: 8),
                                          Icon(Icons.calendar_today_rounded, size: 11,
                                              color: _slate.withValues(alpha: 0.6)),
                                          const SizedBox(width: 4),
                                          Text(dateStr,
                                              style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: _slate.withValues(alpha: 0.8))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (judul.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(judul,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _slateDark)),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _orange.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _orange.withValues(alpha: 0.12)),
                              ),
                              child: Text(isi,
                                  style: const TextStyle(
                                      fontSize: 13, color: _slateDark, height: 1.5)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRefleksiCard(dynamic ref) {
    DateTime? tgl;
    try {
      tgl = DateTime.parse(ref['tanggal']);
    } catch (_) {
      tgl = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          onTap: () => _showDetailDialog(ref),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_rounded, color: _primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ref['nama_anak'] != null
                                ? '${ref['nama_anak']} (${ref['nama_kelas'] ?? '-'})'
                                : '${ref['nama_kelas'] ?? '-'} \u2022 Minggu ${ref['minggu_ke'] ?? '-'}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _slateDark),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 11, color: _slate.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                tgl != null ? DateFormat('dd MMM yyyy', 'id_ID').format(tgl) : '-',
                                style: TextStyle(fontSize: 11.5, color: _slate.withOpacity(0.8)),
                              ),
                              if (ref['nama_anak'] != null) ...[
                                const SizedBox(width: 8),
                                Text('\u2022', style: TextStyle(fontSize: 11.5, color: _slate.withOpacity(0.6))),
                                const SizedBox(width: 8),
                                Text(
                                  'Minggu ${ref['minggu_ke'] ?? '-'}',
                                  style: TextStyle(fontSize: 11.5, color: _slate.withOpacity(0.8)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert_rounded, color: _slate.withOpacity(0.6), size: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (c) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 17, color: _slateDark),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 17, color: _red),
                              SizedBox(width: 10),
                              Text('Hapus', style: TextStyle(color: _red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (v) {
                        if (v == 'edit') {
                          _showFormDialog(item: ref);
                        } else if (v == 'delete') {
                          _confirmDelete(ref);
                        }
                      },
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

  void _showDetailDialog(dynamic ref) {
    DateTime? tgl;
    try {
      tgl = DateTime.parse(ref['tanggal']);
    } catch (_) {
      tgl = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 700),
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
                            child: const Icon(Icons.note_alt_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ref['nama_anak'] != null
                                      ? ref['nama_anak'].toString()
                                      : '${ref['nama_kelas'] ?? '-'} • Minggu ${ref['minggu_ke'] ?? '-'}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ref['nama_anak'] != null
                                      ? '${ref['nama_kelas'] ?? '-'} • Minggu ${ref['minggu_ke'] ?? '-'} • ${tgl != null ? DateFormat('dd MMMM yyyy', 'id_ID').format(tgl) : '-'}'
                                      : (tgl != null ? DateFormat('dd MMMM yyyy', 'id_ID').format(tgl) : '-'),
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pencapaian
                      if ((ref['pencapaian'] ?? '').toString().isNotEmpty) ...[
                        _DetailLabel('Pencapaian'),
                        const SizedBox(height: 8),
                        _DetailContent(ref['pencapaian'] ?? '-'),
                        const SizedBox(height: 16),
                      ],
                      // Hambatan
                      if ((ref['hambatan'] ?? '').toString().isNotEmpty) ...[
                        _DetailLabel('Hambatan'),
                        const SizedBox(height: 8),
                        _DetailContent(ref['hambatan'] ?? '-', color: _red.withOpacity(0.05), borderColor: _red.withOpacity(0.2)),
                        const SizedBox(height: 16),
                      ],
                      // Solusi
                      if ((ref['solusi'] ?? '').toString().isNotEmpty) ...[
                        _DetailLabel('Solusi'),
                        const SizedBox(height: 8),
                        _DetailContent(ref['solusi'] ?? '-', color: _green.withOpacity(0.05), borderColor: _green.withOpacity(0.2)),
                        const SizedBox(height: 16),
                      ],
                      // Rencana Tindak Lanjut
                      if ((ref['rencana_tindak_lanjut'] ?? '').toString().isNotEmpty) ...[
                        _DetailLabel('Rencana Tindak Lanjut'),
                        const SizedBox(height: 8),
                        _DetailContent(ref['rencana_tindak_lanjut'] ?? '-', color: _amber.withOpacity(0.05), borderColor: _amber.withOpacity(0.2)),
                        const SizedBox(height: 16),
                      ],
                      // Catatan Perilaku
                      if ((ref['catatan_perilaku'] ?? '').toString().isNotEmpty) ...[
                        _DetailLabel('Catatan Perilaku'),
                        const SizedBox(height: 8),
                        _DetailContent(ref['catatan_perilaku'] ?? '-'),
                        const SizedBox(height: 16),
                      ],
                      // Catatan Pembelajaran
                      if ((ref['catatan_pembelajaran'] ?? '').toString().isNotEmpty) ...[
                        _DetailLabel('Catatan Pembelajaran'),
                        const SizedBox(height: 8),
                        _DetailContent(ref['catatan_pembelajaran'] ?? '-'),
                        const SizedBox(height: 16),
                      ],
                      // Catatan Sosial
                      if ((ref['catatan_sosial'] ?? '').toString().isNotEmpty) ...[
                        _DetailLabel('Catatan Sosial'),
                        const SizedBox(height: 8),
                        _DetailContent(ref['catatan_sosial'] ?? '-'),
                        const SizedBox(height: 16),
                      ],

                    ],
                  ),
                ),
                // Close Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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

// Widget Helpers untuk Detail View
class _DetailLabel extends StatelessWidget {
  final String label;

  const _DetailLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF334155), letterSpacing: 0.3),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final String content;
  final Color color;
  final Color borderColor;

  const _DetailContent(
    this.content, {
    this.color = const Color(0xFFF8F8FB),
    this.borderColor = const Color(0xFFE9E3F5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        content,
        style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.6),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10.5, color: const Color(0xFF64748B).withOpacity(0.7))),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StepIntro extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _StepIntro({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.3)),
            ],
          ),
        ),
      ],
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
