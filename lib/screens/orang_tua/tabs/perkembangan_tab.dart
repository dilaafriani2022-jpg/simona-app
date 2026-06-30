import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../widgets/checklist_card.dart';

// ── Palette ──────────────────────────────────────────────────
const Color _orange700 = AppColors.orange700;
const Color _orange500 = AppColors.orange500;
const Color _bg        = AppColors.bg;
const Color _surface   = AppColors.surface;
const Color _green     = AppColors.green;
const Color _blue      = AppColors.blue;
const Color _purple    = AppColors.purple;
const Color _rose      = AppColors.rose;
const Color _amber     = AppColors.amber;
const Color _teal      = AppColors.teal;

class PerkembanganTab extends StatefulWidget {
  final Map<String, dynamic>? selectedAnak;
  final int checklistBulan;
  final int checklistMingguIdx;
  final String checklistFilterStatus;
  final List<dynamic> checklistList;
  final List<dynamic> anekdotList;
  final List<dynamic> karyaList;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final void Function(int) onBulanSelected;
  final void Function(int) onMingguIdxSelected;
  final void Function(String) onStatusFilterSelected;

  const PerkembanganTab({
    super.key,
    required this.selectedAnak,
    required this.checklistBulan,
    required this.checklistMingguIdx,
    required this.checklistFilterStatus,
    required this.checklistList,
    required this.anekdotList,
    required this.karyaList,
    required this.isLoading,
    required this.onRefresh,
    required this.onBulanSelected,
    required this.onMingguIdxSelected,
    required this.onStatusFilterSelected,
  });

  @override
  State<PerkembanganTab> createState() => _PerkembanganTabState();
}

class _PerkembanganTabState extends State<PerkembanganTab> {
  static const int _totalBulanChecklist = 5;
  static int _weeksForBulan(int b) => b == 5 ? 2 : 4;
  static int _startWeekOfBulan(int b) => b <= 1 ? 1 : (b - 1) * 4 + 1;
  int get _currentChecklistMinggu => _startWeekOfBulan(widget.checklistBulan) + widget.checklistMingguIdx;

  String _selectedAspek = 'Semua';

  List<String> get _availableAspeks {
    final aspeks = widget.checklistList
        .map((item) => item['nama_aspek']?.toString() ?? '')
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList();
    aspeks.sort();
    return ['Semua', ...aspeks];
  }

  @override
  void didUpdateWidget(covariant PerkembanganTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedAspek != 'Semua' && !_availableAspeks.contains(_selectedAspek)) {
      _selectedAspek = 'Semua';
    }
  }

  String _getShortAspekName(String fullName) {
    if (fullName == 'Semua') return 'Semua';
    if (fullName.contains('Agama')) {
      return 'Agama & Budi Pekerti';
    } else if (fullName.contains('Literasi') || fullName.contains('STEAM') || fullName.contains('Sains')) {
      return 'Literasi & STEAM';
    } else if (fullName.contains('Jati Diri')) {
      return 'Jati Diri';
    }
    return fullName;
  }

  List<dynamic> get _filteredChecklist {
    return widget.checklistList.where((item) {
      final mg = int.tryParse(item['minggu_ke']?.toString() ?? '0') ?? 0;
      final matchW = mg == _currentChecklistMinggu;
      if (!matchW) return false;

      if (_selectedAspek != 'Semua') {
        if (item['nama_aspek']?.toString() != _selectedAspek) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _orange700,
          title: const Text('Perkembangan Anak',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.checklist_rounded, size: 18), text: 'Checklist'),
              Tab(icon: Icon(Icons.sticky_note_2_rounded, size: 18), text: 'Anekdot'),
              Tab(icon: Icon(Icons.palette_rounded, size: 18), text: 'Karya'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _buildChecklistTab(),
          _buildAnekdotTab(),
          _buildKaryaTab(),
        ]),
      ),
    );
  }

  Widget _buildChecklistTab() {
    if (widget.isLoading) return const Center(child: CircularProgressIndicator());
    if (widget.checklistList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checklist_rounded, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Belum ada data penilaian checklist',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredChecklist;

    // Hitung stat dari data yang aktif (filtered)
    final totalCount = filtered.length;
    final tmCount = filtered.where((item) => item['status'] == 'TM').length;
    final mmCount = filtered.where((item) => item['status'] == 'MM').length;
    final mCount = filtered.where((item) => item['status'] == 'M').length;

    return Column(
      children: [
        _buildBulanSelector(),
        _buildMingguSelector(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildSmallStatChip('Total', '$totalCount', Colors.blue, null),
              const SizedBox(width: 8),
              _buildSmallStatChip('TM', '$tmCount', _rose, '🚨'),
              const SizedBox(width: 8),
              _buildSmallStatChip('MM', '$mmCount', _amber, '🌱'),
              const SizedBox(width: 8),
              _buildSmallStatChip('M', '$mCount', _green, '🌟'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _availableAspeks.map((aspek) {
                final isSelected = _selectedAspek == aspek;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_getShortAspekName(aspek)),
                    selected: isSelected,
                    selectedColor: _orange500,
                    backgroundColor: _surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : Colors.grey.shade200,
                    ),
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() {
                          _selectedAspek = aspek;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          color: const Color(0xFFFFF2E2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: _orange700, size: 16),
              const SizedBox(width: 6),
              Text(
                'Bulan ${widget.checklistBulan}  •  Minggu $_currentChecklistMinggu',
                style: const TextStyle(
                  fontSize: 12,
                  color: _orange700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? ListView(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 50, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada penilaian untuk\nBulan ${widget.checklistBulan} · Minggu $_currentChecklistMinggu',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (widget.checklistFilterStatus != 'Semua') ...[
                            const SizedBox(height: 4),
                            Text(
                              'dengan status "${widget.checklistFilterStatus}"',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (_selectedAspek != 'Semua') ...[
                            const SizedBox(height: 4),
                            Text(
                              'untuk aspek "$_selectedAspek"',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => ChecklistCard(item: filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildBulanSelector() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _totalBulanChecklist,
        itemBuilder: (context, index) {
          final bulanNum = index + 1;
          final isSelected = widget.checklistBulan == bulanNum;
          final startW = _startWeekOfBulan(bulanNum);
          final endW = startW + _weeksForBulan(bulanNum) - 1;
          
          final count = widget.checklistList.where((item) {
            final mg = int.tryParse(item['minggu_ke']?.toString() ?? '0') ?? 0;
            return mg >= startW && mg <= endW;
          }).length;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => widget.onBulanSelected(bulanNum),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [_orange700, _orange500])
                      : null,
                  color: isSelected ? null : _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey.shade200,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: _orange500.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 3, offset: const Offset(0, 1))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulan $bulanNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Minggu $startW-$endW',
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected ? Colors.white70 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMingguSelector() {
    final totalWeeks = _weeksForBulan(widget.checklistBulan);
    final startW = _startWeekOfBulan(widget.checklistBulan);
    
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: totalWeeks,
        itemBuilder: (context, index) {
          final weekNum = startW + index;
          final isSelected = widget.checklistMingguIdx == index;
          
          final count = widget.checklistList.where((item) {
            final mg = int.tryParse(item['minggu_ke']?.toString() ?? '0') ?? 0;
            return mg == weekNum;
          }).length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Minggu $weekNum'),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white24 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              selectedColor: _orange500,
              backgroundColor: _surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.grey.shade200,
              ),
              onSelected: (bool selected) {
                if (selected) {
                  widget.onMingguIdxSelected(index);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSmallStatChip(String label, String value, Color color, String? emoji) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (emoji != null) ...[
                Text(emoji, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
              ],
              Text(
                '$label: ',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnekdotTab() {
    if (widget.isLoading) return const Center(child: CircularProgressIndicator());
    if (widget.anekdotList.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.sticky_note_2_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Belum ada catatan anekdot', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ]),
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.anekdotList.length,
      itemBuilder: (_, i) {
        final item = widget.anekdotList[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: _purple.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
            border: Border.all(color: _purple.withOpacity(0.1)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sticky_note_2_rounded, color: _purple, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(item['aspek_perkembangan'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)))),
              Text(item['tanggal'] ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ]),
            if ((item['lokasi'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.location_on_rounded, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(item['lokasi'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
            ],
            const SizedBox(height: 10),
            _anekdotSection('Peristiwa', item['peristiwa']),
            if ((item['interpretasi'] ?? '').toString().isNotEmpty)
              _anekdotSection('Interpretasi', item['interpretasi']),
            if ((item['tindak_lanjut'] ?? '').toString().isNotEmpty)
              _anekdotSection('Tindak Lanjut', item['tindak_lanjut']),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.person_rounded, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('Guru: ${item['nama_guru'] ?? '-'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _anekdotSection(String label, String? value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _purple)),
      const SizedBox(height: 3),
      Text(value ?? '-', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
    ]),
  );

  Widget _buildKaryaTab() {
    if (widget.isLoading) return const Center(child: CircularProgressIndicator());
    if (widget.karyaList.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.palette_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Belum ada karya anak', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ]),
      ));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
      itemCount: widget.karyaList.length,
      itemBuilder: (_, i) {
        final item = widget.karyaList[i];
        final colors = [_green, _blue, _purple, _teal, _rose, _amber, _orange700];
        final color = colors[i % colors.length];
        return Container(
          decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.7), color],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(child: Icon(Icons.palette_rounded, color: Colors.white, size: 38)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['judul'] ?? item['nama_karya'] ?? 'Karya ${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(item['tanggal'] ?? '',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

