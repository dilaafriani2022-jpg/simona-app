import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';

class RefleksiOrtuPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? selectedAnak;
  final List<dynamic> refleksiGuruList;
  final List<dynamic> refleksiOrtuList;
  final int semester;
  final VoidCallback onRefresh;

  const RefleksiOrtuPage({
    super.key,
    required this.user,
    required this.selectedAnak,
    required this.refleksiGuruList,
    required this.refleksiOrtuList,
    required this.semester,
    required this.onRefresh,
  });

  @override
  State<RefleksiOrtuPage> createState() => _RefleksiOrtuPageState();
}

class _RefleksiOrtuPageState extends State<RefleksiOrtuPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _isiCtrl   = TextEditingController();
  bool _isSending  = false;
  int _tabIndex    = 0;

  List<dynamic> _myRefleksi  = [];

  @override
  void initState() {
    super.initState();
    _myRefleksi = List.from(widget.refleksiOrtuList);
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  bool _isKelompokB(String? className) {
    if (className == null) return false;
    final lower = className.toLowerCase();
    return lower.contains('kelompok b') || lower == 'b' || lower.contains(' b') || lower.startsWith('b');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final anakId = int.tryParse(widget.selectedAnak?['id']?.toString() ?? '0') ?? 0;
    final ortuId  = int.tryParse(widget.user['id']?.toString() ?? '0') ?? 0;
    final kelasId = int.tryParse(widget.selectedAnak?['id_kelas']?.toString() ?? '0') ?? 0;
    if (anakId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih anak terlebih dahulu')));
      return;
    }

    setState(() => _isSending = true);
    try {
      final res = await ApiService.submitRefleksiOrtu({
        'id_ortu':  ortuId,
        'id_anak': anakId,
        'id_kelas': kelasId,
        'judul':    _judulCtrl.text.trim(),
        'isi':      _isiCtrl.text.trim(),
        'bulan':    DateTime.now().month,
        'semester': widget.semester,
      });
      if (res['status'] == 'success') {
        final titleSent = _judulCtrl.text;
        final bodySent = _isiCtrl.text;
        _judulCtrl.clear();
        _isiCtrl.clear();
        widget.onRefresh();
        final newEntry = {
          'id': res['id'],
          'judul': titleSent,
          'isi': bodySent,
          'created_at': DateTime.now().toString(),
        };
        setState(() {
          _myRefleksi.insert(0, newEntry);
          _tabIndex = 1;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Refleksi berhasil dikirim!'),
              backgroundColor: AppColors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: _tabIndex,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.orange700,
          title: const Text('Refleksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              const Tab(icon: Icon(Icons.psychology_rounded, size: 18), text: 'Tulis Refleksi'),
              const Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Riwayat Saya'),
              Tab(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.school_rounded, size: 18),
                    if (widget.refleksiGuruList.isNotEmpty)
                      Positioned(
                        top: -4, right: -6,
                        child: Container(
                          width: 14, height: 14,
                          decoration: const BoxDecoration(
                              color: AppColors.amber, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              widget.refleksiGuruList.length > 9
                                  ? '9+'
                                  : '${widget.refleksiGuruList.length}',
                              style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                text: 'Dari Guru',
              ),
            ],
          ),
        ),
        body: TabBarView(children: [
          _buildFormTab(),
          _buildRiwayatTab(),
          _buildGuruRefleksiTab(),
        ]),
      ),
    );
  }

  Widget _buildFormTab() {
    final className = widget.selectedAnak?['nama_kelas']?.toString();
    final bool hideRefleksi = _isKelompokB(className) && widget.semester == 2;

    if (hideRefleksi) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.orange500.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.orange700,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Refleksi Tidak Diperlukan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Pengisian Refleksi Orang Tua tidak diperlukan untuk siswa Kelompok B pada Semester 2.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        if (widget.refleksiGuruList.isNotEmpty) ...[
          GestureDetector(
            onTap: () {
              DefaultTabController.of(context).animateTo(2);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.amber.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: AppColors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${widget.refleksiGuruList.length} refleksi terbaru dari guru — ketuk untuk melihat',
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.amber, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.purple, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Tulis Refleksi Anda',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: _judulCtrl,
                decoration: InputDecoration(
                  labelText: 'Judul (opsional)',
                  hintText: 'cth: Perkembangan bulan ini',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.orange700, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.title_rounded, color: AppColors.orange500),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _isiCtrl,
                maxLines: 6,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Isi refleksi tidak boleh kosong' : null,
                decoration: InputDecoration(
                  labelText: 'Isi Refleksi *',
                  hintText: 'Ceritakan perkembangan anak di rumah, kendala, harapan, dll...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.orange700, width: 2),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.notes_rounded, color: AppColors.orange500),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  icon: _isSending
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  label: Text(_isSending ? 'Mengirim...' : 'Kirim Refleksi',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildGuruRefleksiTab() {
    final list = widget.refleksiGuruList;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Belum ada refleksi dari guru',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.purple, Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.purple.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Refleksi Guru',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5)),
                        const SizedBox(height: 3),
                        Text('${list.length} refleksi tersedia',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final r = list[i - 1];
        final namaGuru = (r['nama_guru'] ?? '-').toString();
        final namaKelas = (r['nama_kelas'] ?? '-').toString();
        final minggu = (r['minggu_ke'] ?? '-').toString();
        final pencapaian = (r['pencapaian'] ?? '').toString();
        final hambatan   = (r['hambatan']   ?? '').toString();
        final solusi     = (r['solusi']     ?? '').toString();
        final rencanaTindakLanjut = (r['rencana_tindak_lanjut'] ?? '').toString();
        final catatanPerilaku = (r['catatan_perilaku'] ?? '').toString();
        final catatanPembelajaran = (r['catatan_pembelajaran'] ?? '').toString();
        final catatanSosial = (r['catatan_sosial'] ?? '').toString();
        final tanggal    = (r['tanggal']    ?? '').toString();
        final dateStr    = tanggal.length >= 10 ? tanggal.substring(0, 10) : tanggal;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: AppColors.purple.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
            border: Border.all(color: AppColors.purple.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded, color: AppColors.purple, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(namaGuru,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1E293B))),
                        const SizedBox(height: 2),
                        Text('$namaKelas  •  Minggu $minggu  •  $dateStr',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ],
              ),
              if (pencapaian.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ortuGuruSection('Pencapaian', pencapaian,
                    Colors.green.shade600, Colors.green.shade50),
              ],
              if (hambatan.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ortuGuruSection('Hambatan', hambatan,
                    Colors.red.shade600, Colors.red.shade50),
              ],
              if (solusi.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ortuGuruSection('Solusi', solusi,
                    Colors.blue.shade600, Colors.blue.shade50),
              ],
              if (rencanaTindakLanjut.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ortuGuruSection('Rencana Tindak Lanjut', rencanaTindakLanjut,
                    Colors.teal.shade700, Colors.teal.shade50),
              ],
              if (catatanPerilaku.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ortuGuruSection('Catatan Perilaku Anak', catatanPerilaku,
                    Colors.orange.shade700, Colors.orange.shade50),
              ],
              if (catatanPembelajaran.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ortuGuruSection('Catatan Pembelajaran', catatanPembelajaran,
                    Colors.purple.shade700, Colors.purple.shade50),
              ],
              if (catatanSosial.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ortuGuruSection('Catatan Sosial', catatanSosial,
                    Colors.indigo.shade700, Colors.indigo.shade50),
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _ortuGuruSection(String label, String value, Color textColor, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF334155),
                  height: 1.4)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> item, int index) async {
    final id = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
    if (id == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Refleksi?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus refleksi ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.submitRefleksiOrtu({
          'action': 'delete',
          'id': id,
        });
        if (res['status'] == 'success') {
          setState(() {
            _myRefleksi.removeAt(index);
          });
          widget.onRefresh();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Refleksi berhasil dihapus'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['message'] ?? 'Gagal menghapus')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> item, int index) async {
    final id = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
    if (id == 0) return;

    final editJudulCtrl = TextEditingController(text: item['judul'] ?? '');
    final editIsiCtrl = TextEditingController(text: item['isi'] ?? '');
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('Edit Refleksi', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: editJudulCtrl,
                      decoration: InputDecoration(
                        labelText: 'Judul',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: editIsiCtrl,
                      maxLines: 5,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Isi tidak boleh kosong' : null,
                      decoration: InputDecoration(
                        labelText: 'Isi Refleksi *',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          try {
                            final res = await ApiService.submitRefleksiOrtu({
                              'action': 'update',
                              'id': id,
                              'judul': editJudulCtrl.text.trim(),
                              'isi': editIsiCtrl.text.trim(),
                            });
                            if (res['status'] == 'success') {
                              Navigator.pop(ctx, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res['message'] ?? 'Gagal memperbarui')),
                              );
                              setDialogState(() => isSaving = false);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                            setDialogState(() => isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == true) {
      setState(() {
        final mutableMap = Map<String, dynamic>.from(_myRefleksi[index]);
        mutableMap['judul'] = editJudulCtrl.text.trim();
        mutableMap['isi'] = editIsiCtrl.text.trim();
        _myRefleksi[index] = mutableMap;
      });
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Refleksi berhasil diperbarui'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildRiwayatTab() {
    if (_myRefleksi.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.psychology_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Belum ada refleksi yang dikirim',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500), textAlign: TextAlign.center),
        ]),
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myRefleksi.length,
      itemBuilder: (_, i) {
        final item = _myRefleksi[i];
        final date = item['created_at'] ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
            border: Border.all(color: AppColors.purple.withOpacity(0.1)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.psychology_rounded, color: AppColors.purple, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(
                (item['judul'] ?? '').toString().isNotEmpty
                    ? item['judul'] : 'Refleksi Orang Tua',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              )),
              Text(date.toString().length > 10 ? date.toString().substring(0, 10) : date.toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                padding: EdgeInsets.zero,
                onSelected: (val) {
                  if (val == 'edit') {
                    _showEditDialog(item, i);
                  } else if (val == 'delete') {
                    _confirmDelete(item, i);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 16, color: AppColors.orange700),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(fontSize: 13, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 10),
            Text(item['isi'] ?? '-',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
          ]),
        );
      },
    );
  }
}

