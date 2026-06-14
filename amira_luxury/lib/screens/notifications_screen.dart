import 'package:flutter/material.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFB5945A);
const _olive = Color(0xFF556B4A);

class NotificationItem {
  final String id;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final String time;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      icon: Icons.collections_rounded,
      iconColor: _gold,
      iconBg: Color(0xFFF5EFE3),
      title: 'New Collection Added',
      body: 'Explore our latest PVC marble sheets and bamboo wall panels.',
      time: '2 hours ago',
    ),
    NotificationItem(
      id: '2',
      icon: Icons.local_offer_rounded,
      iconColor: _gold,
      iconBg: Color(0xFFF5EFE3),
      title: 'Exclusive Offer',
      body: 'Enjoy 15% off your first design request this month.',
      time: '1 day ago',
    ),
    NotificationItem(
      id: '3',
      icon: Icons.check_circle_rounded,
      iconColor: _olive,
      iconBg: Color(0xFFEAEFE6),
      title: 'Request Received',
      body: 'Your material request has been received by the Amira team.',
      time: '2 days ago',
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      icon: Icons.auto_awesome_rounded,
      iconColor: _gold,
      iconBg: Color(0xFFF5EFE3),
      title: 'Your Design is Ready',
      body: 'Your Interior Vision Studio render is ready to view.',
      time: '3 days ago',
      isRead: true,
    ),
  ];

  void _markAsRead(String id) {
    setState(() {
      final item = _notifications.firstWhere((n) => n.id == id);
      item.isRead = true;
    });
  }

  void _delete(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

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
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _NotificationTile(
                        item: _notifications[i],
                        onMarkRead: () => _markAsRead(_notifications[i].id),
                        onDelete: () => _delete(_notifications[i].id),
                      ),
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
            child: const Icon(Icons.notifications_rounded, color: _gold, size: 38),
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

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.item,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isRead ? _white.withOpacity(0.55) : _white,
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
          // Icon chip
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(item.icon, color: item.iconColor, size: 22)),
          ),
          const SizedBox(width: 14),
          // Text content
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
                    if (!item.isRead) ...[
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
                  item.time,
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
          // 3-dot menu
          _OptionsMenu(
            isRead: item.isRead,
            onMarkRead: onMarkRead,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _OptionsMenu extends StatelessWidget {
  final bool isRead;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _OptionsMenu({
    required this.isRead,
    required this.onMarkRead,
    required this.onDelete,
  });

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
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        if (!isRead)
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
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete_rounded, size: 18, color: Color(0xFFE74C3C)),
              SizedBox(width: 10),
              Text(
                'Delete',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE74C3C),
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
