import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/currency.dart';
import '../utils/product_colors.dart';

/// Availability of a product, mirrors the admin `status` field.
enum ProductStatus { active, low, out, unknown }

ProductStatus _statusFromString(String? s) {
  switch (s) {
    case 'active':
      return ProductStatus.active;
    case 'low':
      return ProductStatus.low;
    case 'out':
      return ProductStatus.out;
    default:
      return ProductStatus.unknown;
  }
}

/// A catalogue product backed by `products/{productId}` in Firestore.
///
/// Admin-authored (see `.kiro/steering/data-model.md`). The app reads these and
/// resolves [imageKey] to a bundled asset via [productAssetForKey] so the
/// luxury visuals stay local while the data is live.
class Product {
  final String id;
  final String name;
  final String imageKey;
  final String? imageUrl;
  final List<String> images;
  final String category;
  final double value;
  final String unit;
  final String about;
  final String desc;
  final String? badge;
  final int stock;
  final ProductStatus status;
  final int order;
  final List<ProductColor> colors;

  const Product({
    required this.id,
    required this.name,
    required this.imageKey,
    this.imageUrl,
    this.images = const [],
    required this.category,
    required this.value,
    required this.unit,
    required this.about,
    required this.desc,
    required this.badge,
    required this.stock,
    required this.status,
    required this.order,
    this.colors = const [],
  });

  /// Display price, e.g. "From UGX 56 / sqm".
  String get priceLabel => 'From ${formatUgx(value)} / $unit';

  bool get isOutOfStock => status == ProductStatus.out || stock <= 0;
  bool get isLowStock => status == ProductStatus.low;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Product(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      imageKey: (data['imageKey'] as String?) ?? '',
      imageUrl: data['imageUrl'] as String?,
      images: (data['images'] as List?)?.whereType<String>().toList() ??
          const [],
      category: (data['category'] as String?) ?? '',
      value: (data['value'] as num?)?.toDouble() ?? 0,
      unit: (data['unit'] as String?) ?? 'unit',
      about: (data['about'] as String?) ?? '',
      desc: (data['desc'] as String?) ?? '',
      badge: data['badge'] as String?,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      status: _statusFromString(data['status'] as String?),
      order: (data['order'] as num?)?.toInt() ?? 0,
      colors: parseProductColors(data['colors'] as List<dynamic>?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageKey': imageKey,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (images.isNotEmpty) 'images': images,
      'category': category,
      'value': value,
      'unit': unit,
      'about': about,
      'desc': desc,
      'badge': badge,
      'stock': stock,
      'status': status.name,
      'order': order,
      if (colors.isNotEmpty) 'colors': colors.map((c) => c.toMap()).toList(),
    };
  }
}
