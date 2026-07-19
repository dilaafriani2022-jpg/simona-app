import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageGuruScreen extends StatefulWidget {
  const ManageGuruScreen({super.key});

  @override
  State<ManageGuruScreen> createState() => _ManageGuruScreenState();
}

class _ManageGuruScreenState extends State<ManageGuruScreen>
    with SingleTickerProviderStateMixin {

  // ── Palet warna hangat & elegan ────────────────────────────────────────────
  static const Color _primary     = Color(0xFFC17B2F);
  static const Color _primaryDark = Color(0xFFA0601A);
  static const Color _navy        = Color(0xFF1E3A8A);
  static const Color _navyLight   = Color(0xFF2D4EAA);
  static const Color _bg          = Color(0xFFFDF8F3);
  static const Color _cardBorder  = Color(0xFFF0E8DF);
  static const Color _red         = Color(0xFFDC2626);
  static const Color _blueM       = Color(0xFF2980B9);
  static const Color _pinkF       = Color(0xFFEC4899);
  static const Color _green       = Color(0xFF059669);
  static const Color _purple      = Color(0xFF7C3AED);
  static const Color _teal        = Color(0xFF0891B2);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<dynamic> _allGuru      = [];
  List<dynamic> _filteredGuru = [];
  List<dynamic> _kelasList    = [];

  bool _isLoading   = true;
  bool _isConnected = false;
  int  _mockIdCounter = 1000;

  late final AnimationController _headerAnim;

  // ════════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _fetchData();
    _fetchKelas();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DATA
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.fetchData('manage_guru.php', []);
      if (result['status'] == 'success') {
        _allGuru     = List<dynamic>.from(result['data']);
        _isConnected = result['source'] == 'server';
      } else { _allGuru = []; _isConnected = false; }
    } catch (_) { _allGuru = []; _isConnected = false; }
    setState(() {
      _isLoading = false;
      _runFilter();
    });
  }

  Future<void> _fetchKelas() async {
    try {
      final res = await ApiService.fetchData('manage_kelas.php', []);
      if (res['status'] == 'success') setState(() => _kelasList = List<dynamic>.from(res['data']));
    } catch (_) {}
  }

  // Hitung ulang _filteredGuru berdasarkan teks search — TIDAK memanggil setState.
  void _runFilter() {
    final q = _searchController.text.toLowerCase();
    _searchQuery = q;
    _filteredGuru = q.isEmpty ? List.from(_allGuru) : _allGuru.where((g) {
      final name  = (g['name']       ?? '').toString().toLowerCase();
      final nip   = (g['nip']        ?? '').toString().toLowerCase();
      final nik   = (g['nik']        ?? '').toString().toLowerCase();
      final telp  = (g['no_telp']    ?? '').toString().toLowerCase();
      final jab   = (g['jabatan']    ?? '').toString().toLowerCase();
      final kelas = (g['nama_kelas'] ?? '').toString().toLowerCase();
      return name.contains(q)  || nip.contains(q)  || nik.contains(q) ||
             telp.contains(q)  || jab.contains(q)  || kelas.contains(q);
    }).toList();
  }

  // Wrapper yang memanggil _runFilter lalu setState — dipakai oleh listener.
  void _applyFilter() {
    setState(_runFilter);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SNACKBAR
  // ════════════════════════════════════════════════════════════════════════════

  void _snackOk(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18), const SizedBox(width: 8), Expanded(child: Text(msg))]),
    backgroundColor: _green, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  void _snackErr(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: _red, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  // ════════════════════════════════════════════════════════════════════════════
  // FORM SHEET — Multi-step 4 langkah
  // ════════════════════════════════════════════════════════════════════════════

  void _showFormSheet({Map<String, dynamic>? item}) {
    final bool isEditing = item != null;

    // Controllers
    final nameCtrl    = TextEditingController(text: item?['name']           ?? '');
    final nipCtrl     = TextEditingController(text: item?['nip']            ?? '');
    final nikCtrl     = TextEditingController(text: item?['nik']            ?? '');
    final ttlCtrl     = TextEditingController(text: item?['tempat_lahir']   ?? '');
    final tglCtrl     = TextEditingController(text: item?['tanggal_lahir']  ?? '');
    final jurusanCtrl = TextEditingController(text: item?['jurusan']        ?? '');
    final telpCtrl    = TextEditingController(text: item?['no_telp']        ?? '');
    final emailCtrl   = TextEditingController(text: item?['email_guru']     ?? '');
    final alamatCtrl  = TextEditingController(text: item?['alamat']         ?? '');
    final tahunCtrl   = TextEditingController(text: item?['tahun_mulai']?.toString() ?? '');
    final jabatanCtrl = TextEditingController(text: item?['jabatan']        ?? '');

    // Dropdown state
    String selectedJK       = item?['jenis_kelamin']  ?? '';
    String selectedAgama    = item?['agama']           ?? '';
    String selectedNikah    = item?['status_nikah']    ?? '';
    String selectedKepeg    = item?['status_kepeg']    ?? '';
    String selectedPendidik = item?['pendidikan']      ?? '';
    int?   selectedKelasId  = item?['id_kelas'] != null ? int.tryParse(item!['id_kelas'].toString()) : null;

    int  currentStep = 0;
    bool isSaving    = false;

    const stepTitles = ['Identitas Diri', 'Data Kepegawaian', 'Pendidikan', 'Kontak & Tugas'];
    const stepIcons  = [Icons.person_rounded, Icons.badge_rounded, Icons.school_rounded, Icons.contact_phone_rounded];
    const stepColors = [_navy, _primary, _purple, _teal];

    const agamaList   = ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'];
    const nikahList   = ['Belum Menikah', 'Menikah', 'Cerai'];
    const kepegList   = ['PNS', 'PPPK', 'Honorer', 'GTT', 'PTT'];
    const pendList    = ['SMA/SMK', 'D3', 'S1', 'S2', 'S3'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {

          // ── Step 0: Identitas Diri ───────────────────────────────────────
          Widget buildStep0() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _fLabel('Nama Lengkap *'),
            _fField(nameCtrl, Icons.badge_rounded, 'Contoh: Ibu Siti Aminah, S.Pd'),
            const SizedBox(height: 14),
            _fRow([
              _fCol('NIP', _fField(nipCtrl, Icons.fingerprint_rounded, 'Nomor Induk Pegawai', keyboard: TextInputType.number)),
              _fCol('NIK', _fField(nikCtrl, Icons.credit_card_rounded, '16 digit NIK', keyboard: TextInputType.number)),
            ]),
            const SizedBox(height: 14),
            _fLabel('Jenis Kelamin *'),
            _fDropStr(value: selectedJK, items: const ['L', 'P'],
              displayItems: const ['Laki-laki', 'Perempuan'], hint: 'Pilih jenis kelamin',
              icon: Icons.wc_rounded, onChanged: (v) => setSheet(() => selectedJK = v ?? '')),
            const SizedBox(height: 14),
            _fLabel('Tempat Lahir'),
            _fField(ttlCtrl, Icons.location_city_rounded, 'Contoh: Bengkalis'),
            const SizedBox(height: 14),
            _fLabel('Tanggal Lahir'),
            _datePicker(ctx: ctx, ctrl: tglCtrl, setSheet: setSheet),
            const SizedBox(height: 14),
            _fRow([
              _fCol('Agama', _fDropStr(value: selectedAgama, items: agamaList, hint: 'Pilih agama',
                icon: Icons.mosque_rounded, onChanged: (v) => setSheet(() => selectedAgama = v ?? ''))),
              _fCol('Status Pernikahan', _fDropStr(value: selectedNikah, items: nikahList, hint: 'Pilih status',
                icon: Icons.favorite_rounded, onChanged: (v) => setSheet(() => selectedNikah = v ?? ''))),
            ]),
          ]);

          // ── Step 1: Data Kepegawaian ────────────────────────────────────
          Widget buildStep1() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _fLabel('Status Kepegawaian'),
            _fDropStr(value: selectedKepeg, items: kepegList, hint: 'Pilih status kepegawaian',
              icon: Icons.work_rounded, onChanged: (v) => setSheet(() => selectedKepeg = v ?? '')),
            const SizedBox(height: 14),
            _fLabel('Jabatan'),
            _fField(jabatanCtrl, Icons.military_tech_rounded, 'Contoh: Guru Kelas / Guru Pendamping'),
            const SizedBox(height: 14),
            _fLabel('Tahun Mulai Mengajar'),
            _fField(tahunCtrl, Icons.calendar_today_rounded, 'Contoh: 2015', keyboard: TextInputType.number),
            const SizedBox(height: 14),
            // Info password default
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(Icons.lock_outline_rounded, color: _primary, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Password login guru otomatis diset ke NIP. Jika NIP kosong, password default: guru123',
                  style: TextStyle(fontSize: 11, color: _primary.withOpacity(0.85), height: 1.4),
                )),
              ]),
            ),
          ]);

          // ── Step 2: Pendidikan ──────────────────────────────────────────
          Widget buildStep2() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _fLabel('Pendidikan Terakhir'),
            _fDropStr(value: selectedPendidik, items: pendList, hint: 'Pilih jenjang pendidikan',
              icon: Icons.school_rounded, onChanged: (v) => setSheet(() => selectedPendidik = v ?? '')),
            const SizedBox(height: 14),
            _fLabel('Jurusan / Program Studi'),
            _fField(jurusanCtrl, Icons.menu_book_rounded, 'Contoh: PGPAUD / Pendidikan Anak Usia Dini'),
            const SizedBox(height: 16),
            // Info chip pendidikan
            if (selectedPendidik.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _purple.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: _purple, size: 15),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Guru dengan pendidikan $selectedPendidik${jurusanCtrl.text.isNotEmpty ? " jurusan ${jurusanCtrl.text}" : ""}',
                    style: TextStyle(fontSize: 12, color: _purple.withOpacity(0.85)),
                  )),
                ]),
              ),
          ]);

          // ── Step 3: Kontak & Tugas ──────────────────────────────────────
          Widget buildStep3() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _fLabel('No. HP / WA'),
            _fField(telpCtrl, Icons.phone_rounded, '08xxxxxxxxxx', keyboard: TextInputType.phone),
            const SizedBox(height: 14),
            _fLabel('Email'),
            _fField(emailCtrl, Icons.email_rounded, 'email@contoh.com', keyboard: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _fLabel('Alamat Lengkap'),
            _fArea(ctrl: alamatCtrl, hint: 'Jalan, RT/RW, Kelurahan, Kecamatan...'),
            const SizedBox(height: 14),
            _fLabel('Kelas Diampu'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: selectedKelasId,
                  isExpanded: true,
                  hint: Row(children: [
                    Icon(Icons.class_rounded, color: _primary, size: 18),
                    const SizedBox(width: 10),
                    const Flexible(child: Text('-- Belum Ditugaskan --', overflow: TextOverflow.ellipsis)),
                  ]),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
                  items: [
                    DropdownMenuItem<int?>(value: null, child: Text('-- Belum Ditugaskan --', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
                    ..._kelasList.map((k) {
                      final id = int.tryParse(k['id'].toString());
                      return DropdownMenuItem<int?>(
                        value: id,
                        child: Row(children: [
                          Icon(Icons.class_rounded, color: _primary, size: 14),
                          const SizedBox(width: 8),
                          Flexible(child: Text(
                            '${k['nama_kelas']}${k['tahun'] != null ? ' (${k['tahun']})' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ]),
                      );
                    }),
                  ],
                  onChanged: (v) => setSheet(() => selectedKelasId = v),
                ),
              ),
            ),
          ]);

          // ── Validasi per step ───────────────────────────────────────────
          String? _validate() {
            switch (currentStep) {
              case 0:
                if (nameCtrl.text.trim().isEmpty) return 'Nama lengkap wajib diisi';
                if (selectedJK.isEmpty) return 'Jenis kelamin wajib dipilih';
                break;
            }
            return null;
          }

          final mq = MediaQuery.of(ctx);

          return Container(
            height: mq.size.height * 0.93,
            decoration: const BoxDecoration(
              color: Color(0xFFFDF8F3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(children: [

              // Header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(children: [
                  Center(child: Container(width: 44, height: 4, margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: _primary.withOpacity(0.25), borderRadius: BorderRadius.circular(4)))),
                  // Header gradient
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [stepColors[currentStep], stepColors[currentStep].withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: stepColors[currentStep].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: Icon(stepIcons[currentStep], color: Colors.white, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(isEditing ? 'Edit Data Guru' : 'Tambah Guru Baru',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Langkah ${currentStep + 1} dari ${stepTitles.length} — ${stepTitles[currentStep]}',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                      ])),
                      GestureDetector(onTap: () => Navigator.pop(ctx),
                        child: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  Row(children: List.generate(stepTitles.length, (i) {
                    final isDone = i < currentStep; final isAct = i == currentStep;
                    return Expanded(child: Row(children: [
                      Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 250), height: 4,
                        decoration: BoxDecoration(color: isDone || isAct ? stepColors[i] : Colors.grey.shade200, borderRadius: BorderRadius.circular(4)))),
                      if (i < stepTitles.length - 1) const SizedBox(width: 4),
                    ]));
                  })),
                  const SizedBox(height: 6),
                  // Step labels
                  Row(children: List.generate(stepTitles.length, (i) {
                    final isDone = i < currentStep; final isAct = i == currentStep;
                    return Expanded(child: Center(child: Text(
                      stepTitles[i], overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, fontWeight: isAct ? FontWeight.bold : FontWeight.normal,
                        color: isDone || isAct ? stepColors[i] : Colors.grey.shade400),
                    )));
                  })),
                  const SizedBox(height: 12),
                ]),
              ),

              // Content
              Expanded(child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 14, 16, mq.viewInsets.bottom + 16),
                child: _formCard(children: [
                  if (currentStep == 0) buildStep0(),
                  if (currentStep == 1) buildStep1(),
                  if (currentStep == 2) buildStep2(),
                  if (currentStep == 3) buildStep3(),
                ]),
              )),

              // Bottom nav
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 12),
                decoration: BoxDecoration(color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))]),
                child: Row(children: [
                  Expanded(child: currentStep > 0
                    ? OutlinedButton.icon(
                        onPressed: () => setSheet(() => currentStep--),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: _primary.withOpacity(0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 13)),
                        icon: Icon(Icons.arrow_back_rounded, size: 17, color: _primary),
                        label: Text('Kembali', style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
                      )
                    : OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: _primary.withOpacity(0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 13)),
                        child: Text('Batal', style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
                      )),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentStep == stepTitles.length - 1 ? _green : stepColors[currentStep],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0,
                    ),
                    onPressed: isSaving ? null : () async {
                      final err = _validate();
                      if (err != null) { _snackErr(err); return; }

                      if (currentStep < stepTitles.length - 1) { setSheet(() => currentStep++); return; }

                      setSheet(() => isSaving = true);

                      final data = <String, dynamic>{
                        'action'         : isEditing ? 'update' : 'add',
                        'name'           : nameCtrl.text.trim(),
                        'nip'            : nipCtrl.text.trim(),
                        'nik'            : nikCtrl.text.trim(),
                        'jenis_kelamin'  : selectedJK,
                        'tempat_lahir'   : ttlCtrl.text.trim(),
                        'tanggal_lahir'  : tglCtrl.text,
                        'agama'          : selectedAgama,
                        'status_nikah'   : selectedNikah,
                        'status_kepeg'   : selectedKepeg,
                        'jabatan'        : jabatanCtrl.text.trim(),
                        'pendidikan'     : selectedPendidik,
                        'jurusan'        : jurusanCtrl.text.trim(),
                        'tahun_mulai'    : tahunCtrl.text.trim(),
                        'no_telp'        : telpCtrl.text.trim(),
                        'email_guru'     : emailCtrl.text.trim(),
                        'alamat'         : alamatCtrl.text.trim(),
                        'id_kelas'       : selectedKelasId,
                      };
                      if (isEditing) data['id'] = item!['id'];

                      if (!_isConnected) {
                        if (isEditing) {
                          final idx = _allGuru.indexWhere((e) => e['id'] == item!['id']);
                          if (idx != -1) _allGuru[idx] = {..._allGuru[idx], ...data};
                        } else { data['id'] = _mockIdCounter++; _allGuru.add(data); }
                        _applyFilter();
                        if (mounted) Navigator.pop(ctx);
                        return;
                      }

                      final res = await ApiService.postData('manage_guru.php', data);
                      setSheet(() => isSaving = false);

                      if (res['status'] == 'success') {
                        if (mounted) {
                          Navigator.pop(ctx);
                          _fetchData();
                          _snackOk(res['message'] ?? (isEditing ? 'Data guru diperbarui' : 'Guru berhasil ditambahkan'));
                        }
                      } else { _snackErr(res['message'] ?? 'Terjadi kesalahan'); }
                    },
                    child: isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(currentStep < stepTitles.length - 1 ? Icons.arrow_forward_rounded : Icons.save_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(currentStep < stepTitles.length - 1 ? 'Lanjut' : (isEditing ? 'Perbarui' : 'Simpan Guru'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ]),
                  )),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DETAIL SHEET
  // ════════════════════════════════════════════════════════════════════════════

  void _showDetailSheet(Map<String, dynamic> item) {
    final name   = item['name'] ?? 'Tanpa Nama';
    final isMale = item['jenis_kelamin'] == 'L';
    final gColor = isMale ? _blueM : _pinkF;

    // Hitung masa mengajar
    String masaMengajar = '-';
    if (item['tahun_mulai'] != null && item['tahun_mulai'].toString().isNotEmpty) {
      final tahun = int.tryParse(item['tahun_mulai'].toString());
      if (tahun != null) {
        final lama = DateTime.now().year - tahun;
        masaMengajar = '$lama tahun (sejak $tahun)';
      }
    }

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.80, maxChildSize: 0.95,
        builder: (ctx2, scroll) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: _primary.withOpacity(0.25), borderRadius: BorderRadius.circular(4)))),

              // Header card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_navy, _navyLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Container(width: 56, height: 56,
                    decoration: BoxDecoration(color: gColor.withOpacity(0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                    child: Icon(isMale ? Icons.male_rounded : Icons.female_rounded, color: Colors.white, size: 28)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if ((item['jabatan'] ?? '').toString().isNotEmpty)
                        _badge(item['jabatan'].toString(), Colors.white.withOpacity(0.2), Colors.white),
                      if ((item['status_kepeg'] ?? '').toString().isNotEmpty)
                        _badge(item['status_kepeg'].toString(), gColor.withOpacity(0.35), Colors.white),
                    ]),
                  ])),
                ]),
              ),
              const SizedBox(height: 18),

              // Identitas
              _sectionTitle('Identitas Diri'),
              const SizedBox(height: 10),
              _detailCard(children: [
                _dRow(Icons.fingerprint_rounded,  'NIP',              item['nip']          ?? '-'),
                _dRow(Icons.credit_card_rounded,  'NIK',              item['nik']          ?? '-'),
                _dRow(isMale ? Icons.male_rounded : Icons.female_rounded, 'Jenis Kelamin', isMale ? 'Laki-laki' : 'Perempuan'),
                _dRow(Icons.cake_rounded,         'Tempat, Tgl Lahir',
                    '${item['tempat_lahir'] ?? '-'}, ${item['tanggal_lahir'] ?? '-'}'),
                _dRow(Icons.mosque_rounded,       'Agama',            item['agama']        ?? '-'),
                _dRow(Icons.favorite_rounded,     'Status Nikah',     item['status_nikah'] ?? '-', isLast: true),
              ]),
              const SizedBox(height: 16),

              // Kepegawaian
              _sectionTitle('Data Kepegawaian'),
              const SizedBox(height: 10),
              _detailCard(children: [
                _dRow(Icons.work_rounded,          'Status Kepegawaian', item['status_kepeg']  ?? '-'),
                _dRow(Icons.military_tech_rounded, 'Jabatan',            item['jabatan']        ?? '-'),
                _dRow(Icons.school_rounded,        'Pendidikan',         '${item['pendidikan'] ?? '-'}${(item['jurusan'] ?? '').toString().isNotEmpty ? " — ${item['jurusan']}" : ""}'),
                _dRow(Icons.timer_rounded,         'Masa Mengajar',      masaMengajar),
                _dRow(Icons.class_rounded,         'Kelas Diampu',
                    (item['nama_kelas'] ?? '').toString().isNotEmpty ? item['nama_kelas'].toString() : 'Belum ditugaskan', isLast: true),
              ]),
              const SizedBox(height: 16),

              // Kontak
              _sectionTitle('Kontak'),
              const SizedBox(height: 10),
              _detailCard(children: [
                _dRow(Icons.phone_rounded,       'No. HP',   item['no_telp']   ?? '-'),
                _dRow(Icons.email_rounded,       'Email',    item['email_guru'] ?? '-'),
                _dRow(Icons.location_on_rounded, 'Alamat',   item['alamat']    ?? '-', isLast: true),
              ]),

              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Tutup', style: TextStyle(color: Color(0xFF64748B))))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _showFormSheet(item: item); },
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                  icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                  label: const Text('Edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DELETE
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _confirmDelete(Map<String, dynamic> guru) async {
    final confirmed = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: const BoxDecoration(color: Color(0xFFFEF2F2), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(children: [
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _red.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(Icons.delete_outline_rounded, color: _red, size: 32)),
              const SizedBox(height: 12),
              const Text('Hapus Data Guru?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B))),
            ])),
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), child: Column(children: [
            Container(width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFDF8F3), borderRadius: BorderRadius.circular(12), border: Border.all(color: _cardBorder)),
              child: Row(children: [
                Icon(Icons.school_rounded, color: _primary, size: 18), const SizedBox(width: 10),
                Expanded(child: Text(guru['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              ])),
            const SizedBox(height: 12),
            Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0),
                icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 16),
                label: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ]),
          ])),
        ]),
      ),
    );

    if (confirmed != true || !mounted) return;

    if (!_isConnected) {
      setState(() { _allGuru.removeWhere((e) => e['id'] == guru['id']); _runFilter(); });
      _snackOk('Data guru dihapus'); return;
    }

    final res = await ApiService.postData('manage_guru.php', {'action': 'delete', 'id': guru['id']});
    if (res['status'] == 'success') { _fetchData(); _snackOk(res['message'] ?? 'Data berhasil dihapus'); }
    else _snackErr(res['message'] ?? 'Gagal menghapus data');
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CARD GURU
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildGuruCard(Map<String, dynamic> guru) {
    final name   = guru['name'] ?? 'Tanpa Nama';
    final isMale = guru['jenis_kelamin'] == 'L';
    final gColor = isMale ? _blueM : _pinkF;
    final gBg    = isMale ? const Color(0xFFE3F2FD) : const Color(0xFFFCE4EC);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Material(color: Colors.transparent, child: InkWell(
        onTap: () => _showDetailSheet(guru), borderRadius: BorderRadius.circular(20),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(color: gBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: gColor.withOpacity(0.2), width: 1.5)),
              child: Icon(isMale ? Icons.male_rounded : Icons.female_rounded, color: gColor, size: 26)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('NIP: ${guru['nip'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                // Badge gender
                _smallBadge(isMale ? 'Laki-laki' : 'Perempuan', gColor),
                // Badge jabatan
                if ((guru['jabatan'] ?? '').toString().isNotEmpty)
                  _smallBadge(guru['jabatan'].toString(), _primary),
                // Badge status kepegawaian
                if ((guru['status_kepeg'] ?? '').toString().isNotEmpty)
                  _smallBadge(guru['status_kepeg'].toString(), _navy),
                // Badge kelas
                if ((guru['nama_kelas'] ?? '').toString().isNotEmpty)
                  _smallBadge(guru['nama_kelas'].toString(), _teal),
              ]),
            ])),
            // Menu titik tiga
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4,
              itemBuilder: (_) => [
                _popItem('detail', Icons.visibility_rounded,      'Lihat Detail', _navy.withOpacity(0.08), _navy),
                _popItem('edit',   Icons.edit_rounded,            'Edit Data',    Colors.blue.shade50,     Colors.blue.shade600),
                const PopupMenuDivider(),
                _popItem('delete', Icons.delete_outline_rounded,  'Hapus',        Colors.red.shade50,      Colors.red.shade600, isRed: true),
              ],
              onSelected: (val) {
                if (val == 'detail') _showDetailSheet(guru);
                if (val == 'edit')   _showFormSheet(item: guru);
                if (val == 'delete') _confirmDelete(guru);
              },
            ),
          ]),

          // Info kontak bawah
          if ((guru['no_telp'] ?? '').toString().isNotEmpty || (guru['pendidikan'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 8),
            Row(children: [
              if ((guru['no_telp'] ?? '').toString().isNotEmpty) ...[
                Icon(Icons.phone_rounded, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(guru['no_telp'] ?? '-', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(width: 16),
              ],
              if ((guru['pendidikan'] ?? '').toString().isNotEmpty) ...[
                Icon(Icons.school_rounded, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('${guru['pendidikan']}${(guru['jurusan'] ?? '').toString().isNotEmpty ? " — ${guru['jurusan']}" : ""}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
              ],
            ]),
          ],
        ])),
      )),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final sw     = MediaQuery.of(context).size.width;
    final totalL = _allGuru.where((g) => g['jenis_kelamin'] == 'L').length;
    final totalP = _allGuru.where((g) => g['jenis_kelamin'] == 'P').length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('Data Guru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchData)],
      ),
      body: Column(children: [
        // Header gradient
        AnimatedBuilder(animation: _headerAnim, builder: (_, __) => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_primary, _primaryDark, const Color(0xFF8B5E1A)], stops: const [0.0, 0.5, 1.0]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          child: Stack(children: [
            Positioned(right: -20, bottom: -20, child: Opacity(opacity: 0.07 + _headerAnim.value * 0.05,
              child: Icon(Icons.school_rounded, size: sw * 0.46, color: Colors.white))),
            Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Data Guru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 3),
              Text('Kelola data guru dan tenaga pendidik', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _statChip(icon: Icons.school_rounded,  label: 'Total',      value: '${_allGuru.length}')),
                const SizedBox(width: 8),
                Expanded(child: _statChip(icon: Icons.male_rounded,    label: 'Laki-laki',  value: '$totalL', accent: const Color(0xFFADD8E6))),
                const SizedBox(width: 8),
                Expanded(child: _statChip(icon: Icons.female_rounded,  label: 'Perempuan',  value: '$totalP', accent: const Color(0xFFFFB6C1))),
              ]),
            ])),
          ]),
        )),

        // Search
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
          child: TextField(controller: _searchController, decoration: InputDecoration(
            hintText: 'Cari nama, NIP, jabatan...', hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: _primary, size: 22),
            suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: Icon(Icons.close_rounded, color: Colors.grey.shade400), onPressed: _searchController.clear) : null,
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14),
          )),
        )),

        // Counter
        if (!_isLoading) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 2), child: Align(alignment: Alignment.centerLeft,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('${_filteredGuru.length} Guru', style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 12))))),

        // List
        Expanded(child: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(onRefresh: _fetchData, color: _primary,
              child: _filteredGuru.isEmpty
                ? ListView(children: [SizedBox(height: 280, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.school_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(_searchQuery.isEmpty ? 'Belum ada data guru' : 'Guru tidak ditemukan',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500)),
                    if (_searchQuery.isEmpty) ...[const SizedBox(height: 8), Text('Tekan + untuk menambahkan', style: TextStyle(color: Colors.grey.shade400, fontSize: 12))],
                  ])))])
                : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 10, 16, 100), itemCount: _filteredGuru.length,
                    itemBuilder: (_, i) => _buildGuruCard(Map<String, dynamic>.from(_filteredGuru[i]))))),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormSheet(), backgroundColor: _primary, elevation: 4,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Tambah Guru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // WIDGET HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _statChip({required IconData icon, required String label, required String value, Color? accent}) =>
    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.25))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: accent ?? const Color(0xFFFFE0A3), size: 13)),
        const SizedBox(width: 7),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 9)),
        ])),
      ]));

  Widget _smallBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)));

  Widget _badge(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10)));

  PopupMenuItem<String> _popItem(String val, IconData icon, String label, Color bg, Color fg, {bool isRed = false}) =>
    PopupMenuItem(value: val, child: Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: fg, size: 15)),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isRed ? Colors.red.shade600 : null)),
    ]));

  Widget _formCard({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _cardBorder),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));

  Widget _fLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))));

  Widget _fField(TextEditingController c, IconData icon, String hint, {TextInputType keyboard = TextInputType.text}) =>
    Container(decoration: BoxDecoration(color: const Color(0xFFFDF8F3), borderRadius: BorderRadius.circular(14), border: Border.all(color: _cardBorder)),
      child: TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(
        border: InputBorder.none, hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: _primary, size: 19), contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16))));

  Widget _fArea({required TextEditingController ctrl, required String hint}) =>
    Container(decoration: BoxDecoration(color: const Color(0xFFFDF8F3), borderRadius: BorderRadius.circular(14), border: Border.all(color: _cardBorder)),
      child: TextField(controller: ctrl, maxLines: 3, decoration: InputDecoration(
        border: InputBorder.none, hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13), contentPadding: const EdgeInsets.all(14))));

  Widget _fDropStr({required String value, required List<String> items, List<String>? displayItems,
      required String hint, required IconData icon, required ValueChanged<String?> onChanged}) =>
    Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFFDF8F3), borderRadius: BorderRadius.circular(14), border: Border.all(color: _cardBorder)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: value.isEmpty ? null : value, isExpanded: true,
        hint: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primary, size: 20),
        items: items.asMap().entries.map((e) => DropdownMenuItem(value: e.value,
          child: Text(displayItems != null ? displayItems[e.key] : e.value, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged)));

  Widget _datePicker({required BuildContext ctx, required TextEditingController ctrl, required StateSetter setSheet}) =>
    GestureDetector(
      onTap: () async {
        DateTime first = DateTime(1950);
        DateTime last = DateTime(2005);
        DateTime initial = DateTime(1985);
        if (ctrl.text.isNotEmpty) {
          final parsed = DateTime.tryParse(ctrl.text);
          if (parsed != null) {
            if (parsed.isBefore(first)) {
              first = DateTime(parsed.year - 1);
            }
            if (parsed.isAfter(last)) {
              last = parsed;
            }
            initial = parsed;
          }
        }
        final picked = await showDatePicker(context: ctx,
          initialDate: initial, firstDate: first, lastDate: last,
          builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: _primary)), child: child!));
        if (picked != null) setSheet(() => ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFFDF8F3), borderRadius: BorderRadius.circular(14), border: Border.all(color: ctrl.text.isEmpty ? _cardBorder : _primary.withOpacity(0.4))),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, color: ctrl.text.isEmpty ? Colors.grey.shade400 : _primary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(ctrl.text.isEmpty ? 'Tgl lahir' : ctrl.text,
            style: TextStyle(fontSize: 13, color: ctrl.text.isEmpty ? Colors.grey.shade400 : const Color(0xFF1E293B)))),
        ])));

  Widget _fRow(List<Widget> cols) => Row(crossAxisAlignment: CrossAxisAlignment.start,
    children: cols.expand((c) sync* { yield c is Expanded ? c : Expanded(child: c); if (c != cols.last) yield const SizedBox(width: 10); }).toList());

  Widget _fCol(String label, Widget field) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_fLabel(label), field]);

  Widget _sectionTitle(String t) => Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade800));

  Widget _detailCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(children: children));

  Widget _dRow(IconData icon, String label, String value, {bool isLast = false}) => Column(children: [
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 17, color: _primary), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 1),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        ])),
      ])),
    if (!isLast) Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16),
  ]);
}
