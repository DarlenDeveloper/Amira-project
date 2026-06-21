import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin broadcast notification (`notifications/{docId}`).
class AmiraNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String audience;
  final DateTime? sentAt;

  const AmiraNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.audience,
    required this.sentAt,
  });

  factory AmiraNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final sent = data['sentAt'];
    return AmiraNotification(
      id: doc.id,
      type: (data['type'] as String?) ?? 'collection',
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      audience: (data['audience'] as String?) ?? 'all',
      sentAt: sent is Timestamp ? sent.toDate() : null,
    );
  }

  bool matchesAudience(String? uid) {
    final a = audience.trim().toLowerCase();
    if (a == 'all' || a == 'all users' || a == 'all users & guests') return true;
    if (uid != null && a == 'user:$uid') return true;
    return false;
  }
}
