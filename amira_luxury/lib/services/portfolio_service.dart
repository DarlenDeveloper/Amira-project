import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/portfolio.dart';

/// Read-only access to the admin-authored `portfolio` collection.
///
/// The app shows only published entries. See `.kiro/steering/data-model.md`.
class PortfolioService {
  PortfolioService._();
  static final PortfolioService instance = PortfolioService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _portfolio =>
      _db.collection('portfolio');

  /// Live list of published portfolio entries, ordered for display.
  /// Equality-only query (no composite index needed); sort client-side.
  Stream<List<Portfolio>> watchPublished() {
    return _portfolio
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snap) {
      final items = snap.docs.map(Portfolio.fromDoc).toList();
      items.sort((a, b) => a.order.compareTo(b.order));
      return items;
    });
  }
}
