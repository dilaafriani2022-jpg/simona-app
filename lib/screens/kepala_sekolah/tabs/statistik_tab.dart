import 'package:flutter/material.dart';

class StatistikTab extends StatelessWidget {
  final Map<String, dynamic> aspekStats;
  final Map<String, dynamic> absensiStats;

  const StatistikTab({
    super.key,
    required this.aspekStats,
    required this.absensiStats,
  });

  @override
  Widget build(BuildContext context) {
    final int agama = aspekStats['agama'] ?? 0;
    final int jati = aspekStats['jati_diri'] ?? 0;
    final int steam = aspekStats['steam'] ?? 0;
    
    // Absensi
    final int hadir = absensiStats['hadir'] ?? 0;
    final int sakit = absensiStats['sakit'] ?? 0;
    final int izin = absensiStats['izin'] ?? 0;
    final int alpa = absensiStats['alpa'] ?? 0;
    final int totalAbsen = hadir + sakit + izin + alpa;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Statistik Sekolah",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),

          // Perkembangan Aspek Anak
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 10,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "📈 Perkembangan Aspek Anak",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                const Divider(height: 24),
                _buildAspectStatBar("Perkembangan Anak (Rata-rata)", ((agama + jati + steam) / 3).round(), Colors.indigo),
                const SizedBox(height: 16),
                _buildAspectStatBar("Nilai Agama dan Budi Pekerti", agama, Colors.green),
                const SizedBox(height: 16),
                _buildAspectStatBar("Jati Diri", jati, Colors.blue),
                const SizedBox(height: 16),
                _buildAspectStatBar("Dasar Literasi & STEAM", steam, Colors.purple),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Kehadiran Anak
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 10,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "📅 Statistik Kehadiran Anak",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                const Divider(height: 24),
                _buildAbsensiProgress("Hadir", hadir, totalAbsen, Colors.green),
                const SizedBox(height: 12),
                _buildAbsensiProgress("Sakit", sakit, totalAbsen, Colors.blue),
                const SizedBox(height: 12),
                _buildAbsensiProgress("Izin", izin, totalAbsen, Colors.amber),
                const SizedBox(height: 12),
                _buildAbsensiProgress("Alpa", alpa, totalAbsen, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectStatBar(String title, int count, Color color) {
    // scale to max 100 for display
    final double value = (count / 100).clamp(0.05, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF475569)),
            ),
            Text(
              "$count Skor",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: Colors.blueGrey.shade50,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildAbsensiProgress(String label, int count, int total, Color color) {
    final double pct = total > 0 ? (count / total) : 0.0;
    final int pctInt = (pct * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
            ),
            Text(
              "$count Hari ($pctInt%)",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.blueGrey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
