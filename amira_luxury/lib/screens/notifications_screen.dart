import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFB5945A);
const _olive = Color(0xFF556B4A);

class _TypeStyle {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _TypeStyle({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

_TypeStyle _styleFor(String type) {
  switch (type) {
    case 'offer':
      return const _TypeStyle(
        icon: Icons.local_offer_rounded,
        iconColor: _gold,
        iconBg: Color(0xFFF5EFE3),
      );
    case 'order':
      return const _TypeStyle(
        icon: Icons.check_circle_rounded,
        iconColor: _olive,
        iconBg: Color(0xFFEAEFE6),
      );
    case 'design':
      return const _TypeStyle(
        icon: Icons.auto_awesome_rounded,
        iconColor: _gold,
        iconBg: Color(0xFFF5EFE3),
      );
    case 'collection':
    default:
      return const _TypeStyle(
        icon: Icons.collections_rounded,
        iconColor: _gold,
        iconBg: Color(0xFFF5EFE3),
      );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
                    'NOTIFICATIONS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                      fontFamily: 'Satoshi',
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<AmiraNotification>>(
                stream: NotificationService.instance.watchForUser(uid: uid),
                builder: (context, notifSnap) {
                  if (notifSnap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _gold, strokeWidth: 2),
                    );
                  }
                  final notifications = notifSnap.data ?? const <AmiraNotification>[];
                  if (notifications.isEmpty) {
                    return _buildEmptyState();
                  }
                  if (uid == null) {
                    return _NotificationList(
                      notifications: notifications,
                      readIds: const {},
                    );
                  }
                  return StreamBuilder<Set<String>>(
                    stream: NotificationService.instance.watchReadIds(uid),
                    builder: (context, readSnap) {
                      return _NotificationList(
                        notifications: notifications,
                        readIds: readSnap.data ?? const {},
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFFF5EFE3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.notification5, color: _gold, size: 38),
          ),
          const SizedBox(height: 20),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _dark,
              fontFamily: 'Satoshi',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "We'll let you know when something arrives.",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _grey,
              fontFamily: 'Satoshi',
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<AmiraNotification> notifications;
  final Set<String> readIds;

  const _NotificationList({
    required this.notifications,
    required this.readIds,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final item = notifications[i];
        final isRead = readIds.contains(item.id);
        return _NotificationTile(
          item: item,
          isRead: isRead,
          onMarkRead: () => NotificationService.instance.markRead(item.id),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AmiraNotification item;
  final bool isRead;
  final VoidCallback onMarkRead;

  const _NotificationTile({
    required this.item,
    required this.isRead,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(item.type);
    final time = NotificationService.instance.formatTimeAgo(item.sentAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? _white.withOpacity(0.55) : _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: style.iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(style.icon, color: style.iconColor, size: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                          fontFamily: 'Satoshi',
                        ),
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _grey,
                    fontFamily: 'Satoshi',
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _grey,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ],
            ),
          ),
          if (!isRead)
            _OptionsMenu(onMarkRead: onMarkRead),
        ],
      ),
    );
  }
}

class _OptionsMenu extends StatelessWidget {
  final VoidCallback onMarkRead;

  const _OptionsMenu({required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: _grey, size: 20),
      color: _white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'read') onMarkRead();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'read',
          child: Row(
            children: const [
              Icon(Icons.check_circle_rounded, size: 18, color: _dark),
              SizedBox(width: 10),
              Text(
                'Mark as read',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _dark,
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
