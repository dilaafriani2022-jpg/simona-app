import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutSystemScreen extends StatelessWidget {
  final Color primaryColor;
  final Color primaryDark;
  final Color backgroundColor;
  final Color borderColor;

  const AboutSystemScreen({
    super.key,
    this.primaryColor = const Color(0xFFC17B2F),
    this.primaryDark = const Color(0xFFA0601A),
    this.backgroundColor = const Color(0xFFFDF8F3),
    this.borderColor = const Color(0xFFF0E8DF),
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          title: Text(
            'Tentang SiMONA',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.normal, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.info_outline_rounded), text: 'Informasi'),
              Tab(icon: Icon(Icons.alt_route_rounded), text: 'Jalannya Sistem'),
              Tab(icon: Icon(Icons.terminal_rounded), text: 'Teknologi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(context),
            _buildWorkflowTab(context),
            _buildTechTab(context),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: INFORMASI UMUM ───────────────────────────────────────────────
  Widget _buildInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 16),
                Text(
                  'SiMONA',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistem Informasi Monitoring Penilaian Perkembangan Anak',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Versi 1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Deskripsi
          Text(
            'Deskripsi Sistem',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'SiMONA adalah platform digital monitoring penilaian perkembangan anak usia dini di TK Negeri 2 Bengkalis yang dirancang khusus berbasis Kurikulum Merdeka. Aplikasi ini menjembatani kolaborasi aktif antara Operator, Guru, Orang Tua, dan Kepala Sekolah untuk memantau, mendokumentasikan, serta mengevaluasi seluruh proses monitoring dan penilaian perkembangan tumbuh kembang anak secara real-time dan terintegrasi.',
              textAlign: TextAlign.justify,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF475569),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Detail Institusi
          Text(
            'Informasi Institusi',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Nama Sekolah', 'TK Negeri 2 Bengkalis'),
                _buildDivider(),
                _buildInfoRow('Alamat', 'Jl. Awang Mahmuda, Sungai Alam, Bengkalis'),
                _buildDivider(),
                _buildInfoRow('Wilayah', 'Kab. Bengkalis, Prov. Riau'),
                _buildDivider(),
                _buildInfoRow('Kategori', 'Taman Kanak-Kanak Negeri'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── TAB 2: JALANNYA SISTEM (WORKFLOW) ────────────────────────────────────
  Widget _buildWorkflowTab(BuildContext context) {
    final workflows = [
      {
        'title': '1. Setup & Data Master',
        'actor': 'Operator / Admin',
        'desc': 'Operator mengelola data profil sekolah, data kelas, data pendidik (guru), data peserta didik (anak), dan menghubungkan akun orang tua. Operator juga menyusun aspek penilaian indikator perkembangan anak yang digunakan untuk proses monitoring penilaian.',
        'icon': Icons.settings_suggest_rounded,
        'color': const Color(0xFFC17B2F),
      },
      {
        'title': '2. Perencanaan Pembelajaran',
        'actor': 'Guru',
        'desc': 'Guru menyusun Rencana Pelaksanaan Pembelajaran Mingguan (RPPM), Program Semester (Prosem), dan Modul Ajar berbasis Kurikulum Merdeka yang disesuaikan dengan fokus capaian penilaian perkembangan kelompok usia kelas.',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF15803D),
      },
      {
        'title': '3. Kegiatan & Penilaian Harian',
        'actor': 'Guru',
        'desc': 'Saat pembelajaran berlangsung, Guru mencatat kehadiran anak dan melakukan monitoring penilaian perkembangan anak secara berkala. Penilaian berfokus pada hasil belajar anak melalui instrumen Checklist Capaian TP (Tujuan Pembelajaran), Catatan Anekdot (perilaku penting), serta hasil karya anak yang ditulis secara naratif/deskriptif.',
        'icon': Icons.assignment_turned_in_rounded,
        'color': const Color(0xFF16A34A),
      },
      {
        'title': '4. Rekap & Cetak Raport',
        'actor': 'Guru & Kepala Sekolah',
        'desc': 'Di akhir periode pembelajaran, Guru melakukan rekapitulasi penilaian perkembangan anak dan mencetak raport secara langsung. Kepala Sekolah dapat memantau hasil grafik rekapitulasi penilaian perkembangan anak secara keseluruhan di sistem.',
        'icon': Icons.print_rounded,
        'color': const Color(0xFF1E1B4B),
      },
      {
        'title': '5. Pemantauan & Refleksi',
        'actor': 'Orang Tua',
        'desc': 'Orang Tua memantau rekap absensi harian anak, catatan anekdot perilaku anak, deskripsi naratif hasil karya anak, serta hasil rekapitulasi penilaian raport anak secara instan. Orang Tua juga memberikan input catatan refleksi untuk menyelaraskan penilaian di sekolah dan di rumah.',
        'icon': Icons.family_restroom_rounded,
        'color': const Color(0xFFD97706),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workflows.length,
      itemBuilder: (context, index) {
        final wf = workflows[index];
        final isLast = index == workflows.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (wf['color'] as Color).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: (wf['color'] as Color).withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(
                    wf['icon'] as IconData,
                    color: wf['color'] as Color,
                    size: 22,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 120,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              wf['title'] as String,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (wf['color'] as Color).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              wf['actor'] as String,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                color: wf['color'] as Color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        wf['desc'] as String,
                        textAlign: TextAlign.justify,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: const Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── TAB 3: TEKNOLOGI & ARSITEKTUR ────────────────────────────────────────
  Widget _buildTechTab(BuildContext context) {
    final techStack = [
      {
        'title': 'Frontend Framework',
        'value': 'Flutter SDK (Dart)',
        'desc': 'Membangun antarmuka pengguna (UI) modern yang responsif untuk berbagai resolusi perangkat seluler Android dan Windows Desktop.',
        'icon': Icons.phonelink_setup_rounded,
        'color': const Color(0xFF0284C7),
      },
      {
        'title': 'Penyimpanan Sesi & Sesi Login',
        'value': 'shared_preferences',
        'desc': 'Menyimpan konfigurasi status login pengguna, token otentikasi, dan preferensi lokal secara persisten di penyimpanan perangkat.',
        'icon': Icons.vpn_key_rounded,
        'color': const Color(0xFFD97706),
      },
      {
        'title': 'Grafik & Statistik Penilaian',
        'value': 'fl_chart',
        'desc': 'Library visualisasi grafik yang digunakan untuk menampilkan statistik capaian penilaian perkembangan anak secara interaktif di dashboard.',
        'icon': Icons.insert_chart_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Cetak & Eksport Dokumen',
        'value': 'pdf & printing',
        'desc': 'Digunakan oleh Guru untuk menyusun format dokumen digital PDF raport penilaian perkembangan anak dan mencetaknya secara langsung.',
        'icon': Icons.picture_as_pdf_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'title': 'Komunikasi REST API',
        'value': 'http & ApiService Adaptor',
        'desc': 'Mengirimkan request HTTP JSON secara asynchronous ke backend, dilengkapi pendeteksi port dinamis emulator IP 10.0.2.2 vs localhost 127.0.0.1.',
        'icon': Icons.sync_alt_rounded,
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'Backend REST API',
        'value': 'PHP Native (PDO Connection)',
        'desc': 'Engine backend lokal modular yang memproses seluruh transaksi data aplikasi dan menghasilkan output data terstruktur format JSON.',
        'icon': Icons.dns_rounded,
        'color': const Color(0xFF7C3AED),
      },
      {
        'title': 'Database Penyimpanan',
        'value': 'MySQL Database (XAMPP)',
        'desc': 'Sistem penyimpanan data relasional terpusat yang menyimpan konfigurasi master sekolah, log riwayat, dan data monitoring penilaian anak.',
        'icon': Icons.storage_rounded,
        'color': const Color(0xFF0D9488),
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Arsitektur & Paket Teknologi Aplikasi',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ...techStack.map((tech) {
            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (tech['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        tech['icon'] as IconData,
                        color: tech['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tech['title'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            tech['value'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tech['desc'] as String,
                            textAlign: TextAlign.justify,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: const Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Helper Row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16);
  }
}
