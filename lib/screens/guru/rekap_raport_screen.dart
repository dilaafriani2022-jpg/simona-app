import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/api_service.dart';
import '../../utils/file_download_helper.dart';

// ── Colors ─────────────────────────────────────────────────────────────
const Color _primary = Color(0xFFC17B2F);
const Color _primaryDark = Color(0xFFA0601A);
const Color _navy = Color(0xFF1E3A8A);
const Color _bg = Color(0xFFFDF8F3);
const Color _cardBorder = Color(0xFFF0E8DF);
const Color _surface = Colors.white;
const Color _slate = Color(0xFF64748B);
const Color _red = Color(0xFFDC2626);
const Color _green = Color(0xFF059669);
const Color _teal = Color(0xFF0891B2);
const Color _amber = Color(0xFFF59E0B);

String _getCleanKelasName(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  String s = raw.trim();
  s = s.replaceAll(RegExp(r'\bkelompok\b', caseSensitive: false), '').trim();
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return 'Kelompok $s';
}

class RekapRaportScreen extends StatefulWidget {
  final int? idGuru;
  final int? idKelas;
  final bool isReadOnly;
  const RekapRaportScreen({super.key, this.idGuru, this.idKelas, this.isReadOnly = false});

  @override
  State<RekapRaportScreen> createState() => _RekapRaportScreenState();
}

class _RekapRaportScreenState extends State<RekapRaportScreen> {
  List<dynamic> _anakList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
    _loadAnak();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAnak() async {
    setState(() => _isLoading = true);
    try {
      final idKelas = widget.idKelas ?? 1;
      final res = await ApiService.fetch('manage_anak.php?id_kelas=$idKelas');
      if (res['status'] == 'success') {
        setState(() {
          _anakList = List<dynamic>.from(res['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint("Error loading anak: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAnak = _anakList.where((s) {
      final name = (s['nama_anak'] ?? '').toString().toLowerCase();
      final nisn = (s['nisn'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || nisn.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Rekap & Rapor Anak',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari nama anak atau NISN...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search_rounded, color: _primary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),

                // Kid List
                Expanded(
                  child: filteredAnak.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada data anak ditemukan',
                            style: GoogleFonts.poppins(color: _slate, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredAnak.length,
                          itemBuilder: (context, index) {
                            final s = filteredAnak[index];
                            final initial = (s['nama_anak'] ?? 'A')
                                .toString()
                                .trim()
                                .split(' ')
                                .map((word) => word.isNotEmpty ? word[0] : '')
                                .take(2)
                                .join()
                                .toUpperCase();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: _primary.withValues(alpha: 0.1),
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.poppins(
                                      color: _primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  s['nama_anak'] ?? 'Nama Anak',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'NISN: ${s['nisn'] ?? "-"} • Kelas: ${_getCleanKelasName(s['nama_kelas'])}',
                                    style: GoogleFonts.poppins(color: _slate, fontSize: 12),
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, color: _primary),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RekapRaportDetailScreen(
                                        anak: s,
                                        idGuru: widget.idGuru,
                                        idKelas: widget.idKelas,
                                        isReadOnly: widget.isReadOnly,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL SCREEN (REKAP BULANAN & RAPOR SEMESTER)
// ─────────────────────────────────────────────────────────────────────────────
class RekapRaportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> anak;
  final int? idGuru;
  final int? idKelas;
  final bool isReadOnly;
  const RekapRaportDetailScreen({
    super.key,
    required this.anak,
    this.idGuru,
    this.idKelas,
    this.isReadOnly = false,
  });

  @override
  State<RekapRaportDetailScreen> createState() => _RekapRaportDetailScreenState();
}

class _RekapRaportDetailScreenState extends State<RekapRaportDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedBulan = 1;
  int _semester = 1;
  bool _isLoadingData = false;
  bool _isExporting   = false;
  int  _currentTabIndex = 0;

  // Monthly Recap State
  Map<String, dynamic> _narasiData = {};
  Map<String, dynamic> _kehadiranStats = {'Hadir': 0, 'Sakit': 0, 'Izin': 0, 'Alpa': 0};
  List<dynamic> _ekskulList = [];
  List<dynamic> _activityRecaps = [];
  List<dynamic> _anekdotList = [];
  List<dynamic> _karyaList = [];

  // Semester Report State
  Map<String, dynamic> _semesterNarasi = {};
  Map<String, dynamic> _semesterKehadiran = {'Hadir': 0, 'Sakit': 0, 'Izin': 0, 'Alpa': 0};
  Map<String, dynamic> _schoolInfo = {};
  List<dynamic> _aspekList = [];
  Map<String, dynamic> _currentPhysical = {'berat_badan': '-', 'tinggi_badan': '-'};
  List<dynamic> _semesterRefleksiGuru = [];
  List<dynamic> _semesterRefleksiOrtu = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      setState(() => _currentTabIndex = _tabCtrl.index);
      _loadCurrentTab();
    });
    _loadCurrentTab();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool _isKelompokB(String? className) {
    if (className == null) return false;
    final lower = className.toLowerCase();
    return lower.contains('kelompok b') || lower == 'b' || lower.contains(' b') || lower.startsWith('b');
  }

  Future<void> _loadCurrentTab() async {
    if (_tabCtrl.index == 0) {
      await _loadMonthlyRecap();
    } else {
      await _loadSemesterReport();
    }
  }


  // ── LOAD MONTHLY RECAP DATA ───────────────────────────────────────────────
  Future<void> _loadMonthlyRecap() async {
    setState(() => _isLoadingData = true);
    final anakId = widget.anak['id'];
    final idGuru = widget.idGuru ?? 2;
    try {
      final narasiRes = await ApiService.fetch(
        'manage_rekap_bulanan.php?type=narasi_aspek&id_anak=$anakId&bulan=$_selectedBulan&semester=$_semester&id_guru=$idGuru',
      );
      if (narasiRes['status'] == 'success') {
        _narasiData = narasiRes['data'] ?? {};
      }

      final kehadiranRes = await ApiService.fetch(
        'get_kehadiran_ortu.php?id_anak=$anakId&bulan=$_selectedBulan&semester=$_semester',
      );
      if (kehadiranRes['status'] == 'success') {
        _kehadiranStats = Map<String, dynamic>.from(kehadiranRes['stats'] ?? {
          'Hadir': 0,
          'Sakit': 0,
          'Izin': 0,
          'Alpa': 0,
        });
      }

      final ekskulRes = await ApiService.fetch(
        'manage_ekstrakurikuler.php?type=anak-ekstra&id_anak=$anakId&semester=$_semester',
      );
      if (ekskulRes['status'] == 'success') {
        _ekskulList = List<dynamic>.from(ekskulRes['data'] ?? []);
      }

      final recapsRes = await ApiService.fetch(
        'manage_rekap_bulanan.php?type=rekomendasi&id_anak=$anakId&bulan=$_selectedBulan&semester=$_semester&id_guru=$idGuru',
      );
      if (recapsRes['status'] == 'success') {
        _activityRecaps = List<dynamic>.from(recapsRes['data'] ?? []);
      } else {
        _activityRecaps = [];
      }

      final anRes = await ApiService.getAnekdotOrtu(anakId);
      if (anRes['status'] == 'success') {
        _anekdotList = List<dynamic>.from(anRes['data'] ?? []);
      } else {
        _anekdotList = [];
      }

      final karyaRes = await ApiService.getKaryaAnak(anakId);
      if (karyaRes['status'] == 'success') {
        _karyaList = List<dynamic>.from(karyaRes['data'] ?? []);
      } else {
        _karyaList = [];
      }
    } catch (e) {
      debugPrint("Error loading monthly recap: $e");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _resyncDraft() async {
    setState(() => _isLoadingData = true);
    final anakId = widget.anak['id'];
    final idGuru = widget.idGuru ?? 2;
    try {
      final narasiRes = await ApiService.fetch(
        'manage_rekap_bulanan.php?type=narasi_aspek&id_anak=$anakId&bulan=$_selectedBulan&semester=$_semester&id_guru=$idGuru&force_draft=1',
      );
      if (narasiRes['status'] == 'success') {
        _narasiData = narasiRes['data'] ?? {};
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Draft narasi berhasil disinkronkan dari data penilaian & anekdot terbaru!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error resyncing draft: $e");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // ── LOAD SEMESTER REPORT DATA ──────────────────────────────────────────────
  Future<void> _loadSemesterReport() async {
    setState(() => _isLoadingData = true);
    final anakId = widget.anak['id'];
    final idGuru = widget.idGuru ?? 2;
    try {
      final narasiRes = await ApiService.fetch(
        'manage_rekap_bulanan.php?type=narasi_aspek&id_anak=$anakId&bulan=6&semester=$_semester&id_guru=$idGuru',
      );
      if (narasiRes['status'] == 'success') {
        _semesterNarasi = narasiRes['data'] ?? {};
      }

      final schoolRes = await ApiService.fetch('manage_sekolah.php');
      if (schoolRes['status'] == 'success') {
        _schoolInfo = schoolRes['data'] ?? {};
      }

      final physicalRes = await ApiService.fetch('get_pertumbuhan_fisik.php?id_anak=$anakId');
      if (physicalRes['status'] == 'success') {
        _currentPhysical = Map<String, dynamic>.from(physicalRes['current'] ?? {
          'berat_badan': '-',
          'tinggi_badan': '-',
        });
      }

      int totalHadir = 0;
      int totalSakit = 0;
      int totalIzin = 0;
      int totalAlpa = 0;
      final List<int> academicMonths = [1, 2, 3, 4, 5, 6];
      final futures = academicMonths.map((m) {
        return ApiService.fetch(
          'get_kehadiran_ortu.php?id_anak=$anakId&bulan=$m&semester=$_semester',
        );
      }).toList();

      final results = await Future.wait(futures);
      for (var r in results) {
        if (r['status'] == 'success' && r['stats'] != null) {
          final stats = r['stats'];
          totalHadir += int.tryParse(stats['Hadir']?.toString() ?? '0') ?? 0;
          totalSakit += int.tryParse(stats['Sakit']?.toString() ?? '0') ?? 0;
          totalIzin += int.tryParse(stats['Izin']?.toString() ?? '0') ?? 0;
          totalAlpa += int.tryParse(stats['Alpa']?.toString() ?? '0') ?? 0;
        }
      }

      _semesterKehadiran = {
        'Hadir': totalHadir,
        'Sakit': totalSakit,
        'Izin': totalIzin,
        'Alpa': totalAlpa,
      };

      final ekskulRes = await ApiService.fetch(
        'manage_ekstrakurikuler.php?type=anak-ekstra&id_anak=$anakId&semester=$_semester',
      );
      if (ekskulRes['status'] == 'success') {
        _ekskulList = List<dynamic>.from(ekskulRes['data'] ?? []);
      }

      final aspekRes = await ApiService.fetch('manage_aspek.php');
      if (aspekRes['status'] == 'success') {
        _aspekList = List<dynamic>.from(aspekRes['data'] ?? []);
      }

      final rgRes = await ApiService.fetch(
        'manage_refleksi_guru.php?id_anak=$anakId&semester=$_semester',
      );
      if (rgRes['status'] == 'success') {
        _semesterRefleksiGuru = List<dynamic>.from(rgRes['data'] ?? []);
      }

      final roRes = await ApiService.fetch(
        'manage_refleksi_ortu.php?id_anak=$anakId&semester=$_semester',
      );
      if (roRes['status'] == 'success') {
        _semesterRefleksiOrtu = List<dynamic>.from(roRes['data'] ?? []);
      }
    } catch (e) {
      debugPrint("Error loading semester report: $e");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // ── SAVE ASPECT NARRATIVES ────────────────────────────────────────────────
  Future<void> _saveAspectNarratives({
    required int bulan,
    required String agama,
    required String jatiDiri,
    required String steam,
    String? kokurikuler,
  }) async {
    final anakId = widget.anak['id'];
    final idGuru = widget.idGuru ?? 2;

    setState(() => _isLoadingData = true);
    try {
      final res = await ApiService.post('manage_rekap_bulanan.php', {
        'action': 'save_narasi_aspek',
        'id_anak': anakId,
        'id_guru': idGuru,
        'bulan': bulan,
        'semester': _semester,
        'narasi_agama': agama,
        'narasi_jati_diri': jatiDiri,
        'narasi_literasi_steam': steam,
        if (kokurikuler != null) 'narasi_kokurikuler': kokurikuler,
      });

      if (!mounted) return;
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapor berhasil disimpan!'), backgroundColor: Colors.green),
        );
        _loadCurrentTab();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Error saving: $e");
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  // ── EXPORT PDF ────────────────────────────────────────────────────────────
  Future<void> _executePdfExport({required bool saveDirectly}) async {
    setState(() => _isExporting = true);
    try {
      late final pw.Document doc;
      try {
        final fontRegular = await PdfGoogleFonts.robotoRegular();
        final fontBold = await PdfGoogleFonts.robotoBold();
        final fontItalic = await PdfGoogleFonts.robotoItalic();
        doc = pw.Document(
          theme: pw.ThemeData.withFont(
            base:   fontRegular,
            bold:   fontBold,
            italic: fontItalic,
          ),
        );
      } catch (e) {
        debugPrint('Error loading Google Fonts, falling back to standard font: $e');
        doc = pw.Document();
      }

      pw.MemoryImage? logoImage;
      try {
        final logoData = await rootBundle.load('assets/logo.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        debugPrint('Error loading logo asset: $e');
      }

      String cleanText(String? text) {
        if (text == null) return '';
        return text
            .replaceAll('•', '-')
            .replaceAll('“', '"')
            .replaceAll('”', '"')
            .replaceAll('‘', "'")
            .replaceAll('’', "'")
            .replaceAll('—', '-')
            .replaceAll('–', '-');
      }

      // ── Data ──────────────────────────────────────────────
      final name    = cleanText(widget.anak['nama_anak'] ?? '-');
      final nisn    = cleanText(widget.anak['nisn']      ?? '-');
      final kelas   = cleanText(_getCleanKelasName(widget.anak['nama_kelas']));
      final namaSekolah  = cleanText(_schoolInfo['nama_sekolah']  ?? 'TK NEGERI 2 BENGKALIS');
      final npsn         = cleanText(_schoolInfo['npsn']           ?? '6901094');
      final alamat       = cleanText(_schoolInfo['alamat']         ?? 'Sungai Alam, Bengkalis');
      final kepalaSekolah = cleanText(_schoolInfo['kepala_sekolah']        ?? 'H. Ahmad, M.Pd');
      final nipKepala    = cleanText(_schoolInfo['nip_kepala_sekolah']     ?? '');
      final namaGuru     = cleanText(_semesterNarasi['nama_guru']  ?? '-');
      final nipGuru      = cleanText(_semesterNarasi['nip_guru']   ?? '');
      final agamaSem     = cleanText(_semesterNarasi['narasi_agama']           ?? '-');
      final jatiDiriSem  = cleanText(_semesterNarasi['narasi_jati_diri']       ?? '-');
      final steamSem     = cleanText(_semesterNarasi['narasi_literasi_steam']  ?? '-');
      final semesterLabel = _semester == 1 ? '1 (SATU)' : '2 (DUA)';
      final tahunAjaran  = cleanText(widget.anak['tahun_ajaran'] ?? '2025/2026');
      final tanggal = DateFormat('d MMMM yyyy', 'id').format(DateTime.now());
      final bool hideRefleksiOrtu = _isKelompokB(widget.anak['nama_kelas']?.toString()) && _semester == 2;

      // ── Reflections & Kokurikuler ─────────────────────────
      String refGuruText = '';
      if (_semesterRefleksiGuru.isNotEmpty) {
        final List<String> parts = [];
        for (var ref in _semesterRefleksiGuru) {
          final p = cleanText(ref['pencapaian']?.toString() ?? '');
          if (p.isNotEmpty) parts.add(p);
        }
        if (parts.isNotEmpty) {
          refGuruText = parts.first;
        }
      }
      if (refGuruText.isEmpty) {
        refGuruText = 'Kemampuan komunikasi Ananda $name sudah aktif, jelas, dan percaya diri. Ananda juga mampu memahami dan melaksanakan instruksi yang diberikan ibuk guru dengan benar dan cepat.';
      }

      final List<String> refOrtuLines = [];
      if (_semesterRefleksiOrtu.isNotEmpty) {
        for (var ref in _semesterRefleksiOrtu) {
          final isi = cleanText(ref['isi']?.toString() ?? '');
          if (isi.isNotEmpty) {
            refOrtuLines.add(isi);
          }
        }
      }
      if (refOrtuLines.isEmpty) {
        refOrtuLines.addAll([
          'Saya merasa sangat puas dengan perkembangan anak saya disekolah.',
          'Anak saya bisa lebih cepat bangun dipagi hari.',
          'Saya ingin lebih terlibat dalam kegiatan sekolah anak saya.',
          'Saya berharap anak saya lebih mandiri, dan percaya diri.',
          'Anak saya sudah bisa berhitung, mengenal huruf bahkan membaca do\'a.',
          'Anak saya lebih aktif dan kreatif seperti menggambar, mewarnai membuat mainan dari kertas.',
          'Anak saya semakin percaya diri dalam menyampaikan pikiran.',
        ]);
      }

      final kokurikulerText = cleanText(_semesterNarasi['narasi_kokurikuler'] ?? '');

      // ── PDF Styles ─────────────────────────────────────────
      final styleBold  = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10);
      final styleNormal = const pw.TextStyle(fontSize: 10);
      final styleSmall  = const pw.TextStyle(fontSize: 9);
      final styleItalic = pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic);

      pw.Widget cell(String text, {bool bold = false, pw.Alignment align = pw.Alignment.centerLeft}) =>
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(text, style: bold ? styleBold : styleNormal,
                textAlign: align == pw.Alignment.center ? pw.TextAlign.center : pw.TextAlign.left),
          );

      pw.TableRow metadataRow(String key, String value, {bool boldValue = false}) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(key, style: styleNormal),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(':', style: styleBold),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(value, style: boldValue ? styleBold : styleNormal),
            ),
          ],
        );
      }

      pw.TableRow metadataCoverRow(String key, String value, {bool isLink = false}) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
              child: pw.Text(key, style: styleNormal.copyWith(fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
              child: pw.Text(':', style: styleNormal.copyWith(fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
              child: pw.Text(
                value,
                style: styleNormal.copyWith(
                  fontSize: 10,
                  decoration: isLink ? pw.TextDecoration.underline : null,
                  color: isLink ? PdfColors.blue : null,
                ),
              ),
            ),
          ],
        );
      }

      // ── Aspect box: colored header + paragraph narasi (Word-friendly pw.Table) ─────────────────────
      pw.Widget aspectBox(String title, String content, PdfColor headerColor, PdfColor borderColor) {
        // Split narasi into paragraphs (separated by blank lines or single newlines)
        final rawParas = content.trim().split(RegExp(r'\n\s*\n|\n'));
        final paras = rawParas.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
        final displayText = content.isEmpty || content == '-';

        return pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 1.0),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: headerColor),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                  child: pw.Center(
                    child: pw.Text(
                      title,
                      style: styleBold.copyWith(fontSize: 11, color: PdfColors.black),
                    ),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: displayText
                      ? pw.Text('Belum diisi.', style: styleItalic)
                      : pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: paras.asMap().entries.map((e) => pw.Padding(
                            padding: pw.EdgeInsets.only(bottom: e.key < paras.length - 1 ? 8 : 0),
                            child: pw.Text(
                              '      ${e.value}',  // indent first line with spaces
                              style: styleNormal.copyWith(lineSpacing: 2.0),
                              textAlign: pw.TextAlign.justify,
                            ),
                          )).toList(),
                        ),
                ),
              ],
            ),
          ],
        );
      }

      pw.Widget ekskulBox() {
        final List<pw.TableRow> rows = [];
        rows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#C55A11')),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Center(child: pw.Text('No', style: styleBold.copyWith(color: PdfColors.white, fontSize: 9))),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Center(child: pw.Text('Ekstrakurikuler', style: styleBold.copyWith(color: PdfColors.white, fontSize: 9))),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Center(child: pw.Text('Keterangan', style: styleBold.copyWith(color: PdfColors.white, fontSize: 9))),
              ),
            ],
          ),
        );

        if (_ekskulList.isEmpty) {
          rows.add(
            pw.TableRow(
              children: [
                cell('-', align: pw.Alignment.center),
                cell('-', align: pw.Alignment.center),
                cell('-', align: pw.Alignment.center),
              ],
            ),
          );
        } else {
          for (var i = 0; i < _ekskulList.length; i++) {
            final e = _ekskulList[i];
            final no = '${i + 1}.';
            final nama = cleanText(e['nama_ekstrakurikuler']?.toString() ?? '-');
            final catatan = cleanText(e['catatan']?.toString() ?? '-');
            rows.add(
              pw.TableRow(
                children: [
                  cell(no, align: pw.Alignment.center),
                  cell(nama),
                  cell(catatan),
                ],
              ),
            );
          }
        }

        return pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
          columnWidths: const {
            0: pw.FixedColumnWidth(30),
            1: pw.FixedColumnWidth(120),
            2: pw.FixedColumnWidth(373),
          },
          children: rows,
        );
      }

      pw.Widget prestasiBox() {
        return pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
          columnWidths: const {
            0: pw.FixedColumnWidth(30),
            1: pw.FixedColumnWidth(120),
            2: pw.FixedColumnWidth(373),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#A9D08E')),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Center(child: pw.Text('No', style: styleBold.copyWith(color: PdfColors.black, fontSize: 9))),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Center(child: pw.Text('JENIS PRESTASI', style: styleBold.copyWith(color: PdfColors.black, fontSize: 9))),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Center(child: pw.Text('Keterangan', style: styleBold.copyWith(color: PdfColors.black, fontSize: 9))),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                cell('-', align: pw.Alignment.center),
                cell('-', align: pw.Alignment.center),
                cell('-', align: pw.Alignment.center),
              ],
            ),
          ],
        );
      }

      pw.Widget kehadiranBoxItem(String value, String label, PdfColor labelBgColor) {
        return pw.Container(
          width: 90,
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6),
                    child: pw.Center(
                      child: pw.Text(
                        value,
                        style: styleBold.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                decoration: pw.BoxDecoration(color: labelBgColor),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6),
                    child: pw.Center(
                      child: pw.Text(
                        label,
                        style: styleNormal.copyWith(fontSize: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      pw.Widget tingkatKehadiranBox() {
        final sakitVal = _semesterKehadiran["Sakit"]?.toString() ?? '0';
        final izinVal = _semesterKehadiran["Izin"]?.toString() ?? '0';
        final alpaVal = _semesterKehadiran["Alpa"]?.toString() ?? '0';
        final alpaDisplay = alpaVal == '0' ? '-' : alpaVal;

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#A9D08E')),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Center(
                        child: pw.Text(
                          'TINGKAT KEHADIRAN',
                          style: styleBold.copyWith(fontSize: 10, color: PdfColors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                kehadiranBoxItem(sakitVal, 'Sakit', PdfColor.fromHex('#FCE4D6')),
                kehadiranBoxItem(izinVal, 'Izin', PdfColor.fromHex('#FFF2CC')),
                kehadiranBoxItem(alpaDisplay, 'Tanpa Keterangan', PdfColor.fromHex('#E7E6E6')),
              ],
            ),
          ],
        );
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
          build: (context) => [
            // ── COVER PAGE (Halaman 1) ──────────────────────────────────
            // Semua widget TOP-LEVEL MultiPage → dapat bounded width 523pt
            // Tidak ada FlexColumnWidth di dalam Column/Align → tidak ada NaN
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 20),
                  logoImage != null
                      ? pw.Image(logoImage, width: 90, height: 90)
                      : pw.SizedBox(width: 90, height: 90),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'LAPORAN',
                    style: styleBold.copyWith(fontSize: 13),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'PENILAIAN PERKEMBANGAN ANAK DIDIK',
                    style: styleBold.copyWith(fontSize: 12),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    namaSekolah.toUpperCase(),
                    style: styleBold.copyWith(fontSize: 12),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 35),
                  pw.Container(
                    width: 320,
                    child: pw.Table(
                      columnWidths: const {
                        0: pw.FixedColumnWidth(110),
                        1: pw.FixedColumnWidth(15),
                        2: pw.FixedColumnWidth(195),
                      },
                      children: [
                        metadataCoverRow('Nama Lembaga', namaSekolah.toUpperCase()),
                        metadataCoverRow('NPSN', npsn),
                        metadataCoverRow('NSTK', _schoolInfo['nstk']?.toString() ?? '002090201009'),
                        metadataCoverRow('Alamat', alamat.toUpperCase(), isLink: true),
                        metadataCoverRow('Desa/Kelurahan', (_schoolInfo['kelurahan'] ?? 'SUNGAI ALAM').toString().toUpperCase()),
                        metadataCoverRow('Kecamatan', (_schoolInfo['kecamatan'] ?? 'BENGKALIS').toString().toUpperCase()),
                        metadataCoverRow('Kabupaten/Kota', (_schoolInfo['kabupaten'] ?? 'BENGKALIS').toString().toUpperCase()),
                        metadataCoverRow('Propinsi', (_schoolInfo['provinsi'] ?? 'RIAU').toString().toUpperCase()),
                        metadataCoverRow('Kode Pos', _schoolInfo['kode_pos'] ?? '28751'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 35),
                  pw.Text(
                    'Nama Anak Didik',
                    style: styleBold.copyWith(fontSize: 11),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    name.toUpperCase(),
                    style: styleBold.copyWith(
                      fontSize: 11,
                      decoration: pw.TextDecoration.underline,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'NISN : $nisn',
                    style: styleBold.copyWith(
                      fontSize: 10,
                      decoration: pw.TextDecoration.underline,
                      color: PdfColors.blue,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 70),
                  pw.Text(
                    namaSekolah.toUpperCase(),
                    style: styleBold.copyWith(fontSize: 11),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),

            pw.NewPage(),

            // ── Halaman 2: Keterangan Anak Didik ────────────────────────────
            pw.Text(
              'KETERANGAN ANAK DIDIK',
              style: styleBold.copyWith(fontSize: 13),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 16),

            // Helper: indent row builder for keterangan page
            ..._buildKeteranganItems(widget.anak, styleBold, styleNormal, cleanText),

            pw.SizedBox(height: 30),

            // Signature block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: stamp/photo box + footnote
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 80,
                      height: 90,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 1.0),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      '*) Coret yang tidaksesuai',
                      style: styleSmall.copyWith(fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ),
                // Right: date + principal
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Bengkalis, $tanggal',
                      style: styleNormal,
                    ),
                    pw.Text(
                      'KEPALA ${namaSekolah.toUpperCase()}',
                      style: styleBold,
                    ),
                    pw.SizedBox(height: 55),
                    pw.Text(
                      kepalaSekolah,
                      style: styleBold.copyWith(decoration: pw.TextDecoration.underline),
                    ),
                    if (nipKepala.isNotEmpty)
                      pw.Text('NIP. $nipKepala', style: styleNormal),
                  ],
                ),
              ],
            ),

            pw.NewPage(),

            // ── Halaman 3: Petunjuk Penggunaan ───────────────────────────────
            pw.Text(
              'PETUNJUK PENGGUNAAN',
              style: styleBold.copyWith(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 20),

            // Item 1
            _petunjukItem(
              '1.',
              [pw.TextSpan(text:
                'Raport PAUD yang selanjutnya disebut Buku Laporan Penilaian Perkembangan Anak '
                '(LPPA) Kurikulum Merdeka PAUD dipergunakan selama Anak didik mengikuti '
                'seluruh Program Pembelajaran di Sekolah',
                style: styleNormal)],
            ),
            pw.SizedBox(height: 10),

            // Item 2
            _petunjukItem(
              '2.',
              [pw.TextSpan(text:
                'Apabila Anak didik pindah sekolah, buku LPPA dibawa oleh Anak didik yang '
                'bersangkutan untuk dipergunakan di sekolah baru sebagai bukti pencapaian '
                'kompetensi dengan meninggalkan arsip di Sekolah asal;',
                style: styleNormal)],
            ),
            pw.SizedBox(height: 10),

            // Item 3
            _petunjukItem(
              '3.',
              [pw.TextSpan(text:
                'Identitas Satuan PAUD dan identitas Anak didik diisi sesuai dengan data riil lembaga '
                'dan data Anak didik bersangkutan;',
                style: styleNormal)],
            ),
            pw.SizedBox(height: 10),

            // Item 4 — "ukuran 3" underlined
            _petunjukItem(
              '4.',
              [
                pw.TextSpan(
                  text: 'Buku Laporan Penilaian Perkembangan Anak Didik TK dilengkapi dengan Pasfhoto ',
                  style: styleNormal,
                ),
                pw.TextSpan(
                  text: 'ukuran 3',
                  style: styleNormal.copyWith(decoration: pw.TextDecoration.underline),
                ),
                pw.TextSpan(
                  text: ' x 4 Cm',
                  style: styleNormal,
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Item 5 — "bentuk uraian" underlined
            _petunjukItem(
              '5.',
              [
                pw.TextSpan(
                  text: 'Penilaian Perkembangan Anak Didik TK diberikan secara kualitatif dalam ',
                  style: styleNormal,
                ),
                pw.TextSpan(
                  text: 'bentuk uraian',
                  style: styleNormal.copyWith(decoration: pw.TextDecoration.underline),
                ),
                pw.TextSpan(
                  text: ' (deskripsi) yang dikelompokkan dalam 2 program kegiatan belajar yaitu:',
                  style: styleNormal,
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            // Sub-items a & b
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('a.   Pembentukan Perilaku', style: styleNormal),
                  pw.SizedBox(height: 4),
                  pw.Text('b.   Pengembangan Kemampuan Dasar', style: styleNormal),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Item 6 — "terus menerus" underlined
            _petunjukItem(
              '6.',
              [
                pw.TextSpan(
                  text: 'Penilaian tersebut dilakukan dengan menggunakan teknik-teknik penilaian yang '
                      'berlaku di TK secara ',
                  style: styleNormal,
                ),
                pw.TextSpan(
                  text: 'terus menerus',
                  style: styleNormal.copyWith(decoration: pw.TextDecoration.underline),
                ),
                pw.TextSpan(text: '.', style: styleNormal),
              ],
            ),

            pw.NewPage(),

            // ── Halaman 4: Keterangan Nilai Kualitatif Capaian Pembelajaran ──
            pw.Text(
              'KETERANGAN NILAI KUALITATIF',
              style: styleBold.copyWith(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'CAPAIAN PEMBELAJARAN',
              style: styleBold.copyWith(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 16),

            // Dynamic list of aspek + descriptions from operator
            ..._aspekList.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final aspek = entry.value as Map<String, dynamic>;
              final namaAspek = cleanText(aspek['nama_aspek']?.toString() ?? '');
              final deskripsiRaw = cleanText(aspek['deskripsi']?.toString() ?? '');
              // Split multi-line descriptions into bullet points
              final bullets = deskripsiRaw
                  .split('\n')
                  .map((l) => l.trim())
                  .where((l) => l.isNotEmpty)
                  .toList();

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Numbered bold aspect name
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 20,
                        child: pw.Text('$idx.', style: styleBold),
                      ),
                      pw.Container(
                        width: 503,
                        child: pw.Text(namaAspek, style: styleBold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  if (bullets.isEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 20, bottom: 10),
                      child: pw.Text('-', style: styleItalic),
                    )
                  else
                    ...bullets.map(
                      (bullet) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 20, bottom: 5),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('• ', style: styleNormal),
                            pw.Container(
                              width: 493,
                              child: pw.Text(
                                bullet,
                                style: styleNormal,
                                textAlign: pw.TextAlign.justify,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  pw.SizedBox(height: 6),
                ],
              );
            }),

            pw.NewPage(),

            // ── Halaman 5: Judul, Identitas & Agama ─────────────────────────

            pw.Text(
              'LAPORAN PENILAIAN PERKEMBANGAN ANAK',
              style: styleBold.copyWith(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 15),

            // Metadata 2 Kolom — borderless like template
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 251.5,
                    child: pw.Table(
                      columnWidths: const {
                        0: pw.FixedColumnWidth(90),
                        1: pw.FixedColumnWidth(8),
                        2: pw.FixedColumnWidth(153.5),
                      },
                      children: [
                        metadataRow('Nama Sekolah', namaSekolah),
                        metadataRow('Nama Anak Didik', name, boldValue: true),
                        metadataRow('Tahun Ajaran', tahunAjaran),
                        metadataRow('Semester', semesterLabel),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Container(
                    width: 251.5,
                    child: pw.Table(
                      columnWidths: const {
                        0: pw.FixedColumnWidth(70),
                        1: pw.FixedColumnWidth(8),
                        2: pw.FixedColumnWidth(173.5),
                      },
                      children: [
                        metadataRow('Kelompok', kelas),
                        metadataRow('Fase', 'Fondasi'),
                        metadataRow('Tinggi Badan', '${_currentPhysical["tinggi_badan"] ?? "-"} Cm'),
                        metadataRow('Berat Badan', '${_currentPhysical["berat_badan"] ?? "-"} Kg'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),


            aspectBox(
              'Nilai Agama dan Budi Pekerti',
              agamaSem,
              PdfColor.fromHex('#A2D149'),   // bright green header
              PdfColors.black,               // black border
            ),

            pw.NewPage(),

            // ── Halaman 6: Jati Diri & STEAM ──────────────────────────────
            aspectBox(
              'Jati Diri',
              jatiDiriSem,
              PdfColor.fromHex('#29B6F6'),   // bright blue header
              PdfColors.black,               // black border
            ),
            pw.SizedBox(height: 14),
            aspectBox(
              'Dasar Literasi dan STEAM',
              steamSem,
              PdfColor.fromHex('#F27B79'),   // coral/pink header
              PdfColors.black,               // black border
            ),

            pw.NewPage(),

            // ── Halaman 7: Foto Kegiatan Anak ───────────────────────────────
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.red),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8),
                      child: pw.Center(
                        child: pw.Text(
                          'Foto Kegiatan Anak',
                          style: styleBold.copyWith(fontSize: 11, color: PdfColors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Container(
                              height: 190,
                              child: pw.Center(child: pw.Text('Foto 1', style: styleSmall.copyWith(color: PdfColors.grey400))),
                            ),
                            pw.Container(
                              height: 190,
                              child: pw.Center(child: pw.Text('Foto 2', style: styleSmall.copyWith(color: PdfColors.grey400))),
                            ),
                            pw.Container(
                              height: 190,
                              child: pw.Center(child: pw.Text('Foto 3', style: styleSmall.copyWith(color: PdfColors.grey400))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Container(
                              height: 190,
                              child: pw.Center(child: pw.Text('Foto 4', style: styleSmall.copyWith(color: PdfColors.grey400))),
                            ),
                            pw.Container(
                              height: 190,
                              child: pw.Center(child: pw.Text('Foto 5', style: styleSmall.copyWith(color: PdfColors.grey400))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Container(
                              height: 190,
                              child: pw.Center(child: pw.Text('Foto 6', style: styleSmall.copyWith(color: PdfColors.grey400))),
                            ),
                            pw.Container(
                              height: 190,
                              child: pw.Center(child: pw.Text('Foto 7', style: styleSmall.copyWith(color: PdfColors.grey400))),
                            ),
                            pw.Container(
                              height: 190,
                              child: pw.Center(child: pw.Text('Foto 8', style: styleSmall.copyWith(color: PdfColors.grey400))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            pw.NewPage(),

            // ── Halaman 8: Refleksi & Kokurikuler ────────────────────────────
            // 1. Refleksi Guru
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#A2D149')),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Center(
                        child: pw.Text(
                          'Refleksi Guru',
                          style: styleBold.copyWith(fontSize: 10, color: PdfColors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text(
                        refGuruText,
                        style: styleNormal.copyWith(lineSpacing: 2.0),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 2. Refleksi Orang Tua
            if (!hideRefleksiOrtu) ...[
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FFD966')),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Center(
                          child: pw.Text(
                            'Refleksi Orang Tua',
                            style: styleBold.copyWith(fontSize: 10, color: PdfColors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: refOrtuLines.asMap().entries.map((entry) {
                            final idx = entry.key + 1;
                            final text = entry.value;
                            return pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('$idx. ', style: styleNormal),
                                  pw.Container(
                                    width: 488,
                                    child: pw.Text(
                                      text,
                                      style: styleNormal.copyWith(lineSpacing: 2.0),
                                      textAlign: pw.TextAlign.justify,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
            ],

            // 3. Kokurikuler Gerakan 7 Kebiasaan Anak Indonesia Hebat
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#29B6F6')),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Center(
                        child: pw.Text(
                          'KOKURIKULER GERAKAN 7 KEBIASAAN ANAK INDONESIA HEBAT',
                          style: styleBold.copyWith(fontSize: 9, color: PdfColors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text(
                        kokurikulerText,
                        style: styleNormal.copyWith(lineSpacing: 2.0),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 4. Foto Kegiatan Kokurikuler
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#BDD7EE')),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Center(
                        child: pw.Text(
                          'FOTO KEGIATAN KOKURIKULER',
                          style: styleBold.copyWith(fontSize: 10, color: PdfColors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Container(
                              height: 140,
                              child: pw.Center(child: pw.Text('Foto Kokurikuler 1', style: styleSmall.copyWith(color: PdfColors.grey400))),
                            ),
                            pw.Container(
                              height: 140,
                              child: pw.Center(child: pw.Text('Foto Kokurikuler 2', style: styleSmall.copyWith(color: PdfColors.grey400))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            pw.NewPage(),

            // ── Halaman 9: Ekskul, Prestasi, Kehadiran, & Tanda Tangan ──────
            pw.Text(
              'A. KEGIATAN EKSTRAKURIKULER',
              style: styleBold.copyWith(fontSize: 10),
            ),
            pw.SizedBox(height: 6),
            ekskulBox(),
            pw.SizedBox(height: 14),

            pw.Text(
              'B. PRESTASI',
              style: styleBold.copyWith(fontSize: 10),
            ),
            pw.SizedBox(height: 6),
            prestasiBox(),
            pw.SizedBox(height: 14),

            tingkatKehadiranBox(),
            pw.SizedBox(height: 20),

            // Date block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.SizedBox(width: 80, child: pw.Text('Diberikan di', style: styleNormal)),
                        pw.Text(': Bengkalis', style: styleNormal),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.SizedBox(width: 80, child: pw.Text('Tanggal', style: styleNormal)),
                        pw.Text(': $tanggal', style: styleNormal),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Signature Row 1
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 30),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Orang Tua/Wali', style: styleBold),
                      pw.SizedBox(height: 45),
                      pw.Text('(                           )', style: styleBold),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 30),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Guru Kelompok', style: styleBold),
                      pw.SizedBox(height: 45),
                      pw.Text(
                        namaGuru.toUpperCase(),
                        style: styleBold.copyWith(decoration: pw.TextDecoration.underline),
                      ),
                      if (nipGuru.isNotEmpty)
                        pw.Text('NIP. $nipGuru', style: styleNormal),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 25),

            // Signature Row 2 (Principal)
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Kepala $namaSekolah', style: styleBold),
                  pw.SizedBox(height: 45),
                  pw.Text(
                    kepalaSekolah.toUpperCase(),
                    style: styleBold.copyWith(decoration: pw.TextDecoration.underline),
                  ),
                  if (nipKepala.isNotEmpty)
                    pw.Text('NIP. $nipKepala', style: styleNormal),
                ],
              ),
            ),
          ],
        ),
      );

      final pdfBytes = await doc.save();
      final filename = 'Rapor_${name.replaceAll(' ', '_')}_Semester$_semester.pdf';

      if (kIsWeb) {
        await downloadFile(pdfBytes, filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Rapor berhasil diunduh ke folder download browser Anda.'),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else if (saveDirectly) {
        final filePath = await _saveFileToDevice(pdfBytes, filename);
        if (filePath != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rapor berhasil diunduh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          Text(filename, style: const TextStyle(fontSize: 10, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                action: SnackBarAction(
                  label: 'BUKA',
                  textColor: Colors.yellowAccent,
                  onPressed: () async {
                    try {
                      await OpenFilex.open(filePath);
                    } catch (e) {
                      debugPrint("Gagal membuka file: $e");
                    }
                  },
                ),
              ),
            );
          }
        } else {
          throw Exception('Gagal menyimpan ke penyimpanan HP');
        }
      } else {
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _executeWordExport({required bool saveDirectly}) async {
    setState(() => _isExporting = true);
    try {
      final anakId = widget.anak['id'];
      final name = widget.anak['nama_anak'] ?? 'Anak';
      final url = '${ApiService.baseUrl}/export_raport_word.php?id_anak=$anakId&semester=$_semester';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final filename = 'Rapor_${name.replaceAll(' ', '_')}_Semester$_semester.doc';
        if (kIsWeb) {
          await downloadFile(response.bodyBytes, filename);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Rapor Word berhasil diunduh ke folder download browser Anda.'),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        } else if (saveDirectly) {
          final filePath = await _saveFileToDevice(response.bodyBytes, filename);
          if (filePath != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rapor berhasil diunduh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                            Text(filename, style: const TextStyle(fontSize: 10, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  action: SnackBarAction(
                    label: 'BUKA',
                    textColor: Colors.yellowAccent,
                    onPressed: () async {
                      try {
                        await OpenFilex.open(filePath);
                      } catch (e) {
                        debugPrint("Gagal membuka file: $e");
                      }
                    },
                  ),
                ),
              );
            }
          } else {
            throw Exception('Gagal menyimpan ke penyimpanan HP');
          }
        } else {
          await Printing.sharePdf(
            bytes: response.bodyBytes,
            filename: filename,
          );
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export Word: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

    Future<String?> _saveFileToDevice(Uint8List bytes, String filename) async {
    try {
      Directory? dir;
      if (!kIsWeb) {
  
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final filePath = '${dir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      }
    } catch (e) {
      debugPrint("Error saving file directly: $e");
    }
    return null;
  }

  Future<void> _showExportConfirmation(BuildContext context, String type) async {
    final name = widget.anak['nama_anak'] ?? 'Anak';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              type == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
              color: type == 'PDF' ? Colors.red : Colors.blue,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text('Ekspor Rapor $type', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('Apakah Anda yakin ingin mengekspor rapor $name ke format $type?'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (type == 'PDF') {
                    _executePdfExport(saveDirectly: true);
                  } else {
                    _executeWordExport(saveDirectly: true);
                  }
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: _primary),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                icon: const Icon(Icons.download_rounded, size: 16, color: _primary),
                label: const Text('Simpan', style: TextStyle(fontSize: 12, color: _primary)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (type == 'PDF') {
                    _executePdfExport(saveDirectly: false);
                  } else {
                    _executeWordExport(saveDirectly: false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  elevation: 0,
                ),
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Bagikan', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── HELPER: Numbered item for Petunjuk Penggunaan page ──────────────────
  pw.Widget _petunjukItem(String number, List<pw.TextSpan> spans) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 22,
          child: pw.Text(number, style: const pw.TextStyle(fontSize: 10)),
        ),
        pw.Container(
          width: 501,
          child: pw.RichText(
            textAlign: pw.TextAlign.justify,
            text: pw.TextSpan(children: spans),
          ),
        ),
      ],
    );
  }

  // ── HELPER: Build numbered list for Keterangan Anak Didik page ───────────

  List<pw.Widget> _buildKeteranganItems(
    Map<String, dynamic> anak,
    pw.TextStyle bold,
    pw.TextStyle normal,
    String Function(String?) clean,
  ) {
    final nameLengkap = clean(anak['nama_anak'] ?? '-');
    final namaPanggilan = clean(anak['nama_panggilan'] ?? '');
    final nisnVal = clean(anak['nisn'] ?? '-');
    final nikVal = clean(anak['nik'] ?? '');
    final jenisKelamin = (anak['jenis_kelamin']?.toString() ?? '') == 'L' ? 'Laki-laki' : 'Perempuan';
    final tempatLahir = clean(anak['tempat_lahir'] ?? '-');
    final tglLahirRaw = anak['tanggal_lahir']?.toString() ?? '';
    String tglLahirStr = tglLahirRaw;
    try {
      if (tglLahirRaw.isNotEmpty) {
        final parsed = DateTime.parse(tglLahirRaw);
        tglLahirStr = DateFormat('d MMMM yyyy', 'id').format(parsed);
      }
    } catch (_) {}
    final ttl = '$tempatLahir, $tglLahirStr';
    final agama = clean(anak['agama'] ?? 'Islam');
    final anakKe = anak['anak_ke']?.toString() ?? '-';
    final anakKeLabel = _numberToWords(int.tryParse(anakKe) ?? 0);
    final ayahNama = clean(anak['ayah_nama'] ?? '-').toUpperCase();
    final ibuNama = clean(anak['ibu_nama'] ?? '-').toUpperCase();
    final ayahPekerjaan = clean(anak['ayah_pekerjaan'] ?? '-');
    final ibuPekerjaan = clean(anak['ibu_pekerjaan'] ?? '-');
    final jalan = clean(anak['alamat_ortu_detail'] ?? anak['alamat'] ?? '-');
    final telp = clean(anak['no_hp_ortu'] ?? anak['ayah_hp'] ?? '-');
    final desa = clean(anak['kelurahan'] ?? '-');
    final kecamatan = clean(anak['kecamatan'] ?? '-');
    final kota = clean(anak['kota'] ?? '-');
    final provinsi = clean(anak['provinsi'] ?? '-');

    final colWidths = {
      0: const pw.FixedColumnWidth(28.0),  // number/letter indent
      1: const pw.FixedColumnWidth(192.4), // label
      2: const pw.FixedColumnWidth(14.0),  // colon
      3: const pw.FixedColumnWidth(288.6), // value
    };

    pw.TableRow itemRow(String num, String label, String value, {bool boldValue = false}) =>
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
              child: pw.Text(num, style: normal),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
              child: pw.Text(label, style: normal),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
              child: pw.Text(':', style: normal),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
              child: pw.Text(
                value,
                style: boldValue
                    ? bold.copyWith(decoration: pw.TextDecoration.underline)
                    : normal,
              ),
            ),
          ],
        );

    return [
      pw.Table(
        columnWidths: colWidths,
        children: [
          itemRow('1.', 'Nama Anak Didik', ''),
          itemRow('', '  a.  Nama Lengkap', nameLengkap, boldValue: true),
          itemRow('', '  b.  Nama Panggilan', namaPanggilan.isEmpty ? '-' : namaPanggilan),
          itemRow('2.', 'Nomor NISN / Nomor Induk', nikVal.isNotEmpty ? '$nisnVal /$nikVal' : nisnVal),
          itemRow('3.', 'Jenis Kelamin', jenisKelamin),
          itemRow('4.', 'Tempat, TanggalLahir', ttl),
          itemRow('5.', 'Agama', agama),
          itemRow('6.', 'Anak Ke', '$anakKe ($anakKeLabel)'),
          itemRow('7.', 'Nama Orang Tua/Wali*)', ''),
          itemRow('', '  a.  Ayah', ayahNama),
          itemRow('', '  b.  Ibu', ibuNama),
          itemRow('8.', 'Pekerjaan Orang Tua/Wali*)', ''),
          itemRow('', '  a.  Ayah', ayahPekerjaan),
          itemRow('', '  b.  Ibu', ibuPekerjaan),
          itemRow('9.', 'Alamat Orang Tua/Wali*)', ''),
          itemRow('', '  a.  Jalan', jalan),
          itemRow('', '  b.  Telepon', telp),
          itemRow('', '  c.  Desa/Kelurahan', desa),
          itemRow('', '  d.  Kecamatan', kecamatan.toUpperCase()),
          itemRow('', '  e.  Kabupaten/Kota', kota.toUpperCase()),
          itemRow('', '  f.  Propinsi', provinsi.toUpperCase()),
        ],
      ),
    ];
  }

  String _numberToWords(int n) {
    const words = ['', 'Satu', 'Dua', 'Tiga', 'Empat', 'Lima', 'Enam', 'Tujuh', 'Delapan', 'Sembilan', 'Sepuluh'];
    if (n <= 0 || n >= words.length) return n.toString();
    return words[n];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          widget.anak['nama_anak'] ?? 'Detail Anak',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          // ── Export PDF button (only on Rapor Akhir tab and if not read-only) ──────────────
          if (_currentTabIndex == 1 && !widget.isReadOnly)
            _isExporting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Export Word',
                        icon: const Icon(Icons.description_rounded, color: Colors.white),
                        onPressed: () => _showExportConfirmation(context, 'Word'),
                      ),
                      IconButton(
                        tooltip: 'Export PDF',
                        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                        onPressed: () => _showExportConfirmation(context, 'PDF'),
                      ),
                    ],
                  ),
          // ── Semester selector ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<int>(
              value: _semester,
              dropdownColor: _primary,
              underline: const SizedBox(),
              iconEnabledColor: Colors.white,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Semester 1')),
                DropdownMenuItem(value: 2, child: Text('Semester 2')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _semester = val);
                  _loadCurrentTab();
                }
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Rekap Penilaian'),
            Tab(text: 'Rapor Akhir'),
          ],
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildRekapPenilaianTab(),
                _buildRaporSemesterTab(),
              ],
            ),
    );
  }

  Widget _buildRekapPenilaianTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(6, (index) {
                final bulanIndex = index + 1;
                final isSelected = _selectedBulan == bulanIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      'Bulan $bulanIndex',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : _slate,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: _primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? _primary : _cardBorder),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedBulan = bulanIndex);
                        _loadMonthlyRecap();
                      }
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          _buildIdentitasCard(),
          const SizedBox(height: 16),

          _buildDominantRatingsCard(),
          const SizedBox(height: 16),

          _buildAspekCard(),
          const SizedBox(height: 16),

          _buildKehadiranCard(_kehadiranStats),
          const SizedBox(height: 16),

          _buildEkskulCard(),
          const SizedBox(height: 16),

          _buildWeeklyActivitiesCard(),
          const SizedBox(height: 16),
          _buildAnekdotCardLaporan(),
          const SizedBox(height: 16),
          _buildKaryaCardLaporan(),
          if (!widget.isReadOnly) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showActivityRecapSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(
                  'Nilai & Rekap Kegiatan Pembelajaran',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdentitasCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.anak['nama_anak'] ?? '-',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryDark),
          ),
          const SizedBox(height: 4),
          Text(
            'NISN: ${widget.anak["nisn"] ?? "-"} • Kelas: ${widget.anak["nama_kelas"] ?? "-"}',
            style: GoogleFonts.poppins(fontSize: 12, color: _slate),
          ),
        ],
      ),
    );
  }

  Widget _identitasRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.poppins(color: _slate, fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspekCard() {
    final agama = _narasiData['narasi_agama'] ?? '-';
    final jatiDiri = _narasiData['narasi_jati_diri'] ?? '-';
    final steam = _narasiData['narasi_literasi_steam'] ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rekap Per Aspek',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 14),
              ),
              if (!widget.isReadOnly)
                IconButton(
                  onPressed: () => _showEditNarasiDialog(
                    bulan: _selectedBulan,
                    currentAgama: agama,
                    currentJatiDiri: jatiDiri,
                    currentSteam: steam,
                  ),
                  icon: const Icon(Icons.edit_rounded, color: _primary, size: 20),
                )
            ],
          ),
          const Divider(height: 10),
          _aspekItem('Nilai Agama dan Budi Pekerti', agama),
          const SizedBox(height: 14),
          _aspekItem('Jati Diri', jatiDiri),
          const SizedBox(height: 14),
          _aspekItem('Dasar Literasi dan STEAM', steam),
        ],
      ),
    );
  }

  Widget _aspekItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDominantRatingsCard() {
    final Map<String, dynamic>? ratings = _narasiData['dominant_ratings'] is Map
        ? Map<String, dynamic>.from(_narasiData['dominant_ratings'])
        : null;

    if (ratings == null || ratings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Color(0xFF059669), size: 20),
              const SizedBox(width: 8),
              Text(
                'Analisis Capaian Terbanyak Bulan Ini',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Berdasarkan seluruh checklist mingguan untuk bulan terpilih',
            style: GoogleFonts.poppins(fontSize: 10, color: _slate),
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          _dominantRatingRow('Agama & Budi Pekerti', ratings['agama']),
          const SizedBox(height: 12),
          _dominantRatingRow('Jati Diri', ratings['jati_diri']),
          const SizedBox(height: 12),
          _dominantRatingRow('Dasar Literasi & STEAM', ratings['steam']),
        ],
      ),
    );
  }

  Widget _dominantRatingRow(String title, Map<String, dynamic>? info) {
    if (info == null) return const SizedBox.shrink();

    final String dominant = info['dominant']?.toString() ?? '-';
    final int count = int.tryParse(info['count']?.toString() ?? '0') ?? 0;
    final int total = int.tryParse(info['total']?.toString() ?? '0') ?? 0;

    Color badgeBg = Colors.grey.shade100;
    Color badgeText = Colors.grey.shade600;
    String label = 'Belum Dinilai';

    if (dominant == 'M') {
      badgeBg = const Color(0xFFD1FAE5);
      badgeText = const Color(0xFF065F46);
      label = 'Muncul (M)';
    } else if (dominant == 'MM') {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFF92400E);
      label = 'Mulai Muncul (MM)';
    } else if (dominant == 'TM') {
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFF991B1B);
      label = 'Tidak Muncul (TM)';
    }

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: badgeText,
              fontSize: 10.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          total > 0 ? '$count/$total kali' : '-',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildKehadiranCard(Map<String, dynamic> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rekap Kehadiran',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 14),
          ),
          const Divider(height: 20),
          _kehadiranRow('Hadir', '${stats['Hadir'] ?? 0} Hari', _green),
          _kehadiranRow('Izin', '${stats['Izin'] ?? 0} Hari', _amber),
          _kehadiranRow('Sakit', '${stats['Sakit'] ?? 0} Hari', _teal),
          _kehadiranRow('Alpha', '${stats['Alpa'] ?? 0} Hari', _red),
        ],
      ),
    );
  }

  Widget _kehadiranRow(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 12),
          ),
          Text(
            val,
            style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEkskulCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ekstrakurikuler',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 14),
          ),
          const Divider(height: 20),
          if (_ekskulList.isEmpty)
            Text(
              'Tidak mengikuti kegiatan ekstrakurikuler semester ini.',
              style: GoogleFonts.poppins(color: _slate, fontSize: 12, fontStyle: FontStyle.italic),
            )
          else
            ..._ekskulList.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star_rounded, color: _amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e['nama_ekstrakurikuler'] ?? '-',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 12),
                            ),
                            if (e['catatan'] != null && e['catatan'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  e['catatan'],
                                  style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  void _showEditNarasiDialog({
    required int bulan,
    required String currentAgama,
    required String currentJatiDiri,
    required String currentSteam,
    String? currentKokurikuler,
  }) {
    final agamaCtrl = TextEditingController(text: currentAgama == '-' ? '' : currentAgama);
    final jatiDiriCtrl = TextEditingController(text: currentJatiDiri == '-' ? '' : currentJatiDiri);
    final steamCtrl = TextEditingController(text: currentSteam == '-' ? '' : currentSteam);
    final kokurikulerCtrl = TextEditingController(text: (currentKokurikuler ?? '') == '-' ? '' : (currentKokurikuler ?? ''));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          bulan == 6 ? 'Edit Rapor Semester' : 'Edit Narasi Bulan $bulan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryDark),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNarrativeField('Nilai Agama dan Budi Pekerti', agamaCtrl),
                const SizedBox(height: 14),
                _buildNarrativeField('Jati Diri', jatiDiriCtrl),
                const SizedBox(height: 14),
                _buildNarrativeField('Dasar Literasi dan STEAM', steamCtrl),
                if (bulan == 6) ...[
                  const SizedBox(height: 14),
                  _buildNarrativeField('Kokurikuler Gerakan 7 Kebiasaan Anak Indonesia Hebat', kokurikulerCtrl),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.poppins(color: _slate)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveAspectNarratives(
                bulan: bulan,
                agama: agamaCtrl.text,
                jatiDiri: jatiDiriCtrl.text,
                steam: steamCtrl.text,
                kokurikuler: bulan == 6 ? kokurikulerCtrl.text : null,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Simpan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrativeField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: 4,
          style: GoogleFonts.poppins(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Tulis deskripsi capaian anak di sini...',
            fillColor: _bg,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardBorder),
            ),
          ),
        ),
      ],
    );
  }

  void _showActivityRecapSheet() async {
    setState(() => _isLoadingData = true);
    final anakId = widget.anak['id'];
    final idGuru = widget.idGuru ?? 2;

    List<dynamic> recaps = [];
    try {
      final res = await ApiService.fetch(
        'manage_rekap_bulanan.php?type=rekomendasi&id_anak=$anakId&bulan=$_selectedBulan&semester=$_semester&id_guru=$idGuru',
      );
      if (res['status'] == 'success') {
        recaps = List<dynamic>.from(res['data'] ?? []);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoadingData = false);
    }

    if (recaps.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada kegiatan pembelajaran yang direncanakan pada bulan ini.'),
            backgroundColor: _amber,
          ),
        );
      }
      return;
    }

    final List<Map<String, dynamic>> editedItems = recaps.map((item) {
      return {
        'id_kegiatan': item['id_kegiatan'],
        'nama_kegiatan': item['nama_kegiatan'],
        'nama_tujuan': item['nama_tujuan'],
        'nama_aspek': item['nama_aspek'],
        'detail_mingguan': item['detail_mingguan'] ?? [],
        'status_rekomendasi': item['status_rekomendasi'] ?? 'TM',
        'status_akhir': item['sudah_direkap'] == true
            ? item['status_tersimpan']
            : item['status_rekomendasi'] ?? 'TM',
        'catatan_perkembangan': item['sudah_direkap'] == true
            ? item['catatan_tersimpan'] ?? ''
            : '',
      };
    }).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rekap Kegiatan Pembelajaran',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _primaryDark,
                              ),
                            ),
                            Text(
                              'Bulan $_selectedBulan • ${widget.anak["nama_anak"]}',
                              style: GoogleFonts.poppins(fontSize: 12, color: _slate),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() => _isLoadingData = true);
                          try {
                            final saveRes = await ApiService.post('manage_rekap_bulanan.php', {
                              'action': 'save_batch',
                              'id_anak': anakId,
                              'id_guru': idGuru,
                              'bulan': _selectedBulan,
                              'semester': _semester,
                              'items': editedItems.map((e) => {
                                    'id_kegiatan': e['id_kegiatan'],
                                    'status_akhir': e['status_akhir'],
                                    'catatan_perkembangan': e['catatan_perkembangan'],
                                  }).toList(),
                            });

                            if (!mounted) return;
                            if (saveRes['status'] == 'success') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rekap kegiatan berhasil disimpan!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadMonthlyRecap();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(saveRes['message'] ?? 'Gagal menyimpan'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint(e.toString());
                          } finally {
                            setState(() => _isLoadingData = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: Text(
                          'Simpan',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: editedItems.length,
                    itemBuilder: (context, index) {
                      final item = editedItems[index];

                      final details = List<dynamic>.from(item['detail_mingguan'] ?? []);
                      final String detailsStr = details.isEmpty
                          ? '-'
                          : details.map((d) => 'Mgg ${d["minggu_ke"]}: ${d["status"]}').join(', ');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item["nama_aspek"]} • ${item["nama_tujuan"]}',
                                style: GoogleFonts.poppins(
                                  color: _primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              item['nama_kegiatan'] ?? '-',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),

                            Text(
                              'Histori Penilaian Mingguan:',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildWeeklyStatusRow(details),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Text(
                                  'Status Akhir: ',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusChip(
                                  label: 'TM',
                                  isSelected: item['status_akhir'] == 'TM',
                                  activeColor: _red,
                                  onTap: () {
                                    setLocalState(() => item['status_akhir'] = 'TM');
                                  },
                                ),
                                const SizedBox(width: 6),
                                _buildStatusChip(
                                  label: 'MM',
                                  isSelected: item['status_akhir'] == 'MM',
                                  activeColor: _amber,
                                  onTap: () {
                                    setLocalState(() => item['status_akhir'] = 'MM');
                                  },
                                ),
                                const SizedBox(width: 6),
                                _buildStatusChip(
                                  label: 'M',
                                  isSelected: item['status_akhir'] == 'M',
                                  activeColor: _green,
                                  onTap: () {
                                    setLocalState(() => item['status_akhir'] = 'M');
                                  },
                                ),
                                const Spacer(),
                                if (item['status_rekomendasi'] != null)
                                  Text(
                                    'Rekomendasi: ${item["status_rekomendasi"]}',
                                    style: GoogleFonts.poppins(
                                      color: _slate,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              initialValue: item['catatan_perkembangan'],
                              onChanged: (val) {
                                item['catatan_perkembangan'] = val;
                              },
                              style: GoogleFonts.poppins(fontSize: 12),
                              decoration: InputDecoration(
                                labelText: 'Catatan Perkembangan Kegiatan',
                                labelStyle: GoogleFonts.poppins(fontSize: 11, color: _slate),
                                hintText: 'Tulis catatan spesifik untuk kegiatan ini...',
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _cardBorder),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor : _cardBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : _slate,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyStatusRow(List<dynamic> details) {
    final int weeksInMonth = _selectedBulan == 5 ? 2 : 4;
    final int startWeek = (_selectedBulan - 1) * 4 + 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(weeksInMonth, (i) {
        final weekNum = startWeek + i;
        final weekData = details.firstWhere(
          (d) => int.tryParse(d['minggu_ke'].toString()) == weekNum,
          orElse: () => null,
        );
        final String status = weekData != null ? weekData['status'] ?? '-' : '-';

        Color badgeBg = Colors.grey.shade100;
        Color textCol = Colors.grey.shade600;
        if (status == 'M') {
          badgeBg = _green.withValues(alpha: 0.15);
          textCol = _green;
        } else if (status == 'MM') {
          badgeBg = _amber.withValues(alpha: 0.15);
          textCol = _amber;
        } else if (status == 'TM') {
          badgeBg = _red.withValues(alpha: 0.15);
          textCol = _red;
        }

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < weeksInMonth - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: weekData != null ? textCol.withValues(alpha: 0.3) : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Minggu $weekNum',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textCol,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWeeklyActivitiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detail Penilaian Mingguan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Bulan $_selectedBulan',
                  style: GoogleFonts.poppins(
                    color: _primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (_activityRecaps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Belum ada data penilaian mingguan untuk bulan ini.',
                style: GoogleFonts.poppins(
                  color: _slate,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activityRecaps.length,
              itemBuilder: (context, idx) {
                final item = _activityRecaps[idx];
                final details = List<dynamic>.from(item['detail_mingguan'] ?? []);
                final bool sudahDirekap = item['sudah_direkap'] == true;
                final statusAkhir = sudahDirekap ? item['status_tersimpan'] : null;
                final catatan = sudahDirekap ? item['catatan_tersimpan'] : null;

                Color statusColor = _slate;
                if (statusAkhir == 'M') statusColor = _green;
                if (statusAkhir == 'MM') statusColor = _amber;
                if (statusAkhir == 'TM') statusColor = _red;

                return Container(
                  margin: EdgeInsets.only(bottom: idx < _activityRecaps.length - 1 ? 16.0 : 0.0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item["nama_aspek"]} • ${item["nama_tujuan"]}',
                                style: GoogleFonts.poppins(
                                  color: _primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (statusAkhir != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Akhir: $statusAkhir',
                                style: GoogleFonts.poppins(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Belum direkap',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['nama_kegiatan'] ?? '-',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildWeeklyStatusRow(details),
                      if (catatan != null && catatan.toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Text(
                            catatan,
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnekdotCardLaporan() {
    final filtered = _anekdotList.where((item) {
      final dateStr = item['tanggal']?.toString() ?? '';
      if (dateStr.isEmpty) return false;
      try {
        final parsedDate = DateTime.parse(dateStr);
        final month = parsedDate.month;
        int itemAcademicBulan = 0;
        if (_semester == 1) {
          if (month >= 7 && month <= 12) itemAcademicBulan = month - 6;
        } else {
          if (month >= 1 && month <= 6) itemAcademicBulan = month;
        }
        return itemAcademicBulan == _selectedBulan;
      } catch (e) {
        return false;
      }
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _navy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sticky_note_2_rounded, color: _navy, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Catatan Anekdot Bulan Ini',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800),
              ),
            ],
          ),
          const Divider(height: 20),
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Tidak ada catatan anekdot untuk bulan ini.',
                  style: GoogleFonts.poppins(color: _slate, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            Column(
              children: filtered.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['aspek_perkembangan'] ?? '-',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['tanggal'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 10, color: _slate),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Peristiwa: ${item['peristiwa'] ?? '-'}',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      if ((item['interpretasi'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Interpretasi: ${item['interpretasi']}',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildKaryaCardLaporan() {
    final filtered = _karyaList.where((item) {
      final dateStr = item['tanggal']?.toString() ?? '';
      if (dateStr.isEmpty) return false;
      try {
        final parsedDate = DateTime.parse(dateStr);
        final month = parsedDate.month;
        int itemAcademicBulan = 0;
        if (_semester == 1) {
          if (month >= 7 && month <= 12) itemAcademicBulan = month - 6;
        } else {
          if (month >= 1 && month <= 6) itemAcademicBulan = month;
        }
        return itemAcademicBulan == _selectedBulan;
      } catch (e) {
        return false;
      }
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.palette_rounded, color: _teal, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Hasil Karya Bulan Ini',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800),
              ),
            ],
          ),
          const Divider(height: 20),
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Tidak ada hasil karya untuk bulan ini.',
                  style: GoogleFonts.poppins(color: _slate, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            Column(
              children: filtered.map((item) {
                final String? urlFoto = item['url_foto'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (urlFoto != null && urlFoto.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            urlFoto.startsWith('http') ? urlFoto : '${ApiService.baseUrl}/$urlFoto',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_rounded, size: 20, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['judul'] ?? '-',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade800),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item['tanggal'] ?? '',
                                  style: GoogleFonts.poppins(fontSize: 9, color: _slate),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kategori: ${item['kategori'] ?? '-'}',
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _teal),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['deskripsi'] ?? '-',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRaporSemesterTab() {
    final name = widget.anak['nama_anak'] ?? '-';
    final nisn = widget.anak['nisn'] ?? '-';
    final kelas = widget.anak['nama_kelas'] ?? 'B';
    final activeTA = '2024 / 2025';

    final String kelasDisplay = _getCleanKelasName(kelas);

    final agamaSem = _semesterNarasi['narasi_agama'] ?? '-';
    final jatiDiriSem = _semesterNarasi['narasi_jati_diri'] ?? '-';
    final steamSem = _semesterNarasi['narasi_literasi_steam'] ?? '-';

    String refGuruText = '';
    if (_semesterRefleksiGuru.isNotEmpty) {
      final List<String> parts = [];
      for (var ref in _semesterRefleksiGuru) {
        final p = ref['pencapaian']?.toString() ?? '';
        if (p.isNotEmpty) parts.add(p);
      }
      if (parts.isNotEmpty) {
        refGuruText = parts.first;
      }
    }
    if (refGuruText.isEmpty) {
      refGuruText = 'Kemampuan komunikasi Ananda $name sudah aktif, jelas, dan percaya diri. Ananda juga mampu memahami dan melaksanakan instruksi yang diberikan ibuk guru dengan benar dan cepat.';
    }

    final List<String> refOrtuLines = [];
    if (_semesterRefleksiOrtu.isNotEmpty) {
      for (var ref in _semesterRefleksiOrtu) {
        final isi = ref['isi']?.toString() ?? '';
        if (isi.isNotEmpty) {
          refOrtuLines.add(isi);
        }
      }
    }
    if (refOrtuLines.isEmpty) {
      refOrtuLines.addAll([
        'Saya merasa sangat puas dengan perkembangan anak saya disekolah.',
        'Anak saya bisa lebih cepat bangun dipagi hari.',
        'Saya ingin lebih terlibat dalam kegiatan sekolah anak saya.',
        'Saya berharap anak saya lebih mandiri, dan percaya diri.',
        'Anak saya sudah bisa berhitung, mengenal huruf bahkan membaca do\'a.',
        'Anak saya lebih aktif dan kreatif seperti menggambar, mewarnai membuat mainan dari kertas.',
        'Anak saya semakin percaya diri dalam menyampaikan pikiran.',
      ]);
    }

    final kokurikulerText = _semesterNarasi['narasi_kokurikuler']?.toString() ?? '';
    final bool hideRefleksiOrtu = _isKelompokB(widget.anak['nama_kelas']?.toString()) && _semester == 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        _schoolInfo['nama_sekolah']?.toString().toUpperCase() ?? 'TK NEGERI 2 BENGKALIS',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NPSN: ${_schoolInfo["npsn"] ?? "6901094"} • Alamat: ${_schoolInfo["alamat"] ?? "Sungai Alam, Bengkalis"}',
                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.black, width: 1),
                      bottom: BorderSide(color: Colors.black, width: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: Text(
                    'LAPORAN CAPAIAN PERKEMBANGAN ANAK (RAPOR)',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.underline),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                _buildSemesterMetadataTable(name, nisn, kelasDisplay, activeTA),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'I. Capaian Perkembangan',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                    ),
                    if (!widget.isReadOnly)
                      InkWell(
                        onTap: () => _showEditNarasiDialog(
                          bulan: 6,
                          currentAgama: agamaSem,
                          currentJatiDiri: jatiDiriSem,
                          currentSteam: steamSem,
                          currentKokurikuler: _semesterNarasi['narasi_kokurikuler']?.toString() ?? '',
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_rounded, color: _primary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Edit Narasi',
                              style: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.bold, fontSize: 11),
                            )
                          ],
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 8),
                _formalNarrativeBlock('A. Nilai Agama dan Budi Pekerti', agamaSem, const Color(0xFFA2D149)),
                _formalNarrativeBlock('B. Jati Diri', jatiDiriSem, const Color(0xFF29B6F6)),
                _formalNarrativeBlock('C. Dasar Literasi dan STEAM', steamSem, const Color(0xFFF27B79)),
                const SizedBox(height: 20),

                Text(
                  'II. Foto Kegiatan Anak',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black87),
                  ),
                  child: Center(
                    child: Text(
                      '📸 Foto Kegiatan Anak (Tersedia pada file PDF/Word hasil ekspor)',
                      style: GoogleFonts.poppins(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'III. Refleksi & Kokurikuler',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                _refleksiBlock('Refleksi Guru', refGuruText, const Color(0xFFA2D149)),
                if (!hideRefleksiOrtu)
                  _refleksiListBlock('Refleksi Orang Tua', refOrtuLines, const Color(0xFFFFD966)),
                _refleksiBlock('Kokurikuler Gerakan 7 Kebiasaan Anak Indonesia Hebat', kokurikulerText, const Color(0xFF29B6F6)),
                const SizedBox(height: 12),
                Text(
                  'Foto Kegiatan Kokurikuler',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Center(
                    child: Text(
                      '📸 Foto Kegiatan Kokurikuler (Tersedia pada file PDF/Word hasil ekspor)',
                      style: GoogleFonts.poppins(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'IV. Ekstrakurikuler, Prestasi, & Kehadiran',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 8),

                Text(
                  'A. Ekstrakurikuler',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                if (_ekskulList.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
                    child: Text(
                      '-',
                      style: GoogleFonts.poppins(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Table(
                    border: TableBorder.all(color: Colors.black26),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(3),
                    },
                    children: [
                      TableRow(children: [
                        _tableHeaderCell('Nama Kegiatan'),
                        _tableHeaderCell('Deskripsi/Catatan'),
                      ]),
                      ..._ekskulList.map((e) => TableRow(children: [
                            _tableDataCell(e['nama_ekstrakurikuler'] ?? '-'),
                            _tableDataCell(e['catatan'] ?? '-'),
                          ])),
                    ],
                  ),
                const SizedBox(height: 16),

                Text(
                  'B. Prestasi',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Table(
                  border: TableBorder.all(color: Colors.black26),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(4),
                    2: FlexColumnWidth(5),
                  },
                  children: [
                    TableRow(children: [
                      _tableHeaderCell('No'),
                      _tableHeaderCell('Jenis Prestasi'),
                      _tableHeaderCell('Keterangan'),
                    ]),
                    TableRow(children: [
                      _tableDataCell('-'),
                      _tableDataCell('-'),
                      _tableDataCell('-'),
                    ]),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'C. Kehadiran (Kumulatif Semester)',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Table(
                  border: TableBorder.all(color: Colors.black26),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(children: [
                      _tableHeaderCell('Hadir'),
                      _tableHeaderCell('Sakit'),
                      _tableHeaderCell('Izin'),
                      _tableHeaderCell('Alpa'),
                    ]),
                    TableRow(children: [
                      _tableDataCell('${_semesterKehadiran["Hadir"] ?? 0} hari'),
                      _tableDataCell('${_semesterKehadiran["Sakit"] ?? 0} hari'),
                      _tableDataCell('${_semesterKehadiran["Izin"] ?? 0} hari'),
                      _tableDataCell('${_semesterKehadiran["Alpa"] ?? 0} hari'),
                    ]),
                  ],
                ),
                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Orang Tua / Wali Murid,',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                        const SizedBox(height: 50),
                        Text(
                          '( ....................................... )',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Bengkalis, ${DateFormat('d MMMM yyyy', 'id').format(DateTime.now())}",
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                        Text(
                          'Guru Kelas,',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                        const SizedBox(height: 50),
                        Text(
                          _semesterNarasi['nama_guru'] ?? 'Budi Santoso',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Mengetahui,',
                        style: GoogleFonts.poppins(fontSize: 11),
                      ),
                      Text(
                        'Kepala Sekolah ${_schoolInfo["nama_sekolah"] ?? "TK Negeri 2 Bengkalis"},',
                        style: GoogleFonts.poppins(fontSize: 11),
                      ),
                      const SizedBox(height: 50),
                      Text(
                        _schoolInfo['kepala_sekolah'] ?? 'H. Ahmad, M.Pd',
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      ),
                      Text(
                        'NIP. ${_schoolInfo["nip_kepala_sekolah"] ?? "123456789"}',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterMetadataTable(String name, String nisn, String kelas, String activeTA) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FixedColumnWidth(16),
        2: FlexColumnWidth(),
      },
      children: [
        _metadataRow('Nama Peserta Didik', name),
        _metadataRow('NISN', nisn),
        _metadataRow('Nama Kelas', kelas),
        _metadataRow('Semester', _semester == 1 ? '1 (Ganjil)' : '2 (Genap)'),
        _metadataRow('Tahun Ajaran', activeTA),
      ],
    );
  }

  TableRow _metadataRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            ':',
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _formalNarrativeBlock(String title, String content, Color headerColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: headerColor,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Text(
                title.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                content,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  height: 1.6,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _refleksiBlock(String title, String content, Color headerColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: headerColor,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Text(
                title.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                content,
                style: GoogleFonts.poppins(fontSize: 11, height: 1.5, color: Colors.black87),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _refleksiListBlock(String title, List<String> lines, Color headerColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: headerColor,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Text(
                title.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(lines.length, (idx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${idx + 1}. ', style: GoogleFonts.poppins(fontSize: 11, color: Colors.black87)),
                        Expanded(
                          child: Text(
                            lines[idx],
                            style: GoogleFonts.poppins(fontSize: 11, height: 1.5, color: Colors.black87),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeaderCell(String label) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(8),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _tableDataCell(String val) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        val,
        style: GoogleFonts.poppins(fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
  }
}

