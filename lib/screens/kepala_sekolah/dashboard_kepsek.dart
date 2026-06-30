import 'package:flutter/material.dart';
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

class _DashboardKepsekState extends State<DashboardKepsek> {
  int _currentIndex = 0;
  bool _isLoadingHome = true;
  bool _isLoadingMonitoring = true;
  
  Map<String, dynamic> _stats = {};
  List<dynamic> _notifications = [];
  
  // Monitoring Data
  List<dynamic> _guruMonitoring = [];
  List<dynamic> _anakMonitoring = [];
  Map<String, dynamic> _aspekStats = {'agama': 0, 'jati_diri': 0, 'steam': 0, 'total': 0};
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
      final statsRes = await ApiService.getDashboardStats();
      if (statsRes['status'] == 'success') {
        _stats = statsRes['data'] ?? {};
      }
      final notifRes = await ApiService.fetch('get_notifications.php?role=kepsek');
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
      final res = await ApiService.fetch('get_kepsek_monitoring.php?semester=$_selectedSemester');
      if (res['status'] == 'success') {
        final mData = res['data'] ?? {};
        _guruMonitoring = mData['guru_monitoring'] ?? [];
        _anakMonitoring = mData['anak_monitoring'] ?? [];
        _aspekStats = Map<String, dynamic>.from(mData['aspek_stats'] ?? {'agama': 0, 'jati_diri': 0, 'steam': 0, 'total': 0});
        _absensiStats = Map<String, dynamic>.from(mData['absensi_stats'] ?? {'hadir': 0, 'sakit': 0, 'izin': 0, 'alpa': 0});
      }
    } catch (e) {
      debugPrint("Error loading monitoring data: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMonitoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (_currentIndex == 0) {
              await _loadHomeData();
            } else {
              await _loadMonitoringData();
            }
          },
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) _loadHomeData();
          if (index == 1 || index == 2) _loadMonitoringData();
        },
        selectedItemColor: const Color(0xFF1E1B4B),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Monitoring'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Statistik'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _isLoadingHome
            ? const Center(child: CircularProgressIndicator())
            : HomeTab(
                stats: _stats,
                notifications: _notifications,
                currentUserData: _currentUserData,
              );
      case 1:
        return MonitoringTab(
          isLoading: _isLoadingMonitoring,
          guruMonitoring: _guruMonitoring,
          anakMonitoring: _anakMonitoring,
          selectedSemester: _selectedSemester,
          onSemesterChanged: (semester) {
            setState(() {
              _selectedSemester = semester;
            });
            _loadMonitoringData();
          },
        );
      case 2:
        return _isLoadingMonitoring
            ? const Center(child: CircularProgressIndicator())
            : StatistikTab(
                aspekStats: _aspekStats,
                absensiStats: _absensiStats,
              );
      case 3:
        return ProfilTab(
          currentUserData: _currentUserData,
          onProfileUpdated: (updatedData) {
            setState(() {
              _currentUserData = updatedData;
            });
          },
        );
      default:
        return const Center(child: Text("Tab not found"));
    }
  }
}
