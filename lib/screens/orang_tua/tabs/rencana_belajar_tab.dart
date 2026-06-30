import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../guru/prosem_tab.dart';
import '../../guru/rppm_tab.dart';
import '../../guru/modul_ajar_tab.dart';

/// Tab Rencana Belajar untuk Orang Tua — read-only Prosem / RPPM / Modul Ajar.
/// Dipanggil dari DashboardOrtu sebagai pengganti JadwalTab (tab index 3).
class RencanaBelajarTab extends StatefulWidget {
  final Map<String, dynamic>? selectedAnak;

  const RencanaBelajarTab({super.key, required this.selectedAnak});

  @override
  State<RencanaBelajarTab> createState() => _RencanaBelajarTabState();
}

class _RencanaBelajarTabState extends State<RencanaBelajarTab>
    with SingleTickerProviderStateMixin {
  static const Color _primary   = Color(0xFFC17B2F);
  static const Color _navy      = Color(0xFF1E3A8A);
  static const Color _surface   = AppColors.surface;
  static const Color _bg        = AppColors.bg;

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  int? get _idKelas {
    if (widget.selectedAnak == null) return null;
    return int.tryParse(widget.selectedAnak!['id_kelas']?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedAnak == null) {
      return _buildNoChild();
    }

    final namaAnak  = widget.selectedAnak!['nama_anak']  ?? '';
    final namaKelas = widget.selectedAnak!['nama_kelas'] ?? '';

    return Column(
      children: [
        // ─── Header ─────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2D5BA8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rencana Belajar',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$namaAnak • $namaKelas',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Sub-tab bar
              TabBar(
                controller: _tabCtrl,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(text: 'Prosem'),
                  Tab(text: 'RPPM (Mingguan)'),
                  Tab(text: 'Modul Ajar'),
                ],
              ),
            ],
          ),
        ),

        // ─── Tab Content ────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              ProsemTab(
                idKelas: _idKelas,
                idGuru: null,
                isReadOnly: true,
              ),
              RppmTab(
                idKelas: _idKelas,
                idGuru: null,
                isReadOnly: true,
              ),
              ModulAjarTab(
                idKelas: _idKelas,
                idGuru: null,
                isReadOnly: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoChild() {
    return Container(
      color: _bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _navy.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.child_care_rounded, size: 52, color: _navy.withOpacity(0.4)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih anak terlebih dahulu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rencana belajar akan ditampilkan\nsesuai kelas anak yang dipilih.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
