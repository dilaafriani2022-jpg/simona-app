import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DataAnakScreen extends StatefulWidget {
  final int? idKelas;
  const DataAnakScreen({super.key, this.idKelas});

  @override
  State<DataAnakScreen> createState() => _DataAnakScreenState();
}

class _DataAnakScreenState extends State<DataAnakScreen>
    with SingleTickerProviderStateMixin {

  // ── Palet ────────────────────────────────────────────────────────────────
  static const Color _primary    = Color(0xFF7C3AED);   // ungu hangat
  static const Color _primaryDk  = Color(0xFF5B21B6);
  static const Color _primaryLt  = Color(0xFF8B5CF6);
  static const Color _bg         = Color(0xFFFAF5FF);
  static const Color _surface    = Colors.white;
  static const Color _border     = Color(0xFFEDE9FE);
  static const Color _slate      = Color(0xFF64748B);
  static const Color _green      = Color(0xFF059669);
  static const Color _amber      = Color(0xFFD97706);
  static const Color _rose       = Color(0xFFE11D48);

  // Warna per gender
  static const Color _boyColor   = Color(0xFF2563EB);
  static const Color _girlColor  = Color(0xFFDB2777);

  // ── State ────────────────────────────────────────────────────────────────
  List<dynamic> _anakList      = [];
  List<dynamic> _filtered      = [];
  bool          _isLoading     = true;
  String        _searchQuery   = '';
  String        _filterGender  = 'Semua';
  dynamic       _selectedAnak  = null;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase();
        _applyFilter();
      });
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
      final idKelas = widget.idKelas ?? 2;
      final res = await ApiService.fetch('manage_anak.php?id_kelas=$idKelas');
      if (res['status'] == 'success') {
        _anakList = List<dynamic>.from(res['data'] ?? []);
        _applyFilter();
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    _filtered = _anakList.where((a) {
      final nama  = (a['nama_anak'] ?? '').toString().toLowerCase();
      final nisn  = (a['nisn'] ?? '').toString().toLowerCase();
      final jk    = (a['jenis_kelamin'] ?? '').toString();
      final matchQ = _searchQuery.isEmpty ||
          nama.contains(_searchQuery) ||
          nisn.contains(_searchQuery);
      final matchG = _filterGender == 'Semua' ||
          (_filterGender == 'L' && jk == 'L') ||
          (_filterGender == 'P' && jk == 'P');
      return matchQ && matchG;
    }).toList();
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final lCount = _anakList.where((a) => a['jenis_kelamin'] == 'L').length;
    final pCount = _anakList.where((a) => a['jenis_kelamin'] == 'P').length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Data Anak',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAnak,
          ),
        ],
      ),

      body: Column(children: [

        // ── Header gradient ──────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _primaryLt, Color(0xFF9F67FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Stack(children: [
            Positioned(right: -20, top: -15,
              child: Opacity(opacity: 0.08,
                child: Icon(Icons.child_care_rounded,
                  size: MediaQuery.of(context).size.width * 0.4,
                  color: Colors.white))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Stat chips
                Row(children: [
                  _statChip('${_anakList.length}', 'Total Anak', Icons.people_rounded),
                  const SizedBox(width: 8),
                  _statChip('$lCount', 'Laki-laki', Icons.boy_rounded, color: _boyColor),
                  const SizedBox(width: 8),
                  _statChip('$pCount', 'Perempuan', Icons.girl_rounded, color: _girlColor),
                ]),
              ]),
            ),
          ]),
        ),

        // ── Search + Filter ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NISN...',
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
          ]),
        ),

        // ── Gender filter chips ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
          child: SizedBox(height: 34, child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _genderChip('Semua',     Icons.people_rounded,   null),
              _genderChip('L',         Icons.boy_rounded,      _boyColor),
              _genderChip('P',         Icons.girl_rounded,     _girlColor),
              const SizedBox(width: 16),
            ],
          )),
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
              child: Text('${_filtered.length} Anak Ditemukan',
                style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 12))))),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _primary))
            : _filtered.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadAnak, color: _primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _buildCard(_filtered[i], i),
                  ),
                ),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // CARD ANAK
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildCard(dynamic anak, int index) {
    final nama   = anak['nama_anak']?.toString() ?? '-';
    final nisn   = anak['nisn']?.toString() ?? '-';
    final jk     = anak['jenis_kelamin']?.toString() ?? '-';
    final tgl    = anak['tanggal_lahir']?.toString() ?? '-';
    final color  = jk == 'L' ? _boyColor : _girlColor;
    final icon   = jk == 'L' ? '👦' : '👧';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDetailSheet(anak),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Avatar
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(icon, style: const TextStyle(fontSize: 18)),
                ])),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text('${index + 1}',
                      style: TextStyle(fontSize: 10, color: _primary, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 7),
                  Expanded(child: Text(nama,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 5),
                Row(children: [
                  _infoChip(Icons.badge_rounded, 'NISN: $nisn', color),
                  const SizedBox(width: 6),
                  _infoChip(jk == 'L' ? Icons.boy_rounded : Icons.girl_rounded,
                    jk == 'L' ? 'Laki-laki' : 'Perempuan', color),
                ]),
                if (tgl != '-') ...[
                  const SizedBox(height: 4),
                  _infoChip(Icons.cake_rounded, _fmtTgl(tgl), Colors.grey.shade500),
                ],
              ])),

              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    ]);

  // ════════════════════════════════════════════════════════════════════════
  // DETAIL SHEET
  // ════════════════════════════════════════════════════════════════════════
  void _showDetailSheet(dynamic anak) {
    String val(String? key) {
      final s = anak[key]?.toString().trim() ?? '';
      return s.isEmpty ? '-' : s;
    }

    final nama   = val('nama_anak');
    final nisn   = val('nisn');
    final nik    = val('nik');
    final jk     = val('jenis_kelamin');
    final tempatLahir = val('tempat_lahir');
    final tgl    = val('tanggal_lahir');
    final agama  = val('agama');
    final statusAnak = val('status_anak');
    final anakKe = val('anak_ke');
    final beratBadan = val('berat_badan');
    final tinggiBadan = val('tinggi_badan');
    final alamat = val('alamat');

    // ── Ayah
    final ayahStatus   = val('ayah_status');   // 'Hidup' / 'Meninggal' / '-'
    final showAyah     = ayahStatus != 'Meninggal';
    final ayahNama     = val('ayah_nama');
    final ayahNik      = val('ayah_nik');
    final ayahTtl      = val('ayah_ttl');
    final ayahAgama    = val('ayah_agama');
    final ayahPendidikan = val('ayah_pendidikan');
    final ayahPekerjaan  = val('ayah_pekerjaan');
    final ayahPenghasilan= val('ayah_penghasilan');
    final ayahHp       = val('ayah_hp');

    // ── Ibu
    final ibuStatus    = val('ibu_status');    // 'Hidup' / 'Meninggal' / '-'
    final showIbu      = ibuStatus != 'Meninggal';
    final ibuNama      = val('ibu_nama');
    final ibuNik       = val('ibu_nik');
    final ibuTtl       = val('ibu_ttl');
    final ibuAgama     = val('ibu_agama');
    final ibuPendidikan = val('ibu_pendidikan');
    final ibuPekerjaan  = val('ibu_pekerjaan');
    final ibuPenghasilan= val('ibu_penghasilan');
    final ibuHp        = val('ibu_hp');

    // ── Wali (jika ada)
    final waliNama      = val('wali_nama');
    final waliHubungan  = val('wali_hubungan');
    final waliPekerjaan = val('wali_pekerjaan');
    final waliHp        = val('wali_hp');

    // ── Info kontak akun ortu (akun login)
    final emailOrtu  = val('email_ortu');
    final nikOrtu    = val('nisn_ortu');
    final hpOrtu     = val('no_hp_ortu');
    final alamatOrtu = val('alamat_ortu_detail');
    final color  = jk == 'L' ? _boyColor : _girlColor;
    final icon   = jk == 'L' ? '👦' : '👧';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.75, maxChildSize: 0.93,
        builder: (ctx2, scroll) => Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Handle
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: _primary.withOpacity(0.25), borderRadius: BorderRadius.circular(4)))),

              // Header card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(22)),
                child: Row(children: [
                  Container(width: 60, height: 60,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(18)),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 30)))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nama, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text('NISN: $nisn',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                  ])),
                ])),
              const SizedBox(height: 20),

              // Data diri
              _sheetSection('Data Diri', Icons.person_rounded, _primary),
              const SizedBox(height: 10),
              _detailCard(children: [
                if (nik != '-') _dRow(Icons.credit_card_rounded, 'NIK', nik),
                _dRow(Icons.wc_rounded, 'Jenis Kelamin', jk == 'L' ? 'Laki-laki' : 'Perempuan'),
                _dRow(Icons.cake_rounded, 'Tanggal Lahir', (tempatLahir != '-' ? '$tempatLahir, ' : '') + _fmtTgl(tgl)),
                if (agama != '-') _dRow(Icons.star_rounded, 'Agama', agama),
                if (statusAnak != '-') _dRow(Icons.family_restroom_rounded, 'Status Anak', '$statusAnak (Anak ke-$anakKe)'),
                if (beratBadan != '-') _dRow(Icons.monitor_weight_rounded, 'Berat Badan', '$beratBadan kg'),
                if (tinggiBadan != '-') _dRow(Icons.height_rounded, 'Tinggi Badan', '$tinggiBadan cm'),
                _dRow(Icons.home_rounded, 'Alamat', alamat, isLast: true),
              ]),
              const SizedBox(height: 16),

              // ── Data Ayah
              if (showAyah && ayahNama != '-') ...[
                _sheetSection('Data Ayah', Icons.man_rounded, const Color(0xFF1D4ED8)),
                const SizedBox(height: 10),
                _detailCard(children: [
                  _dRow(Icons.badge_rounded, 'Nama Ayah', ayahNama),
                  if (ayahNik != '-') _dRow(Icons.credit_card_rounded, 'NIK Ayah', ayahNik),
                  if (ayahTtl != '-') _dRow(Icons.cake_rounded, 'Tempat, Tgl Lahir', ayahTtl),
                  if (ayahAgama != '-') _dRow(Icons.star_rounded, 'Agama', ayahAgama),
                  if (ayahPendidikan != '-') _dRow(Icons.school_rounded, 'Pendidikan', ayahPendidikan),
                  if (ayahPekerjaan != '-') _dRow(Icons.work_rounded, 'Pekerjaan', ayahPekerjaan),
                  if (ayahPenghasilan != '-') _dRow(Icons.payments_rounded, 'Penghasilan', ayahPenghasilan),
                  if (ayahHp != '-') _dRow(Icons.phone_rounded, 'No. HP Ayah', ayahHp, isLast: true)
                  else _dRow(Icons.phone_rounded, 'No. HP', '-', isLast: true),
                ]),
                const SizedBox(height: 16),
              ],

              // ── Data Ibu
              if (showIbu && ibuNama != '-') ...[
                _sheetSection('Data Ibu', Icons.woman_rounded, const Color(0xFFDB2777)),
                const SizedBox(height: 10),
                _detailCard(children: [
                  _dRow(Icons.badge_rounded, 'Nama Ibu', ibuNama),
                  if (ibuNik != '-') _dRow(Icons.credit_card_rounded, 'NIK Ibu', ibuNik),
                  if (ibuTtl != '-') _dRow(Icons.cake_rounded, 'Tempat, Tgl Lahir', ibuTtl),
                  if (ibuAgama != '-') _dRow(Icons.star_rounded, 'Agama', ibuAgama),
                  if (ibuPendidikan != '-') _dRow(Icons.school_rounded, 'Pendidikan', ibuPendidikan),
                  if (ibuPekerjaan != '-') _dRow(Icons.work_rounded, 'Pekerjaan', ibuPekerjaan),
                  if (ibuPenghasilan != '-') _dRow(Icons.payments_rounded, 'Penghasilan', ibuPenghasilan),
                  if (ibuHp != '-') _dRow(Icons.phone_rounded, 'No. HP Ibu', ibuHp, isLast: true)
                  else _dRow(Icons.phone_rounded, 'No. HP', '-', isLast: true),
                ]),
                const SizedBox(height: 16),
              ],

              // ── Data Wali (jika ada)
              if (waliNama != '-') ...[
                _sheetSection('Data Wali', Icons.supervisor_account_rounded, const Color(0xFF0891B2)),
                const SizedBox(height: 10),
                _detailCard(children: [
                  _dRow(Icons.badge_rounded, 'Nama Wali', waliNama),
                  if (waliHubungan != '-') _dRow(Icons.people_rounded, 'Hubungan', waliHubungan),
                  if (waliPekerjaan != '-') _dRow(Icons.work_rounded, 'Pekerjaan', waliPekerjaan),
                  if (waliHp != '-') _dRow(Icons.phone_rounded, 'No. HP Wali', waliHp, isLast: true)
                  else _dRow(Icons.phone_rounded, 'No. HP', '-', isLast: true),
                ]),
                const SizedBox(height: 16),
              ],

              // ── Info Kontak Akun Orang Tua
              if (emailOrtu != '-' || hpOrtu != '-' || alamatOrtu != '-') ...[
                _sheetSection('Kontak & Alamat', Icons.contact_phone_rounded, const Color(0xFF059669)),
                const SizedBox(height: 10),
                _detailCard(children: [
                  if (nikOrtu != '-') _dRow(Icons.credit_card_rounded, 'NIK / NISN (Akun)', nikOrtu),
                  if (hpOrtu != '-') _dRow(Icons.phone_rounded, 'No. Telepon', hpOrtu),
                  if (emailOrtu != '-') _dRow(Icons.email_rounded, 'Email', emailOrtu),
                  if (alamatOrtu != '-') _dRow(Icons.home_rounded, 'Alamat Lengkap', alamatOrtu, isLast: true)
                  else _dRow(Icons.home_rounded, 'Alamat', '-', isLast: true),
                ]),
                const SizedBox(height: 20),
              ],

              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ]),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════════════
  Widget _statChip(String value, String label, IconData icon, {Color? color}) =>
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

  Widget _genderChip(String label, IconData icon, Color? color) {
    final sel = _filterGender == label;
    final disp = label == 'Semua' ? 'Semua' : label == 'L' ? 'Laki-laki' : 'Perempuan';
    return GestureDetector(
      onTap: () => setState(() { _filterGender = label; _applyFilter(); }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? (color ?? _primary) : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? (color ?? _primary) : Colors.grey.shade200),
          boxShadow: sel ? [BoxShadow(color: (color ?? _primary).withOpacity(0.2), blurRadius: 8)] : []),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: sel ? Colors.white : _slate),
          const SizedBox(width: 5),
          Text(disp, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: sel ? Colors.white : _slate)),
        ])));
  }

  Widget _sheetSection(String title, IconData icon, Color color) =>
    Row(children: [
      Container(padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 15)),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800)),
    ]);

  Widget _detailCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(children: children));

  Widget _dRow(IconData icon, String label, String value, {bool isLast = false}) =>
    Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: _primary), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 1),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          ])),
        ])),
      if (!isLast) Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16),
    ]);

  Widget _buildEmpty() => ListView(children: [
    SizedBox(height: 280, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _primary.withOpacity(0.07), shape: BoxShape.circle),
        child: Icon(Icons.child_care_rounded, size: 48, color: _primary.withOpacity(0.4))),
      const SizedBox(height: 16),
      Text(_searchQuery.isEmpty ? 'Belum ada data anak' : 'Anak tidak ditemukan',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Data anak dikelola oleh admin', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
    ]))),
  ]);

  String _fmtTgl(String raw) {
    try {
      final d = DateTime.parse(raw);
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) { return raw; }
  }
}
