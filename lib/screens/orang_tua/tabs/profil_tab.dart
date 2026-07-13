import 'package:flutter/material.dart';
import '../../profil_sekolah_screen.dart';
import '../../../theme/colors.dart';
import '../../about_system_screen.dart';

// ── Palette ──────────────────────────────────────────────────
const Color _orange900 = AppColors.orange900;
const Color _orange700 = AppColors.orange700;
const Color _orange500 = AppColors.orange500;
const Color _surface   = AppColors.surface;
const Color _green     = AppColors.green;
const Color _purple    = AppColors.purple;
const Color _rose      = AppColors.rose;
const Color _teal      = AppColors.teal;

class ProfilTab extends StatelessWidget {
  final Map<String, dynamic> user;
  final List<dynamic> anakList;
  final VoidCallback onLogout;
  final VoidCallback onChangePasswordTap;

  const ProfilTab({
    super.key,
    required this.user,
    required this.anakList,
    required this.onLogout,
    required this.onChangePasswordTap,
  });

  @override
  Widget build(BuildContext context) {
    final namaOrtu  = user['name'] ?? user['username'] ?? 'Orang Tua';
    final username  = user['username'] ?? '-';
    final email     = user['email'] ?? '-';
    final telp      = user['telp'] ?? user['no_hp'] ?? '-';
    final childNames = anakList.map((s) => s['nama_anak'] ?? '').where((n) => n.isNotEmpty).join(', ');

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: _orange700,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _buildProfilHero(namaOrtu, childNames),
          ),
          title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
              children: [
                _buildInfoSection('Data Akun', Icons.person_rounded, _orange700, [
                  _buildInfoRow(Icons.badge_rounded,           'Nama Lengkap', namaOrtu),
                  _buildInfoRow(Icons.account_circle_rounded,  'Username',     username),
                  _buildInfoRow(Icons.email_rounded,           'Email',        email),
                  _buildInfoRow(Icons.phone_rounded,           'No. HP',       telp, isLast: true),
                ]),
                if ((user['ayah_nama'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Data Ayah', Icons.man_rounded, _orange500,
                      _buildParentProfileRows(
                        nama: user['ayah_nama'], status: user['ayah_status'],
                        nik: user['ayah_nik'], ttl: user['ayah_ttl'],
                        agama: user['ayah_agama'], pendidikan: user['ayah_pendidikan'],
                        pekerjaan: user['ayah_pekerjaan'], penghasilan: user['ayah_penghasilan'],
                        hp: user['ayah_hp'],
                      )),
                ],
                if ((user['ibu_nama'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Data Ibu', Icons.woman_rounded, const Color(0xFFE91E63),
                      _buildParentProfileRows(
                        nama: user['ibu_nama'], status: user['ibu_status'],
                        nik: user['ibu_nik'], ttl: user['ibu_ttl'],
                        agama: user['ibu_agama'], pendidikan: user['ibu_pendidikan'],
                        pekerjaan: user['ibu_pekerjaan'], penghasilan: user['ibu_penghasilan'],
                        hp: user['ibu_hp'],
                      )),
                ],
                if ((user['wali_nama'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Data Wali', Icons.recent_actors_rounded, _purple, [
                    _buildInfoRow(Icons.badge_rounded,             'Nama Wali',  user['wali_nama'] ?? '-'),
                    _buildInfoRow(Icons.family_restroom_rounded,   'Hubungan',   user['wali_hubungan'] ?? '-'),
                    _buildInfoRow(Icons.work_rounded,              'Pekerjaan',  user['wali_pekerjaan'] ?? '-'),
                    _buildInfoRow(Icons.phone_rounded,             'No. HP',     user['wali_hp'] ?? '-', isLast: true),
                  ]),
                ],
                if ((user['alamat'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final String alJalan = (user['alamat'] ?? '').toString();
                      final String rt = (user['rt_rw'] ?? '').toString();
                      final String kel = (user['kelurahan'] ?? '').toString();
                      final String kec = (user['kecamatan'] ?? '').toString();
                      final String kota = (user['kota'] ?? '').toString();
                      final String prov = (user['provinsi'] ?? '').toString();
                      final String pos = (user['kode_pos'] ?? '').toString();

                      final bool showRt = rt.isNotEmpty && rt != '-' && !alJalan.toLowerCase().contains(rt.toLowerCase());
                      final bool showKel = kel.isNotEmpty && kel != '-' && !alJalan.toLowerCase().contains(kel.toLowerCase());
                      final bool showKec = kec.isNotEmpty && kec != '-' && !alJalan.toLowerCase().contains(kec.toLowerCase());
                      final bool showKota = kota.isNotEmpty && kota != '-' && !alJalan.toLowerCase().contains(kota.toLowerCase());
                      final bool showProv = prov.isNotEmpty && prov != '-' && !alJalan.toLowerCase().contains(prov.toLowerCase());
                      final bool showPos = pos.isNotEmpty && pos != '-' && !alJalan.toLowerCase().contains(pos.toLowerCase());

                      final List<Map<String, dynamic>> items = [
                        {'icon': Icons.location_on_rounded, 'label': 'Alamat Jalan', 'value': alJalan},
                      ];
                      if (showRt)   items.add({'icon': Icons.grid_view_rounded, 'label': 'RT / RW', 'value': rt});
                      if (showKel)  items.add({'icon': Icons.villa_rounded, 'label': 'Kelurahan', 'value': kel});
                      if (showKec)  items.add({'icon': Icons.map_rounded, 'label': 'Kecamatan', 'value': kec});
                      if (showKota) items.add({'icon': Icons.location_city_rounded, 'label': 'Kota/Kab', 'value': kota});
                      if (showProv) items.add({'icon': Icons.apartment_rounded, 'label': 'Provinsi', 'value': prov});
                      if (showPos)  items.add({'icon': Icons.local_post_office_rounded, 'label': 'Kode Pos', 'value': pos});

                      return _buildInfoSection(
                        'Alamat Lengkap',
                        Icons.home_rounded,
                        _green,
                        List.generate(items.length, (idx) {
                          final item = items[idx];
                          return _buildInfoRow(
                            item['icon'] as IconData,
                            item['label'] as String,
                            item['value'] as String,
                            isLast: idx == items.length - 1,
                          );
                        }),
                      );
                    },
                  ),
                ],
                if (anakList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Anak Terdaftar', Icons.child_care_rounded, _teal, [
                    ...anakList.asMap().entries.map((e) {
                      final s = e.value;
                      return _buildInfoRow(
                        Icons.person_pin_circle_rounded, 'Anak ${e.key + 1}',
                        '${s['nama_anak'] ?? '-'}  •  Kelas ${s['nama_kelas'] ?? '-'}',
                        isLast: e.key == anakList.length - 1,
                      );
                    }),
                  ]),
                ],
                const SizedBox(height: 16),
                // Profil Sekolah
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfilSekolahScreen(primaryColor: _orange700))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _surface, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _orange500.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.account_balance_rounded, color: _orange700, size: 22)),
                      const SizedBox(width: 14),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Profil Sekolah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                        SizedBox(height: 2),
                        Text('Lihat informasi lengkap sekolah', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ])),
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                // Tentang SiMONA
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AboutSystemScreen(
                        primaryColor: _orange700,
                        primaryDark: _orange900,
                        backgroundColor: _surface,
                        borderColor: Color(0xFFE2E8F0),
                      ))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _surface, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _orange500.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.info_outline_rounded, color: _orange700, size: 22)),
                      const SizedBox(width: 14),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Tentang SiMONA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                        SizedBox(height: 2),
                        Text('Informasi detail dan alur jalannya sistem', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ])),
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                // Keamanan
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surface, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Keamanan Akun',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onChangePasswordTap,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _orange700.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        icon: const Icon(Icons.lock_outline_rounded, color: _orange700, size: 18),
                        label: const Text('Ganti Password', style: TextStyle(color: _orange700, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rose,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0,
                    ),
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                    label: const Text('Keluar Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildParentProfileRows({
    required String? nama, required String? status, required String? nik,
    required String? ttl, required String? agama, required String? pendidikan,
    required String? pekerjaan, required String? penghasilan, required String? hp,
  }) {
    final List<Map<String, dynamic>> rows = [
      {'icon': Icons.badge_rounded,       'label': 'Nama Lengkap',      'value': nama ?? '-'},
      {'icon': Icons.info_outline_rounded, 'label': 'Status',           'value': status ?? 'Hidup'},
    ];
    if (status != 'Meninggal') {
      rows.addAll([
        {'icon': Icons.credit_card_rounded,  'label': 'NIK',              'value': nik ?? '-'},
        {'icon': Icons.cake_rounded,         'label': 'Tempat, Tgl Lahir','value': ttl ?? '-'},
        {'icon': Icons.mosque_rounded,       'label': 'Agama',            'value': agama ?? '-'},
        {'icon': Icons.school_rounded,       'label': 'Pendidikan',       'value': pendidikan ?? '-'},
        {'icon': Icons.work_rounded,         'label': 'Pekerjaan',        'value': pekerjaan ?? '-'},
        {'icon': Icons.payments_rounded,     'label': 'Penghasilan',      'value': penghasilan ?? '-'},
        {'icon': Icons.phone_rounded,        'label': 'No. HP',           'value': hp ?? '-'},
      ]);
    }
    return List.generate(rows.length, (index) {
      final r = rows[index];
      return _buildInfoRow(r['icon'] as IconData, r['label'] as String, r['value'] as String, isLast: index == rows.length - 1);
    });
  }

  Widget _buildProfilHero(String nama, String childNames) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [_orange900, _orange700], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: Stack(children: [
      Positioned(top: -30, right: -20, child: Container(
        width: 150, height: 150,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
      )),
      Center(child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16)]),
            child: Center(child: Text(
              nama.isNotEmpty ? nama.substring(0, 1).toUpperCase() : 'O',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _orange700),
            )),
          ),
          const SizedBox(height: 10),
          Text(
            nama,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(
              childNames.isNotEmpty ? 'Orang Tua — $childNames' : 'Orang Tua',
              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
      )),
    ]),
  );

  Widget _buildInfoSection(String title, IconData icon, Color color, List<Widget> children) => Container(
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border(bottom: BorderSide(color: color.withOpacity(0.1))),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ]),
      ),
      ...children,
    ]),
  );

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLast = false}) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: _orange700),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ])),
      ]),
    ),
    if (!isLast) Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
  ]);
}

