import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/responsive.dart';

class ManageAnakScreen extends StatefulWidget {
  const ManageAnakScreen({super.key});
  @override
  State<ManageAnakScreen> createState() => _ManageAnakScreenState();
}

class _ManageAnakScreenState extends State<ManageAnakScreen> {
  final TextEditingController _searchController = TextEditingController();

  // ── Palet: Warm Sage & Cream ─────────────────────────────────────────────
  static const Color _sage      = Color(0xFF4D7C6F);   // sage hijau hangat
  static const Color _sageDk    = Color(0xFF3A5F54);
  static const Color _sageLt    = Color(0xFF6B9E90);
  static const Color _cream     = Color(0xFFFDF8F0);   // krem hangat
  static const Color _surface   = Colors.white;
  static const Color _border    = Color(0xFFE8E0D5);
  static const Color _textMain  = Color(0xFF2D3748);
  static const Color _textSub   = Color(0xFF718096);
  static const Color _amber     = Color(0xFFD97706);
  static const Color _rose      = Color(0xFFBE4B6A);
  static const Color _sky       = Color(0xFF2980B9);
  static const Color _violet    = Color(0xFF6B46C1);
  static const Color _boyColor  = Color(0xFF2980B9);
  static const Color _girlColor = Color(0xFFBE4B6A);
  static const Color _green     = Color(0xFF2F855A);
  static const Color _orange    = Color(0xFFDD6B20);

  List<dynamic> _allItems      = [];
  List<dynamic> _filteredItems = [];
  List<dynamic> _listKelas     = [];
  List<dynamic> _listTahun     = [];
  List<dynamic> _listOrtu      = [];

  bool _isLoading   = true;
  bool _isConnected = false;

  String  _searchQuery     = '';
  String? _selectedTahunId;
  String? _selectedKelasId;

  int _mockIdCounter = 1000;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _applyFilter();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final resTahun = await ApiService.fetchData('manage_tahun_ajaran.php', []);
      final resKelas = await ApiService.fetchData('manage_kelas.php', []);
      final resUsers = await ApiService.getUsers();
      final result   = await ApiService.fetchData('manage_anak.php', []);
      if (!mounted) return;
      setState(() {
        if (resTahun['status'] == 'success') _listTahun = List<dynamic>.from(resTahun['data']);
        if (resKelas['status'] == 'success') _listKelas = List<dynamic>.from(resKelas['data']);
        if (resUsers['status'] == 'success') {
          _listOrtu = (resUsers['data'] as List).where((u) => u['role'] == 'orang_tua').toList();
        }
        if (result['status'] == 'success') {
          _allItems    = List<dynamic>.from(result['data']);
          _isConnected = result['source'] == 'server';
        }
        _applyFilter();
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    _filteredItems = _allItems.where((item) {
      final nama = (item['nama_anak'] ?? '').toString().toLowerCase();
      final nisn = (item['nisn'] ?? '').toString().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || nama.contains(_searchQuery) || nisn.contains(_searchQuery);
      bool matchesTahun = true;
      if (_selectedTahunId != null) {
        final kd = _listKelas.cast<Map<String,dynamic>?>().firstWhere(
          (k) => k?['id'].toString() == item['id_kelas'].toString(), orElse: () => null);
        matchesTahun = kd != null ? kd['id_tahun_ajaran'].toString() == _selectedTahunId : false;
      }
      bool matchesKelas = true;
      if (_selectedKelasId != null) matchesKelas = item['id_kelas']?.toString() == _selectedKelasId;
      return matchesSearch && matchesTahun && matchesKelas;
    }).toList();
  }

  Map<String, List<dynamic>> _groupByTahun() {
    final Map<String, List<dynamic>> grouped = {};
    for (final item in _filteredItems) {
      final tahun = item['tahun_ajaran']?.toString() ?? 'Belum Ada Tahun';
      grouped.putIfAbsent(tahun, () => []).add(item);
    }
    return grouped;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FORM SHEET
  // ════════════════════════════════════════════════════════════════════════════
  void _showFormSheet({Map<String, dynamic>? item}) {
    final bool isEditing     = item != null;
    final namaCtrl           = TextEditingController(text: item?['nama_anak'] ?? '');
    final nisnCtrl           = TextEditingController(text: item?['nisn'] ?? '');
    final nikCtrl            = TextEditingController(text: item?['nik'] ?? '');
    final tempatLahirCtrl    = TextEditingController(text: item?['tempat_lahir'] ?? '');
    final tanggalCtrl        = TextEditingController(text: item?['tanggal_lahir'] ?? '');
    final beratCtrl          = TextEditingController(text: item?['berat_badan'] ?? '');
    final tinggiCtrl         = TextEditingController(text: item?['tinggi_badan'] ?? '');
    final anakKeCtrl         = TextEditingController(text: item?['anak_ke'] ?? '');
    final alamatCtrl         = TextEditingController(text: item?['alamat'] ?? '');
    final kelasCtrl          = TextEditingController(text: item?['id_kelas']?.toString() ?? '');
    final ortuCtrl           = TextEditingController(text: item?['id_ortu']?.toString() ?? '');

    String selectedGender    = item?['jenis_kelamin'] ?? '';
    String selectedAgama     = item?['agama'] ?? '';
    String selectedAnak      = item?['status_anak'] ?? '';

    const agamaList      = ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'];
    const statusAnakList = ['Kandung', 'Tiri', 'Angkat'];

    bool isSaving    = false;
    int  currentStep = 0;
    const totalSteps = 4;
    final stepTitles = ['Data Pribadi', 'Kelahiran & Fisik', 'Alamat', 'Data Sekolah'];
    final stepIcons  = [Icons.person_rounded, Icons.cake_rounded, Icons.home_rounded, Icons.school_rounded];
    final stepAccent = [_sage, _violet, _orange, _sky];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {

          // ── Step 0: Data Pribadi ─────────────────────────────────────
          Widget buildStep0() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _fLabel('Nama Lengkap', required: true),
            _fField(ctrl: namaCtrl, icon: Icons.badge_rounded, hint: 'Contoh: Muhammad Rizki Pratama', accent: _sage),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fLabel('NISN', required: true),
                _fFieldNum(ctrl: nisnCtrl, icon: Icons.fingerprint_rounded, hint: '10 digit', accent: _sage),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fLabel('NIK'),
                _fFieldNum(ctrl: nikCtrl, icon: Icons.credit_card_rounded, hint: '16 digit', accent: _sage),
              ])),
            ]),
            const SizedBox(height: 16),

            _fLabel('Jenis Kelamin', required: true),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _genderBtn(
                label: 'Laki-laki', value: 'L', selected: selectedGender == 'L',
                icon: Icons.boy_rounded, color: _boyColor,
                onTap: () => setSheet(() => selectedGender = 'L'))),
              const SizedBox(width: 10),
              Expanded(child: _genderBtn(
                label: 'Perempuan', value: 'P', selected: selectedGender == 'P',
                icon: Icons.girl_rounded, color: _girlColor,
                onTap: () => setSheet(() => selectedGender = 'P'))),
            ]),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fLabel('Agama'),
                _fDropStr(value: selectedAgama, items: agamaList, hint: 'Pilih agama',
                  icon: Icons.mosque_rounded, accent: _sage,
                  onChanged: (v) => setSheet(() => selectedAgama = v ?? '')),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fLabel('Status Anak'),
                _fDropStr(value: selectedAnak, items: statusAnakList, hint: 'Pilih status',
                  icon: Icons.family_restroom_rounded, accent: _sage,
                  onChanged: (v) => setSheet(() => selectedAnak = v ?? '')),
              ])),
            ]),
            const SizedBox(height: 16),

            _fLabel('Anak ke-'),
            _fFieldNum(ctrl: anakKeCtrl, icon: Icons.format_list_numbered_rounded, hint: 'Contoh: 1', accent: _sage),
          ]);

          // ── Step 1: Kelahiran & Fisik ────────────────────────────────
          Widget buildStep1() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _fLabel('Tempat Lahir'),
            _fField(ctrl: tempatLahirCtrl, icon: Icons.location_city_rounded, hint: 'Contoh: Bengkalis', accent: _violet),
            const SizedBox(height: 16),

            _fLabel('Tanggal Lahir', required: true),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: DateTime(2018),
                  firstDate: DateTime(2010), lastDate: DateTime.now(),
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: _violet)),
                    child: child!));
                if (picked != null) {
                  final f = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
                  setSheet(() => tanggalCtrl.text = f);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: _cream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tanggalCtrl.text.isEmpty ? _border : _violet.withOpacity(0.5), width: 1.5)),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded,
                    color: tanggalCtrl.text.isEmpty ? Colors.grey.shade400 : _violet, size: 19),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    tanggalCtrl.text.isEmpty ? 'Pilih tanggal lahir' : tanggalCtrl.text,
                    style: TextStyle(fontSize: 14,
                      color: tanggalCtrl.text.isEmpty ? Colors.grey.shade400 : _textMain,
                      fontWeight: tanggalCtrl.text.isEmpty ? FontWeight.normal : FontWeight.w600))),
                  if (tanggalCtrl.text.isNotEmpty)
                    Icon(Icons.check_circle_rounded, color: _violet, size: 18),
                ])),
            ),

            if (tanggalCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              Builder(builder: (_) {
                try {
                  final p = tanggalCtrl.text.split('-');
                  final dob = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
                  final now = DateTime.now();
                  final yrs = now.year - dob.year - ((now.month < dob.month || (now.month == dob.month && now.day < dob.day)) ? 1 : 0);
                  final mos = ((now.month - dob.month) % 12).abs();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _violet.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _violet.withOpacity(0.2))),
                    child: Row(children: [
                      Icon(Icons.cake_rounded, color: _violet, size: 16), const SizedBox(width: 8),
                      Text('Usia: $yrs tahun $mos bulan',
                        style: TextStyle(fontSize: 13, color: _violet, fontWeight: FontWeight.w600)),
                    ]));
                } catch (_) { return const SizedBox.shrink(); }
              }),
            ],
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fLabel('Berat Badan (kg)'),
                _fFieldNum(ctrl: beratCtrl, icon: Icons.monitor_weight_outlined, hint: 'Contoh: 18', accent: _violet),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fLabel('Tinggi Badan (cm)'),
                _fFieldNum(ctrl: tinggiCtrl, icon: Icons.height_rounded, hint: 'Contoh: 110', accent: _violet),
              ])),
            ]),
          ]);

          // ── Step 2: Alamat ────────────────────────────────────────────
          Widget buildStep2() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _fLabel('Alamat Lengkap'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: _cream, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border, width: 1.5)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Aksen kiri berwarna
                Container(width: 4, height: 110,
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.6),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)))),
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: TextField(
                    controller: alamatCtrl, maxLines: 4,
                    style: TextStyle(fontSize: 13, color: _textMain),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Masukkan alamat lengkap anak\n(jalan, RT/RW, kelurahan, kecamatan)',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5),
                      contentPadding: const EdgeInsets.fromLTRB(4, 14, 14, 14))))),
              ])),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.info_outline_rounded, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 5),
              Text('Isi sesuai KK atau dokumen resmi',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ]),
          ]);

          // ── Step 3: Data Sekolah ──────────────────────────────────────
          Widget buildStep3() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _fLabel('Kelas', required: true),
            const SizedBox(height: 6),
            _fDropDynamic(ctrl: kelasCtrl, items: _listKelas, labelKey: 'nama_kelas',
              hint: 'Pilih kelas', icon: Icons.meeting_room_rounded, accent: _sky, setSheet: setSheet),
            if (kelasCtrl.text.isNotEmpty && tanggalCtrl.text.isNotEmpty) ...[
              Builder(builder: (_) {
                final selectedClass = _listKelas.firstWhere(
                  (k) => k['id'].toString() == kelasCtrl.text, orElse: () => null);
                if (selectedClass == null) return const SizedBox.shrink();
                final className = (selectedClass['nama_kelas'] ?? '').toString();
                
                // Calculate age
                double ageYears = 0.0;
                int yrs = 0;
                int mos = 0;
                try {
                  final p = tanggalCtrl.text.split('-');
                  final dob = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
                  final now = DateTime.now();
                  yrs = now.year - dob.year - ((now.month < dob.month || (now.month == dob.month && now.day < dob.day)) ? 1 : 0);
                  mos = ((now.month - dob.month) % 12).abs();
                  ageYears = yrs + (mos / 12.0);
                } catch (_) {
                  return const SizedBox.shrink();
                }

                bool isWarning = false;
                String expectedRange = '';
                String actualAgeStr = '$yrs tahun $mos bulan';

                if (className.startsWith('Kelompok A')) {
                  expectedRange = '4 - 5 tahun';
                  if (ageYears < 4.0 || ageYears >= 5.0) {
                    isWarning = true;
                  }
                } else if (className.startsWith('Kelompok B')) {
                  expectedRange = '5 - 6 tahun';
                  if (ageYears < 5.0 || ageYears >= 6.0) {
                    isWarning = true;
                  }
                }

                if (!isWarning) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      'Peringatan: Usia anak ($actualAgeStr) tidak sesuai dengan kriteria $className ($expectedRange).',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                    )),
                  ]),
                );
              }),
            ],
            const SizedBox(height: 16),

            _fLabel('Orang Tua / Wali'),
            const SizedBox(height: 6),
            // Info banner
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: _sky.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _sky.withOpacity(0.2))),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, color: _sky, size: 15),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Pastikan orang tua sudah terdaftar sebagai pengguna',
                  style: TextStyle(fontSize: 12, color: _sky.withOpacity(0.9)))),
              ])),
            _fDropDynamic(ctrl: ortuCtrl, items: _listOrtu, labelKey: 'name',
              hint: 'Pilih orang tua / wali', icon: Icons.family_restroom_rounded, accent: _sky, setSheet: setSheet),

            if (ortuCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Builder(builder: (_) {
                final ortu = _listOrtu.firstWhere(
                  (o) => o['id'].toString() == ortuCtrl.text, orElse: () => null);
                if (ortu == null) return const SizedBox.shrink();
                final nama = ortu['name']?.toString() ?? '-';
                final initials = nama.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _green.withOpacity(0.2))),
                  child: Row(children: [
                    CircleAvatar(radius: 20, backgroundColor: _green.withOpacity(0.12),
                      child: Text(initials, style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _green.withOpacity(0.9))),
                      Text('Orang tua / wali terpilih', style: TextStyle(fontSize: 11, color: _green.withOpacity(0.7))),
                    ])),
                    Icon(Icons.check_circle_rounded, color: _green, size: 20),
                  ]));
              }),
            ],
          ]);

          // ── Validasi ─────────────────────────────────────────────────
          String? validateStep() {
            switch (currentStep) {
              case 0:
                if (namaCtrl.text.trim().isEmpty) return 'Nama lengkap wajib diisi';
                if (nisnCtrl.text.trim().isEmpty) return 'NISN wajib diisi';
                if (selectedGender.isEmpty)       return 'Jenis kelamin wajib dipilih';
                break;
              case 1:
                if (tanggalCtrl.text.isEmpty) return 'Tanggal lahir wajib diisi';
                break;
              case 3:
                if (kelasCtrl.text.isEmpty) return 'Kelas wajib dipilih';
                break;
            }
            return null;
          }

          final accent = stepAccent[currentStep];

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.93,
            decoration: const BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(children: [

              // ── Fixed header ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))]),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(children: [
                  // Handle
                  Center(child: Container(width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: accent.withOpacity(0.25), borderRadius: BorderRadius.circular(4)))),

                  // Title gradient card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.7)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 5))]),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                        child: Icon(stepIcons[currentStep], color: Colors.white, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(isEditing ? 'Edit Data Anak' : 'Tambah Data Anak',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('Langkah ${currentStep + 1} dari $totalSteps — ${stepTitles[currentStep]}',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                      ])),
                      GestureDetector(onTap: () => Navigator.pop(ctx),
                        child: Container(padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16))),
                    ])),

                  const SizedBox(height: 14),

                  // Progress bar
                  Row(children: List.generate(totalSteps, (i) {
                    final done = i < currentStep; final act = i == currentStep;
                    return Expanded(child: Row(children: [
                      Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 280), height: 4,
                        decoration: BoxDecoration(
                          color: done ? stepAccent[i] : act ? stepAccent[i] : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4)))),
                      if (i < totalSteps - 1) const SizedBox(width: 4),
                    ]));
                  })),
                  const SizedBox(height: 8),

                  // Step labels
                  Row(children: List.generate(totalSteps, (i) {
                    final done = i < currentStep; final act = i == currentStep;
                    return Expanded(child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (done) Icon(Icons.check_circle_rounded, size: 10, color: stepAccent[i]),
                      if (done) const SizedBox(width: 2),
                      Flexible(child: Text(stepTitles[i], overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9,
                          fontWeight: act ? FontWeight.bold : FontWeight.normal,
                          color: done || act ? stepAccent[i] : Colors.grey.shade400))),
                    ])));
                  })),
                  const SizedBox(height: 14),
                ])),

              // ── Scrollable content ─────────────────────────────────
              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _surface, borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Section heading inside card
                    Padding(padding: const EdgeInsets.only(bottom: 16),
                      child: Row(children: [
                        Container(width: 3, height: 18, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 8),
                        Text(stepTitles[currentStep],
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: accent)),
                      ])),
                    if (currentStep == 0) buildStep0(),
                    if (currentStep == 1) buildStep1(),
                    if (currentStep == 2) buildStep2(),
                    if (currentStep == 3) buildStep3(),
                  ])))),

              // ── Fixed bottom nav ───────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(ctx).padding.bottom + 12),
                decoration: BoxDecoration(
                  color: _surface,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, -4))]),
                child: Row(children: [
                  Expanded(child: currentStep > 0
                    ? OutlinedButton.icon(
                        onPressed: () => setSheet(() => currentStep--),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accent.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                        icon: Icon(Icons.arrow_back_rounded, size: 17, color: accent),
                        label: Text('Kembali', style: TextStyle(color: accent, fontWeight: FontWeight.w600)))
                    : OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Batal', style: TextStyle(color: _textSub, fontWeight: FontWeight.w600)))),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                    onPressed: isSaving ? null : () async {
                      final err = validateStep();
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(err), backgroundColor: _rose, behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                        return;
                      }
                      if (currentStep < totalSteps - 1) { setSheet(() => currentStep++); return; }

                      setSheet(() => isSaving = true);
                      final data = {
                        'action': isEditing ? 'update' : 'add', 'id': item?['id'],
                        'nama_anak': namaCtrl.text.trim(), 'nisn': nisnCtrl.text.trim(),
                        'nik': nikCtrl.text.trim(), 'tempat_lahir': tempatLahirCtrl.text.trim(),
                        'jenis_kelamin': selectedGender, 'agama': selectedAgama,
                        'status_anak': selectedAnak, 'anak_ke': anakKeCtrl.text.trim(),
                        'tanggal_lahir': tanggalCtrl.text, 'berat_badan': beratCtrl.text.trim(),
                        'tinggi_badan': tinggiCtrl.text.trim(), 'alamat': alamatCtrl.text.trim(),
                        'id_kelas': kelasCtrl.text, 'id_ortu': ortuCtrl.text,
                      };
                      try {
                        if (!_isConnected) {
                          if (isEditing) {
                            final idx = _allItems.indexWhere((e) => e['id'] == item!['id']);
                            if (idx != -1) _allItems[idx] = {..._allItems[idx], ...data};
                          } else { data['id'] = _mockIdCounter++; _allItems.add(data); }
                          setState(() => _applyFilter());
                          if (mounted) Navigator.pop(ctx);
                          return;
                        }
                        final res = await ApiService.postData('manage_anak.php', data);
                        if (res['status'] == 'success') {
                          if (mounted) {
                            Navigator.pop(ctx); _fetchData();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Row(children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(isEditing ? 'Data berhasil diperbarui' : 'Data anak berhasil ditambahkan'),
                              ]),
                              backgroundColor: _green, behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res['message'] ?? 'Gagal menyimpan'),
                            backgroundColor: _rose, behavior: SnackBarBehavior.floating));
                        }
                      } catch (e) { debugPrint(e.toString()); }
                      finally { setSheet(() => isSaving = false); }
                    },
                    child: isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(currentStep < totalSteps - 1 ? Icons.arrow_forward_rounded : (isEditing ? Icons.save_rounded : Icons.check_rounded),
                            color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(currentStep < totalSteps - 1 ? 'Lanjut' : (isEditing ? 'Perbarui Data' : 'Simpan Data'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                        ]),
                  )),
                ]),
              ),
            ]));
        }));
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DETAIL SHEET
  // ════════════════════════════════════════════════════════════════════════════
  void _showDetailSheet(Map<String, dynamic> item) {
    final name      = item['nama_anak'] ?? 'Tanpa Nama';
    final initials  = name.toString().trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();
    final isLaki    = item['jenis_kelamin'] == 'L';
    final avatarColor = isLaki ? _boyColor : _girlColor;
    final hasParent = item['id_ortu'] != null && item['id_ortu'].toString().isNotEmpty;
    final ortuNama  = item['nama_ortu'] ?? '-';
    final ortuInit  = ortuNama.toString().trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.85, maxChildSize: 0.95,
        builder: (context, sc) => Container(
          decoration: const BoxDecoration(color: _cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SingleChildScrollView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: _sage.withOpacity(0.25), borderRadius: BorderRadius.circular(4)))),

              // ── Hero card ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [avatarColor, avatarColor.withOpacity(0.7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(22)),
                child: Row(children: [
                  CircleAvatar(radius: 32, backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 7),
                    Wrap(spacing: 7, children: [
                      _heroBadge(isLaki ? 'Laki-laki' : 'Perempuan', Icons.wc_rounded),
                      if (hasParent) _heroBadge('Ada Wali ✓', Icons.family_restroom_rounded),
                      _heroBadge(item['nama_kelas'] ?? '-', Icons.class_rounded),
                    ]),
                  ])),
                ])),
              const SizedBox(height: 20),

              _sheetSection('Data Pribadi', Icons.person_rounded, _sage),
              const SizedBox(height: 10),
              _detailCard(children: [
                _dRow(Icons.fingerprint_rounded,          'NISN',          item['nisn'] ?? '-'),
                _dRow(Icons.credit_card_rounded,          'NIK',           item['nik'] ?? '-'),
                _dRow(Icons.wc_rounded,                  'Jenis Kelamin', isLaki ? 'Laki-laki' : 'Perempuan'),
                _dRow(Icons.mosque_rounded,              'Agama',         item['agama'] ?? '-'),
                _dRow(Icons.family_restroom_rounded,     'Status Anak',   item['status_anak'] ?? '-'),
                _dRow(Icons.format_list_numbered_rounded,'Anak ke-',      item['anak_ke']?.toString() ?? '-', isLast: true),
              ]),
              const SizedBox(height: 16),

              _sheetSection('Kelahiran & Fisik', Icons.cake_rounded, _violet),
              const SizedBox(height: 10),
              _detailCard(children: [
                _dRow(Icons.location_city_rounded,    'Tempat Lahir',   item['tempat_lahir'] ?? '-'),
                _dRow(Icons.calendar_today_rounded,   'Tanggal Lahir',  item['tanggal_lahir'] ?? '-'),
                _dRow(Icons.monitor_weight_outlined,  'Berat Badan',    item['berat_badan'] != null ? '${item["berat_badan"]} kg' : '-'),
                _dRow(Icons.height_rounded,           'Tinggi Badan',   item['tinggi_badan'] != null ? '${item["tinggi_badan"]} cm' : '-', isLast: true),
              ]),
              const SizedBox(height: 16),

              _sheetSection('Sekolah & Alamat', Icons.school_rounded, _sky),
              const SizedBox(height: 10),
              _detailCard(children: [
                _dRow(Icons.meeting_room_rounded, 'Kelas',  item['nama_kelas'] ?? '-'),
                _dRow(Icons.location_on_rounded,  'Alamat', item['alamat'] ?? '-', isLast: true),
              ]),
              const SizedBox(height: 16),

              _sheetSection('Orang Tua / Wali', Icons.family_restroom_rounded, _orange),
              const SizedBox(height: 10),
              hasParent
                ? Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.06), borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _green.withOpacity(0.2))),
                    child: Row(children: [
                      CircleAvatar(radius: 24, backgroundColor: _green.withOpacity(0.12),
                        child: Text(ortuInit, style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 13))),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(ortuNama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _green.withOpacity(0.9))),
                        Text('Orang Tua / Wali Terdaftar', style: TextStyle(fontSize: 11, color: _green.withOpacity(0.7))),
                      ])),
                      Icon(Icons.verified_rounded, color: _green, size: 20),
                    ]))
                : Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _amber.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _amber.withOpacity(0.25))),
                    child: Row(children: [
                      Icon(Icons.warning_amber_rounded, color: _amber, size: 22), const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Belum Dihubungkan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _amber.withOpacity(0.9))),
                        Text('Orang tua belum terhubung dengan anak ini',
                          style: TextStyle(fontSize: 11, color: _amber.withOpacity(0.7))),
                      ])),
                    ])),
              const SizedBox(height: 24),

              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Tutup', style: TextStyle(color: _textSub)))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _showFormSheet(item: item); },
                  style: ElevatedButton.styleFrom(backgroundColor: _sage,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                  icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                  label: const Text('Edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _heroBadge(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 11), const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    ]));

  // ════════════════════════════════════════════════════════════════════════════
  // ANAK CARD
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildAnakCard(Map<String, dynamic> item) {
    final name      = item['nama_anak'] ?? 'Tanpa Nama';
    final initials  = name.toString().trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();
    final isLaki    = item['jenis_kelamin'] == 'L';
    final hasParent = item['id_ortu'] != null && item['id_ortu'].toString().isNotEmpty;
    final avatarBg  = isLaki ? _boyColor.withOpacity(0.1) : _girlColor.withOpacity(0.1);
    final avatarFg  = isLaki ? _boyColor : _girlColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: avatarFg, width: 4)),
        boxShadow: [
          BoxShadow(color: avatarFg.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3)),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailSheet(item),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Avatar
              Container(width: 50, height: 50,
                decoration: BoxDecoration(color: avatarBg, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: avatarFg.withOpacity(0.2))),
                child: Center(child: Text(initials,
                  style: TextStyle(color: avatarFg, fontWeight: FontWeight.bold, fontSize: 15)))),
              const SizedBox(width: 12),

              // Info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textMain),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(children: [
                  _miniChip(item['nisn'] ?? '-', _sage, Icons.fingerprint_rounded),
                  const SizedBox(width: 6),
                  _miniChip(item['nama_kelas'] ?? '-', _sky, Icons.class_rounded),
                ]),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(hasParent ? Icons.family_restroom_rounded : Icons.person_off_outlined,
                    size: 12, color: hasParent ? _green : _amber),
                  const SizedBox(width: 4),
                  Text(hasParent ? 'Ada wali terdaftar' : 'Belum ada wali',
                    style: TextStyle(fontSize: 11,
                      color: hasParent ? _green : _amber,
                      fontWeight: FontWeight.w500)),
                ]),
              ])),

              // Aksi
              Column(children: [
                _actionBtn(Icons.visibility_rounded, _sage, _sage.withOpacity(0.08),
                  () => _showDetailSheet(item)),
                const SizedBox(height: 6),
                _actionBtn(Icons.edit_rounded, _sky, _sky.withOpacity(0.08),
                  () => _showFormSheet(item: item)),
                const SizedBox(height: 6),
                _actionBtn(Icons.delete_outline_rounded, _rose, _rose.withOpacity(0.08),
                  () => _confirmDelete(item)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(7)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: color), const SizedBox(width: 3),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 10),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    ]));

  Widget _actionBtn(IconData icon, Color color, Color bg, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 16, color: color)));

  // ════════════════════════════════════════════════════════════════════════════
  // DELETE
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: const BoxDecoration(color: Color(0xFFFFF0F3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(children: [
              Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _rose.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(Icons.delete_outline_rounded, color: _rose, size: 32)),
              const SizedBox(height: 10),
              const Text('Hapus Data Anak?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _textMain)),
            ])),
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), child: Column(children: [
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border)),
              child: Row(children: [
                Icon(Icons.child_care_rounded, color: _sage, size: 18), const SizedBox(width: 10),
                Text(item['nama_anak'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ])),
            const SizedBox(height: 10),
            Text('Tindakan ini tidak dapat dibatalkan.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text('Batal', style: TextStyle(color: _textSub, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: _rose,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
                icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 16),
                label: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ]),
          ])),
        ]),
      ));
    if (confirm != true) return;
    if (!_isConnected) {
      setState(() { _allItems.removeWhere((e) => e['id'] == item['id']); _applyFilter(); });
      return;
    }
    final res = await ApiService.postData('manage_anak.php', {'action': 'delete', 'id': item['id']});
    if (res['status'] == 'success') {
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Data berhasil dihapus'), backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final grouped   = _groupByTahun();
    final tahunKeys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Data Anak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _sage, foregroundColor: Colors.white,
        centerTitle: true, elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchData),
        ],
      ),
      body: Column(children: [

        // ── Header gradient + search ──────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_sage, _sageDk, const Color(0xFF2E5048)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
          child: Column(children: [
            // Stat chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                _headerStat('${_filteredItems.length}', 'Total Anak', Icons.child_care_rounded),
                const SizedBox(width: 8),
                _headerStat('${_filteredItems.where((e) => e['jenis_kelamin'] == 'L').length}', 'Laki-laki', Icons.boy_rounded),
                const SizedBox(width: 8),
                _headerStat('${_filteredItems.where((e) => e['jenis_kelamin'] == 'P').length}', 'Perempuan', Icons.girl_rounded),
                const SizedBox(width: 8),
                _headerStat('${_filteredItems.where((e) => e['id_ortu'] != null && e['id_ortu'].toString().isNotEmpty).length}', 'Ada Wali', Icons.family_restroom_rounded),
              ])),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))]),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Cari nama atau NISN...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: _sage, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(onPressed: _searchController.clear,
                          icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18))
                      : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14)))),
            ),
          ])),

        // ── List ─────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _sage))
            : _filteredItems.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(color: _sage.withOpacity(0.07), shape: BoxShape.circle),
                    child: Icon(Icons.child_care_rounded, size: 52, color: _sage.withOpacity(0.35))),
                  const SizedBox(height: 16),
                  Text('Belum ada data anak',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(_searchQuery.isEmpty ? 'Tap + untuk menambah data anak' : 'Tidak ada hasil pencarian',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ]))
              : RefreshIndicator(color: _sage, onRefresh: _fetchData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: tahunKeys.length,
                    itemBuilder: (context, index) {
                      final tahun     = tahunKeys[index];
                      final anakList = grouped[tahun]!;
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Tahun ajaran header
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _sageDk, borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: _sage.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text('Tahun Ajaran $tahun',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                              child: Text('${anakList.length} anak',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                          ])),
                        ...anakList.map((e) => _buildAnakCard(Map<String, dynamic>.from(e))),
                        const SizedBox(height: 8),
                      ]);
                    })),
        ),
      ]),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _sage, elevation: 4,
        onPressed: () => _showFormSheet(),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Tambah Anak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // WIDGET HELPERS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _headerStat(String value, String label, IconData icon) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.22))),
    child: Column(children: [
      Icon(icon, color: Colors.white, size: 14), const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 8), textAlign: TextAlign.center),
    ])));

  Widget _sheetSection(String title, IconData icon, Color color) =>
    Row(children: [
      Container(padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 15)),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800)),
    ]);

  Widget _detailCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
    child: Column(children: children));

  Widget _dRow(IconData icon, String label, String value, {bool isLast = false}) =>
    Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: _sage), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: _textSub, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
          ])),
        ])),
      if (!isLast) Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
    ]);

  // ── Form field helpers ────────────────────────────────────────────────────
  Widget _fLabel(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: RichText(text: TextSpan(
      text: text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF4A5568)),
      children: required ? const [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFBE4B6A)))] : [])));

  Widget _fField({required TextEditingController ctrl, required IconData icon,
      required String hint, required Color accent}) =>
    Container(
      decoration: BoxDecoration(
        color: _cream, borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border, width: 1.5)),
      child: Row(children: [
        // Aksen kiri
        Container(width: 4, height: 48,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.5),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)))),
        const SizedBox(width: 10),
        Icon(icon, color: accent, size: 18), const SizedBox(width: 10),
        Expanded(child: TextField(controller: ctrl,
          style: TextStyle(fontSize: 13, color: _textMain),
          decoration: InputDecoration(
            border: InputBorder.none, hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(vertical: 14)))),
        const SizedBox(width: 12),
      ]));

  Widget _fFieldNum({required TextEditingController ctrl, required IconData icon,
      required String hint, required Color accent}) =>
    Container(
      decoration: BoxDecoration(
        color: _cream, borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border, width: 1.5)),
      child: Row(children: [
        Container(width: 4, height: 48,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.5),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)))),
        const SizedBox(width: 10),
        Icon(icon, color: accent, size: 18), const SizedBox(width: 10),
        Expanded(child: TextField(controller: ctrl, keyboardType: TextInputType.number,
          style: TextStyle(fontSize: 13, color: _textMain),
          decoration: InputDecoration(
            border: InputBorder.none, hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(vertical: 14)))),
        const SizedBox(width: 12),
      ]));

  Widget _fDropStr({required String value, required List<String> items, required String hint,
      required IconData icon, required Color accent, required ValueChanged<String?> onChanged}) =>
    Container(
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: _cream, borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border, width: 1.5)),
      child: Row(children: [
        Container(width: 4, height: 48,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.5),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)))),
        const SizedBox(width: 10),
        Icon(icon, color: accent, size: 18), const SizedBox(width: 8),
        Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value.isEmpty ? null : value, isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent, size: 20),
          items: items.map((a) => DropdownMenuItem(value: a,
            child: Text(a, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged))),
      ]));

  Widget _fDropDynamic({required TextEditingController ctrl, required List<dynamic> items,
      required String labelKey, required String hint, required IconData icon,
      required Color accent, required StateSetter setSheet}) =>
    Container(
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: _cream, borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border, width: 1.5)),
      child: Row(children: [
        Container(width: 4, height: 48,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.5),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)))),
        const SizedBox(width: 10),
        Icon(icon, color: accent, size: 18), const SizedBox(width: 8),
        Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: ctrl.text.isEmpty ? null : ctrl.text, isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent, size: 20),
          items: items.map((e) => DropdownMenuItem<String>(
            value: e['id'].toString(),
            child: Text(e[labelKey].toString(), style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setSheet(() => ctrl.text = v ?? '')))),
      ]));

  Widget _genderBtn({required String label, required String value, required bool selected,
      required IconData icon, required Color color, required VoidCallback onTap}) =>
    GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : _cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : _border, width: selected ? 2 : 1.5),
          boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))] : []),
        child: Column(children: [
          Icon(icon, color: selected ? color : Colors.grey.shade400, size: 26),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: selected ? color : _textSub,
            fontWeight: FontWeight.w600, fontSize: 12)),
        ])));
}
