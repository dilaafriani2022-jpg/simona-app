import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/school_profile_model.dart';
import '../../utils/responsive.dart';

class ManageSekolahScreen extends StatefulWidget {
  const ManageSekolahScreen({super.key});

  @override
  State<ManageSekolahScreen> createState() => _ManageSekolahScreenState();
}

class _ManageSekolahScreenState extends State<ManageSekolahScreen> {
  bool _isLoading = true;
  bool _saving = false;
  SchoolProfile? _profile;

  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _teleponController = TextEditingController();
  final _emailController = TextEditingController();
  final _kepalaController = TextEditingController();
  final _visiController = TextEditingController();
  final _misiController = TextEditingController();
  final _logoController = TextEditingController();
  final _tahunController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getSchoolProfile();
    if (res['status'] == 'success' && res['data'] != null) {
      final p = SchoolProfile.fromJson(Map<String, dynamic>.from(res['data']));
      setState(() {
        _profile = p;
        _namaController.text = p.namaSekolah;
        _alamatController.text = p.alamat ?? '';
        _teleponController.text = p.telepon ?? '';
        _emailController.text = p.email ?? '';
        _kepalaController.text = p.kepalaSekol ?? '';
        _visiController.text = p.visi ?? '';
        _misiController.text = p.misi ?? '';
        _logoController.text = p.logoUrl ?? '';
        _tahunController.text = p.tahunBerdiri?.toString() ?? '';
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (_namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama sekolah wajib diisi')));
      return;
    }

    setState(() => _saving = true);

    final payload = {
      'nama_sekolah': _namaController.text.trim(),
      'alamat': _alamatController.text.trim(),
      'telepon': _teleponController.text.trim(),
      'email': _emailController.text.trim(),
      'kepala_sekolah': _kepalaController.text.trim(),
      'visi': _visiController.text.trim(),
      'misi': _misiController.text.trim(),
      'logo_url': _logoController.text.trim(),
      'tahun_berdiri': _tahunController.text.trim(),
    };

    final res = _profile == null
        ? await ApiService.createSchoolProfile(payload)
        : await ApiService.updateSchoolProfile(payload);

    setState(() => _saving = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil sekolah berhasil disimpan')));
      _fetch();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan')));
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    _kepalaController.dispose();
    _visiController.dispose();
    _misiController.dispose();
    _logoController.dispose();
    _tahunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Sekolah', style: TextStyle(fontSize: context.fontSize(base: 18, mobile: 16), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.05, vertical: context.spacing),
              child: Column(
                children: [
                  if (_logoController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 32, backgroundImage: NetworkImage(_logoController.text)),
                          SizedBox(width: context.spacing),
                          Expanded(child: Text(_namaController.text, style: TextStyle(fontSize: context.fontSize(base: 18, mobile: 16), fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                  SizedBox(height: context.spacing),

                  TextField(controller: _namaController, decoration: const InputDecoration(labelText: 'Nama Sekolah')),
                  SizedBox(height: context.isSmall ? 10 : 14),
                  TextField(controller: _alamatController, maxLines: 2, decoration: const InputDecoration(labelText: 'Alamat')),
                  SizedBox(height: context.isSmall ? 10 : 14),
                  TextField(controller: _teleponController, decoration: const InputDecoration(labelText: 'Telepon')),
                  SizedBox(height: context.isSmall ? 10 : 14),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                  SizedBox(height: context.isSmall ? 10 : 14),
                  TextField(controller: _kepalaController, decoration: const InputDecoration(labelText: 'Kepala Sekolah')),
                  SizedBox(height: context.isSmall ? 10 : 14),
                  TextField(controller: _visiController, maxLines: 3, decoration: const InputDecoration(labelText: 'Visi')),
                  SizedBox(height: context.isSmall ? 10 : 14),
                  TextField(controller: _misiController, maxLines: 3, decoration: const InputDecoration(labelText: 'Misi')),
                  SizedBox(height: context.isSmall ? 10 : 14),
                  TextField(controller: _logoController, decoration: const InputDecoration(labelText: 'Logo URL')),
                  SizedBox(height: context.isSmall ? 10 : 14),
                  TextField(controller: _tahunController, decoration: const InputDecoration(labelText: 'Tahun Berdiri')),

                  SizedBox(height: context.spacing * 1.5),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: _isLoading ? null : () => _fetch(), child: const Text('Batal')),
                      ),
                      SizedBox(width: context.isSmall ? 8 : 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
                          child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

