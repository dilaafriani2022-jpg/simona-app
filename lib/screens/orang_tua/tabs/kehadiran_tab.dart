import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

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
const Color _slate     = AppColors.slate;

class KehadiranTab extends StatelessWidget {
  final Map<String, dynamic>? selectedAnak;
  final int selectedKehadiranBulan;
  final int selectedKehadiranTahun;
  final Map<String, dynamic> kehadiranStats;
  final List<dynamic> kehadiranList;
  final bool isLoading;
  final VoidCallback onMonthPrev;
  final VoidCallback onMonthNext;
  final VoidCallback onMonthPickerTap;

  const KehadiranTab({
    super.key,
    required this.selectedAnak,
    required this.selectedKehadiranBulan,
    required this.selectedKehadiranTahun,
    required this.kehadiranStats,
    required this.kehadiranList,
    required this.isLoading,
    required this.onMonthPrev,
    required this.onMonthNext,
    required this.onMonthPickerTap,
  });

  String _namaBulan(int b) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (b >= 1 && b <= 12) return months[b - 1];
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        backgroundColor: _orange700,
        automaticallyImplyLeading: false,
        title: const Text('Kehadiran Anak',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildMonthSelectorRow(),
            const SizedBox(height: 16),
            _buildRekapKehadiran(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _kehadiranLegend(_green,  'Hadir'),
                _kehadiranLegend(_rose,   'Alfa'),
                _kehadiranLegend(_amber,  'Izin'),
                _kehadiranLegend(_blue,   'Sakit'),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader('Riwayat Kehadiran', Icons.history_rounded, _orange700),
            const SizedBox(height: 12),
            _buildRiwayatKehadiran(),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildMonthSelectorRow() {
    final namaBulan = _namaBulan(selectedKehadiranBulan);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onMonthPrev,
            icon: const Icon(Icons.chevron_left_rounded, color: _orange700),
            tooltip: 'Bulan Sebelumnya',
          ),
          GestureDetector(
            onTap: onMonthPickerTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: _orange700),
                const SizedBox(width: 8),
                Text(
                  '$namaBulan $selectedKehadiranTahun',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: _orange700),
              ],
            ),
          ),
          IconButton(
            onPressed: onMonthNext,
            icon: const Icon(Icons.chevron_right_rounded, color: _orange700),
            tooltip: 'Bulan Selanjutnya',
          ),
        ],
      ),
    );
  }

  Widget _buildRekapKehadiran() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_orange900, _orange700],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _orange500.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Rekap Kehadiran', style: TextStyle(color: Colors.white70, fontSize: 12)),
        Text('Bulan ${_namaBulan(selectedKehadiranBulan)} $selectedKehadiranTahun', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(children: [
          _rekapBox('${kehadiranStats['Hadir'] ?? 0}', 'Hadir',  Colors.white),
          _rekapSep(),
          _rekapBox('${kehadiranStats['Sakit'] ?? 0}', 'Sakit',  Colors.white),
          _rekapSep(),
          _rekapBox('${kehadiranStats['Izin']  ?? 0}', 'Izin',   Colors.white),
          _rekapSep(),
          _rekapBox('${kehadiranStats['Alpa']  ?? 0}', 'Alfa',   Colors.white),
        ]),
      ]),
    );
  }

  Widget _rekapBox(String val, String label, Color c) => Expanded(child: Column(children: [
    Text(val, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.bold)),
    Text(label, style: TextStyle(color: c.withOpacity(0.7), fontSize: 11)),
  ]));

  Widget _rekapSep() => Container(width: 1, height: 36, color: Colors.white24);

  Widget _kehadiranLegend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 5),
    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
  ]);

  Widget _buildRiwayatKehadiran() {
    if (isLoading) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (kehadiranList.isEmpty) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18)),
        child: const Center(child: Text('Belum ada riwayat kehadiran', style: TextStyle(color: _slate))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(
        children: kehadiranList.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final String status = item['status'] ?? 'Hadir';
          Color statusColor = _green;
          if (status == 'Sakit') statusColor = _blue;
          if (status == 'Izin')  statusColor = _amber;
          if (status == 'Alpa')  statusColor = _rose;

          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                    status == 'Hadir' ? Icons.check_circle_rounded
                        : status == 'Sakit' ? Icons.sick_rounded
                        : status == 'Izin' ? Icons.event_busy_rounded
                        : Icons.cancel_rounded,
                    color: statusColor, size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(item['tanggal'] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(status == 'Alpa' ? 'Alfa' : status,
                      style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            if (i < kehadiranList.length - 1)
              Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
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

