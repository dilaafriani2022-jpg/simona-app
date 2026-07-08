import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class ChecklistCard extends StatelessWidget {
  final dynamic item;

  const ChecklistCard({super.key, required this.item});

  String _getShortAspekName(String fullName) {
    if (fullName.contains('Agama')) {
      return 'Agama & Budi Pekerti';
    } else if (fullName.contains('Literasi') || fullName.contains('STEAM') || fullName.contains('Sains') || fullName.contains('Matematika')) {
      return 'Literasi & STEAM';
    } else if (fullName.contains('Jati Diri')) {
      return 'Jati Diri';
    }
    return fullName;
  }

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? 'TM';
    Color statusColor;
    String emoji;
    if (status == 'M') {
      statusColor = AppColors.green;
      emoji = '🌟';
    } else if (status == 'MM') {
      statusColor = AppColors.amber;
      emoji = '🌱';
    } else {
      statusColor = AppColors.rose;
      emoji = '🚨';
    }

    final aspek = item['nama_aspek'] ?? 'Lainnya';
    final shortAspek = _getShortAspekName(aspek);

    return GestureDetector(
      onTap: () => _showChecklistDetailSheet(context, statusColor, emoji),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: statusColor, width: 5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            shortAspek,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // Container grey box containing Tujuan, Kegiatan, and Catatan
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tujuan Pembelajaran Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.gps_fixed_rounded, size: 13, color: Color(0xFF8B5E3C)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: RichText(
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF334155),
                                          height: 1.35,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: 'Tujuan: ',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                          ),
                                          TextSpan(text: item['nama_tujuan']?.toString() ?? '-'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Kegiatan Pembelajaran Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.play_lesson_rounded, size: 13, color: AppColors.orange700),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: RichText(
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF334155),
                                          height: 1.35,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: 'Kegiatan: ',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                          ),
                                          TextSpan(text: item['nama_kegiatan']?.toString() ?? '-'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Catatan Pembelajaran Row (if not empty)
                              Builder(builder: (context) {
                                final catatan = item['catatan']?.toString().trim() ?? '';
                                if (catatan.isEmpty) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.comment_rounded, size: 13, color: AppColors.slate),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: RichText(
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF475569),
                                              height: 1.35,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: 'Catatan Pembelajaran: ',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                              ),
                                              TextSpan(text: catatan),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showChecklistDetailSheet(BuildContext context, Color statusColor, String emoji) {
    final status = item['status']?.toString() ?? 'TM';
    String statusLabel;
    if (status == 'M') {
      statusLabel = 'Sudah Muncul';
    } else if (status == 'MM') {
      statusLabel = 'Mulai Muncul';
    } else {
      statusLabel = 'Belum Muncul';
    }

    final aspek = item['nama_aspek'] ?? 'Lainnya';
    final tanggal = item['tanggal'] ?? '-';
    final semester = item['semester'] ?? '1';
    final mingguKe = item['minggu_ke'] ?? '-';
    final namaGuru = item['nama_guru'] ?? '-';
    final konteks = item['konteks'] ?? '';
    final hasil = item['hasil'] ?? '';
    final kejadian = item['kejadian'] ?? '';
    final catatan = item['catatan'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [statusColor, statusColor.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(emoji, style: const TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Text(
                                        item['nama_tujuan'] ?? '-',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$status — $statusLabel',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        _sheetSectionTitle('Tujuan Pembelajaran (TP)'),
                        const SizedBox(height: 6),
                        _sheetTextBox(item['nama_tujuan']?.toString() ?? '-', AppColors.orange700),
                        const SizedBox(height: 16),

                        _sheetSectionTitle('Kegiatan Pembelajaran (KP)'),
                        const SizedBox(height: 6),
                        _sheetTextBox(item['nama_kegiatan']?.toString() ?? '-', AppColors.blue),
                        const SizedBox(height: 16),

                        _sheetSectionTitle('Informasi Umum'),
                        const SizedBox(height: 8),
                        _sheetDetailCard(children: [
                          _sheetRow(Icons.category_rounded, 'Aspek Penilaian', aspek),
                          _sheetRow(Icons.calendar_today_rounded, 'Tanggal Penilaian', tanggal),
                          _sheetRow(Icons.school_rounded, 'Semester', 'Semester $semester'),
                          _sheetRow(Icons.view_week_rounded, 'Minggu Ke', 'Minggu ke-$mingguKe'),
                          _sheetRow(Icons.person_rounded, 'Penilai (Guru)', namaGuru, isLast: true),
                        ]),
                        const SizedBox(height: 16),

                        if (konteks.toString().trim().isNotEmpty) ...[
                          _sheetSectionTitle('Konteks / Situasi'),
                          const SizedBox(height: 6),
                          _sheetTextBox(konteks.toString(), AppColors.blue),
                          const SizedBox(height: 16),
                        ],

                        if (hasil.toString().trim().isNotEmpty) ...[
                          _sheetSectionTitle('Hasil Penilaian (CP)'),
                          const SizedBox(height: 6),
                          _sheetTextBox(hasil.toString(), AppColors.green),
                          const SizedBox(height: 16),
                        ],

                        if (kejadian.toString().trim().isNotEmpty) ...[
                          _sheetSectionTitle('Kejadian / Cerita Anak'),
                          const SizedBox(height: 6),
                          _sheetTextBox(kejadian.toString(), AppColors.purple),
                          const SizedBox(height: 16),
                        ],

                        if (catatan.toString().trim().isNotEmpty) ...[
                          _sheetSectionTitle('Catatan Pembelajaran'),
                          const SizedBox(height: 6),
                          _sheetTextBox(catatan.toString(), AppColors.slate),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.grey.shade800,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _sheetDetailCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(children: children),
    );
  }

  Widget _sheetRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetTextBox(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 125 / 10,
          color: const Color(0xFF334155),
          height: 1.4,
        ),
      ),
    );
  }
}

