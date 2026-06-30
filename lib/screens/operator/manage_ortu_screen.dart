import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageOrtuScreen extends StatefulWidget {
  const ManageOrtuScreen({super.key});

  @override
  State<ManageOrtuScreen> createState() => _ManageOrtuScreenState();
}

class _ManageOrtuScreenState extends State<ManageOrtuScreen> {
  final TextEditingController _searchController = TextEditingController();

  // ── Palette ────────────────────────────────────────────────────────────────
  // Ungu soft sebagai primary (mengikuti ikon orang tua di gambar referensi)
  static const Color _primary      = Color(0xFF7C5CBF); // ungu medium
  static const Color _primaryLight = Color(0xFFEDE8F8); // ungu sangat muda
  static const Color _primaryDark  = Color(0xFF5E3FA3); // ungu gelap (header)
  static const Color _bg           = Color(0xFFEFF6F5); // background mint sangat muda (sama dgn referensi)
  static const Color _surface      = Color(0xFFFFFFFF);
  static const Color _border       = Color(0xFFE4D9F7); // border ungu pucat
  static const Color _textHead     = Color(0xFF1E1B4B); // hampir hitam ungu
  static const Color _textSub      = Color(0xFF6B6B8A);
  static const Color _textHint     = Color(0xFFAAA8C0);

  // Aksen lain (untuk multi-step form)
  static const Color _amber  = Color(0xFFF59E0B);
  static const Color _green  = Color(0xFF059669);
  static const Color _teal   = Color(0xFF0891B2);
  static const Color _red    = Color(0xFFDC2626);

  List<dynamic> _allItems      = [];
  List<dynamic> _filteredItems = [];
  List<dynamic> _listAnak     = [];

  bool   _isLoading   = true;
  String _searchQuery = '';

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

  // ═══════════════════════════════════════════════════════════════
  //  FETCH
  // ═══════════════════════════════════════════════════════════════
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final resOrtu  = await ApiService.fetchData('manage_ortu.php', []);
      final resAnak = await ApiService.fetchData('manage_ortu.php?action=get_anak', []);
      if (!mounted) return;
      setState(() {
        if (resOrtu['status']  == 'success') _allItems  = List<dynamic>.from(resOrtu['data']);
        if (resAnak['status'] == 'success') _listAnak = List<dynamic>.from(resAnak['data']);
        _applyFilter();
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredItems = List.from(_allItems);
    } else {
      _filteredItems = _allItems.where((item) {
        final nama      = (item['name']      ?? '').toString().toLowerCase();
        final pekerjaan = (item['pekerjaan'] ?? '').toString().toLowerCase();
        final hp        = (item['no_hp']     ?? '').toString().toLowerCase();
        final nik       = (item['nik']       ?? '').toString().toLowerCase();
        return nama.contains(_searchQuery) ||
            pekerjaan.contains(_searchQuery) ||
            hp.contains(_searchQuery) ||
            nik.contains(_searchQuery);
      }).toList();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS — initials & color
  // ═══════════════════════════════════════════════════════════════
  String _initials(String name) =>
      name.trim().split(' ').map((e) => e.isEmpty ? '' : e[0]).take(2).join().toUpperCase();

  int _anakCount(dynamic item) => ((item['anak'] as List?) ?? []).length;

  // ═══════════════════════════════════════════════════════════════
  //  CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildOrtuCard(Map<String, dynamic> item) {
    final name     = item['name'] ?? 'Tanpa Nama';
    final inits    = _initials(name);
    final anakList = (item['anak'] as List?) ?? [];
    final noHp     = item['no_hp']     ?? '-';
    final pekerjaan= item['pekerjaan'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailSheet(item),
          borderRadius: BorderRadius.circular(20),
          splashColor: _primaryLight,
          highlightColor: _primaryLight.withOpacity(0.4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar rounded-square (persis seperti referensi)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        inits,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _textHead,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Chip baris: tahun / anak (mirip referensi)
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _chip(
                                icon: Icons.phone_rounded,
                                label: noHp,
                                color: _primary,
                              ),
                              _chip(
                                icon: Icons.work_rounded,
                                label: pekerjaan,
                                color: _amber,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Three-dot menu
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: _textSub, size: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      onSelected: (v) {
                        if (v == 'edit')   _showFormSheet(ortu: item);
                        if (v == 'link')   _showLinkAnakSheet(item);
                        if (v == 'delete') _confirmDelete(item);
                      },
                      itemBuilder: (_) => [
                        _popItem('edit',   Icons.edit_rounded,          'Edit Data',          _primary),
                        _popItem('link',   Icons.link_rounded,          'Hubungkan Anak',     _teal),
                        _popItem('delete', Icons.delete_outline_rounded, 'Hapus',             _red),
                      ],
                    ),
                  ],
                ),

                // Divider & anak chips
                if (anakList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: _border.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.child_care_rounded, size: 13, color: _teal),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: anakList.map((anak) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: _teal.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              anak['nama_anak'] ?? '-',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _teal.withOpacity(0.85),
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: _border.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 13, color: _amber),
                      const SizedBox(width: 5),
                      Text(
                        'Belum ada anak dihubungkan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _amber.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Chip kecil (mirip chip "2024/2025" dan "1 Anak" di referensi)
  Widget _chip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color.withOpacity(0.85)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DELETE
  // ═══════════════════════════════════════════════════════════════
  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final name             = item['name'] ?? 'Tanpa Nama';
    final List<dynamic> anakList = item['anak'] ?? [];

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: _red, size: 30),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hapus Data Orang Tua?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _textHead),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.person_rounded, color: _primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _textHead))),
                  ]),
                ),
                if (anakList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.warning_amber_rounded, color: _amber, size: 17),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'Orang tua ini memiliki ${anakList.length} anak terhubung. Relasi akan diputus, data anak tidak terhapus.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
                      )),
                    ]),
                  ),
                ],
                const SizedBox(height: 10),
                Text('Tindakan ini tidak dapat dibatalkan.',
                    style: TextStyle(fontSize: 12, color: _textHint), textAlign: TextAlign.center),
                const SizedBox(height: 16),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Batal', style: TextStyle(color: _textSub, fontWeight: FontWeight.w600)),
                )),
                const SizedBox(width: 12),
                Expanded(child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: _red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w700)),
                )),
              ]),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final res = await ApiService.postData('manage_ortu.php', {
        'action'  : 'delete_ortu',
        'ortu_id' : item['id'],
      });
      if (!mounted) return;
      if (res['status'] == 'success') {
        _fetchData();
        _showSnack('Data $name berhasil dihapus', _red);
      } else {
        _showSnack(res['message'] ?? 'Gagal menghapus data', _red);
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) _showSnack('Terjadi kesalahan, coba lagi', _red);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  DETAIL SHEET
  // ═══════════════════════════════════════════════════════════════
  void _showDetailSheet(Map<String, dynamic> item) {
    final name     = item['name'] ?? 'Tanpa Nama';
    final inits    = _initials(name);
    final anakList = (item['anak'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),

                // Header card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryDark, _primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(inits, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Orang Tua / Wali Murid',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
                      ),
                    ])),
                  ]),
                ),
                const SizedBox(height: 20),

                _sectionLabel('Informasi Kontak'),
                const SizedBox(height: 8),
                _detailCard(children: [
                  _detailRow(Icons.phone_rounded,       'No. HP',    item['no_hp']     ?? '-'),
                  _detailRow(Icons.email_rounded,       'Email',     item['email']     ?? '-'),
                  _detailRow(Icons.work_rounded,        'Pekerjaan', item['pekerjaan'] ?? '-'),
                  _detailRow(Icons.location_on_rounded, 'Alamat',    item['alamat']    ?? '-', isLast: true),
                ]),
                const SizedBox(height: 16),

                if ((item['ayah_nama'] ?? '').toString().isNotEmpty) ...[
                  _sectionLabel('Data Ayah'),
                  const SizedBox(height: 8),
                  _detailCard(children: _buildParentDetailRows(
                    nama: item['ayah_nama'],
                    status: item['ayah_status'],
                    nik: item['ayah_nik'],
                    ttl: item['ayah_ttl'],
                    agama: item['ayah_agama'],
                    pendidikan: item['ayah_pendidikan'],
                    pekerjaan: item['ayah_pekerjaan'],
                    penghasilan: item['ayah_penghasilan'],
                    hp: item['ayah_hp'],
                  )),
                  const SizedBox(height: 16),
                ],

                if ((item['ibu_nama'] ?? '').toString().isNotEmpty) ...[
                  _sectionLabel('Data Ibu'),
                  const SizedBox(height: 8),
                  _detailCard(children: _buildParentDetailRows(
                    nama: item['ibu_nama'],
                    status: item['ibu_status'],
                    nik: item['ibu_nik'],
                    ttl: item['ibu_ttl'],
                    agama: item['ibu_agama'],
                    pendidikan: item['ibu_pendidikan'],
                    pekerjaan: item['ibu_pekerjaan'],
                    penghasilan: item['ibu_penghasilan'],
                    hp: item['ibu_hp'],
                  )),
                  const SizedBox(height: 16),
                ],

                if ((item['wali_nama'] ?? '').toString().isNotEmpty) ...[
                  _sectionLabel('Data Wali'),
                  const SizedBox(height: 8),
                  _detailCard(children: [
                    _detailRow(Icons.person_rounded,          'Nama Wali', item['wali_nama']      ?? '-'),
                    _detailRow(Icons.family_restroom_rounded, 'Hubungan',  item['wali_hubungan']  ?? '-'),
                    _detailRow(Icons.work_rounded,             'Pekerjaan', item['wali_pekerjaan'] ?? '-'),
                    _detailRow(Icons.phone_rounded,            'No. HP',    item['wali_hp']        ?? '-', isLast: true),
                  ]),
                  const SizedBox(height: 16),
                ],

                Row(children: [
                  _sectionLabel('Anak / Anak Terdaftar'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                    decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text('${anakList.length}',
                        style: const TextStyle(color: _teal, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 10),

                if (anakList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded, color: _amber, size: 18),
                      const SizedBox(width: 10),
                      const Text('Belum ada anak yang dihubungkan',
                          style: TextStyle(fontSize: 13, color: Color(0xFF92400E))),
                    ]),
                  )
                else
                  ...anakList.map((a) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _teal.withOpacity(0.15)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _teal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.child_care_rounded, color: _teal, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a['nama_anak'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _textHead)),
                        Text('NISN: ${a['nisn'] ?? '-'}',
                            style: const TextStyle(fontSize: 11, color: _textSub)),
                      ])),
                    ]),
                  )),

                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Tutup', style: TextStyle(color: _textSub, fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton.icon(
                    onPressed: () { Navigator.pop(ctx); _showFormSheet(ortu: item); },
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 17),
                    label: const Text('Edit Data', style: TextStyle(fontWeight: FontWeight.w700)),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  FORM SHEET — multi-step wizard
  // ═══════════════════════════════════════════════════════════════
  void _showFormSheet({Map<String, dynamic>? ortu}) {
    final bool isEditing = ortu != null;

    final ayahNamaCtrl        = TextEditingController(text: ortu?['ayah_nama']        ?? '');
    final ayahNikCtrl         = TextEditingController(text: ortu?['ayah_nik']         ?? '');
    final ayahTtlCtrl         = TextEditingController(text: ortu?['ayah_ttl']         ?? '');
    final ayahAgamaCtrl       = TextEditingController(text: ortu?['ayah_agama']       ?? '');
    final ayahPendCtrl        = TextEditingController(text: ortu?['ayah_pendidikan']  ?? '');
    final ayahKerjaCtrl       = TextEditingController(text: ortu?['ayah_pekerjaan']   ?? '');
    final ayahPenghasilanCtrl = TextEditingController(text: ortu?['ayah_penghasilan'] ?? '');
    final ayahHpCtrl          = TextEditingController(text: ortu?['ayah_hp']          ?? '');

    final ibuNamaCtrl         = TextEditingController(text: ortu?['ibu_nama']         ?? '');
    final ibuNikCtrl          = TextEditingController(text: ortu?['ibu_nik']          ?? '');
    final ibuTtlCtrl          = TextEditingController(text: ortu?['ibu_ttl']          ?? '');
    final ibuAgamaCtrl        = TextEditingController(text: ortu?['ibu_agama']        ?? '');
    final ibuPendCtrl         = TextEditingController(text: ortu?['ibu_pendidikan']   ?? '');
    final ibuKerjaCtrl        = TextEditingController(text: ortu?['ibu_pekerjaan']    ?? '');
    final ibuPenghasilanCtrl  = TextEditingController(text: ortu?['ibu_penghasilan']  ?? '');
    final ibuHpCtrl           = TextEditingController(text: ortu?['ibu_hp']           ?? '');

    final waliNamaCtrl        = TextEditingController(text: ortu?['wali_nama']      ?? '');
    final waliHubunganCtrl    = TextEditingController(text: ortu?['wali_hubungan']  ?? '');
    final waliKerjaCtrl       = TextEditingController(text: ortu?['wali_pekerjaan'] ?? '');
    final waliHpCtrl          = TextEditingController(text: ortu?['wali_hp']        ?? '');

    final emailCtrl     = TextEditingController(text: ortu?['email']     ?? '');
    final alamatCtrl    = TextEditingController(text: ortu?['alamat']    ?? '');
    final rtRwCtrl      = TextEditingController(text: ortu?['rt_rw']     ?? '');
    final kelurahanCtrl = TextEditingController(text: ortu?['kelurahan'] ?? '');
    final kecamatanCtrl = TextEditingController(text: ortu?['kecamatan'] ?? '');
    final kotaCtrl      = TextEditingController(text: ortu?['kota']      ?? '');
    final provinsiCtrl  = TextEditingController(text: ortu?['provinsi']  ?? '');
    final kodeposCtrl   = TextEditingController(text: ortu?['kode_pos']  ?? '');

    final List<dynamic> anakExisting = ortu?['anak'] ?? [];
    Set<int> selectedAnak = anakExisting.map<int>((a) => int.parse(a['id'].toString())).toSet();

    String ayahStatus = ortu?['ayah_status'] ?? 'Hidup';
    String ibuStatus = ortu?['ibu_status'] ?? 'Hidup';
    int  currentStep = 0;
    bool isSaving    = false;

    const stepTitles = ['Data Ayah', 'Data Ibu', 'Wali & Kontak', 'Alamat', 'Hubungkan Anak'];
    const stepIcons  = [
      Icons.man_rounded,
      Icons.woman_rounded,
      Icons.recent_actors_rounded,
      Icons.home_rounded,
      Icons.child_care_rounded,
    ];
    // Warna per step — ungu sebagai primary, lainnya aksen
    const stepColors = [_primary, Color(0xFFE91E8C), Color(0xFF7C3AED), _green, _teal];

    const agamaList   = ['Islam','Kristen','Katolik','Hindu','Buddha','Konghucu'];
    const pendList    = ['SD / Sederajat','SMP / Sederajat','SMA / Sederajat','D3','S1','S2','S3'];
    const penghasilan = [
      '< Rp 1.000.000','Rp 1.000.000 – 2.000.000','Rp 2.000.000 – 3.500.000',
      'Rp 3.500.000 – 5.000.000','Rp 5.000.000 – 10.000.000','> Rp 10.000.000',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {

          Widget buildStep0() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _fLabel('Status Ayah *'),
            _fDropStr(
              value: ayahStatus,
              items: const ['Hidup', 'Meninggal'],
              hint: 'Pilih status',
              icon: Icons.info_outline_rounded,
              color: stepColors[0],
              onChanged: (v) => setSheet(() => ayahStatus = v ?? 'Hidup'),
            ),
            const SizedBox(height: 14),
            _fLabel('Nama Lengkap Ayah *'),
            _fField(ayahNamaCtrl, Icons.badge_rounded, 'Nama sesuai KTP', stepColors[0]),
            if (ayahStatus == 'Hidup') ...[
              const SizedBox(height: 14),
              _formRow([
                _fCol('NIK Ayah', _fFieldNum(ayahNikCtrl, Icons.credit_card_rounded, '16 digit NIK', stepColors[0])),
                _fCol('Tempat, Tanggal Lahir', _fField(ayahTtlCtrl, Icons.cake_rounded, 'Bengkalis, 12 Januari 1985', stepColors[0])),
              ]),
              const SizedBox(height: 14),
              _formRow([
                _fCol('Agama', _fDropStr(value: ayahAgamaCtrl.text, items: agamaList, hint: 'Pilih agama', icon: Icons.mosque_rounded, color: stepColors[0], onChanged: (v) => setSheet(() => ayahAgamaCtrl.text = v ?? ''))),
                _fCol('Pendidikan', _fDropStr(value: ayahPendCtrl.text, items: pendList, hint: 'Pilih pendidikan', icon: Icons.school_rounded, color: stepColors[0], onChanged: (v) => setSheet(() => ayahPendCtrl.text = v ?? ''))),
              ]),
              const SizedBox(height: 14),
              _fLabel('Pekerjaan Ayah'),
              _fField(ayahKerjaCtrl, Icons.work_rounded, 'PNS / Wiraswasta / Buruh', stepColors[0]),
              const SizedBox(height: 14),
              _fLabel('Penghasilan Rata-rata / Bulan'),
              _fDropStr(value: ayahPenghasilanCtrl.text, items: penghasilan, hint: 'Pilih rentang', icon: Icons.payments_rounded, color: stepColors[0], onChanged: (v) => setSheet(() => ayahPenghasilanCtrl.text = v ?? '')),
              const SizedBox(height: 14),
              _fLabel('No. HP Ayah'),
              _fFieldNum(ayahHpCtrl, Icons.phone_rounded, '08xxxxxxxxxx', stepColors[0]),
            ],
          ]);

          Widget buildStep1() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _fLabel('Status Ibu *'),
            _fDropStr(
              value: ibuStatus,
              items: const ['Hidup', 'Meninggal'],
              hint: 'Pilih status',
              icon: Icons.info_outline_rounded,
              color: stepColors[1],
              onChanged: (v) => setSheet(() => ibuStatus = v ?? 'Hidup'),
            ),
            const SizedBox(height: 14),
            _fLabel('Nama Lengkap Ibu *'),
            _fField(ibuNamaCtrl, Icons.badge_rounded, 'Nama sesuai KTP', stepColors[1]),
            if (ibuStatus == 'Hidup') ...[
              const SizedBox(height: 14),
              _formRow([
                _fCol('NIK Ibu', _fFieldNum(ibuNikCtrl, Icons.credit_card_rounded, '16 digit NIK', stepColors[1])),
                _fCol('Tempat, Tanggal Lahir', _fField(ibuTtlCtrl, Icons.cake_rounded, 'Bengkalis, 5 Maret 1988', stepColors[1])),
              ]),
              const SizedBox(height: 14),
              _formRow([
                _fCol('Agama', _fDropStr(value: ibuAgamaCtrl.text, items: agamaList, hint: 'Pilih agama', icon: Icons.mosque_rounded, color: stepColors[1], onChanged: (v) => setSheet(() => ibuAgamaCtrl.text = v ?? ''))),
                _fCol('Pendidikan', _fDropStr(value: ibuPendCtrl.text, items: pendList, hint: 'Pilih pendidikan', icon: Icons.school_rounded, color: stepColors[1], onChanged: (v) => setSheet(() => ibuPendCtrl.text = v ?? ''))),
              ]),
              const SizedBox(height: 14),
              _fLabel('Pekerjaan Ibu'),
              _fField(ibuKerjaCtrl, Icons.work_rounded, 'IRT / Guru / Perawat', stepColors[1]),
              const SizedBox(height: 14),
              _fLabel('Penghasilan Rata-rata / Bulan'),
              _fDropStr(value: ibuPenghasilanCtrl.text, items: penghasilan, hint: 'Pilih rentang', icon: Icons.payments_rounded, color: stepColors[1], onChanged: (v) => setSheet(() => ibuPenghasilanCtrl.text = v ?? '')),
              const SizedBox(height: 14),
              _fLabel('No. HP Ibu'),
              _fFieldNum(ibuHpCtrl, Icons.phone_rounded, '08xxxxxxxxxx', stepColors[1]),
            ],
          ]);

          Widget buildStep2() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _infoBox('Isi data wali jika anak diasuh oleh selain ayah/ibu kandung. Boleh dikosongkan.', stepColors[2]),
            const SizedBox(height: 14),
            _fLabel('Nama Wali (opsional)'),
            _fField(waliNamaCtrl, Icons.person_rounded, 'Nama lengkap wali', stepColors[2]),
            const SizedBox(height: 14),
            _formRow([
              _fCol('Hubungan dengan Anak', _fField(waliHubunganCtrl, Icons.family_restroom_rounded, 'Kakek, Paman…', stepColors[2])),
              _fCol('No. HP Wali', _fFieldNum(waliHpCtrl, Icons.phone_rounded, '08xxxxxxxxxx', stepColors[2])),
            ]),
            const SizedBox(height: 14),
            _fLabel('Pekerjaan Wali'),
            _fField(waliKerjaCtrl, Icons.work_rounded, 'Pekerjaan wali', stepColors[2]),
            const SizedBox(height: 20),
            Divider(color: _border.withOpacity(0.5)),
            const SizedBox(height: 16),
            _fLabel('Email (untuk akses aplikasi)'),
            _fField(emailCtrl, Icons.email_rounded, 'email@contoh.com', stepColors[2]),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('Email digunakan sebagai username login orang tua',
                  style: const TextStyle(fontSize: 11, color: _textHint)),
            ),
          ]);

          Widget buildStep3() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _fLabel('Alamat Jalan / Gang *'),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: alamatCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Nama jalan, No. rumah, Gang, RT/RW',
                  hintStyle: TextStyle(color: _textHint, fontSize: 13),
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _formRow([
              _fCol('RT / RW', _fField(rtRwCtrl, Icons.grid_view_rounded, '001/002', stepColors[3])),
              _fCol('Kode Pos', _fFieldNum(kodeposCtrl, Icons.local_post_office_rounded, '28711', stepColors[3])),
            ]),
            const SizedBox(height: 14),
            _fLabel('Kelurahan / Desa'),
            _fField(kelurahanCtrl, Icons.villa_rounded, 'Nama kelurahan / desa', stepColors[3]),
            const SizedBox(height: 14),
            _fLabel('Kecamatan'),
            _fField(kecamatanCtrl, Icons.map_rounded, 'Nama kecamatan', stepColors[3]),
            const SizedBox(height: 14),
            _formRow([
              _fCol('Kota / Kabupaten', _fField(kotaCtrl, Icons.location_city_rounded, 'Nama kota/kab', stepColors[3])),
              _fCol('Provinsi', _fField(provinsiCtrl, Icons.apartment_rounded, 'Nama provinsi', stepColors[3])),
            ]),
          ]);

          Widget buildStep4() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _infoBox('Pilih anak yang merupakan anak kandung / wali dari orang tua ini.', _teal),
            const SizedBox(height: 14),
            if (_listAnak.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('Belum ada data anak', style: TextStyle(color: _textHint))),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: _listAnak.asMap().entries.map((entry) {
                    final i     = entry.key;
                    final anak = entry.value;
                    final id    = int.parse(anak['id'].toString());
                    final sel   = selectedAnak.contains(id);
                    return Column(children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setSheet(() {
                          if (sel) selectedAnak.remove(id); else selectedAnak.add(id);
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: sel ? _teal : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: sel ? _teal : const Color(0xFFCBD5E1), width: 1.5),
                              ),
                              child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(anak['nama_anak'] ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _textHead)),
                              Text('NISN: ${anak['nisn'] ?? '-'}',
                                  style: const TextStyle(fontSize: 11, color: _textSub)),
                            ])),
                            if (sel)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: const Text('Terpilih', style: TextStyle(fontSize: 10, color: _teal, fontWeight: FontWeight.w700)),
                              ),
                          ]),
                        ),
                      ),
                      if (i < _listAnak.length - 1) Divider(height: 1, color: _border.withOpacity(0.5)),
                    ]);
                  }).toList(),
                ),
              ),
            if (selectedAnak.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: _teal, size: 17),
                  const SizedBox(width: 8),
                  Text('${selectedAnak.length} anak terpilih',
                      style: const TextStyle(color: _teal, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ),
            ],
          ]);

          String? validateStep() {
            switch (currentStep) {
              case 0: if (ayahNamaCtrl.text.trim().isEmpty) return 'Nama ayah wajib diisi'; break;
              case 1: if (ibuNamaCtrl.text.trim().isEmpty)  return 'Nama ibu wajib diisi';  break;
              case 3: if (alamatCtrl.text.trim().isEmpty)    return 'Alamat wajib diisi';    break;
            }
            return null;
          }

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.93,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(children: [

              // Fixed header
              Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(children: [
                  _sheetHandle(),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: stepColors[currentStep].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(stepIcons[currentStep], color: stepColors[currentStep], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        isEditing ? 'Edit Data Orang Tua' : 'Tambah Data Orang Tua',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _textHead),
                      ),
                      Text(
                        'Langkah ${currentStep + 1} dari ${stepTitles.length} — ${stepTitles[currentStep]}',
                        style: const TextStyle(fontSize: 12, color: _textSub),
                      ),
                    ])),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.close_rounded, size: 18, color: _textSub),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Progress bar
                  Row(children: List.generate(stepTitles.length, (i) {
                    final isActive = i == currentStep;
                    final isDone   = i < currentStep;
                    return Expanded(child: Row(children: [
                      Expanded(child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        decoration: BoxDecoration(
                          color: (isDone || isActive) ? stepColors[i] : const Color(0xFFE8EDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                      if (i < stepTitles.length - 1) const SizedBox(width: 4),
                    ]));
                  })),
                  const SizedBox(height: 8),
                  Row(children: List.generate(stepTitles.length, (i) {
                    final isActive = i == currentStep;
                    final isDone   = i < currentStep;
                    return Expanded(child: Center(child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                        color: (isDone || isActive) ? stepColors[i] : _textHint,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (isDone) Icon(Icons.check_circle_rounded, size: 9, color: stepColors[i]),
                        if (isDone) const SizedBox(width: 2),
                        Flexible(child: Text(stepTitles[i], overflow: TextOverflow.ellipsis)),
                      ]),
                    )));
                  })),
                  const SizedBox(height: 14),
                ]),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _formSection(
                    icon: stepIcons[currentStep],
                    title: stepTitles[currentStep],
                    color: stepColors[currentStep],
                    children: [
                      if (currentStep == 0) buildStep0(),
                      if (currentStep == 1) buildStep1(),
                      if (currentStep == 2) buildStep2(),
                      if (currentStep == 3) buildStep3(),
                      if (currentStep == 4) buildStep4(),
                    ],
                  ),
                ),
              ),

              // Bottom nav
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(ctx).padding.bottom + 12),
                decoration: BoxDecoration(
                  color: _surface,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
                ),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: currentStep > 0
                          ? () => setSheet(() => currentStep--)
                          : () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(
                        currentStep > 0 ? Icons.arrow_back_rounded : Icons.close_rounded,
                        size: 17,
                        color: _textSub,
                      ),
                      label: Text(
                        currentStep > 0 ? 'Kembali' : 'Batal',
                        style: const TextStyle(color: _textSub, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: currentStep == stepTitles.length - 1 ? _green : stepColors[currentStep],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: isSaving ? null : () async {
                        final err = validateStep();
                        if (err != null) { _showSnack(err, _red); return; }

                        if (currentStep < stepTitles.length - 1) {
                          setSheet(() => currentStep++);
                          return;
                        }

                        setSheet(() => isSaving = true);

                        final alamatLengkap = [
                          alamatCtrl.text.trim(),
                          rtRwCtrl.text.trim().isNotEmpty ? 'RT/RW ${rtRwCtrl.text.trim()}' : '',
                          kelurahanCtrl.text.trim(),
                          kecamatanCtrl.text.trim(),
                          kotaCtrl.text.trim(),
                          provinsiCtrl.text.trim(),
                          kodeposCtrl.text.trim(),
                        ].where((s) => s.isNotEmpty).join(', ');

                        try {
                          Map<String, dynamic> res;
                          final primaryName = ayahNamaCtrl.text.trim();
                          final primaryHp = ayahStatus == 'Hidup' ? ayahHpCtrl.text.trim() : (ibuStatus == 'Hidup' ? ibuHpCtrl.text.trim() : '');
                          final primaryJob = ayahStatus == 'Hidup' ? ayahKerjaCtrl.text.trim() : (ibuStatus == 'Hidup' ? ibuKerjaCtrl.text.trim() : '');

                          Map<String, dynamic> payload = {
                            'name': primaryName,
                            'no_hp': primaryHp,
                            'pekerjaan': primaryJob,
                            'alamat': alamatLengkap,
                            'email': emailCtrl.text.trim(),
                            'ayah_nama': ayahNamaCtrl.text.trim(),
                            'ayah_nik': ayahStatus == 'Hidup' ? ayahNikCtrl.text.trim() : '',
                            'ayah_ttl': ayahStatus == 'Hidup' ? ayahTtlCtrl.text.trim() : '',
                            'ayah_agama': ayahStatus == 'Hidup' ? ayahAgamaCtrl.text : '',
                            'ayah_pendidikan': ayahStatus == 'Hidup' ? ayahPendCtrl.text : '',
                            'ayah_pekerjaan': ayahStatus == 'Hidup' ? ayahKerjaCtrl.text.trim() : '',
                            'ayah_penghasilan': ayahStatus == 'Hidup' ? ayahPenghasilanCtrl.text : '',
                            'ayah_hp': ayahStatus == 'Hidup' ? ayahHpCtrl.text.trim() : '',
                            'ayah_status': ayahStatus,
                            'ibu_nama': ibuNamaCtrl.text.trim(),
                            'ibu_nik': ibuStatus == 'Hidup' ? ibuNikCtrl.text.trim() : '',
                            'ibu_ttl': ibuStatus == 'Hidup' ? ibuTtlCtrl.text.trim() : '',
                            'ibu_agama': ibuStatus == 'Hidup' ? ibuAgamaCtrl.text : '',
                            'ibu_pendidikan': ibuStatus == 'Hidup' ? ibuPendCtrl.text : '',
                            'ibu_pekerjaan': ibuStatus == 'Hidup' ? ibuKerjaCtrl.text.trim() : '',
                            'ibu_penghasilan': ibuStatus == 'Hidup' ? ibuPenghasilanCtrl.text : '',
                            'ibu_hp': ibuStatus == 'Hidup' ? ibuHpCtrl.text.trim() : '',
                            'ibu_status': ibuStatus,
                            'wali_nama': waliNamaCtrl.text.trim(),
                            'wali_hubungan': waliHubunganCtrl.text.trim(),
                            'wali_pekerjaan': waliKerjaCtrl.text.trim(),
                            'wali_hp': waliHpCtrl.text.trim(),
                            'rt_rw': rtRwCtrl.text.trim(),
                            'kelurahan': kelurahanCtrl.text.trim(),
                            'kecamatan': kecamatanCtrl.text.trim(),
                            'kota': kotaCtrl.text.trim(),
                            'provinsi': provinsiCtrl.text.trim(),
                            'kode_pos': kodeposCtrl.text.trim(),
                          };

                          if (isEditing) {
                            payload['action'] = 'update_detail';
                            payload['ortu_id'] = ortu!['id'];
                            res = await ApiService.postData('manage_ortu.php', payload);
                          } else {
                            payload['action'] = 'add_parent';
                            res = await ApiService.postData('manage_ortu.php', payload);
                          }

                          if (res['status'] == 'success') {
                            final ortuId = isEditing
                                ? int.parse(ortu!['id'].toString())
                                : res['ortu_id'];
                            if (selectedAnak.isNotEmpty) {
                              await ApiService.updateOrtuAnakLink(ortuId, selectedAnak.toList());
                            }
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            _fetchData();
                            _showSnack(isEditing ? 'Data berhasil diperbarui' : 'Data orang tua berhasil ditambahkan', _green);
                          } else {
                            _showSnack(res['message'] ?? 'Gagal menyimpan', _red);
                          }
                        } catch (e) {
                          debugPrint(e.toString());
                        } finally {
                          setSheet(() => isSaving = false);
                        }
                      },
                      icon: isSaving
                          ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Icon(currentStep < stepTitles.length - 1 ? Icons.arrow_forward_rounded : Icons.save_rounded, size: 17),
                      label: Text(
                        isSaving ? '' : currentStep < stepTitles.length - 1 ? 'Lanjut' : (isEditing ? 'Perbarui' : 'Simpan Data'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LINK ANAK SHEET
  // ═══════════════════════════════════════════════════════════════
  void _showLinkAnakSheet(Map<String, dynamic> ortu) {
    final List<dynamic> anakList = ortu['anak'] ?? [];
    Set<int> selectedIds = anakList.map<int>((a) => int.parse(a['id'].toString())).toSet();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border.withOpacity(0.5)))),
              child: Column(children: [
                _sheetHandle(),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.link_rounded, color: _teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Hubungkan Anak', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _textHead)),
                    Text(ortu['name'] ?? '-', style: const TextStyle(fontSize: 12, color: _textSub)),
                  ])),
                ]),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _listAnak.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: _border.withOpacity(0.4)),
                itemBuilder: (_, i) {
                  final anak   = _listAnak[i];
                  final anakId = int.parse(anak['id'].toString());
                  final sel     = selectedIds.contains(anakId);
                  return InkWell(
                    onTap: () => setSheet(() {
                      if (sel) selectedIds.remove(anakId); else selectedIds.add(anakId);
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: sel ? _teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: sel ? _teal : const Color(0xFFCBD5E1), width: 1.5),
                          ),
                          child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(anak['nama_anak'] ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _textHead)),
                          Text('NISN: ${anak['nisn'] ?? '-'}',
                              style: const TextStyle(fontSize: 11, color: _textSub)),
                        ])),
                      ]),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(ctx).padding.bottom + 12),
              decoration: BoxDecoration(
                color: _surface,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -3))],
              ),
              child: FilledButton(
                onPressed: isSaving ? null : () async {
                  setSheet(() => isSaving = true);
                  final res = await ApiService.updateOrtuAnakLink(
                      int.parse(ortu['id'].toString()), selectedIds.toList());
                  setSheet(() => isSaving = false);
                  if (res['status'] == 'success') {
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _fetchData();
                    _showSnack('Data anak berhasil dihubungkan', _green);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS UI
  List<Widget> _buildParentDetailRows({
    required String? nama,
    required String? status,
    required String? nik,
    required String? ttl,
    required String? agama,
    required String? pendidikan,
    required String? pekerjaan,
    required String? penghasilan,
    required String? hp,
  }) {
    final List<Map<String, dynamic>> rows = [
      {'icon': Icons.badge_rounded, 'label': 'Nama Lengkap', 'value': nama ?? '-'},
      {'icon': Icons.info_outline_rounded, 'label': 'Status', 'value': status ?? 'Hidup'},
    ];
    if (status != 'Meninggal') {
      rows.addAll([
        {'icon': Icons.credit_card_rounded, 'label': 'NIK', 'value': nik ?? '-'},
        {'icon': Icons.cake_rounded, 'label': 'Tempat, Tgl Lahir', 'value': ttl ?? '-'},
        {'icon': Icons.mosque_rounded, 'label': 'Agama', 'value': agama ?? '-'},
        {'icon': Icons.school_rounded, 'label': 'Pendidikan', 'value': pendidikan ?? '-'},
        {'icon': Icons.work_rounded, 'label': 'Pekerjaan', 'value': pekerjaan ?? '-'},
        {'icon': Icons.payments_rounded, 'label': 'Penghasilan', 'value': penghasilan ?? '-'},
        {'icon': Icons.phone_rounded, 'label': 'No. HP', 'value': hp ?? '-'},
      ]);
    }
    return List.generate(rows.length, (index) {
      final r = rows[index];
      return _detailRow(r['icon'] as IconData, r['label'] as String, r['value'] as String, isLast: index == rows.length - 1);
    });
  }

  // ═══════════════════════════════════════════════════════════════
  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info_rounded, color: Colors.white, size: 17),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40, height: 4,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
    ),
  );

  Widget _sectionLabel(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _textHead));

  Widget _detailCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Column(children: children),
  );

  Widget _detailRow(IconData icon, String label, String value, {bool isLast = false}) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 17, color: _primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _textHint, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textHead)),
        ])),
      ]),
    ),
    if (!isLast) Divider(height: 1, color: _border.withOpacity(0.5), indent: 16, endIndent: 16),
  ]);

  Widget _infoBox(String text, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(Icons.info_outline_rounded, color: color, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color.withOpacity(0.85)))),
    ]),
  );

  Widget _formSection({required IconData icon, required String title, required Color color, required List<Widget> children}) =>
      Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: _primary.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.12))),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        ]),
      );

  Widget _fLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _textSub)),
  );

  Widget _fField(TextEditingController c, IconData icon, String hint, Color color) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
    ),
    child: TextField(
      controller: c,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(color: _textHint, fontSize: 13),
        prefixIcon: Icon(icon, color: color, size: 18),
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      ),
    ),
  );

  Widget _fFieldNum(TextEditingController c, IconData icon, String hint, Color color) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
    ),
    child: TextField(
      controller: c,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(color: _textHint, fontSize: 13),
        prefixIcon: Icon(icon, color: color, size: 18),
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      ),
    ),
  );

  Widget _fDropStr({
    required String value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required Color color,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value.isEmpty ? null : value,
            isExpanded: true,
            hint: Text(hint, style: const TextStyle(color: _textHint, fontSize: 13)),
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: color),
            items: items.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _fCol(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [_fLabel(label), field],
  );

  Widget _formRow(List<Widget> cols) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: cols.expand((c) sync* {
      yield Expanded(child: c);
      if (c != cols.last) yield const SizedBox(width: 10);
    }).toList(),
  );

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // AppBar — solid ungu gelap, persis seperti teal di referensi
      appBar: AppBar(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Data Orang Tua', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _fetchData,
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: Column(children: [

        // Header extended (judul + counter) — mirip referensi "Kelola Kelas / 2 kelas terdaftar"
        Container(
          width: double.infinity,
          color: _primaryDark,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Orang Tua',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${_filteredItems.length} wali murid terdaftar',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
            ],
          ),
        ),

        // Search bar — putih, di luar header (persis referensi)
        Container(
          color: _bg,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
              boxShadow: [BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14, color: _textHead),
              decoration: InputDecoration(
                hintText: 'Cari nama, pekerjaan, atau no HP…',
                hintStyle: const TextStyle(color: _textHint, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: _primary, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: _textHint, size: 18),
                        onPressed: _searchController.clear,
                      )
                    : null,
              ),
            ),
          ),
        ),

        // Stat chips — mirip "Total Kelas / Total Anak / Filter" di referensi
        if (!_isLoading)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              _statChip(Icons.people_alt_rounded, '${_allItems.length}', 'Total Wali', _primary),
              const SizedBox(width: 10),
              _statChip(Icons.child_care_rounded, '${_allItems.fold<int>(0, (s, i) => s + _anakCount(i))}', 'Total Anak', _amber),
              const SizedBox(width: 10),
              _statChip(Icons.warning_amber_rounded,
                  '${_allItems.where((i) => _anakCount(i) == 0).length}',
                  'Belum Link', _red.withOpacity(0.8) as Color, light: true),
            ]),
          ),

        const SizedBox(height: 12),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5))
              : RefreshIndicator(
                  color: _primary,
                  onRefresh: _fetchData,
                  child: _filteredItems.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(color: _primaryLight, borderRadius: BorderRadius.circular(22)),
                            child: const Icon(Icons.family_restroom_rounded, size: 34, color: _primary),
                          ),
                          const SizedBox(height: 16),
                          const Text('Belum ada data orang tua',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textSub)),
                          const SizedBox(height: 6),
                          const Text('Tap tombol + untuk menambahkan',
                              style: TextStyle(fontSize: 13, color: _textHint)),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: _filteredItems.length,
                          itemBuilder: (_, i) => _buildOrtuCard(Map<String, dynamic>.from(_filteredItems[i])),
                        ),
                ),
        ),
      ]),

      // FAB extended — mirip referensi
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormSheet(),
        backgroundColor: _primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
        label: const Text('Tambah Ortu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }

  // Stat chip (mirip card statistik di referensi)
  Widget _statChip(IconData icon, String value, String label, Color color, {bool light = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: _primary.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: _textHint, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }
}
