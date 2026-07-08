import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'manage_ortu_screen.dart';
import 'manage_anak_screen.dart';
import 'manage_guru_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// NotificationPanelScreen — ditampilkan saat operator mengetuk ikon lonceng
/// ─────────────────────────────────────────────────────────────────────────────
class NotificationPanelScreen extends StatefulWidget {
  const NotificationPanelScreen({super.key});

  @override
  State<NotificationPanelScreen> createState() => _NotificationPanelScreenState();
}

class _NotificationPanelScreenState extends State<NotificationPanelScreen> {
  static const Color _primary   = Color(0xFFC17B2F);
  static const Color _primaryDk = Color(0xFFA0601A);
  static const Color _bg        = Color(0xFFFDF8F3);
  static const Color _border    = Color(0xFFF0E8DF);

  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    final result = await ApiService.fetch('get_notifications.php');
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['status'] == 'success') {
        _alerts = (result['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    });
  }

  // ── Color helpers ──────────────────────────────────────────────────────────
  Color _levelColor(String level) {
    switch (level) {
      case 'error':   return const Color(0xFFE74C3C);
      case 'warning': return const Color(0xFFE67E22);
      case 'info':    return const Color(0xFF2980B9);
      default:        return _primary;
    }
  }

  Color _levelBg(String level) {
    switch (level) {
      case 'error':   return const Color(0xFFFDE8E8);
      case 'warning': return const Color(0xFFFFF5E6);
      case 'info':    return const Color(0xFFE8F2FD);
      default:        return const Color(0xFFFFF3E0);
    }
  }

  IconData _jenisIcon(String jenis) {
    switch (jenis) {
      case 'anak': return Icons.child_care_rounded;
      case 'guru': return Icons.school_rounded;
      case 'ortu': return Icons.family_restroom_rounded;
      default:     return Icons.info_outline_rounded;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Notifikasi Sistem',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: Column(children: [
        _buildSummaryBanner(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  // ── Summary banner ─────────────────────────────────────────────────────────
  Widget _buildSummaryBanner() {
    return Container(
      width: double.infinity,
      color: _primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _isLoading
        ? const SizedBox.shrink()
        : Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  _alerts.isEmpty ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: Colors.white, size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _alerts.isEmpty
                      ? 'Semua data sudah lengkap ✓'
                      : '${_alerts.length} peringatan perlu perhatian',
                    style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_alerts.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadAlerts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _alerts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i == 0) return _buildInfoNote();
          return _buildAlertCard(_alerts[i - 1]);
        },
      ),
    );
  }

  // ── Info note ──────────────────────────────────────────────────────────────
  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBD8F5)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_rounded, size: 18, color: Colors.blue.shade600),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'Notifikasi ini adalah peringatan integritas data yang perlu segera diselesaikan oleh operator. '
          'Selesaikan satu per satu untuk memastikan kelengkapan data anak.',
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.blue.shade700, height: 1.5),
        )),
      ]),
    );
  }

  // ── Alert card ─────────────────────────────────────────────────────────────
  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final level  = (alert['level']  ?? 'warning').toString();
    final jenis  = (alert['jenis']  ?? 'info').toString();
    final judul  = (alert['judul']  ?? '').toString();
    final pesan  = (alert['pesan']  ?? '').toString();
    final count  = int.tryParse(alert['count'].toString()) ?? 0;
    final aksi   = (alert['aksi']   ?? 'Lihat').toString();
    final route  = (alert['route']  ?? '').toString();

    final lColor = _levelColor(level);
    final lBg    = _levelBg(level);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: lColor.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        // ── Header ────────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: lBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18)),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: lColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(_jenisIcon(jenis), color: lColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(judul,
                style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(pesan,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
                maxLines: 3, overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 12),
            // Count badge
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: lColor, shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('$count',
                style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        // ── Action button ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (route == 'manage_ortu') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageOrtuScreen()));
                } else if (route == 'manage_anak') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAnakScreen()));
                } else if (route == 'manage_guru') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageGuruScreen()));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: lColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      aksi,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_rounded, size: 55, color: Colors.green.shade400),
          ),
          const SizedBox(height: 20),
          Text('Semua Data Sudah Lengkap!',
            style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w700, color: Colors.green.shade700)),
          const SizedBox(height: 8),
          Text(
            'Tidak ada peringatan saat ini.\n'
            'Semua anak sudah terhubung ke orang tua, '
            'sudah masuk kelas, dan semua guru sudah ditetapkan kelasnya.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12, color: Colors.grey.shade500, height: 1.6),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadAlerts,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.green.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            ),
            icon: Icon(Icons.refresh_rounded, color: Colors.green.shade600),
            label: Text('Cek Ulang',
              style: GoogleFonts.poppins(
                color: Colors.green.shade600, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

