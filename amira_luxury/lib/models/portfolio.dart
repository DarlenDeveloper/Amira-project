import 'package:cloud_firestore/cloud_firestore.dart';

/// A completed/showcase interior project, backed by `portfolio/{docId}`.
///
/// Admin-authored. Images come only from [imageUrl] (no bundled fallback). Each
/// entry references the Amira product used on the project — the app shows the
/// product name where a price used to sit. See `.kiro/steering/data-model.md`.
class Portfolio {
  final String id;
  final String title;
  final String? imageUrl;
  final String room;
  final String location;
  final String size;
  final String productId;
  final String productName;
  final String status; // published | draft | concept
  final int order;

  const Portfolio({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.room,
    required this.location,
    required this.size,
    required this.productId,
    required this.productName,
    required this.status,
    required this.order,
  });

  factory Portfolio.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Portfolio(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      imageUrl: data['imageUrl'] as String?,
      room: (data['room'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      size: (data['size'] as String?) ?? '',
      productId: (data['productId'] as String?) ?? '',
      productName: (data['productName'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'draft',
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }
}
