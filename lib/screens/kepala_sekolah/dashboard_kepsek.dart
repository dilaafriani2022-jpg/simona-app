import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/monitoring_tab.dart';
import 'tabs/statistik_tab.dart';
import 'tabs/profil_tab.dart';

class DashboardKepsek extends StatefulWidget {
  final Map<String, dynamic> user;
  const DashboardKepsek({super.key, required this.user});

  @override
  State<DashboardKepsek> createState() => _DashboardKepsekState();
}

class _DashboardKepsekState extends State<DashboardKepsek>
    with SingleTickerProviderStateMixin {
  // ── Palet ────────────────────────────────────────────────────────────────
  static const Color _navy    = Color(0xFF1A1F3C);
  static const Color _gold    = Color(0xFFD4A853);
  static const Color _cream   = Color(0xFFFBF8F3);
  static const Color _inactive = Color(0xFFB0AECB);

  int _currentIndex = 0;
  bool _isLoadingHome = true;
  bool _isLoadingMonitoring = true;

  Map<String, dynamic> _stats = {};
  List<dynamic> _notifications = [];

  List<dynamic> _guruMonitoring = [];
  List<dynamic> _anakMonitoring = [];
  Map<String, dynamic> _aspekStats   = {'agama': 0, 'jati_diri': 0, 'steam': 0, 'total': 0};
  Map<String, dynamic> _absensiStats = {'hadir': 0, 'sakit': 0, 'izin': 0, 'alpa': 0};

  int _selectedSemester = 1;
  late Map<String, dynamic> _currentUserData;

  @override
  void initState() {
    super.initState();
    _currentUserData = Map<String, dynamic>.from(widget.user);
    _loadHomeData();
    _loadMonitoringData();
  }

  Future<void> _loadHomeData() async {
    if (!mounted) return;
    setState(() => _isLoadingHome = true);
    try {
      final statsRes = await ApiService.getDashboardStats(semester: _selectedSemester);
      if (statsRes['status'] == 'success') {
        _stats = statsRes['data'] ?? {};
      }
      final notifRes = await ApiService.fetch('get_notifications.php?role=kepsek&semester=$_selectedSemester');
      if (notifRes['status'] == 'success') {
        _notifications = notifRes['data'] ?? [];
      }
    } catch (e) {
      debugPrint("Error loading home stats: $e");
    } finally {
      if (mounted) setState(() => _isLoadingHome = false);
    }
  }

  Future<void> _loadMonitoringData() async {
    if (!mounted) return;
    setState(() => _isLoadingMonitoring = true);
    try {
      final res = await ApiService.fetch(
          'get_kepsek_monitoring.php?semester=$_selectedSemester');
      if (res['status'] == 'success') {
        final mData = res['data'] ?? {};
        _guruMonitoring = mData['guru_monitoring'] ?? [];
        _anakMonitoring = mData['anak_monitoring'] ?? [];
        _aspekStats     = Map<String, dynamic>.from(mData['aspek_stats']   ?? {'agama': 0, 'jati_diri': 0, 'steam': 0, 'total': 0});
        _absensiStats   = Map<String, dynamic>.from(mData['absensi_stats'] ?? {'hadir': 0, 'sakit': 0, 'izin': 0, 'alpa': 0});
      }
    } catch (e) {
      debugPrint("Error loading monitoring data: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMonitoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _cream,
      extendBody: true,
      body: RefreshIndicator(
        color: _navy,
        backgroundColor: Colors.white,
        onRefresh: () async {
          if (_currentIndex == 0) {
            await _loadHomeData();
          } else {
            await _loadMonitoringData();
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: _buildBody(),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Beranda'),
            _navItem(1, Icons.analytics_rounded, Icons.analytics_outlined, 'Monitoring'),
            _navItem(2, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Statistik'),
            _navItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final bool isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentIndex == index) return;
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
          if (index == 0) _loadHomeData();
          if (index == 1 || index == 2) _loadMonitoringData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? _gold.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isActive ? activeIcon : inactiveIcon,
                  key: ValueKey(isActive),
                  size: 22,
                  color: isActive ? _gold : _inactive,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? _gold : _inactive,
                  letterSpacing: 0.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _isLoadingHome
            ? _buildLoading()
            : HomeTab(
                stats: _stats,
                notifications: _notifications,
                currentUserData: _currentUserData,
                onTapRekap: () {
                  setState(() => _currentIndex = 1);
                  _loadMonitoringData();
                },
              );
      case 1:
        return MonitoringTab(
          isLoading: _isLoadingMonitoring,
          guruMonitoring: _guruMonitoring,
          anakMonitoring: _anakMonitoring,
          selectedSemester: _selectedSemester,
          onSemesterChanged: (semester) {
            setState(() => _selectedSemester = semester);
            _loadMonitoringData();
            _loadHomeData();
          },
        );
      case 2:
        return _isLoadingMonitoring
            ? _buildLoading()
            : StatistikTab(
                aspekStats: _aspekStats,
                absensiStats: _absensiStats,
              );
      case 3:
        return ProfilTab(
          currentUserData: _currentUserData,
          onProfileUpdated: (updatedData) {
            setState(() => _currentUserData = updatedData);
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: _navy,
              backgroundColor: _navy.withValues(alpha: 0.1),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Memuat data…',
            style: TextStyle(
              color: Color(0xFF8A8AAA),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}