import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class EditSchoolProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  const EditSchoolProfileScreen({super.key, required this.profileData});

  @override
  State<EditSchoolProfileScreen> createState() =>
      _EditSchoolProfileScreenState();
}

class _EditSchoolProfileScreenState extends State<EditSchoolProfileScreen> {
  static const Color primaryColor = Color(0xFFC17B2F);
  static const Color scaffoldBg   = Color(0xFFFDF8F3);
  static const Color cardBorder   = Color(0xFFF0E8DF);

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controller untuk setiap field
  late final Map<String, TextEditingController> _ctrl;

  @override
  void initState() {
    super.initState();
    // Isi controller dengan data yang sudah ada
    _ctrl = {
      'nama_sekolah'   : TextEditingController(text: widget.profileData['nama_sekolah']   ?? ''),
      'npsn'           : TextEditingController(text: widget.profileData['npsn']            ?? ''),
      'jenjang'        : TextEditingController(text: widget.profileData['jenjang']         ?? ''),
      'status'         : TextEditingController(text: widget.profileData['status']          ?? ''),
      'alamat'         : TextEditingController(text: widget.profileData['alamat']          ?? ''),
      'kelurahan'      : TextEditingController(text: widget.profileData['kelurahan']       ?? ''),
      'kecamatan'      : TextEditingController(text: widget.profileData['kecamatan']       ?? ''),
      'kabupaten'      : TextEditingController(text: widget.profileData['kabupaten']       ?? ''),
      'provinsi'       : TextEditingController(text: widget.profileData['provinsi']        ?? ''),
      'kode_pos'       : TextEditingController(text: widget.profileData['kode_pos']        ?? ''),
      'no_telp'        : TextEditingController(text: widget.profileData['no_telp']         ?? ''),
      'email'          : TextEditingController(text: widget.profileData['email']           ?? ''),
      'website'        : TextEditingController(text: widget.profileData['website']         ?? ''),
      'kepala_sekolah' : TextEditingController(text: widget.profileData['kepala_sekolah']  ?? ''),
      'nip_kepala_sekolah' : TextEditingController(text: widget.profileData['nip_kepala_sekolah'] ?? ''),
      'operator_nama'  : TextEditingController(text: widget.profileData['operator_nama']   ?? ''),
      'tahun_berdiri'  : TextEditingController(text: widget.profileData['tahun_berdiri']   ?? ''),
      'akreditasi'     : TextEditingController(text: widget.profileData['akreditasi']      ?? ''),
      'visi'           : TextEditingController(text: widget.profileData['visi']            ?? ''),
      'misi'           : TextEditingController(text: widget.profileData['misi']            ?? ''),
    };
  }

  @override
  void dispose() {
    _ctrl.forEach((_, c) => c.dispose());
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Kumpulkan semua nilai dari controller
    final data = _ctrl.map((key, ctrl) => MapEntry(key, ctrl.text.trim()));

    final result = await ApiService.updateSchoolProfile(data);

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil sekolah berhasil diperbarui"),
          backgroundColor: Colors.green,
        ),
      );
      // Kirim sinyal "true" ke halaman sebelumnya agar reload data
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.height < 680;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          "Edit Profil Sekolah",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          // Tombol simpan di AppBar
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Simpan",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 14 : 18),
          child: Column(
            children: [
              _buildFormSection(
                title: "Identitas Sekolah",
                icon: Icons.account_balance_rounded,
                isSmall: isSmall,
                children: [
                  _buildField("Nama Sekolah",  'nama_sekolah',   required: true),
                  _buildField("NPSN",          'npsn'),
                  _buildField("Jenjang",       'jenjang'),
                  _buildField("Status",        'status'),
                  _buildField("Akreditasi",    'akreditasi'),
                  _buildField("Tahun Berdiri", 'tahun_berdiri'),
                ],
              ),

              SizedBox(height: isSmall ? 14 : 18),

              _buildFormSection(
                title: "Kontak",
                icon: Icons.contact_phone_rounded,
                isSmall: isSmall,
                children: [
                  _buildField("No. Telepon", 'no_telp',  keyboardType: TextInputType.phone),
                  _buildField("Email",       'email',    keyboardType: TextInputType.emailAddress),
                  _buildField("Website",     'website'),
                ],
              ),

              SizedBox(height: isSmall ? 14 : 18),

              _buildFormSection(
                title: "Alamat",
                icon: Icons.location_on_rounded,
                isSmall: isSmall,
                children: [
                  _buildField("Alamat Jalan", 'alamat',    maxLines: 2),
                  _buildField("Kelurahan",    'kelurahan'),
                  _buildField("Kecamatan",    'kecamatan'),
                  _buildField("Kabupaten",    'kabupaten'),
                  _buildField("Provinsi",     'provinsi'),
                  _buildField("Kode Pos",     'kode_pos',  keyboardType: TextInputType.number),
                ],
              ),

              SizedBox(height: isSmall ? 14 : 18),

              _buildFormSection(
                title: "SDM",
                icon: Icons.people_rounded,
                isSmall: isSmall,
                children: [
                  _buildField("Kepala Sekolah",   'kepala_sekolah'),
                  _buildField("NIP Kepala Sekolah", 'nip_kepala_sekolah'),
                  _buildField("Operator Sekolah", 'operator_nama'),
                ],
              ),

              SizedBox(height: isSmall ? 14 : 18),

              _buildFormSection(
                title: "Visi & Misi",
                icon: Icons.remove_red_eye_rounded,
                isSmall: isSmall,
                children: [
                  _buildField("Visi", 'visi', maxLines: 4),
                  _buildField("Misi", 'misi', maxLines: 6),
                ],
              ),

              SizedBox(height: isSmall ? 20 : 28),

              // Tombol simpan di bawah
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded, color: Colors.white),
                  label: Text(
                    _isSaving ? "Menyimpan..." : "Simpan Perubahan",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: isSmall ? 16 : 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form Section Container ───────────────────────────────────────────────────
  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required bool isSmall,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 14 : 18,
              vertical: isSmall ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: cardBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmall ? 14 : 18),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ── Field Input ──────────────────────────────────────────────────────────────
  Widget _buildField(
    String label,
    String key, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              if (required)
                const Text(
                  " *",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _ctrl[key],
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(fontSize: 13),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? '$label tidak boleh kosong'
                    : null
                : null,
            decoration: InputDecoration(
              hintText: "Masukkan $label",
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
