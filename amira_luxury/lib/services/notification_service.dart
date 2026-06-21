import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification.dart';

/// Read-only access to admin broadcast notifications plus per-user read state.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  /// Live broadcasts for the signed-in user (or all guests if [uid] is null).
  Stream<List<AmiraNotification>> watchForUser({String? uid}) {
    return _notifications.orderBy('sentAt', descending: true).snapshots().map(
      (snap) {
        final list = snap.docs
            .map(AmiraNotification.fromDoc)
            .where((n) => n.matchesAudience(uid))
            .toList();
        return list;
      },
    );
  }

  Stream<Set<String>> watchReadIds(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notificationState')
        .snapshots()
        .map(
          (snap) => snap.docs
              .where((d) => d.data()['readAt'] != null)
              .map((d) => d.id)
              .toSet(),
        );
  }

  Future<void> markRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('notificationState')
        .doc(notificationId)
        .set({'readAt': FieldValue.serverTimestamp()});
  }

  /// Unread broadcast count for the home-screen badge.
  Stream<int> watchUnreadCount() {
    final uid = _auth.currentUser?.uid;
    return watchForUser(uid: uid).asyncExpand((notifications) {
      if (uid == null) {
        return Stream.value(notifications.length);
      }
      return watchReadIds(uid).map(
        (readIds) =>
            notifications.where((n) => !readIds.contains(n.id)).length,
      );
    });
  }

  String formatTimeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
