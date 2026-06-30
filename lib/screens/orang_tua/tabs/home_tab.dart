import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

// ── Palette ──────────────────────────────────────────────────
const Color _orange900 = AppColors.orange900;
const Color _orange700 = AppColors.orange700;
const Color _orange500 = AppColors.orange500;
const Color _orange100 = AppColors.orange100;
const Color _surface   = AppColors.surface;
const Color _green     = AppColors.green;
const Color _blue      = AppColors.blue;
const Color _purple    = AppColors.purple;
const Color _rose      = AppColors.rose;
const Color _amber     = AppColors.amber;
const Color _teal      = AppColors.teal;
const Color _slate     = AppColors.slate;
const Color _navy      = AppColors.navy;

class HomeTab extends StatelessWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? selectedAnak;
  final List<dynamic> anakList;
  final Map<String, dynamic> kehadiranStats;
  final List<dynamic> penilaianSummary;
  final List<dynamic> anekdotList;
  final List<dynamic> ekstraList;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onMenuTap;
  final VoidCallback onAnakSwitcherTap;
  final VoidCallback onEkstraTap;
  final VoidCallback onRefleksiTap;

  const HomeTab({
    super.key,
    required this.user,
    required this.selectedAnak,
    required this.anakList,
    required this.kehadiranStats,
    required this.penilaianSummary,
    required this.anekdotList,
    required this.ekstraList,
    required this.isLoading,
    required this.onRefresh,
    required this.onMenuTap,
    required this.onAnakSwitcherTap,
    required this.onEkstraTap,
    required this.onRefleksiTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Hero AppBar ───────────────────────────────────────
        SliverAppBar(
          expandedHeight: 210,
          collapsedHeight: 70,
          pinned: true,
          backgroundColor: _orange700,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _buildHeroBanner(),
          ),
          title: const Text('SiMONA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 1.5)),
          actions: [
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 4),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Kartu Anak Aktif ──────────────────────────
              _buildAnakActiveCard(),
              const SizedBox(height: 20),

              // ── Ringkasan Kehadiran ────────────────────────
              _buildSectionHeader('Kehadiran Bulan Ini', Icons.calendar_month_rounded, _blue),
              const SizedBox(height: 12),
              _buildKehadiranSummaryRow(),
              const SizedBox(height: 22),

              // ── Perkembangan Terbaru ──────────────────────
              _buildSectionHeader('Perkembangan Terbaru', Icons.trending_up_rounded, _green),
              const SizedBox(height: 12),
              _buildPerkembanganCard(),
              const SizedBox(height: 22),

              // ── Menu Cepat ────────────────────────────────
              _buildSectionHeader('Menu', Icons.grid_view_rounded, _orange700),
              const SizedBox(height: 14),
              _buildMenuGrid(),
              const SizedBox(height: 22),

              // ── Anekdot Terbaru ───────────────────────────
              if (anekdotList.isNotEmpty) ...[
                _buildSectionHeader('Catatan Anekdot Terbaru', Icons.notes_rounded, _purple),
                const SizedBox(height: 12),
                _buildAnekdotPreview(),
                const SizedBox(height: 22),
              ],

              // ── Ekstrakurikuler ───────────────────────────
              if (ekstraList.isNotEmpty) ...[
                _buildSectionHeader('Ekstrakurikuler', Icons.sports_rounded, _teal),
                const SizedBox(height: 12),
                _buildEkstraPreview(),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_orange900, _orange700, _orange500],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -30, child: Container(
          width: 160, height: 160,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), shape: BoxShape.circle),
        )),
        Positioned(bottom: 10, right: 40, child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
        )),
        Positioned(
          left: 20, right: 20, bottom: 20,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Selamat Datang,', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(user['name'] ?? 'Orang Tua',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ]),
            const SizedBox(height: 12),
            if (selectedAnak != null)
              Row(children: [
                _heroBadge(Icons.child_care_rounded, selectedAnak!['nama_anak'] ?? ''),
                const SizedBox(width: 8),
                _heroBadge(Icons.meeting_room_rounded, selectedAnak!['nama_kelas'] ?? 'Kelompok'),
              ]),
          ]),
        ),
      ]),
    );
  }

  Widget _heroBadge(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 12),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _buildAnakActiveCard() {
    if (selectedAnak == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _orange100),
        ),
        child: const Center(child: Text('Belum ada anak terhubung', style: TextStyle(color: _slate))),
      );
    }

    final initial = selectedAnak!['nama_anak']?.substring(0, 1).toUpperCase() ?? '?';
    final hasMultiple = anakList.length > 1;

    return GestureDetector(
      onTap: hasMultiple ? onAnakSwitcherTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _orange500.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))],
          border: Border.all(color: _orange100),
        ),
        child: Row(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_orange500, _orange700],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(child: Text(initial,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(selectedAnak!['nama_anak'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Row(children: [
              _infoPill(Icons.fingerprint_rounded, 'NISN: ${selectedAnak!['nisn'] ?? ''}', _orange700),
              const SizedBox(width: 6),
              _infoPill(Icons.meeting_room_rounded, selectedAnak!['nama_kelas'] ?? '', _navy),
            ]),
            const SizedBox(height: 6),
            if (hasMultiple)
              Text('(Ketuk untuk mengganti anak)',
                  style: TextStyle(color: _orange700.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600))
            else
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('Terdaftar aktif', style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
          ])),
          if (hasMultiple)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _orange100, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.swap_horiz_rounded, size: 18, color: _orange700),
            ),
        ]),
      ),
    );
  }

  Widget _infoPill(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _buildKehadiranSummaryRow() {
    final stats = kehadiranStats;
    final data = [
      _StatData('Hadir', '${stats['Hadir'] ?? 0}', Icons.check_circle_rounded, _green),
      _StatData('Sakit', '${stats['Sakit'] ?? 0}', Icons.sick_rounded, _blue),
      _StatData('Izin',  '${stats['Izin']  ?? 0}', Icons.event_busy_rounded,   _amber),
      _StatData('Alfa',  '${stats['Alpa']  ?? 0}', Icons.cancel_rounded,       _rose),
    ];
    return Row(
      children: data.map((s) => Expanded(child: Padding(
        padding: EdgeInsets.only(right: s == data.last ? 0 : 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: s.color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(s.icon, color: s.color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(s.value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: s.color)),
            const SizedBox(height: 2),
            Text(s.label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ]),
        ),
      ))).toList(),
    );
  }

  Widget _buildPerkembanganCard() {
    if (isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (penilaianSummary.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          Icon(Icons.auto_graph_outlined, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text('Belum ada data perkembangan', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Guru belum memasukkan penilaian', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        ]),
      );
    }

    final colors = [_green, _blue, _amber, _purple, _teal, _rose, _orange700];

    return Container(
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(bottom: BorderSide(color: _green.withOpacity(0.1))),
          ),
          child: Row(children: [
            const Text('Rekap Penilaian per Aspek',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
            const Spacer(),
            GestureDetector(
              onTap: () => onMenuTap(1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('Lihat Semua', style: TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: penilaianSummary.asMap().entries.map((e) {
              final i = e.key;
              final aspek = e.value;
              final color = colors[i % colors.length];
              final status = aspek['status_terakhir'] ?? '-';
              final progress = status == 'M' ? 1.0 : status == 'MM' ? 0.55 : 0.2;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  SizedBox(width: 130,
                    child: Text(aspek['nama_aspek'] ?? '-',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)))),
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  )),
                  const SizedBox(width: 10),
                  Container(
                    width: 40, padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _legendItem('TM', Colors.red.shade300),
            _legendItem('MM', _amber),
            _legendItem('M',  _green),
          ]),
        ),
      ]),
    );
  }

  Widget _legendItem(String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
  ]);

  Widget _buildMenuGrid() {
    final menus = [
      _MenuData('Perkembangan',    Icons.auto_graph_rounded,    _green,  () => onMenuTap(1)),
      _MenuData('Kehadiran',       Icons.calendar_month_rounded,_blue,   () => onMenuTap(2)),
      _MenuData('Jadwal',          Icons.schedule_rounded,      _orange700, () => onMenuTap(3)),
      _MenuData('Laporan Anak',    Icons.description_rounded,   _purple, () => onMenuTap(4)),
      _MenuData('Ekstrakurikuler', Icons.sports_rounded,        _teal,   onEkstraTap),
      _MenuData('Refleksi',        Icons.psychology_rounded,    _amber,  onRefleksiTap),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: menus.map((m) => GestureDetector(
        onTap: m.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: m.color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [m.color, m.color.withOpacity(0.75)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(m.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 9),
            Text(m.label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey.shade800),
                textAlign: TextAlign.center),
          ]),
        ),
      )).toList(),
    );
  }

  Widget _buildAnekdotPreview() {
    final preview = anekdotList.take(2).toList();
    return Container(
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        ...preview.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.sticky_note_2_rounded, color: _purple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['aspek_perkembangan'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
                  const SizedBox(height: 3),
                  Text(item['peristiwa'] ?? '-',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(item['tanggal'] ?? '',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ])),
              ]),
            ),
            if (i < preview.length - 1) Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14),
          ]);
        }),
        if (anekdotList.length > 2)
          InkWell(
            onTap: () => onMenuTap(1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border(top: BorderSide(color: _purple.withOpacity(0.1))),
              ),
              child: Text('Lihat semua ${anekdotList.length} catatan',
                  style: const TextStyle(fontSize: 12, color: _purple, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
          ),
      ]),
    );
  }

  Widget _buildEkstraPreview() {
    return Container(
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: ekstraList.take(3).toList().asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.sports_rounded, color: _teal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['nama_ekstrakurikuler'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
                  if ((item['prestasi'] ?? '').toString().isNotEmpty)
                    Text('Prestasi: ${item['prestasi']}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ])),
              ]),
            ),
            if (i < (ekstraList.length > 3 ? 2 : ekstraList.length - 1))
              Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) => Row(children: [
    Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 16),
    ),
    const SizedBox(width: 10),
    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
  ]);
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatData(this.label, this.value, this.icon, this.color);
}

class _MenuData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MenuData(this.label, this.icon, this.color, this.onTap);
}

