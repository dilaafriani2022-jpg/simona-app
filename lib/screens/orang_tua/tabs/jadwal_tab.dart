import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../widgets/jadwal_card.dart';

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

class JadwalTab extends StatelessWidget {
  final Map<String, dynamic>? selectedAnak;
  final List<dynamic> jadwalList;
  final String selectedHariJadwal;
  final bool isLoadingJadwal;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onHariSelected;

  const JadwalTab({
    super.key,
    required this.selectedAnak,
    required this.jadwalList,
    required this.selectedHariJadwal,
    required this.isLoadingJadwal,
    required this.onRefresh,
    required this.onHariSelected,
  });

  @override
  Widget build(BuildContext context) {
    const hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final jadwalHariIni = jadwalList
        .where((j) => j['hari']?.toString() == selectedHariJadwal)
        .toList()
      ..sort((a, b) {
        final ta = a['jam_mulai']?.toString() ?? '';
        final tb = b['jam_mulai']?.toString() ?? '';
        return ta.compareTo(tb);
      });

    // Warna per hari
    final hariColors = {
      'Senin':  _blue,
      'Selasa': _green,
      'Rabu':   _purple,
      'Kamis':  _amber,
      'Jumat':  _rose,
      'Sabtu':  _teal,
    };

    final activeColor = hariColors[selectedHariJadwal] ?? _orange700;

    return CustomScrollView(
      slivers: [
        // ── App Bar ─────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          expandedHeight: 140,
          backgroundColor: _orange700,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_orange900, _orange700, _orange500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                Positioned(top: -20, right: -20, child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), shape: BoxShape.circle),
                )),
                Positioned(bottom: 20, left: 20,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Jadwal Belajar', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        if (selectedAnak != null)
                          Text('${selectedAnak!['nama_anak']} • ${selectedAnak!['nama_kelas'] ?? ''}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text('${jadwalList.length} Kegiatan',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
          actions: [
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Refresh Jadwal',
            ),
          ],
        ),

        // ── Hari Chip Tabs ───────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverPinnedHeader(
            child: Container(
              color: _surface,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: hariList.map((hari) {
                    final isActive = hari == selectedHariJadwal;
                    final hColor = hariColors[hari] ?? _orange700;
                    final count = jadwalList.where((j) => j['hari']?.toString() == hari).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => onHariSelected(hari),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? hColor : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: isActive
                                ? [BoxShadow(color: hColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                : [],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(hari,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  color: isActive ? Colors.white : Colors.grey.shade600,
                                )),
                            if (count > 0) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.white.withOpacity(0.25) : hColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('$count',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? Colors.white : hColor,
                                    )),
                              ),
                            ],
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),

        // ── Content ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: isLoadingJadwal
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : selectedAnak == null
                    ? _buildJadwalEmpty('Pilih anak terlebih dahulu', Icons.child_care_rounded)
                    : jadwalHariIni.isEmpty
                        ? _buildJadwalEmpty('Tidak ada jadwal untuk hari $selectedHariJadwal', Icons.event_busy_rounded)
                        : Column(
                            children: [
                              // Timeline header
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: activeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.today_rounded, size: 14, color: activeColor),
                                      const SizedBox(width: 5),
                                      Text(selectedHariJadwal,
                                          style: TextStyle(color: activeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 5),
                                      Text('• ${jadwalHariIni.length} sesi',
                                          style: TextStyle(color: activeColor.withOpacity(0.7), fontSize: 11)),
                                    ]),
                                  ),
                                ]),
                              ),

                              ...jadwalHariIni.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                return JadwalCard(
                                  item: item,
                                  idx: idx,
                                  hariColor: activeColor,
                                  total: jadwalHariIni.length,
                                );
                              }),
                            ],
                          ),
          ),
        ),
      ],
    );
  }

  Widget _buildJadwalEmpty(String msg, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: _orange100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: _orange500.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(msg,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Jadwal akan muncul jika guru sudah mengatur jadwal kelas',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ── Sliver Pinned Header (untuk tab hari jadwal) ─────────────────────────────
class _SliverPinnedHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _SliverPinnedHeader({required this.child});

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_SliverPinnedHeader old) => old.child != child;
}

