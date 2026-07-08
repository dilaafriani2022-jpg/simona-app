import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../profil_sekolah_screen.dart';

class ProfilTab extends StatefulWidget {
  final Map<String, dynamic> currentUserData;
  final Function(Map<String, dynamic>) onProfileUpdated;

  const ProfilTab({
    super.key,
    required this.currentUserData,
    required this.onProfileUpdated,
  });

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  @override
  Widget build(BuildContext context) {
    final name = widget.currentUserData['name'] ?? 'Kepala Sekolah';
    final nip = widget.currentUserData['nip'] ?? '-';
    final email = widget.currentUserData['email'] ?? '-';
    final telp = widget.currentUserData['no_telp'] ?? '-';
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'K';

    final double bottomPad = MediaQuery.of(context).padding.bottom + 96;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF451A03)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Center(
                    child: Text(
                       initial,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kepala Sekolah',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'NIP: $nip',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          _buildProfileSection(
            title: 'Informasi Pribadi',
            icon: Icons.person_rounded,
            color: Colors.indigo.shade800,
            onEdit: _showEditProfileSheet,
            children: [
              _buildProfileRow(Icons.badge_rounded, 'Nama Lengkap', name),
              _buildProfileRow(Icons.credit_card_rounded, 'NIP', nip),
              _buildProfileRow(Icons.email_rounded, 'Email', email),
              _buildProfileRow(Icons.school_rounded, 'Pendidikan', widget.currentUserData['pendidikan'] != null ? '${widget.currentUserData['pendidikan']}${widget.currentUserData['jurusan'] != null ? ' - ${widget.currentUserData['jurusan']}' : ''}' : '-'),
              _buildProfileRow(Icons.cake_rounded, 'TTL', (widget.currentUserData['tempat_lahir'] != null || widget.currentUserData['tanggal_lahir'] != null) ? '${widget.currentUserData['tempat_lahir'] ?? ''}, ${widget.currentUserData['tanggal_lahir'] ?? ''}' : '-'),
              _buildProfileRow(Icons.phone_rounded, 'No. HP', telp),
              _buildProfileRow(Icons.mosque_rounded, 'Agama', widget.currentUserData['agama'] ?? '-'),
              _buildProfileRow(Icons.wc_rounded, 'Jenis Kelamin', widget.currentUserData['jenis_kelamin'] == 'L' ? 'Laki-laki' : (widget.currentUserData['jenis_kelamin'] == 'P' ? 'Perempuan' : '-')),
              _buildProfileRow(Icons.favorite_rounded, 'Status Nikah', widget.currentUserData['status_nikah'] ?? '-', isLast: true),
            ],
          ),
          const SizedBox(height: 16),

          _buildProfileSection(
            title: 'Alamat Lengkap',
            icon: Icons.home_rounded,
            color: Colors.indigo.shade800,
            onEdit: _showEditProfileSheet,
            children: [
              _buildProfileRow(Icons.location_on_rounded, 'Alamat Jalan', widget.currentUserData['alamat'] ?? '-'),
              _buildProfileRow(Icons.grid_view_rounded, 'RT / RW', widget.currentUserData['rt_rw'] ?? '-'),
              _buildProfileRow(Icons.villa_rounded, 'Kelurahan', widget.currentUserData['kelurahan'] ?? '-'),
              _buildProfileRow(Icons.map_rounded, 'Kecamatan', widget.currentUserData['kecamatan'] ?? '-'),
              _buildProfileRow(Icons.location_city_rounded, 'Kota/Kab', widget.currentUserData['kota'] ?? '-'),
              _buildProfileRow(Icons.apartment_rounded, 'Provinsi', widget.currentUserData['provinsi'] ?? '-'),
              _buildProfileRow(Icons.local_post_office_rounded, 'Kode Pos', widget.currentUserData['kode_pos'] ?? '-', isLast: true),
            ],
          ),
          const SizedBox(height: 24),

          // Profil Sekolah Button
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) =>
                ProfilSekolahScreen(primaryColor: Colors.indigo.shade800))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.account_balance_rounded, color: Colors.indigo.shade800, size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Profil Sekolah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text('Lihat informasi lengkap sekolah', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ])),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
              ])),
          ),
          const SizedBox(height: 16),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Keluar Akun'),
                    content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                        },
                        child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
              label: const Text('Keluar Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    VoidCallback? onEdit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color))),
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: Icon(Icons.edit_rounded, color: color, size: 14),
                    ),
                  ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.indigo.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.blueGrey.shade100, indent: 16, endIndent: 16),
      ],
    );
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: widget.currentUserData['name']?.toString() ?? '');
    final nipCtrl = TextEditingController(text: widget.currentUserData['nip']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: widget.currentUserData['email']?.toString() ?? '');
    final telpCtrl = TextEditingController(text: widget.currentUserData['no_telp']?.toString() ?? '');
    final tempatLahirCtrl = TextEditingController(text: widget.currentUserData['tempat_lahir']?.toString() ?? '');
    final tanggalLahirCtrl = TextEditingController(text: widget.currentUserData['tanggal_lahir']?.toString() ?? '');
    final pendidikanCtrl = TextEditingController(text: widget.currentUserData['pendidikan']?.toString() ?? '');
    final jurusanCtrl = TextEditingController(text: widget.currentUserData['jurusan']?.toString() ?? '');
    final alamatCtrl = TextEditingController(text: widget.currentUserData['alamat']?.toString() ?? '');
    final rtRwCtrl = TextEditingController(text: widget.currentUserData['rt_rw']?.toString() ?? '');
    final kelurahanCtrl = TextEditingController(text: widget.currentUserData['kelurahan']?.toString() ?? '');
    final kecamatanCtrl = TextEditingController(text: widget.currentUserData['kecamatan']?.toString() ?? '');
    final kotaCtrl = TextEditingController(text: widget.currentUserData['kota']?.toString() ?? '');
    final provinsiCtrl = TextEditingController(text: widget.currentUserData['provinsi']?.toString() ?? '');
    final kodePosCtrl = TextEditingController(text: widget.currentUserData['kode_pos']?.toString() ?? '');

    String selectedAgama = widget.currentUserData['agama']?.toString() ?? 'Islam';
    if (selectedAgama.isEmpty) selectedAgama = 'Islam';
    String selectedGender = widget.currentUserData['jenis_kelamin']?.toString() ?? 'L';
    if (selectedGender.isEmpty) selectedGender = 'L';
    String selectedNikah = widget.currentUserData['status_nikah']?.toString() ?? 'Menikah';
    if (selectedNikah.isEmpty) selectedNikah = 'Menikah';

    const agamaList = ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'];
    const nikahList = ['Menikah', 'Belum Menikah', 'Duda/Janda'];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final mq = MediaQuery.of(ctx);
          return Container(
            height: mq.size.height * 0.9,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.manage_accounts_rounded, color: Colors.indigo.shade800, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Ubah Profil Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                      Text('Perbarui informasi profil Kepala Sekolah', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ])),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                      ),
                    ),
                  ]),
                ]),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, mq.viewInsets.bottom + 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _editSectionTitle('Identitas Pribadi'),
                    _editField(ctrl: nameCtrl, label: 'Nama Lengkap *', icon: Icons.badge_rounded),
                    _editField(ctrl: nipCtrl, label: 'NIP *', icon: Icons.credit_card_rounded),
                    _editField(ctrl: emailCtrl, label: 'Email', icon: Icons.email_rounded),
                    _editField(ctrl: telpCtrl, label: 'No. HP / Telepon', icon: Icons.phone_rounded),
                    _editField(ctrl: tempatLahirCtrl, label: 'Tempat Lahir', icon: Icons.location_city_rounded),
                    _editField(ctrl: tanggalLahirCtrl, label: 'Tanggal Lahir (TTTT-BB-HH)', icon: Icons.cake_rounded, hint: 'Contoh: 1980-08-17'),

                    const Text('Jenis Kelamin', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(child: RadioListTile<String>(
                        title: const Text('Laki-laki', style: TextStyle(fontSize: 13)),
                        value: 'L', groupValue: selectedGender,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setSheet(() => selectedGender = val!),
                      )),
                      Expanded(child: RadioListTile<String>(
                        title: const Text('Perempuan', style: TextStyle(fontSize: 13)),
                        value: 'P', groupValue: selectedGender,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setSheet(() => selectedGender = val!),
                      )),
                    ]),
                    const SizedBox(height: 12),

                    const Text('Agama', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCBD5E1))),
                      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                        value: selectedAgama, isExpanded: true,
                        items: agamaList.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) => setSheet(() => selectedAgama = val!),
                      )),
                    ),
                    const SizedBox(height: 16),

                    const Text('Status Pernikahan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCBD5E1))),
                      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                        value: selectedNikah, isExpanded: true,
                        items: nikahList.map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) => setSheet(() => selectedNikah = val!),
                      )),
                    ),
                    const SizedBox(height: 20),

                    _editSectionTitle('Riwayat Pendidikan'),
                    _editField(ctrl: pendidikanCtrl, label: 'Pendidikan Terakhir', icon: Icons.school_rounded, hint: 'Contoh: S1 PGPAUD / S2 Pendidikan'),
                    _editField(ctrl: jurusanCtrl, label: 'Jurusan', icon: Icons.menu_book_rounded),

                    _editSectionTitle('Alamat Lengkap'),
                    _editField(ctrl: alamatCtrl, label: 'Alamat Jalan', icon: Icons.location_on_rounded),
                    _editField(ctrl: rtRwCtrl, label: 'RT / RW', icon: Icons.grid_view_rounded, hint: 'Contoh: 002/001'),
                    _editField(ctrl: kelurahanCtrl, label: 'Kelurahan', icon: Icons.villa_rounded),
                    _editField(ctrl: kecamatanCtrl, label: 'Kecamatan', icon: Icons.map_rounded),
                    _editField(ctrl: kotaCtrl, label: 'Kota / Kabupaten', icon: Icons.location_city_rounded),
                    _editField(ctrl: provinsiCtrl, label: 'Provinsi', icon: Icons.apartment_rounded),
                    _editField(ctrl: kodePosCtrl, label: 'Kode Pos', icon: Icons.local_post_office_rounded),
                  ]),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        _showLocalSnack(ctx, 'Nama Lengkap wajib diisi');
                        return;
                      }
                      if (nipCtrl.text.trim().isEmpty) {
                        _showLocalSnack(ctx, 'NIP wajib diisi');
                        return;
                      }

                      setSheet(() => isSaving = true);
                      final payload = {
                        'id': widget.currentUserData['id'],
                        'name': nameCtrl.text.trim(),
                        'nip': nipCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'no_hp': telpCtrl.text.trim(),
                        'tempat_lahir': tempatLahirCtrl.text.trim(),
                        'tanggal_lahir': tanggalLahirCtrl.text.trim(),
                        'pendidikan': pendidikanCtrl.text.trim(),
                        'jurusan': jurusanCtrl.text.trim(),
                        'alamat': alamatCtrl.text.trim(),
                        'rt_rw': rtRwCtrl.text.trim(),
                        'kelurahan': kelurahanCtrl.text.trim(),
                        'kecamatan': kecamatanCtrl.text.trim(),
                        'kota': kotaCtrl.text.trim(),
                        'provinsi': provinsiCtrl.text.trim(),
                        'kode_pos': kodePosCtrl.text.trim(),
                        'agama': selectedAgama,
                        'jenis_kelamin': selectedGender,
                        'status_nikah': selectedNikah,
                      };

                      final res = await ApiService.updateUser(payload);
                      setSheet(() => isSaving = false);

                      if (res['status'] == 'success') {
                        final Map<String, dynamic> updatedData = {
                          ...widget.currentUserData,
                          ...payload,
                          'no_telp': telpCtrl.text.trim(),
                        };
                        widget.onProfileUpdated(updatedData);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profil berhasil diperbarui')),
                        );
                      } else {
                        _showLocalSnack(ctx, res['message'] ?? 'Gagal memperbarui profil');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade800,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  void _showLocalSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  Widget _editSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      child: Row(children: [
        Container(width: 4, height: 16, color: Colors.indigo.shade800),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo.shade800)),
      ]),
    );
  }

  Widget _editField({required TextEditingController ctrl, required String label, required IconData icon, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCBD5E1))),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint ?? 'Masukkan $label',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(icon, color: Colors.indigo.shade800, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
