import 'package:cloud_firestore/cloud_firestore.dart';

import 'product.dart';

/// A single line in a user's cart, backed by `users/{uid}/cart/{productId}`.
class CartLine {
  final String productId;
  final String name;
  final String imageKey;
  final String? imageUrl;
  final String unit;
  final double value;
  final int qty;

  const CartLine({
    required this.productId,
    required this.name,
    required this.imageKey,
    this.imageUrl,
    required this.unit,
    required this.value,
    required this.qty,
  });

  bool get hasRemoteImage => imageUrl != null && imageUrl!.isNotEmpty;
  double get lineTotal => value * qty;

  factory CartLine.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return CartLine(
      productId: doc.id,
      name: (data['name'] as String?) ?? '',
      imageKey: (data['imageKey'] as String?) ?? '',
      imageUrl: data['imageUrl'] as String?,
      unit: (data['unit'] as String?) ?? 'unit',
      value: (data['value'] as num?)?.toDouble() ?? 0,
      qty: (data['qty'] as num?)?.toInt() ?? 1,
    );
  }

  factory CartLine.fromProduct(Product p, {int qty = 1}) {
    return CartLine(
      productId: p.id,
      name: p.name,
      imageKey: p.imageKey,
      imageUrl: p.imageUrl,
      unit: p.unit,
      value: p.value,
      qty: qty,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageKey': imageKey,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'unit': unit,
      'value': value,
      'qty': qty,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
