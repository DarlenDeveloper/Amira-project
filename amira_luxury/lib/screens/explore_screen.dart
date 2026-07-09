import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_shell_controller.dart';
import '../models/cart_line.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/shop_service.dart';
import '../widgets/product_image.dart';
import '../widgets/shimmer.dart';
import '../widgets/coachmark.dart';
import 'cart_screen.dart';
import 'item_details_screen.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFC4A464);

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Active category filter; 'ALL' shows everything. Driven by the live
  // catalogue's categories (see build), not a hardcoded list.
  String _selectedCategory = 'ALL';

  // Client-side pagination: reveal the grid a page at a time so only the cards
  // (and their images) near the viewport are built. More pages are appended as
  // the user scrolls, which keeps first paint fast and images loading in order.
  static const int _pageSize = 8;
  int _visibleCount = _pageSize;
  int _filteredTotal = 0;
  final ScrollController _gridController = ScrollController();

  // Coachmark anchors + trigger state.
  final GlobalKey _tipCartKey = GlobalKey();
  final GlobalKey _tipFilterKey = GlobalKey();
  final GlobalKey _tipGridKey = GlobalKey();
  AppShellController? _shell;
  bool _coachTriggered = false;

  @override
  void initState() {
    super.initState();
    _gridController.addListener(_onGridScroll);
  }

  // Reveal the next page once the user nears the bottom of the grid.
  void _onGridScroll() {
    if (!_gridController.hasClients) return;
    final pos = _gridController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) _revealMore();
  }

  void _revealMore() {
    if (_visibleCount >= _filteredTotal) return;
    setState(() {
      _visibleCount =
          (_visibleCount + _pageSize).clamp(0, _filteredTotal).toInt();
    });
  }

  // Start each category back at page one (and scroll to the top).
  void _selectCategory(String label) {
    setState(() {
      _selectedCategory = label;
      _visibleCount = _pageSize;
    });
    if (_gridController.hasClients) _gridController.jumpTo(0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shell = AppShellController.maybeOf(context);
    if (shell != null && shell != _shell) {
      _shell?.removeListener(_onShell);
      _shell = shell;
      _shell!.addListener(_onShell);
      if (shell.currentIndex == 1) _maybeShowCoachmarks();
    }
  }

  void _onShell() {
    if (_shell?.currentIndex == 1) _maybeShowCoachmarks();
  }

  @override
  void dispose() {
    _shell?.removeListener(_onShell);
    _gridController.dispose();
    super.dispose();
  }

  // Shows the Explore tooltips once, the first time the tab is opened.
  Future<void> _maybeShowCoachmarks() async {
    if (_coachTriggered) return;
    _coachTriggered = true;
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return;
    }
    if (prefs.getBool('coach_explore_v1') ?? false) return;
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Coachmarks.show(
      context,
      [
        CoachStep(
          targetKey: _tipCartKey,
          title: 'Your cart',
          body: 'Items you add are collected here — review them and check out.',
          radius: 24,
        ),
        CoachStep(
          targetKey: _tipFilterKey,
          title: 'Filter materials',
          body: 'Narrow the catalogue by material type.',
          radius: 24,
        ),
        CoachStep(
          targetKey: _tipGridKey,
          title: 'Browse & act',
          body:
              'Tap a material for full details — or long-press for quick options: visualise it with AI, or ask Amira about it.',
          radius: 22,
        ),
      ],
      onFinish: () => prefs.setBool('coach_explore_v1', true),
    );
  }

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
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                GestureDetector(
                  key: _tipCartKey,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart_rounded,
                          color: _dark, size: 26),
                      StreamBuilder<List<CartLine>>(
                        stream: ShopService.instance.watchCart(),
                        builder: (context, snapshot) {
                          final count = (snapshot.data ?? []).length;
                          if (count == 0) return const SizedBox.shrink();
                          return Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              decoration: const BoxDecoration(
                                color: _gold,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _white,
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Live catalogue: filter pills (built from real categories) + grid,
          // both fed by the same products stream so the filter actually applies.
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: ProductService.instance.watchProducts(),
              builder: (context, snapshot) {
                final loading =
                    snapshot.connectionState == ConnectionState.waiting;
                final products = snapshot.data ?? const <Product>[];
                final categories = <String>[
                  'ALL',
                  ...ProductService.instance.categoriesOf(products),
                ];
                // Keep the selection valid as the live category set changes.
                final selected =
                    categories.contains(_selectedCategory) ? _selectedCategory : 'ALL';
                final filtered = selected == 'ALL'
                    ? products
                    : products.where((p) => p.category == selected).toList();

                return Column(
                  children: [
                    // Filter pills
                    SizedBox(
                      key: _tipFilterKey,
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: categories.length,
                        itemBuilder: (_, i) {
                          final label = categories[i];
                          final isActive = label == selected;
                          return GestureDetector(
                            onTap: () => _selectCategory(label),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.black
                                    : _white.withOpacity(0.5),
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
                                  label.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? _white : _grey,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Material grid (filtered)
                    Expanded(
                      child: loading
                          ? const _SkeletonGrid()
                          : StreamBuilder<Set<String>>(
                              stream: ShopService.instance.watchFavouriteIds(),
                              builder: (context, favSnap) {
                                final favourites =
                                    favSnap.data ?? const <String>{};
                                if (filtered.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No materials in this category yet.',
                                      style: TextStyle(
                                        color: _grey,
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                  );
                                }
                                _filteredTotal = filtered.length;
                                final visible = _visibleCount
                                    .clamp(0, filtered.length)
                                    .toInt();
                                final hasMore = visible < filtered.length;
                                return CustomScrollView(
                                  controller: _gridController,
                                  // Bound how far off-screen we pre-build so
                                  // images near the viewport load first.
                                  cacheExtent: 600,
                                  slivers: [
                                    SliverPadding(
                                      padding: EdgeInsets.fromLTRB(
                                          20, 0, 20, hasMore ? 8 : 120),
                                      sliver: SliverGrid(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 22,
                                          childAspectRatio: 0.66,
                                        ),
                                        delegate: SliverChildBuilderDelegate(
                                          (_, i) {
                                            final card = _MaterialCard(
                                              product: filtered[i],
                                              isFavourite: favourites
                                                  .contains(filtered[i].id),
                                            );
                                            // Anchor the first card for the coachmark.
                                            return i == 0
                                                ? KeyedSubtree(
                                                    key: _tipGridKey,
                                                    child: card)
                                                : card;
                                          },
                                          childCount: visible,
                                        ),
                                      ),
                                    ),
                                    if (hasMore)
                                      const SliverToBoxAdapter(
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              20, 12, 20, 120),
                                          child: Center(
                                            child: SizedBox(
                                              width: 26,
                                              height: 26,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                color: _gold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
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
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
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
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
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
                          fontFamily: 'Plus Jakarta Sans',
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
              fontFamily: 'Plus Jakarta Sans',
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
              fontFamily: 'Plus Jakarta Sans',
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
