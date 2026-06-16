import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _divider = Color(0xFFEDEDE8);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Menu divided into logical sections. Language removed; Subscription, Orders,
  // Terms & Conditions and Privacy Policy added.
  static const List<_MenuSection> _sections = [
    _MenuSection('Account', [
      _MenuEntry(Iconsax.profile_circle5, 'Manage Profile'),
      _MenuEntry(Iconsax.crown5, 'Subscription'),
      _MenuEntry(Iconsax.shopping_cart5, 'Orders'),
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
                      fontFamily: 'Satoshi',
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
                        fontFamily: 'Satoshi',
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
                          fontFamily: 'Satoshi',
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
                  fontFamily: 'Satoshi',
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
            fontFamily: 'Satoshi',
          ),
        ),
        content: const Text(
          'You\'ll need to sign in again to access your account.',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: _grey,
            fontFamily: 'Satoshi',
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
                fontFamily: 'Satoshi',
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
                fontFamily: 'Satoshi',
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
              fontFamily: 'Satoshi',
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
                    if (section.entries[i].label == 'Notifications') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
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
  const _MenuEntry(this.icon, this.label);
}

class _MenuTile extends StatelessWidget {
  final _MenuEntry entry;
  final VoidCallback onTap;

  const _MenuTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Center(child: Icon(entry.icon, color: _dark, size: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                entry.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _dark,
                  fontFamily: 'Satoshi',
                ),
              ),
            ),
            const Icon(Iconsax.arrow_right_3, color: _grey, size: 20),
          ],
        ),
      ),
    );
  }
}
