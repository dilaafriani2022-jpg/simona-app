import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../widgets/create_smart_user_sheet.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRoleFilter = 'all';

  final TextEditingController _searchController = TextEditingController();

  // ── Color palette ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF5B7FFF);
  static const Color _primaryLight = Color(0xFFEEF2FF);
  static const Color _bgPage = Color(0xFFF0F4F8);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1A2332);
  static const Color _textSecondary = Color(0xFF5A6882);
  static const Color _textHint = Color(0xFF9BA8BE);
  static const Color _border = Color(0xFFE8EDF5);

  static const Color _green = Color(0xFF34C97A);
  static const Color _greenLight = Color(0xFFEDFAF3);
  static const Color _orange = Color(0xFFFF8C42);
  static const Color _orangeLight = Color(0xFFFFF4EC);
  static const Color _purple = Color(0xFF9B6DFF);
  static const Color _purpleLight = Color(0xFFF3EEFF);

  final List<Map<String, dynamic>> _roleFilters = [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'guru', 'label': 'Guru'},
    {'value': 'orang_tua', 'label': 'Orang Tua'},
    {'value': 'kepsek', 'label': 'Kepsek'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _applyFilter();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getUsers();
    if (result['status'] == 'success') {
      _users = (result['data'] as List)
          .map((u) => UserModel.fromJson(u))
          .toList();
      _applyFilter();
    }
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    _filteredUsers = _users.where((user) {
      final matchRole =
          _selectedRoleFilter == 'all' || user.role == _selectedRoleFilter;
      final identifier =
          (user.nip ?? user.nisn ?? user.email ?? user.username ?? '')
              .toLowerCase();
      final matchSearch = user.name.toLowerCase().contains(_searchQuery) ||
          user.role.toLowerCase().contains(_searchQuery) ||
          identifier.contains(_searchQuery);
      return matchRole && matchSearch;
    }).toList();
  }

  // ── Stats helpers ──────────────────────────────────────────────────────────
  int _countByRole(String role) =>
      _users.where((u) => u.role == role).length;

  // ── Colour / icon helpers ──────────────────────────────────────────────────
  Color _roleColor(String role) => switch (role) {
        'operator' => _primary,
        'guru' => _green,
        'orang_tua' => _orange,
        'kepsek' => _purple,
        _ => _textHint,
      };

  Color _roleColorLight(String role) => switch (role) {
        'operator' => _primaryLight,
        'guru' => _greenLight,
        'orang_tua' => _orangeLight,
        'kepsek' => _purpleLight,
        _ => const Color(0xFFF1F5F9),
      };

  Color _roleBadgeTextColor(String role) => switch (role) {
        'operator' => const Color(0xFF2E55D0),
        'guru' => const Color(0xFF1A8C54),
        'orang_tua' => const Color(0xFFC05A1A),
        'kepsek' => const Color(0xFF6B3FCC),
        _ => _textSecondary,
      };

  IconData _roleIcon(String role) => switch (role) {
        'operator' => Icons.manage_accounts_rounded,
        'guru' => Icons.school_rounded,
        'orang_tua' => Icons.people_alt_rounded,
        'kepsek' => Icons.workspace_premium_rounded,
        _ => Icons.person_rounded,
      };

  String _roleLabel(String role) => switch (role) {
        'operator' => 'Operator',
        'guru' => 'Guru',
        'orang_tua' => 'Orang Tua',
        'kepsek' => 'Kepala Sekolah',
        _ => role,
      };

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ── Bottom sheets ──────────────────────────────────────────────────────────
  void _showCreationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreationOptionsSheet(
        onSmartTap: () {
          Navigator.pop(ctx);
          _showSmartRoleOptions();
        },
        onManualTap: () {
          Navigator.pop(ctx);
          _showAddUserSheet();
        },
      ),
    );
  }

  void _showSmartRoleOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SmartRoleSheet(
        onRoleSelected: (role) {
          Navigator.pop(ctx);
          _showCreateSmartUserSheet(role);
        },
      ),
    );
  }

  void _showCreateSmartUserSheet(String role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateSmartUserSheet(
        role: role,
        onSuccess: _fetchUsers,
      ),
    );
  }

  void _showAddUserSheet({UserModel? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditUserSheet(
        user: user,
        onSuccess: () {
          _fetchUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar(
              user != null ? 'User berhasil diperbarui!' : 'User berhasil ditambahkan!',
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Hapus User?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 14, color: _textSecondary, height: 1.5),
            children: [
              const TextSpan(text: 'Yakin ingin menghapus '),
              TextSpan(
                text: '"${user.name}"',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _textPrimary),
              ),
              const TextSpan(text: '? Tindakan ini tidak dapat dibatalkan.'),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4D),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.deleteUser(user.id);
      if (res['status'] == 'success') {
        _fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar('User berhasil dihapus!'),
          );
        }
      }
    }
  }

  SnackBar _buildSnackBar(String message) => SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(message,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildRoleFilter(),
          _buildListHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── Header with stats ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              // Title row
              Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'Manajemen User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats row
              Row(
                children: [
                  _buildStatCard(
                      label: 'Total', value: _users.length, dot: const Color(0xFFFFD166)),
                  const SizedBox(width: 10),
                  _buildStatCard(
                      label: 'Guru', value: _countByRole('guru'), dot: _green),
                  const SizedBox(width: 10),
                  _buildStatCard(
                      label: 'Orang Tua',
                      value: _countByRole('orang_tua'),
                      dot: _orange),
                  const SizedBox(width: 10),
                  _buildStatCard(
                      label: 'Kepsek',
                      value: _countByRole('kepsek'),
                      dot: _purple),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      {required String label, required int value, required Color dot}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
            fontSize: 14,
            color: _textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Cari nama, role, NIP, email…',
            hintStyle: const TextStyle(
              color: _textHint,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon:
                const Icon(Icons.search_rounded, color: _primary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: _textHint, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }

  // ── Role filter chips ──────────────────────────────────────────────────────
  Widget _buildRoleFilter() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _roleFilters.map((filter) {
            final isActive = _selectedRoleFilter == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRoleFilter = filter['value'] as String;
                    _applyFilter();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? _primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? _primary : _border,
                      width: isActive ? 1.5 : 1.5,
                    ),
                  ),
                  child: Text(
                    filter['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : _textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _buildListHeader() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          const Text(
            'DAFTAR PENGGUNA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textHint,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredUsers.length} user',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _primary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _fetchUsers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) =>
            _buildUserCard(_filteredUsers[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 36, color: _primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tidak ada user ditemukan',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coba ubah filter atau kata kunci pencarian',
            style: TextStyle(fontSize: 14, color: _textHint, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── User card ──────────────────────────────────────────────────────────────
  Widget _buildUserCard(UserModel user) {
    final color = _roleColor(user.role);
    final colorLight = _roleColorLight(user.role);
    final badgeTextColor = _roleBadgeTextColor(user.role);
    final identifier = user.nip ?? user.nisn ?? user.email ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(width: 4, color: color),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getInitials(user.name),
                          style: TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            // Role badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: colorLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_roleIcon(user.role),
                                      size: 12, color: badgeTextColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    _roleLabel(user.role),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: badgeTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.credit_card_rounded,
                                    size: 11, color: _textHint),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    identifier,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _textHint,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _actionButton(
                            icon: Icons.edit_rounded,
                            bgColor: _primaryLight,
                            iconColor: _primary,
                            onTap: () => _showAddUserSheet(user: user),
                          ),
                          if (user.role != 'operator') ...[
                            const SizedBox(height: 6),
                            _actionButton(
                              icon: Icons.delete_outline_rounded,
                              bgColor: const Color(0xFFFFF0F0),
                              iconColor: const Color(0xFFE84646),
                              onTap: () => _confirmDelete(user),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showCreationOptions,
      backgroundColor: _primary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
      label: const Text(
        'Tambah User',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Creation Options Sheet
// ═══════════════════════════════════════════════════════════════════════════
class _CreationOptionsSheet extends StatelessWidget {
  final VoidCallback onSmartTap;
  final VoidCallback onManualTap;

  const _CreationOptionsSheet({
    required this.onSmartTap,
    required this.onManualTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(),
          const Text(
            'Pilih Cara Membuat User',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2332),
            ),
          ),
          const SizedBox(height: 20),
          _SheetOption(
            icon: Icons.link_rounded,
            iconColor: const Color(0xFF34C97A),
            iconBg: const Color(0xFFEDFAF3),
            title: 'Buat User Smart',
            subtitle: 'Link ke Guru / Ortu / Kepsek yang ada',
            onTap: onSmartTap,
          ),
          const SizedBox(height: 10),
          _SheetOption(
            icon: Icons.person_add_rounded,
            iconColor: const Color(0xFF5B7FFF),
            iconBg: const Color(0xFFEEF2FF),
            title: 'Buat User Manual',
            subtitle: 'Input data lengkap secara manual',
            onTap: onManualTap,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF9BA8BE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Smart Role Sheet
// ═══════════════════════════════════════════════════════════════════════════
class _SmartRoleSheet extends StatelessWidget {
  final ValueChanged<String> onRoleSelected;

  const _SmartRoleSheet({required this.onRoleSelected});

  @override
  Widget build(BuildContext context) {
    final roles = [
      {
        'value': 'guru',
        'label': 'Guru',
        'subtitle': 'Hubungkan ke data guru',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF34C97A),
        'bg': const Color(0xFFEDFAF3),
      },
      {
        'value': 'orang_tua',
        'label': 'Orang Tua',
        'subtitle': 'Hubungkan ke data anak',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFFFF8C42),
        'bg': const Color(0xFFFFF4EC),
      },
      {
        'value': 'kepsek',
        'label': 'Kepala Sekolah',
        'subtitle': 'Akses penuh kepala sekolah',
        'icon': Icons.workspace_premium_rounded,
        'color': const Color(0xFF9B6DFF),
        'bg': const Color(0xFFF3EEFF),
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(),
          const Text(
            'Pilih Peran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2332),
            ),
          ),
          const SizedBox(height: 20),
          ...roles.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SheetOption(
                  icon: r['icon'] as IconData,
                  iconColor: r['color'] as Color,
                  iconBg: r['bg'] as Color,
                  title: r['label'] as String,
                  subtitle: r['subtitle'] as String,
                  onTap: () => onRoleSelected(r['value'] as String),
                ),
              )),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF9BA8BE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Add / Edit User Sheet
// ═══════════════════════════════════════════════════════════════════════════
class _AddEditUserSheet extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onSuccess;

  const _AddEditUserSheet({this.user, required this.onSuccess});

  @override
  State<_AddEditUserSheet> createState() => _AddEditUserSheetState();
}

class _AddEditUserSheetState extends State<_AddEditUserSheet> {
  late String _selectedRole;
  bool _obscurePassword = true;
  bool _isSaving = false;
  String? _errorMessage;

  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _identifierCtrl = TextEditingController();

  // Profile controllers specifically for Kepsek
  final _noHpCtrl = TextEditingController();
  final _tempatLahirCtrl = TextEditingController();
  final _tanggalLahirCtrl = TextEditingController();
  final _pendidikanCtrl = TextEditingController();
  final _jurusanCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _rtRwCtrl = TextEditingController();
  final _kelurahanCtrl = TextEditingController();
  final _kecamatanCtrl = TextEditingController();
  final _kotaCtrl = TextEditingController();
  final _provinsiCtrl = TextEditingController();
  final _kodePosCtrl = TextEditingController();

  String _selectedAgama = 'Islam';
  String _selectedGender = 'L';
  String _selectedNikah = 'Menikah';

  static const Color _primary = Color(0xFF5B7FFF);

  final _roles = [
    {
      'value': 'guru',
      'label': 'Guru',
      'icon': Icons.school_rounded,
      'color': const Color(0xFF34C97A),
    },
    {
      'value': 'orang_tua',
      'label': 'Orang Tua',
      'icon': Icons.people_alt_rounded,
      'color': const Color(0xFFFF8C42),
    },
    {
      'value': 'kepsek',
      'label': 'Kepsek',
      'icon': Icons.workspace_premium_rounded,
      'color': const Color(0xFF9B6DFF),
    },
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _selectedRole = u?.role ?? 'guru';
    _nameCtrl.text = u?.name ?? '';
    _identifierCtrl.text = u?.nip ?? u?.nisn ?? u?.email ?? '';

    if (u != null) {
      _noHpCtrl.text = u.noHp ?? '';
      _alamatCtrl.text = u.alamat ?? '';
      _tempatLahirCtrl.text = u.tempatLahir ?? '';
      _tanggalLahirCtrl.text = u.tanggalLahir ?? '';
      _pendidikanCtrl.text = u.pendidikan ?? '';
      _jurusanCtrl.text = u.jurusan ?? '';
      _rtRwCtrl.text = u.rtRw ?? '';
      _kelurahanCtrl.text = u.kelurahan ?? '';
      _kecamatanCtrl.text = u.kecamatan ?? '';
      _kotaCtrl.text = u.kota ?? '';
      _provinsiCtrl.text = u.provinsi ?? '';
      _kodePosCtrl.text = u.kodePos ?? '';

      _selectedAgama = u.agama ?? 'Islam';
      if (_selectedAgama.isEmpty) _selectedAgama = 'Islam';

      _selectedGender = u.jenisKelamin ?? 'L';
      if (_selectedGender.isEmpty) _selectedGender = 'L';

      _selectedNikah = u.statusNikah ?? 'Menikah';
      if (_selectedNikah.isEmpty) _selectedNikah = 'Menikah';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _identifierCtrl.dispose();

    _noHpCtrl.dispose();
    _tempatLahirCtrl.dispose();
    _tanggalLahirCtrl.dispose();
    _pendidikanCtrl.dispose();
    _jurusanCtrl.dispose();
    _alamatCtrl.dispose();
    _rtRwCtrl.dispose();
    _kelurahanCtrl.dispose();
    _kecamatanCtrl.dispose();
    _kotaCtrl.dispose();
    _provinsiCtrl.dispose();
    _kodePosCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.user != null;

  Color get _roleColor => switch (_selectedRole) {
        'guru' => const Color(0xFF34C97A),
        'orang_tua' => const Color(0xFFFF8C42),
        'kepsek' => const Color(0xFF9B6DFF),
        _ => _primary,
      };

  String get _identifierLabel => switch (_selectedRole) {
        'guru' => 'NIP',
        'kepsek' => 'NIP',
        'orang_tua' => 'NISN Anak',
        _ => 'Email',
      };

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Nama wajib diisi');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'role': _selectedRole,
    };

    if (_passwordCtrl.text.isNotEmpty) {
      data['password'] = _passwordCtrl.text;
    }

    switch (_selectedRole) {
      case 'guru':
      case 'kepsek':
        data['nip'] = _identifierCtrl.text;
        break;
      case 'orang_tua':
        data['nisn'] = _identifierCtrl.text;
        break;
      default:
        data['email'] = _identifierCtrl.text;
    }

    if (_selectedRole == 'kepsek') {
      data['no_hp'] = _noHpCtrl.text.trim();
      data['alamat'] = _alamatCtrl.text.trim();
      data['tempat_lahir'] = _tempatLahirCtrl.text.trim();
      data['tanggal_lahir'] = _tanggalLahirCtrl.text.trim();
      data['pendidikan'] = _pendidikanCtrl.text.trim();
      data['jurusan'] = _jurusanCtrl.text.trim();
      data['rt_rw'] = _rtRwCtrl.text.trim();
      data['kelurahan'] = _kelurahanCtrl.text.trim();
      data['kecamatan'] = _kecamatanCtrl.text.trim();
      data['kota'] = _kotaCtrl.text.trim();
      data['provinsi'] = _provinsiCtrl.text.trim();
      data['kode_pos'] = _kodePosCtrl.text.trim();
      data['agama'] = _selectedAgama;
      data['jenis_kelamin'] = _selectedGender;
      data['status_nikah'] = _selectedNikah;
    }

    dynamic res;
    try {
      if (_isEdit) {
        data['id'] = widget.user!.id;
        res = await ApiService.updateUser(data);
      } else {
        res = await ApiService.addUser(data);
      }

      setState(() => _isSaving = false);

      if (res['status'] == 'success') {
        if (mounted) Navigator.pop(context);
        widget.onSuccess();
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Terjadi kesalahan';
        });
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Koneksi gagal: $e';
      });
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: _roleColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _roleColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),

              // Sheet title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: _roleColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _isEdit
                          ? Icons.edit_rounded
                          : Icons.person_add_rounded,
                      color: _roleColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit User' : 'Tambah User Baru',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2332),
                          ),
                        ),
                        Text(
                          _isEdit
                              ? 'Perbarui data pengguna'
                              : 'Isi data pengguna dengan lengkap',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9BA8BE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Role selector
              const Text(
                'Pilih Peran',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A6882),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _roles.map((r) {
                  final isSelected = _selectedRole == r['value'];
                  final c = r['color'] as Color;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedRole = r['value'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? c : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? c : const Color(0xFFE8EDF5),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              r['icon'] as IconData,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF9BA8BE),
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r['label'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF9BA8BE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              _buildField(
                ctrl: _nameCtrl,
                label: 'Nama Lengkap',
                icon: Icons.badge_rounded,
                hint: 'Masukkan nama lengkap',
              ),
              const SizedBox(height: 14),
              _buildField(
                ctrl: _identifierCtrl,
                label: _identifierLabel,
                icon: Icons.fingerprint_rounded,
                hint: 'Masukkan $_identifierLabel',
              ),
              const SizedBox(height: 14),

              // Password field
              _buildFieldLabel('Password'),
              const SizedBox(height: 6),
              _fieldContainer(
                child: TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: _isEdit
                        ? 'Kosongkan jika tidak diubah'
                        : 'Minimal 6 karakter',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9BA8BE),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.lock_rounded,
                        color: _roleColor, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: const Color(0xFF9BA8BE),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Detailed Profile Fields (specifically for Kepsek)
              if (_selectedRole == 'kepsek') ...[
                _sectionTitle('Identitas Detail'),
                _buildField(ctrl: _noHpCtrl, label: 'No. HP / Telepon', icon: Icons.phone_rounded, hint: 'Masukkan no. HP'),
                const SizedBox(height: 14),
                _buildField(ctrl: _tempatLahirCtrl, label: 'Tempat Lahir', icon: Icons.location_city_rounded, hint: 'Masukkan tempat lahir'),
                const SizedBox(height: 14),
                _buildField(ctrl: _tanggalLahirCtrl, label: 'Tanggal Lahir (TTTT-BB-HH)', icon: Icons.cake_rounded, hint: 'Contoh: 1980-08-17'),
                const SizedBox(height: 14),

                _buildFieldLabel('Jenis Kelamin'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Laki-laki', style: TextStyle(fontSize: 13)),
                        value: 'L',
                        groupValue: _selectedGender,
                        contentPadding: EdgeInsets.zero,
                        activeColor: _roleColor,
                        onChanged: (val) => setState(() => _selectedGender = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Perempuan', style: TextStyle(fontSize: 13)),
                        value: 'P',
                        groupValue: _selectedGender,
                        contentPadding: EdgeInsets.zero,
                        activeColor: _roleColor,
                        onChanged: (val) => setState(() => _selectedGender = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Agama'),
                const SizedBox(height: 6),
                _fieldContainer(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAgama,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      items: ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu']
                          .map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedAgama = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Status Pernikahan'),
                const SizedBox(height: 6),
                _fieldContainer(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedNikah,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      items: ['Menikah', 'Belum Menikah', 'Duda/Janda']
                          .map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedNikah = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                _sectionTitle('Riwayat Pendidikan'),
                _buildField(ctrl: _pendidikanCtrl, label: 'Pendidikan Terakhir', icon: Icons.school_rounded, hint: 'Contoh: S1 PGPAUD'),
                const SizedBox(height: 14),
                _buildField(ctrl: _jurusanCtrl, label: 'Jurusan', icon: Icons.menu_book_rounded, hint: 'Masukkan jurusan'),
                const SizedBox(height: 14),

                _sectionTitle('Alamat Lengkap'),
                _buildField(ctrl: _alamatCtrl, label: 'Alamat Jalan', icon: Icons.location_on_rounded, hint: 'Masukkan alamat jalan'),
                const SizedBox(height: 14),
                _buildField(ctrl: _rtRwCtrl, label: 'RT / RW', icon: Icons.grid_view_rounded, hint: 'Contoh: 002/001'),
                const SizedBox(height: 14),
                _buildField(ctrl: _kelurahanCtrl, label: 'Kelurahan', icon: Icons.villa_rounded, hint: 'Masukkan kelurahan'),
                const SizedBox(height: 14),
                _buildField(ctrl: _kecamatanCtrl, label: 'Kecamatan', icon: Icons.map_rounded, hint: 'Masukkan kecamatan'),
                const SizedBox(height: 14),
                _buildField(ctrl: _kotaCtrl, label: 'Kota / Kabupaten', icon: Icons.location_city_rounded, hint: 'Masukkan kota'),
                const SizedBox(height: 14),
                _buildField(ctrl: _provinsiCtrl, label: 'Provinsi', icon: Icons.apartment_rounded, hint: 'Masukkan provinsi'),
                const SizedBox(height: 14),
                _buildField(ctrl: _kodePosCtrl, label: 'Kode Pos', icon: Icons.local_post_office_rounded, hint: 'Masukkan kode pos'),
                const SizedBox(height: 20),
              ],

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _roleColor,
                    disabledBackgroundColor: _roleColor.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isEdit
                                  ? Icons.edit_rounded
                                  : Icons.save_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEdit ? 'Update User' : 'Simpan User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? type,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        _fieldContainer(
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9BA8BE),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: _roleColor, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF5A6882),
        ),
      );

  Widget _fieldContainer({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EDF5)),
        ),
        child: child,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Shared small widgets
// ═══════════════════════════════════════════════════════════════════════════
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EDF5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF5), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2332),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5A6882),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF9BA8BE), size: 20),
          ],
        ),
      ),
    );
  }
}
