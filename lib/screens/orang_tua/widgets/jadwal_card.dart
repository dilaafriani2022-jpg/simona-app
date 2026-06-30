import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class JadwalCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int idx;
  final Color hariColor;
  final int total;

  const JadwalCard({
    super.key,
    required this.item,
    required this.idx,
    required this.hariColor,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final jamMulai   = item['jam_mulai']?.toString() ?? '';
    final jamSelesai = item['jam_selesai']?.toString() ?? '';
    final kegiatan   = item['kegiatan']?.toString() ?? '-';
    final ruangan    = item['ruangan']?.toString() ?? '';
    final namaGuru   = item['nama_guru']?.toString() ?? '';
    final warna      = item['warna']?.toString() ?? '';

    // Parse warna dari DB jika ada, fallback ke hariColor
    Color cardAccent = hariColor;
    if (warna.isNotEmpty) {
      try {
        final hex = warna.startsWith('#') ? warna.substring(1) : warna;
        cardAccent = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }

    // Format jam: "07:30:00" → "07:30"
    String fmtJam(String t) {
      if (t.length >= 5) return t.substring(0, 5);
      return t;
    }

    final isLast = idx == total - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline left
        SizedBox(
          width: 56,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: BoxDecoration(
                color: cardAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(fmtJam(jamMulai),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cardAccent),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 4),
            if (!isLast)
              Container(width: 2, height: 36, color: cardAccent.withOpacity(0.2)),
          ]),
        ),
        const SizedBox(width: 10),
        // Card content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: cardAccent.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
              border: Border(left: BorderSide(color: cardAccent, width: 3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Kegiatan name
                Text(kegiatan,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                // Time & room row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _jadwalPill(Icons.access_time_rounded, '${fmtJam(jamMulai)} – ${fmtJam(jamSelesai)}', cardAccent),
                    if (ruangan.isNotEmpty)
                      _jadwalPill(Icons.room_rounded, ruangan, AppColors.slate),
                    if (namaGuru.isNotEmpty)
                      _jadwalPill(Icons.person_rounded, namaGuru, AppColors.navy),
                  ],
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _jadwalPill(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    ]),
  );
}

