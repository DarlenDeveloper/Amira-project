/// A selectable product colour (admin-authored on `products/{id}.colors`).
class ProductColor {
  final String name;
  final String hex;

  const ProductColor({required this.name, required this.hex});

  factory ProductColor.fromMap(Map<String, dynamic> m) => ProductColor(
        name: (m['name'] as String?)?.trim() ?? '',
        hex: _normalizeHex(m['hex'] as String?),
      );

  Map<String, dynamic> toMap() => {'name': name, 'hex': hex};
}

List<ProductColor> parseProductColors(List<dynamic>? raw) {
  if (raw == null) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(ProductColor.fromMap)
      .where((c) => c.name.isNotEmpty)
      .toList();
}

String _normalizeHex(String? hex) {
  var h = (hex ?? '').trim();
  if (h.isEmpty) return '#888888';
  if (!h.startsWith('#')) h = '#$h';
  if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(h)) return h;
  return '#888888';
}

/// Cart doc id — separate lines per colour variant.
String cartLineId(String productId, ProductColor? color) {
  if (color == null || color.name.isEmpty) return productId;
  final slug = color.name
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return slug.isEmpty ? productId : '${productId}__$slug';
}

/// Strip colour suffix from cart line id for order snapshots.
String baseProductId(String lineId) {
  final idx = lineId.indexOf('__');
  return idx == -1 ? lineId : lineId.substring(0, idx);
}
