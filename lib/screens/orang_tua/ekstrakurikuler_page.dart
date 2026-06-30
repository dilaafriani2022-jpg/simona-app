import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class EkstrakurikulerPage extends StatelessWidget {
  final String anakName;
  final List<dynamic> ekstraList;
  final VoidCallback onRefresh;

  const EkstrakurikulerPage({
    super.key,
    required this.anakName,
    required this.ekstraList,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.teal,
      AppColors.green,
      AppColors.amber,
      AppColors.purple,
      AppColors.orange700
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.orange700,
        title: const Text('Ekstrakurikuler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ekstraList.isEmpty
          ? Center(child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.sports_outlined, size: 70, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Belum ada kegiatan ekstrakurikuler',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade500), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('Guru belum menginput data ekstrakurikuler untuk $anakName',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400), textAlign: TextAlign.center),
              ]),
            ))
          : RefreshIndicator(
              onRefresh: () async => onRefresh(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ekstraList.length,
                itemBuilder: (_, i) {
                  final item = ekstraList[i];
                  final color = colors[i % colors.length];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface, borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.sports_rounded, color: color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item['nama_ekstrakurikuler'] ?? '-',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                            if ((item['deskripsi'] ?? '').toString().isNotEmpty)
                              Text(item['deskripsi'],
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                          ])),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          if ((item['prestasi'] ?? '').toString().isNotEmpty)
                            _ekstraRow(Icons.emoji_events_rounded, 'Prestasi', item['prestasi'], color),
                          if ((item['catatan'] ?? '').toString().isNotEmpty)
                            _ekstraRow(Icons.notes_rounded, 'Catatan', item['catatan'], color),
                          _ekstraRow(Icons.calendar_today_rounded, 'Semester', 'Semester ${item['semester'] ?? 1}', color),
                          _ekstraRow(Icons.person_rounded, 'Guru', item['nama_guru'] ?? '-', color),
                        ]),
                      ),
                    ]),
                  );
                },
              ),
            ),
    );
  }

  Widget _ekstraRow(IconData icon, String label, String value, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
    ]),
  );
}

