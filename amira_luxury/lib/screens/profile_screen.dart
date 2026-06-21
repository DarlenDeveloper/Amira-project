import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_shell_controller.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';
import 'appointments_screen.dart';
import 'renders_screen.dart';
import 'password_security_screen.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _divider = Color(0xFFEDEDE8);
const _red = Color(0xFFB23A3A);
const _gold = Color(0xFFC4A464);

/// External site that backs About Us, Terms & Conditions and Privacy Policy.
const _amiraWebsite = 'https://amirainteriors.com/';

/// Reasons offered when a user chooses to delete their account.
const List<String> _deleteReasons = [
  'I no longer use the app',
  'I found a better alternative',
  'Privacy concerns',
  'Too many notifications',
  'Something didn\'t work as expected',
  'Other',
];

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Menu divided into logical sections. Language removed; Subscription, Orders,
  // Terms & Conditions and Privacy Policy added.
  static const List<_MenuSection> _sections = [
    _MenuSection('Account', [
      _MenuEntry(Iconsax.profile_circle5, 'Manage Profile'),
      _MenuEntry(Iconsax.crown5, 'Subscription', comingSoon: true),
      _MenuEntry(Iconsax.shopping_cart5, 'Orders'),
      _MenuEntry(Iconsax.gallery5, 'My Renders'),
      _MenuEntry(Iconsax.calendar5, 'Appointments'),
    ]),
    _MenuSection('Security & Alerts', [
      _MenuEntry(Iconsax.lock5, 'Password & Security'),
      _MenuEntry(Iconsax.notification5, 'Notifications'),
    ]),
    _MenuSection('About & Legal', [
      _MenuEntry(Iconsax.info_circle5, 'About Us'),
      _MenuEntry(Iconsax.document_text5, 'Terms & Conditions'),
      _MenuEntry(Iconsax.shield_tick5, 'Privacy Policy'),
      _MenuEntry(Iconsax.profile_delete5, 'Delete My Account'),
    ]),
    _MenuSection('Support', [
      _MenuEntry(Iconsax.message_question5, 'Help Center'),
      _MenuEntry(Iconsax.call5, 'Contact Us'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button + centered title
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
                    'Profile',
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
                  children: [
                    _buildUserCard(),
                    const SizedBox(height: 24),
                    ..._sections.map((s) => _buildSection(context, s)),
                    _buildLogoutButton(context),
                    const SizedBox(height: 24),
                    const Text(
                      'Developed by Togashi Technologies',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _grey,
                        fontFamily: 'Plus Jakarta Sans',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<AppUser?>(
      stream: user == null ? null : AuthService.instance.profileStream(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        final profileName = profile?.name?.trim();
        final authName = user?.displayName?.trim();
        final name = (profileName != null && profileName.isNotEmpty)
            ? profileName
            : (authName != null && authName.isNotEmpty)
                ? authName
                : 'Amira Member';

        final subtitle = profile?.email ??
            user?.email ??
            profile?.phone ??
            user?.phoneNumber ??
            '';

        final photoUrl = profile?.photoUrl ?? user?.photoURL;
        final ImageProvider avatar = (photoUrl != null && photoUrl.isNotEmpty)
            ? NetworkImage(photoUrl)
            : const AssetImage('assets/images/user_avatar.jpg') as ImageProvider;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(20),
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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: avatar, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: _grey,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _confirmSignOut(context),
        behavior: HitTestBehavior.opaque,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: Icon(Iconsax.logout5, color: Color(0xFFB23A3A), size: 22),
                ),
              ),
              SizedBox(width: 14),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB23A3A),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _dark,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        content: const Text(
          'You\'ll need to sign in again to access your account.',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: _grey,
            fontFamily: 'Plus Jakarta Sans',
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _grey,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Log Out',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFB23A3A),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Opens the Amira website (About Us / Terms & Conditions / Privacy Policy).
  Future<void> _openWebsite(BuildContext context) async {
    final uri = Uri.parse(_amiraWebsite);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the website.',
            style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
          ),
        ),
      );
    }
  }

  /// Asks the user why they're leaving, then signs them out.
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    String? selectedReason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: _white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Delete account?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _dark,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We\'re sorry to see you go. Could you tell us why you\'re leaving?',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: _grey,
                  fontFamily: 'Plus Jakarta Sans',
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              for (final reason in _deleteReasons)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => selectedReason = reason),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          selectedReason == reason
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selectedReason == reason ? _gold : _grey,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: _dark,
                              fontWeight: selectedReason == reason
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _grey,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: Text(
                'Delete & Log Out',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selectedReason == null ? _grey : _red,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    // Per spec: capture the selected reason, then sign the user out.
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildSection(BuildContext context, _MenuSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            section.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _grey,
              fontFamily: 'Plus Jakarta Sans',
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < section.entries.length; i++) ...[
                _MenuTile(
                  entry: section.entries[i],
                  onTap: () {
                    final label = section.entries[i].label;
                    if (label == 'Manage Profile') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    } else if (label == 'Orders') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OrdersScreen(),
                        ),
                      );
                    } else if (label == 'My Renders') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RendersScreen(),
                        ),
                      );
                    } else if (label == 'Appointments') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AppointmentsScreen(),
                        ),
                      );
                    } else if (label == 'Notifications') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    } else if (label == 'Password & Security') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PasswordSecurityScreen(),
                        ),
                      );
                    } else if (label == 'About Us' ||
                        label == 'Terms & Conditions' ||
                        label == 'Privacy Policy') {
                      _openWebsite(context);
                    } else if (label == 'Delete My Account') {
                      _confirmDeleteAccount(context);
                    } else if (label == 'Help Center' ||
                        label == 'Contact Us') {
                      // Route support requests to the Amira AI agent tab.
                      final shell = AppShellController.maybeOf(context);
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      shell?.openAgent(source: 'support');
                    }
                  },
                ),
                if (i != section.entries.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 56),
                    child: Divider(height: 1, thickness: 1, color: _divider),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}

class _MenuSection {
  final String title;
  final List<_MenuEntry> entries;
  const _MenuSection(this.title, this.entries);
}

class _MenuEntry {
  final IconData icon;
  final String label;
  final bool comingSoon;
  const _MenuEntry(this.icon, this.label, {this.comingSoon = false});
}

class _MenuTile extends StatelessWidget {
  final _MenuEntry entry;
  final VoidCallback onTap;

  const _MenuTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final comingSoon = entry.comingSoon;
    return GestureDetector(
      onTap: comingSoon ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Icon(entry.icon,
                    color: comingSoon ? _grey : _dark, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                entry.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: comingSoon ? _grey : _dark,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            if (comingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Coming soon',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _gold,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              )
            else
              const Icon(Iconsax.arrow_right_3, color: _grey, size: 20),
          ],
        ),
      ),
    );
  }
}
