import 'package:flutter/material.dart';

import 'shimmer.dart';

/// Renders a product image from the admin-uploaded [imageUrl].
///
/// There is no bundled-asset fallback: images come only from the backend. When
/// no URL is set (or it fails to load) a neutral "no image" placeholder is
/// shown. While a remote image loads, a shimmer placeholder is shown.
///
/// Fills its parent — wrap in a sized box / `ClipRRect` at the call site.
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final int? cacheWidth;

  /// Size of the placeholder glyph; tune down for small thumbnails.
  final double placeholderIconSize;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.placeholderIconSize = 32,
  });

  bool get _hasUrl => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasUrl) return _NoImage(iconSize: placeholderIconSize);
    return Image.network(
      imageUrl!,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: cacheWidth,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Shimmer(
          child: SkeletonBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.zero,
          ),
        );
      },
      errorBuilder: (context, error, stack) =>
          _NoImage(iconSize: placeholderIconSize),
    );
  }
}

/// Calm neutral placeholder for products without a hosted image.
class _NoImage extends StatelessWidget {
  final double iconSize;
  const _NoImage({required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFEDEDE8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_rounded,
            size: iconSize,
            color: const Color(0xFFB8B8B2),
          ),
          if (iconSize >= 28) ...[
            const SizedBox(height: 8),
            const Text(
              'No image',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9A9A94),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
