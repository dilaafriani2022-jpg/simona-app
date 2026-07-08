import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../services/api_service.dart';

// ── Palette ──────────────────────────────────────────────────
const Color _orange900 = AppColors.orange900;
const Color _orange700 = AppColors.orange700;
const Color _orange500 = AppColors.orange500;
const Color _surface   = AppColors.surface;
const Color _green     = AppColors.green;
const Color _blue      = AppColors.blue;
const Color _purple    = AppColors.purple;
const Color _rose      = AppColors.rose;
const Color _amber     = AppColors.amber;
const Color _teal      = AppColors.teal;
const Color _slate     = AppColors.slate;

class LaporanTab extends StatelessWidget {
  final Map<String, dynamic>? anak;
  final int selectedBulan;
  final int semester;
  final Map<String, dynamic> narasiData;
  final Map<String, dynamic> kehadiranStats;
  final List<dynamic> ekskulList;
  final List<dynamic> checklistRingkasan;
  final List<dynamic> anekdotList;
  final List<dynamic> karyaList;
  final List<dynamic> rekapKegiatanList;
  final bool isLoading;
  final bool isLoadingMonthlyRecap;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onSemesterSelected;
  final ValueChanged<int> onBulanSelected;

  const LaporanTab({
    super.key,
    required this.anak,
    required this.selectedBulan,
    required this.semester,
    required this.narasiData,
    required this.kehadiranStats,
    required this.ekskulList,
    required this.checklistRingkasan,
    required this.anekdotList,
    required this.karyaList,
    required this.rekapKegiatanList,
    required this.isLoading,
    required this.isLoadingMonthlyRecap,
    required this.onRefresh,
    required this.onSemesterSelected,
    required this.onBulanSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDraft = narasiData['is_draft'] == true || narasiData.isEmpty;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _orange700,
          automaticallyImplyLeading: false,
          title: const Text(
            'Laporan Anak',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_purple, Color(0xFF9333EA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _purple.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rekap Perkembangan',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              anak != null ? 'Anak: ${anak!['nama_anak']}' : 'Pilih anak terlebih dahulu',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (anak == null)
                  _buildEmptyLaporan()
                else ...[
                  // ── Semester Selector ──────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school_rounded, color: _purple, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          'Semester:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: semester,
                              isDense: true,
                              borderRadius: BorderRadius.circular(12),
                              items: const [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('Semester 1 (Ganjil)', style: TextStyle(fontSize: 13)),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('Semester 2 (Genap)', style: TextStyle(fontSize: 13)),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  onSemesterSelected(val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Month Chips ──────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(5, (index) {
                        final bulanIndex = index + 1;
                        final isSelected = selectedBulan == bulanIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              'Bulan $bulanIndex',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : _slate,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: _purple,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? _purple : Colors.grey.shade300,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                onBulanSelected(bulanIndex);
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Detail Cards ──────────────────────────
                  if (isLoadingMonthlyRecap)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    _buildIdentitasCardLaporan(),
                    const SizedBox(height: 14),
                    _buildKehadiranCardLaporan(),
                    const SizedBox(height: 14),

                    if (isDraft) ...[
                      _buildStatusBanner(
                        title: 'Laporan Sedang Dipersiapkan',
                        message: 'Guru kelas belum mempublikasikan narasi laporan perkembangan resmi untuk periode ini. Rekap penilaian di bawah adalah data laporan sementara.',
                        color: _slate,
                        icon: Icons.edit_note_rounded,
                      ),
                      const SizedBox(height: 14),
                    ],

                    _buildAspekCardLaporan(),
                    const SizedBox(height: 14),
                    _buildEkskulCardLaporan(),

                    const SizedBox(height: 20),
                    _buildSectionHeader('Rekap Kegiatan Pembelajaran', Icons.assignment_turned_in_rounded, _orange700),
                    const SizedBox(height: 12),
                    _buildRekapKegiatanCard(),

                    const SizedBox(height: 20),
                    _buildSectionHeader('Ringkasan Checklist', Icons.checklist_rounded, _green),
                    const SizedBox(height: 12),
                    _buildChecklistRingkasan(),
                    const SizedBox(height: 20),
                    _buildAnekdotCardLaporan(),
                    const SizedBox(height: 20),
                    _buildKaryaCardLaporan(),
                  ],

                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color == _amber ? const Color(0xFFB45309) : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLaporan() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(Icons.description_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Belum ada laporan tersedia',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Pilih anak terlebih dahulu untuk melihat laporan',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildIdentitasCardLaporan() {
    final nama = anak?['nama_anak'] ?? '-';
    final nisn = anak?['nisn'] ?? '-';
    final nik = anak?['nik'] ?? '-';
    final jk = (anak?['jenis_kelamin']?.toString() == 'L')
        ? 'Laki-laki'
        : ((anak?['jenis_kelamin']?.toString() == 'P') ? 'Perempuan' : '-');
    final tempat = anak?['tempat_lahir'] ?? '-';
    
    String tglLahir = '';
    final rawTgl = anak?['tanggal_lahir']?.toString() ?? '';
    if (rawTgl.isNotEmpty) {
      try {
        final parsed = DateTime.parse(rawTgl);
        tglLahir = "${parsed.day}-${parsed.month}-${parsed.year}";
      } catch (_) {
        tglLahir = rawTgl;
      }
    }
    final ttl = tglLahir.isNotEmpty ? "$tempat, $tglLahir" : tempat;

    final agama = anak?['agama'] ?? '-';
    final statusAnak = anak?['status_anak'] ?? '-';
    final anakKe = anak?['anak_ke']?.toString() ?? '-';
    
    final bb = (anak?['berat_badan'] != null && anak?['berat_badan'].toString() != 'null')
        ? "${anak!['berat_badan']} kg"
        : '-';
    final tb = (anak?['tinggi_badan'] != null && anak?['tinggi_badan'].toString() != 'null')
        ? "${anak!['tinggi_badan']} cm"
        : '-';
    final alamat = anak?['alamat'] ?? '-';

    final kelas = anak?['nama_kelas'] ?? anak?['kelompok'] ?? '-';
    final namaGuru = (narasiData['nama_guru'] != null && narasiData['nama_guru'] != '-')
        ? narasiData['nama_guru']
        : (anak?['nama_guru'] ?? '-');
    final semLabel = semester == 1 ? 'Ganjil' : 'Genap';
    final tahunAjaran = (narasiData['tahun_ajaran'] != null && narasiData['tahun_ajaran'] != '-')
        ? narasiData['tahun_ajaran']
        : (anak?['tahun'] ?? '-');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_rounded, color: _purple, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Identitas Anak',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.shade100),
          _laporanRow('Nama Lengkap', nama),
          _laporanRow('NISN', nisn),
          _laporanRow('NIK', nik),
          _laporanRow('Jenis Kelamin', jk),
          _laporanRow('Tempat, Tgl Lahir', ttl),
          _laporanRow('Agama', agama),
          _laporanRow('Status Anak', statusAnak),
          _laporanRow('Anak Ke', anakKe),
          _laporanRow('Berat Badan', bb),
          _laporanRow('Tinggi Badan', tb),
          _laporanRow('Kelompok / Kelas', kelas),
          _laporanRow('Tahun Ajaran', tahunAjaran),
          _laporanRow('Semester', semLabel),
          _laporanRow('Guru Kelas', namaGuru),
          _laporanRow('Alamat', alamat),
        ],
      ),
    );
  }

  Widget _laporanRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: _slate, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': ', style: TextStyle(color: _slate, fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspekCardLaporan() {
    final agama = narasiData['narasi_agama'] ?? '-';
    final jatiDiri = narasiData['narasi_jati_diri'] ?? '-';
    final steam = narasiData['narasi_literasi_steam'] ?? '-';
    final hasData = agama != '-' || jatiDiri != '-' || steam != '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_stories_rounded, color: _blue, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Rekap Per Aspek',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.shade100),
          if (!hasData)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Guru belum mengisi narasi untuk bulan ini.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else ...[
            _aspekItemLaporan('Nilai Agama dan Budi Pekerti', agama, _orange700),
            const SizedBox(height: 14),
            _aspekItemLaporan('Jati Diri', jatiDiri, _blue),
            const SizedBox(height: 14),
            _aspekItemLaporan('Dasar Literasi dan STEAM', steam, _green),
          ],
        ],
      ),
    );
  }

  Widget _aspekItemLaporan(String title, String content, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            content,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildKehadiranCardLaporan() {
    final stats = kehadiranStats;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: _green, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Rekap Kehadiran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.shade100),
          Row(
            children: [
              Expanded(child: _kehadiranStatBox('Hadir', '${stats['Hadir'] ?? 0}', _green)),
              const SizedBox(width: 10),
              Expanded(child: _kehadiranStatBox('Sakit', '${stats['Sakit'] ?? 0}', _blue)),
              const SizedBox(width: 10),
              Expanded(child: _kehadiranStatBox('Izin', '${stats['Izin'] ?? 0}', _amber)),
              const SizedBox(width: 10),
              Expanded(child: _kehadiranStatBox('Alpa', '${stats['Alpa'] ?? 0}', _rose)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kehadiranStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Hari',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEkskulCardLaporan() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sports_rounded, color: _amber, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Ekstrakurikuler',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.shade100),
          if (ekskulList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tidak mengikuti kegiatan ekstrakurikuler semester ini.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...ekskulList.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.star_rounded, color: _amber, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['nama_ekstrakurikuler'] ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              fontSize: 13,
                            ),
                          ),
                          if ((e['catatan'] ?? '').toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                e['catatan'].toString(),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.4),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildChecklistRingkasan() {
    if (checklistRingkasan.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18)),
        child: const Center(child: Text('Belum ada data', style: TextStyle(color: _slate))),
      );
    }

    final colors = [_green, _blue, _amber, _purple, _teal, _rose, _orange700];
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          ...checklistRingkasan.asMap().entries.map((e) {
            final i = e.key;
            final aspek = e.value;
            final color = colors[i % colors.length];
            final status = aspek['status_terakhir'] ?? '-';
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          aspek['nama_aspek'] ?? '-',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      _statusBadge(status, color),
                    ],
                  ),
                ),
                if (i < checklistRingkasan.length - 1)
                  Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildRekapKegiatanCard() {
    if (rekapKegiatanList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Belum ada rekap kegiatan',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Guru belum mempublikasikan rekap kegiatan pembelajaran untuk bulan ini.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final statusColors = {
      'M': _green,
      'MM': _blue,
      'TM': _rose,
    };

    final statusLabels = {
      'M': 'Berkembang Sesuai Harapan',
      'MM': 'Mulai Berkembang',
      'TM': 'Belum Berkembang',
    };

    return Column(
      children: rekapKegiatanList.map<Widget>((aspekGroup) {
        final aspekName = aspekGroup['nama_aspek'] ?? '';
        final kegiatanList = aspekGroup['kegiatan'] as List<dynamic>? ?? [];
        final aspekColor = aspekName.toLowerCase().contains('agama') ? _orange700
            : aspekName.toLowerCase().contains('jati') ? _blue
            : aspekName.toLowerCase().contains('literasi') || aspekName.toLowerCase().contains('steam') ? _green
            : _purple;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: aspekColor.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aspek header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: aspekColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(bottom: BorderSide(color: aspekColor.withOpacity(0.12))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: aspekColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.category_rounded, color: aspekColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        aspekName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: aspekColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: aspekColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${kegiatanList.length} kegiatan',
                        style: TextStyle(fontSize: 10, color: aspekColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              // Kegiatan list
              ...kegiatanList.asMap().entries.map<Widget>((entry) {
                final idx = entry.key;
                final item = entry.value;
                final status = item['status_akhir']?.toString() ?? 'TM';
                final statusColor = statusColors[status] ?? _slate;
                final statusLabel = statusLabels[status] ?? status;
                final catatan = item['catatan_perkembangan']?.toString() ?? '';
                final isLast = idx == kegiatanList.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nama_kegiatan'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    if ((item['nama_tujuan'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tujuan: ${item['nama_tujuan']}',
                                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(fontSize: 8, color: statusColor.withOpacity(0.8)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (catatan.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Colors.grey.shade400),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      catatan,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14),
                  ],
                );
              }).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnekdotCardLaporan() {
    final filtered = anekdotList.where((item) {
      final dateStr = item['tanggal']?.toString() ?? '';
      if (dateStr.isEmpty) return false;
      try {
        final parsedDate = DateTime.parse(dateStr);
        final month = parsedDate.month;

        int itemAcademicBulan = 0;
        if (semester == 1) {
          if (month >= 7 && month <= 12) itemAcademicBulan = month - 6;
        } else {
          if (month >= 1 && month <= 6) itemAcademicBulan = month;
        }
        return itemAcademicBulan == selectedBulan;
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
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sticky_note_2_rounded, color: _purple, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Catatan Anekdot Bulan Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.shade100),
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Tidak ada catatan anekdot untuk bulan ini.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic),
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              (item['aspek_perkembangan'] ?? '').toString().trim().isNotEmpty
                                  ? item['aspek_perkembangan']
                                  : 'Catatan Anekdot',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['tanggal'] ?? '',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Peristiwa: ${item['peristiwa'] ?? '-'}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                      ),
                      if ((item['interpretasi'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Interpretasi: ${item['interpretasi']}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                      if ((item['tindak_lanjut'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tindak Lanjut: ${item['tindak_lanjut']}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
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
    final filtered = karyaList.where((item) {
      final dateStr = item['tanggal']?.toString() ?? '';
      if (dateStr.isEmpty) return false;
      try {
        final parsedDate = DateTime.parse(dateStr);
        final month = parsedDate.month;

        int itemAcademicBulan = 0;
        if (semester == 1) {
          if (month >= 7 && month <= 12) itemAcademicBulan = month - 6;
        } else {
          if (month >= 1 && month <= 6) itemAcademicBulan = month;
        }
        return itemAcademicBulan == selectedBulan;
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
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.palette_rounded, color: _teal, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Hasil Karya Bulan Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.shade100),
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Tidak ada hasil karya untuk bulan ini.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic),
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['judul'] ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['tanggal'] ?? '',
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kategori: ${item['kategori'] ?? '-'}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _teal),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['deskripsi'] ?? '-',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((item['bahan'] ?? '').toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Bahan: ${item['bahan']}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                      if ((item['catatan_guru'] ?? '').toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Catatan Guru: ${item['catatan_guru']}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
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
}

