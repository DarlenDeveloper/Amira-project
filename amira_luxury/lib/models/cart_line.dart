import 'package:cloud_firestore/cloud_firestore.dart';

import 'product.dart';
import '../utils/product_colors.dart';

/// A single line in a user's cart, backed by `users/{uid}/cart/{lineId}`.
class CartLine {
  final String productId;
  final String name;
  final String imageKey;
  final String? imageUrl;
  final String unit;
  final double value;
  final int qty;
  final String? colorName;
  final String? colorHex;

  const CartLine({
    required this.productId,
    required this.name,
    required this.imageKey,
    this.imageUrl,
    required this.unit,
    required this.value,
    required this.qty,
    this.colorName,
    this.colorHex,
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
      colorName: data['colorName'] as String?,
      colorHex: data['colorHex'] as String?,
    );
  }

  factory CartLine.fromProduct(Product p, {int qty = 1, ProductColor? color}) {
    return CartLine(
      productId: cartLineId(p.id, color),
      name: p.name,
      imageKey: p.imageKey,
      imageUrl: p.imageUrl,
      unit: p.unit,
      value: p.value,
      qty: qty,
      colorName: color?.name,
      colorHex: color?.hex,
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
      if (colorName != null) 'colorName': colorName,
      if (colorHex != null) 'colorHex': colorHex,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
