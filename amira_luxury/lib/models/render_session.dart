import 'package:cloud_firestore/cloud_firestore.dart';

/// A Visual Studio render session backed by `users/{uid}/renders/{id}`.
class RenderSession {
  final String id;
  final String status;
  final String? roomImageUrl;
  final String? resultUrl;
  final List<String> materialNames;
  final List<String> productIds;
  final String? prompt;
  final String? error;
  final DateTime? createdAt;

  const RenderSession({
    required this.id,
    required this.status,
    this.roomImageUrl,
    this.resultUrl,
    this.materialNames = const [],
    this.productIds = const [],
    this.prompt,
    this.error,
    this.createdAt,
  });

  factory RenderSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RenderSession(
      id: doc.id,
      status: (data['status'] as String?) ?? 'unknown',
      roomImageUrl: data['roomImageUrl'] as String?,
      resultUrl: data['resultUrl'] as String?,
      materialNames: (data['materialNames'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      productIds:
          (data['productIds'] as List?)?.whereType<String>().toList() ?? const [],
      prompt: data['prompt'] as String?,
      error: data['error'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
