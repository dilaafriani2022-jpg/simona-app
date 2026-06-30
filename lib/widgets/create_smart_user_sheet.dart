import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Bottom sheet that lets an operator quickly create a user account
/// (set password) for an existing guru / orang_tua / kepsek record.
class CreateSmartUserSheet extends StatefulWidget {
  final String role;
  final VoidCallback onSuccess;

  const CreateSmartUserSheet({
    super.key,
    required this.role,
    required this.onSuccess,
  });

  @override
  State<CreateSmartUserSheet> createState() => _CreateSmartUserSheetState();
}

class _CreateSmartUserSheetState extends State<CreateSmartUserSheet> {
  // ── Palette ─────────────────────────────────────────────────────────────────
  static const Color _primary     = Color(0xFF5B7FFF);
  static const Color _bg          = Color(0xFFF0F4F8);
  static const Color _surface     = Colors.white;
  static const Color _textPrimary = Color(0xFF1A2332);
  static const Color _textSub     = Color(0xFF5A6882);
  static const Color _border      = Color(0xFFDDE3EE);
  static const Color _error       = Color(0xFFE53935);
  static const Color _success     = Color(0xFF43A047);

  // ── State ───────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _sourceList = [];
  Map<String, dynamic>?      _selectedSource;
  bool   _isLoading        = true;
  bool   _isSaving         = false;
  bool   _obscurePass      = true;
  bool   _obscureConfirm   = true;
  String _errorMsg         = '';

  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────
  Future<void> _loadSources() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getUsers();
      if (result['status'] == 'success') {
        final all = (result['data'] as List)
            .cast<Map<String, dynamic>>();
        final filtered = all
            .where((u) => u['role'] == widget.role)
            .toList();
        setState(() {
          _sourceList = filtered;
          _isLoading  = false;
        });
      } else {
        setState(() {
          _sourceList = [];
          _isLoading  = false;
        });
      }
    } catch (_) {
      setState(() {
        _sourceList = [];
        _isLoading  = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSource == null) {
      setState(() => _errorMsg = 'Pilih data ${_roleName()} terlebih dahulu');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMsg = '';
    });

    try {
      final result = await ApiService.createSmartUser(
        role:     widget.role,
        sourceId: int.tryParse(_selectedSource!['id']?.toString() ?? '0') ?? 0,
        password: _passCtrl.text.trim(),
      );

      if (!mounted) return;

      if (result['status'] == 'success') {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${_roleName()} berhasil dibuat!'),
            backgroundColor: _success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _errorMsg = result['message'] ?? 'Terjadi kesalahan');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Koneksi gagal: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _roleName() {
    switch (widget.role) {
      case 'guru':       return 'Guru';
      case 'orang_tua':  return 'Orang Tua';
      case 'kepsek':     return 'Kepala Sekolah';
      default:           return widget.role;
    }
  }

  String _displayName(Map<String, dynamic> u) {
    return u['name'] ?? u['nama'] ?? 'ID ${u['id']}';
  }

  // ── UI ───────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              'Buat Akun ${_roleName()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set password untuk akun ${_roleName().toLowerCase()} yang sudah terdaftar.',
              style: const TextStyle(fontSize: 13, color: _textSub),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source dropdown
                    _label('Pilih ${_roleName()}'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(10),
                        color: _bg,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          isExpanded: true,
                          value: _selectedSource,
                          hint: Text(
                            'Pilih ${_roleName()}...',
                            style: const TextStyle(color: _textSub, fontSize: 14),
                          ),
                          items: _sourceList.map((u) {
                            return DropdownMenuItem(
                              value: u,
                              child: Text(
                                _displayName(u),
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedSource = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _label('Password Baru'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      decoration: _inputDecoration(
                        hint: 'Minimal 6 karakter',
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePass ? Icons.visibility_off : Icons.visibility,
                            color: _textSub, size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Password wajib diisi';
                        if (v.trim().length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    _label('Konfirmasi Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      decoration: _inputDecoration(
                        hint: 'Ulangi password',
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: _textSub, size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Konfirmasi password wajib diisi';
                        if (v.trim() != _passCtrl.text.trim()) return 'Password tidak cocok';
                        return null;
                      },
                    ),

                    // Error msg
                    if (_errorMsg.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: _error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMsg,
                                style: const TextStyle(color: _error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: _border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(color: _textSub),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Buat Akun',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
      );

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textSub, fontSize: 14),
        suffixIcon: suffix,
        filled: true,
        fillColor: _bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _error, width: 1.5),
        ),
      );
}

