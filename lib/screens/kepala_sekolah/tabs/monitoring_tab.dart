import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../guru/penilaian_checklist_screen.dart';
import '../../guru/anekdot_screen.dart';
import '../../guru/karya_screen.dart';
import '../../guru/rekap_raport_screen.dart';
import '../../guru/jadwal_screen.dart';

class MonitoringTab extends StatefulWidget {
  final bool isLoading;
  final List<dynamic> guruMonitoring;
  final List<dynamic> anakMonitoring;
  final int selectedSemester;
  final Function(int) onSemesterChanged;

  const MonitoringTab({
    super.key,
    required this.isLoading,
    required this.guruMonitoring,
    required this.anakMonitoring,
    required this.selectedSemester,
    required this.onSemesterChanged,
  });

  @override
  State<MonitoringTab> createState() => _MonitoringTabState();
}

class _MonitoringTabState extends State<MonitoringTab> {
  String _selectedClassFilter = 'Semua';
  String _anakSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0.8,
          title: const Text(
            "Hub Monitoring",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Color(0xFF1E1B4B),
            unselectedLabelColor: Color(0xFF94A3B8),
            indicatorColor: Color(0xFFD97706),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: "Guru"),
              Tab(text: "Anak"),
              Tab(text: "Penilaian"),
            ],
          ),
        ),
        body: widget.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildMonitoringGuruTab(),
                  _buildMonitoringAnakTab(),
                  _buildMonitoringPenilaianTab(),
                ],
              ),
      ),
    );
  }

  // ── Monitoring Guru
  Widget _buildMonitoringGuruTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.guruMonitoring.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text("Guru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                Expanded(flex: 2, child: Text("Murid", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text("Penilaian", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)), textAlign: TextAlign.right)),
              ],
            ),
          );
        }

        final g = widget.guruMonitoring[index - 1];
        final String name = g['nama_guru'] ?? '-';
        final int murid = g['student_count'] ?? 0;
        final String status = g['status'] ?? 'Belum';
        final bool raportSiap = g['raport_siap'] == true;
        final bool isDone = status == 'Selesai' || raportSiap;
        final int anakDinilai = g['anak_sudah_dinilai'] ?? 0;
        final int progress = g['progress_percent'] ?? 0;
        final String catatan = g['laporan_catatan'] ?? '';
        final String waktu = g['laporan_waktu'] ?? '';

        // Badge config
        Color badgeColor, badgeBg;
        IconData badgeIcon;
        String badgeLabel;
        if (raportSiap) {
          badgeColor = const Color(0xFF059669);
          badgeBg = const Color(0xFFD1FAE5);
          badgeIcon = Icons.verified_rounded;
          badgeLabel = 'Siap Raport';
        } else if (isDone) {
          badgeColor = const Color(0xFF0891B2);
          badgeBg = const Color(0xFFE0F2FE);
          badgeIcon = Icons.check_circle_rounded;
          badgeLabel = 'Selesai';
        } else {
          badgeColor = const Color(0xFFF59E0B);
          badgeBg = const Color(0xFFFFFBEB);
          badgeIcon = Icons.hourglass_empty_rounded;
          badgeLabel = 'Belum';
        }

        return Card(
          margin: const EdgeInsets.only(top: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: raportSiap ? const Color(0xFF059669).withOpacity(0.4) : const Color(0xFFE2E8F0),
              width: raportSiap ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showTeacherProgressDetail(g),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                        const SizedBox(height: 2),
                        Text(
                          '${g['nama_kelas'] ?? '-'} • $murid anak',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor.withOpacity(0.3))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(badgeIcon, size: 11, color: badgeColor),
                        const SizedBox(width: 4),
                        Text(badgeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(raportSiap
                          ? const Color(0xFF059669)
                          : progress >= 100 ? const Color(0xFF0891B2) : const Color(0xFFF59E0B)),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('$anakDinilai dari $murid anak sudah dinilai',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text('$progress%', style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold,
                        color: raportSiap ? const Color(0xFF059669) : const Color(0xFF64748B))),
                  ]),
                  if (raportSiap && catatan.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6)),
                      child: Row(children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 11, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(catatan, style: const TextStyle(fontSize: 10, color: Color(0xFF059669)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  ],
                  if (raportSiap && waktu.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text('Dilaporkan: $waktu', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTeacherProgressDetail(Map<String, dynamic> guru) {
    final int idKelas = int.tryParse(guru['id_kelas']?.toString() ?? '0') ?? 0;
    final int idGuru = int.tryParse(guru['id_guru']?.toString() ?? '0') ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final progress = guru['progress_percent'] ?? 0;
        final studentCount = guru['student_count'] ?? 0;
        // Pakai anak_sudah_dinilai agar konsisten dengan progress bar
        final anakSudahDinilai = guru['anak_sudah_dinilai'] ?? guru['completed_count'] ?? 0;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              children: [
                // Header
                Text(
                  guru['nama_guru'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  "${guru['nama_kelas'] ?? '-'} • $studentCount Anak",
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500),
                ),
                const Divider(height: 30),
                
                // Progress Bar
                const Text(
                  "Progress Penilaian",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 12,
                          backgroundColor: Colors.blueGrey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      "$progress%",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  anakSudahDinilai >= studentCount && studentCount > 0
                      ? "Semua $studentCount anak telah dinilai (checklist)."
                      : "Telah menilai $anakSudahDinilai dari $studentCount anak (checklist).",
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400),
                ),
                const Divider(height: 30),

                const Text(
                  "Menu Pemantauan Guru (Read-Only)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 12),
                
                _buildMonitoringOptionItem(
                  context,
                  icon: Icons.calendar_today_rounded,
                  title: "Rencana Pembelajaran (RPPH/RPPM)",
                  subtitle: "Pantau rencana harian, kegiatan pembuka, inti, penutup & bahan ajar",
                  color: Colors.orange,
                  onTap: idKelas == 0 ? null : () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JadwalScreen(
                          idGuru: idGuru,
                          idKelas: idKelas,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
                _buildMonitoringOptionItem(
                  context,
                  icon: Icons.playlist_add_check_rounded,
                  title: "Penilaian Checklist",
                  subtitle: "Pantau checklist capaian perkembangan harian, mingguan, bulanan",
                  color: Colors.teal,
                  onTap: idKelas == 0 ? null : () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PenilaianChecklistScreen(
                          idGuru: idGuru,
                          idKelas: idKelas,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
                _buildMonitoringOptionItem(
                  context,
                  icon: Icons.edit_note_rounded,
                  title: "Catatan Anekdot",
                  subtitle: "Pantau catatan peristiwa/kejadian khusus murid kelas ini",
                  color: Colors.purple,
                  onTap: idKelas == 0 ? null : () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnekdotScreen(
                          idGuru: idGuru,
                          idKelas: idKelas,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
                _buildMonitoringOptionItem(
                  context,
                  icon: Icons.palette_rounded,
                  title: "Hasil Karya Anak",
                  subtitle: "Pantau catatan penilaian hasil karya seni & keterampilan murid kelas ini",
                  color: Colors.blue,
                  onTap: idKelas == 0 ? null : () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KaryaScreen(
                          idGuru: idGuru,
                          idKelas: idKelas,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
                _buildMonitoringOptionItem(
                  context,
                  icon: Icons.assignment_rounded,
                  title: "Rapor Bulanan & Semester Kelas",
                  subtitle: "Pantau rekap bulanan & perkembangan rapor semester kelas ini",
                  color: Colors.blueGrey,
                  onTap: idKelas == 0 ? null : () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RekapRaportScreen(
                          idGuru: idGuru,
                          idKelas: idKelas,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Monitoring Anak
  Widget _buildMonitoringAnakTab() {
    final filtered = widget.anakMonitoring.where((s) {
      final name = (s['nama_anak'] ?? '').toString().toLowerCase();
      final matchSearch = name.contains(_anakSearchQuery.toLowerCase()) || 
                          (s['nisn'] ?? '').toString().contains(_anakSearchQuery);
      
      if (_selectedClassFilter == 'Semua') return matchSearch;
      return matchSearch && s['nama_kelas'] == _selectedClassFilter;
    }).toList();

    // Generate unique classes dynamically
    final uniqueClasses = widget.anakMonitoring
        .map((s) => s['nama_kelas']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    uniqueClasses.sort();
    final classesList = ['Semua'] + uniqueClasses;

    return Column(
      children: [
        // Class & Search controls
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              TextField(
                onChanged: (val) => setState(() => _anakSearchQuery = val),
                decoration: InputDecoration(
                  hintText: "Cari nama atau NISN...",
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.blueGrey.shade400, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.indigo.shade400, width: 1.5)),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: classesList.map((cls) {
                    final isSel = _selectedClassFilter == cls;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cls, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        selectedColor: Colors.indigo.shade800,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : Colors.blueGrey.shade600,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedClassFilter = cls);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        
        // List Anak
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text("Anak tidak ditemukan", style: TextStyle(color: Colors.blueGrey.shade400)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    final name = s['nama_anak'] ?? '-';
                    final rating = s['rating'] ?? '-';
                    final kelas = s['nama_kelas'] ?? '-';

                    Color badgeColor = Colors.grey.shade600;
                    Color badgeBg = Colors.grey.shade50;
                    String ratingLabel = rating;
                    
                    if (rating == 'M' || rating == 'BSH' || rating == 'BSB') {
                      badgeColor = const Color(0xFF059669);
                      badgeBg = const Color(0xFFD1FAE5);
                      ratingLabel = 'M';
                    } else if (rating == 'MM' || rating == 'MB') {
                      badgeColor = const Color(0xFFF59E0B);
                      badgeBg = const Color(0xFFFFFBEB);
                      ratingLabel = 'MM';
                    } else if (rating == 'TM' || rating == 'BB') {
                      badgeColor = const Color(0xFFDC2626);
                      badgeBg = const Color(0xFFFEF2F2);
                      ratingLabel = 'TM';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showChildMonitoringOptions(s),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    kelas,
                                    style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  ratingLabel,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showChildMonitoringOptions(Map<String, dynamic> anak) {
    final int idKelas = int.tryParse(anak['id_kelas']?.toString() ?? '0') ?? 0;
    final String namaAnak = anak['nama_anak'] ?? '';
    final String namaKelas = anak['nama_kelas'] ?? '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  namaAnak,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  "Kelas: $namaKelas",
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500),
                ),
                const Divider(height: 30),
                const Text(
                  "Menu Pemantauan Murid (Read-Only)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 12),
                
                _buildMonitoringOptionItem(
                  context,
                  icon: Icons.playlist_add_check_rounded,
                  title: "Penilaian Checklist",
                  subtitle: "Pantau checklist capaian perkembangan harian, mingguan, bulanan kelas",
                  color: Colors.teal,
                  onTap: idKelas == 0 ? null : () {
                    Navigator.pop(ctx);
                    final int idGuru = int.tryParse(anak['id_guru']?.toString() ?? '0') ?? 0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PenilaianChecklistScreen(
                          idGuru: idGuru,
                          idKelas: idKelas,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
                _buildMonitoringOptionItem(
                  context,
                  icon: Icons.edit_note_rounded,
                  title: "Catatan Anekdot",
                  subtitle: "Pantau catatan peristiwa/kejadian khusus murid di kelas",
                  color: Colors.purple,
                  onTap: idKelas == 0 ? null : () {
                    Navigator.pop(ctx);
                    final int idGuru = int.tryParse(anak['id_guru']?.toString() ?? '0') ?? 0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnekdotScreen(
                          idGuru: idGuru,
                          idKelas: idKelas,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
                _buildMonitoringOptionItem(
                  context,
                  icon: Icons.palette_rounded,
                  title: "Hasil Karya Anak",
                  subtitle: "Pantau catatan penilaian hasil karya seni & keterampilan kelas",
                  color: Colors.blue,
                  onTap: idKelas == 0 ? null : () {
                    Navigator.pop(ctx);
                    final int idGuru = int.tryParse(anak['id_guru']?.toString() ?? '0') ?? 0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KaryaScreen(
                          idGuru: idGuru,
                          idKelas: idKelas,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
                _buildMonitoringOptionItem(
                  context,
                  icon: Icons.assignment_rounded,
                  title: "Rapor Bulanan & Semester Anak",
                  subtitle: "Pantau rekap bulanan & perkembangan rapor semester murid ini",
                  color: Colors.blueGrey,
                  onTap: idKelas == 0 ? null : () {
                    Navigator.pop(ctx);
                    final int idGuru = int.tryParse(anak['id_guru']?.toString() ?? '0') ?? 0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RekapRaportDetailScreen(
                          anak: anak,
                          idKelas: idKelas,
                          idGuru: idGuru,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonitoringOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final bool disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  // ── Monitoring Penilaian
  Widget _buildMonitoringPenilaianTab() {
    return Column(
      children: [
        // Semester Selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text("Semester: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Semester Ganjil", style: TextStyle(fontSize: 11)),
                selected: widget.selectedSemester == 1,
                selectedColor: Colors.indigo.shade800,
                labelStyle: TextStyle(color: widget.selectedSemester == 1 ? Colors.white : Colors.blueGrey.shade600),
                onSelected: (val) {
                  if (val) {
                    widget.onSemesterChanged(1);
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Semester Genap", style: TextStyle(fontSize: 11)),
                selected: widget.selectedSemester == 2,
                selectedColor: Colors.indigo.shade800,
                labelStyle: TextStyle(color: widget.selectedSemester == 2 ? Colors.white : Colors.blueGrey.shade600),
                onSelected: (val) {
                  if (val) {
                    widget.onSemesterChanged(2);
                  }
                },
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.guruMonitoring.length,
            itemBuilder: (context, index) {
              final g = widget.guruMonitoring[index];
              final String name = g['nama_guru'] ?? '-';
              final progress = g['progress_percent'] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showTeacherProgressDetail(g),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                            Text(
                              "$progress%",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo.shade800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 8,
                            backgroundColor: Colors.blueGrey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
