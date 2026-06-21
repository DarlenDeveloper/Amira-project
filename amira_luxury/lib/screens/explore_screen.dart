import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../app_shell_controller.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/shop_service.dart';
import '../widgets/product_image.dart';
import '../widgets/shimmer.dart';
import 'cart_screen.dart';
import 'item_details_screen.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFB5945A);

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['ALL', 'FLUTED PANELS', 'WPC PANELS'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Fixed header: title + cart button
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Explore',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                    fontFamily: 'Satoshi',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(Icons.shopping_bag_rounded,
                      color: _dark, size: 26),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Fixed filter pills
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              itemBuilder: (_, i) {
                final isActive = i == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black : _white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? _white : _grey,
                          fontFamily: 'Satoshi',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Scrolling material grid (live catalogue)
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: ProductService.instance.watchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _SkeletonGrid();
                }
                final products = snapshot.data ?? const <Product>[];
                return StreamBuilder<Set<String>>(
                  stream: ShopService.instance.watchFavouriteIds(),
                  builder: (context, favSnap) {
                    final favourites = favSnap.data ?? const <String>{};
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 22,
                        childAspectRatio: 0.66,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) => _MaterialCard(
                        product: products[i],
                        isFavourite: favourites.contains(products[i].id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final Product product;
  final bool isFavourite;

  const _MaterialCard({required this.product, required this.isFavourite});

  @override
  Widget build(BuildContext context) {
    final badge = product.badge;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItemDetailsScreen(product: product),
          ),
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: _white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Iconsax.magic_star5, color: _gold),
                  title: const Text('Visualise with AI',
                      style: TextStyle(fontFamily: 'Satoshi')),
                  onTap: () {
                    final shell = AppShellController.of(context);
                    Navigator.of(ctx).pop();
                    shell.openVisualStudio(
                      product: product,
                      source: 'explore',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Iconsax.message_text5, color: _gold),
                  title: const Text('Ask Amira about this',
                      style: TextStyle(fontFamily: 'Satoshi')),
                  onTap: () {
                    final shell = AppShellController.of(context);
                    Navigator.of(ctx).pop();
                    shell.openAgent(
                      productId: product.id,
                      seedMessage: 'Tell me about ${product.name}',
                      source: 'product_ask',
                      autoSend: true,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with badge + heart overlay
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      cacheWidth: 500,
                    ),
                  ),
                ),

                // Badge pill
                if (badge != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                          fontFamily: 'Satoshi',
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),

                // Heart
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => ShopService.instance
                        .setFavourite(product.id, !isFavourite),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _white.withOpacity(0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavourite ? Iconsax.heart5 : Iconsax.heart,
                        size: 19,
                        color: isFavourite ? _gold : _dark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Title + price below the image, on the background
          const SizedBox(height: 10),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _dark,
              fontFamily: 'Satoshi',
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.priceLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _gold,
              fontFamily: 'Satoshi',
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder shown while the catalogue loads. Mirrors the real grid's
/// padding, spacing and card proportions so the swap is seamless.
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 22,
          childAspectRatio: 0.66,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: SkeletonBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.all(Radius.circular(22)),
              ),
            ),
            SizedBox(height: 10),
            SkeletonBox(width: 120, height: 14),
            SizedBox(height: 8),
            SkeletonBox(width: 80, height: 12),
          ],
        ),
      ),
    );
  }
}
