import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Widget profil sekolah yang bisa digunakan oleh semua role (guru, ortu, kepsek).
class ProfilSekolahScreen extends StatefulWidget {
  /// Warna aksen sesuai tema role (hijau=guru, oranye=ortu, indigo=kepsek)
  final Color primaryColor;

  const ProfilSekolahScreen({
    super.key,
    this.primaryColor = const Color(0xFF15803D),
  });

  @override
  State<ProfilSekolahScreen> createState() => _ProfilSekolahScreenState();
}

class _ProfilSekolahScreenState extends State<ProfilSekolahScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await ApiService.fetch('manage_sekolah.php');
      if (res['status'] == 'success') {
        setState(() { _data = Map<String, dynamic>.from(res['data'] ?? {}); });
      } else {
        setState(() { _error = res['message'] ?? 'Data tidak ditemukan'; });
      }
    } catch (e) {
      setState(() { _error = 'Gagal memuat profil sekolah: $e'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor;
    final dark = HSLColor.fromColor(primary).withLightness(
      (HSLColor.fromColor(primary).lightness - 0.15).clamp(0.0, 1.0)).toColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : _error != null
              ? _buildError(primary)
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(primary, dark),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                        child: _buildContent(primary),
                      ),
                    ),
                  ],
                ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar(Color primary, Color dark) {
    final s      = _data!;
    final nama   = s['nama_sekolah'] ?? 'Profil Sekolah';
    final npsn   = s['npsn']         ?? '';
    final status = s['status']       ?? '';
    final jenjang= s['jenjang']      ?? '';

    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      backgroundColor: primary,
      elevation: 0,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context))
          : null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [dark, primary],
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Stack(children: [
            Positioned(top: -20, right: -20,
              child: Container(width: 140, height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle))),
            Positioned(bottom: -30, left: 40,
              child: Container(width: 90, height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.school_rounded, size: 38, color: Colors.white)),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(nama,
                      style: const TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.bold, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if (npsn.isNotEmpty)    _heroBadge('NPSN: $npsn'),
                      if (jenjang.isNotEmpty) _heroBadge(jenjang),
                      if (status.isNotEmpty)  _heroBadge(status),
                    ]),
                  ])),
              ])),
          ]),
        ),
      ),
      title: const Text('Profil Sekolah',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17)),
    );
  }

  Widget _heroBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20)),
    child: Text(label,
      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)));

  // ─── Content ─────────────────────────────────────────────────────────────
  Widget _buildContent(Color primary) {
    final s = _data!;
    final parts = [
      s['alamat'], s['kelurahan'], s['kecamatan'],
      s['kabupaten'], s['provinsi'],
      if ((s['kode_pos'] ?? '').toString().isNotEmpty) 'Kode Pos: ${s['kode_pos']}',
    ].where((v) => v != null && v.toString().trim().isNotEmpty).toList();
    final alamatLengkap = parts.join(', ');

    final jumlahAnak = s['jumlah_anak'] ?? 0;
    final jumlahGuru = s['jumlah_guru'] ?? 0;
    final jumlahOrtu = s['jumlah_ortu'] ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Stat cards
      Row(children: [
        Expanded(child: _statCard('$jumlahAnak', 'Anak Didik',
          Icons.child_care_rounded, const Color(0xFF0891B2))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('$jumlahGuru', 'Guru',
          Icons.school_rounded, const Color(0xFF7C3AED))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('$jumlahOrtu', 'Orang Tua',
          Icons.family_restroom_rounded, const Color(0xFFEA580C))),
      ]),
      const SizedBox(height: 20),

      // Identitas
      _section('Identitas Sekolah', Icons.info_rounded, primary, [
        _row(Icons.badge_rounded,           'Nama Sekolah',  s['nama_sekolah']  ?? '-'),
        _row(Icons.pin_rounded,             'NPSN',          s['npsn']          ?? '-'),
        _row(Icons.account_balance_rounded, 'Jenjang',       s['jenjang']       ?? '-'),
        _row(Icons.verified_rounded,        'Status',        s['status']        ?? '-'),
        _row(Icons.star_rounded,            'Akreditasi',    s['akreditasi']    ?? '-'),
        _row(Icons.calendar_today_rounded,  'Tahun Berdiri', s['tahun_berdiri'] ?? '-', isLast: true),
      ]),
      const SizedBox(height: 16),

      // Kontak & Lokasi
      _section('Kontak & Lokasi', Icons.location_on_rounded, const Color(0xFF0891B2), [
        if (alamatLengkap.isNotEmpty)
          _row(Icons.home_rounded, 'Alamat Lengkap', alamatLengkap),
        _row(Icons.phone_rounded,   'No. Telepon', s['no_telp'] ?? '-'),
        _row(Icons.email_rounded,   'Email',       s['email']   ?? '-'),
        _row(Icons.language_rounded,'Website',     s['website'] ?? '-', isLast: true),
      ]),
      const SizedBox(height: 16),

      // Pengelola
      _section('Pengelola Sekolah', Icons.manage_accounts_rounded, const Color(0xFF7C3AED), [
        _row(Icons.person_rounded, 'Kepala Sekolah', s['kepala_sekolah'] ?? '-'),
        _row(Icons.badge_rounded, 'NIP Kepala Sekolah', s['nip_kepala_sekolah'] ?? '-'),
        _row(Icons.person_outline, 'Nama Operator',  s['operator_nama']  ?? '-', isLast: true),
      ]),
      const SizedBox(height: 16),

      // Visi
      if ((s['visi'] ?? '').toString().trim().isNotEmpty) ...[
        _section('Visi', Icons.visibility_rounded, const Color(0xFF059669), [
          _textBlock(s['visi'].toString()),
        ]),
        const SizedBox(height: 16),
      ],

      // Misi
      if ((s['misi'] ?? '').toString().trim().isNotEmpty) ...[
        _section('Misi', Icons.flag_rounded, const Color(0xFFF59E0B), [
          _textBlock(s['misi'].toString()),
        ]),
        const SizedBox(height: 16),
      ],
    ]);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  Widget _statCard(String value, String label, IconData icon, Color color) =>
    Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(
          color: color.withValues(alpha: 0.08), blurRadius: 8,
          offset: const Offset(0, 3))]),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center),
      ]));

  Widget _section(String title, IconData icon, Color color, List<Widget> children) =>
    Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.1)))),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16)),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ])),
        ...children,
      ]));

  Widget _row(IconData icon, String label, String value, {bool isLast = false}) =>
    Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(
              fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value.isEmpty ? '-' : value, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          ])),
        ])),
      if (!isLast) Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
    ]);

  Widget _textBlock(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    child: Text(text, style: const TextStyle(
      fontSize: 13, color: Color(0xFF334155), height: 1.6)));

  Widget _buildError(Color primary) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(_error ?? 'Terjadi kesalahan',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Coba Lagi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary, foregroundColor: Colors.white)),
      ])));
}

