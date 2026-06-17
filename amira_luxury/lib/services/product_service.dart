import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

/// Read-only access to the admin-authored `products` catalogue.
///
/// Screens talk to [ProductService.instance] — never to Firestore directly.
/// Products are written by the admin (see `.kiro/steering/data-model.md`); the
/// app only reads.
class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  /// Live catalogue, ordered for stable display.
  Stream<List<Product>> watchProducts() {
    return _products.orderBy('order').snapshots().map(
          (snap) => snap.docs.map(Product.fromDoc).toList(),
        );
  }

  /// Distinct category labels present in the catalogue, in first-seen order.
  /// Useful for building the Explore filter pills from live data.
  List<String> categoriesOf(List<Product> products) {
    final seen = <String>{};
    final result = <String>[];
    for (final p in products) {
      if (p.category.isNotEmpty && seen.add(p.category)) {
        result.add(p.category);
      }
    }
    return result;
  }

  Stream<Product?> watchProduct(String id) {
    return _products.doc(id).snapshots().map(
          (doc) => doc.exists ? Product.fromDoc(doc) : null,
        );
  }

  Future<Product?> fetchProduct(String id) async {
    final doc = await _products.doc(id).get();
    return doc.exists ? Product.fromDoc(doc) : null;
  }
}
