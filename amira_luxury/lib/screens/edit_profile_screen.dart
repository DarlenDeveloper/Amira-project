import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFC4A464);

/// Lets the signed-in user edit their name and address. Read-only identity
/// fields (email / phone) are shown for context but can't be changed here,
/// since they're tied to the auth credential.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  AppUser? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final profile = await AuthService.instance.fetchProfile(user.uid);
      _profile = profile;
      _nameController.text = profile?.name ?? user.displayName ?? '';
      _addressController.text = profile?.address ?? '';
    } catch (_) {
      // Leave fields blank on failure; the user can still enter values.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _canSave =>
      !_saving &&
      _nameController.text.trim().isNotEmpty &&
      _addressController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateProfile(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
      );
      if (!mounted) return;
      _showMessage('Profile updated.');
      Navigator.of(context).maybePop();
    } catch (_) {
      _showMessage('Couldn\'t save changes. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
        backgroundColor: _dark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = _profile?.email ?? user?.email;
    final phone = _profile?.phone ?? user?.phoneNumber;
    
    // Determine if user authenticated with phone
    // If phone exists, we prioritize showing phone over email
    final isPhoneAuth = (phone != null && phone.isNotEmpty);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(_gold),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label('Full name'),
                            _field(
                              icon: Iconsax.user,
                              hint: 'Your full name',
                              controller: _nameController,
                              keyboard: TextInputType.name,
                            ),
                            const SizedBox(height: 20),
                            _label('Address'),
                            _field(
                              icon: Iconsax.location,
                              hint: 'Your address',
                              controller: _addressController,
                              keyboard: TextInputType.streetAddress,
                            ),
                            if (isPhoneAuth) ...[
                              const SizedBox(height: 20),
                              _label('Phone'),
                              _readOnly(Iconsax.call, phone!),
                            ] else if (email != null && email.isNotEmpty && !email.contains('@phone.')) ...[
                              const SizedBox(height: 20),
                              _label('Email'),
                              _readOnly(Iconsax.sms, email),
                            ],
                            const SizedBox(height: 36),
                            _saveButton(),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
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
            'Manage Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _dark,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _grey,
          fontFamily: 'Plus Jakarta Sans',
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _field({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _dark),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboard,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _dark,
                fontFamily: 'Plus Jakarta Sans',
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF9A958E),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Plus Jakarta Sans',
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnly(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDE8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _grey,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
          const Icon(Iconsax.lock_1, size: 16, color: _grey),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return GestureDetector(
      onTap: _canSave ? _save : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _canSave || _saving ? 1 : 0.5,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(_white),
                  ),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _white,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
        ),
      ),
    );
  }
}
