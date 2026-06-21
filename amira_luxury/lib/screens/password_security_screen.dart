import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import '../services/auth_service.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFC4A464);
const _red = Color(0xFFB23A3A);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDateTime(DateTime? dt) {
  if (dt == null) return 'Unknown';
  final local = dt.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  final ampm = local.hour < 12 ? 'AM' : 'PM';
  return '${_months[local.month - 1]} ${local.day}, ${local.year} at $h:$m $ampm';
}

/// Shows account security info (last sign-in) and a change-password form.
class PasswordSecurityScreen extends StatefulWidget {
  const PasswordSecurityScreen({super.key});

  @override
  State<PasswordSecurityScreen> createState() => _PasswordSecurityScreenState();
}

class _PasswordSecurityScreenState extends State<PasswordSecurityScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    setState(() => _error = null);

    if (current.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    if (next.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'New passwords don\'t match.');
      return;
    }
    if (next == current) {
      setState(() => _error = 'New password must differ from the current one.');
      return;
    }

    setState(() => _saving = true);
    try {
      await AuthService.instance.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      if (!mounted) return;
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password updated.',
            style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
          ),
          backgroundColor: _dark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final canChange = auth.canChangePassword;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: _white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: _dark, size: 20),
                      ),
                    ),
                  ),
                  const Text(
                    'Password & Security',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSecurityCard(auth),
                    const SizedBox(height: 24),
                    _sectionLabel('CHANGE PASSWORD'),
                    const SizedBox(height: 10),
                    if (canChange)
                      _buildPasswordForm()
                    else
                      _buildNoPasswordCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _grey,
            fontFamily: 'Plus Jakarta Sans',
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

  Widget _buildSecurityCard(AuthService auth) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Iconsax.clock5, 'Last signed in',
              _formatDateTime(auth.lastSignInTime)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEDEDE8)),
          ),
          _infoRow(Iconsax.user_add, 'Member since',
              _formatDateTime(auth.accountCreatedTime)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Center(child: Icon(icon, color: _gold, size: 20)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _grey,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _dark,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordForm() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _passwordField(
            label: 'Current password',
            controller: _currentCtrl,
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 16),
          _passwordField(
            label: 'New password',
            controller: _newCtrl,
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 16),
          _passwordField(
            label: 'Confirm new password',
            controller: _confirmCtrl,
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: const TextStyle(
                color: _red,
                fontSize: 13,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _saving ? null : _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _saving ? _gold.withValues(alpha: 0.6) : _gold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _saving ? 'Updating…' : 'Update password',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _dark,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: _dark,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure ? Iconsax.eye_slash : Iconsax.eye,
                color: _grey,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPasswordCard() {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.info_circle5, color: _gold, size: 22),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'You signed in with Google, so there\'s no password to change. '
              'Manage your password through your Google account.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _dark,
                fontFamily: 'Plus Jakarta Sans',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
