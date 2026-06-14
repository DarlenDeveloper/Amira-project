import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'cart_screen.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFB5945A);

// Speciality images live in this folder.
const _specialitiesDir = 'assets/images/company specilialities';

final List<Map<String, dynamic>> _materials = [
  {
    'image': '$_specialitiesDir/pvc marble sheet.jpeg',
    'name': 'PVC Marble Sheets',
    'price': 'From \$56 / sqm',
    'badge': 'LUXURY',
    'isFavorite': false,
  },
  {
    'image': '$_specialitiesDir/bamboo wall panel.jpeg',
    'name': 'Bamboo Wall Panel',
    'price': 'From \$42 / sqm',
    'badge': 'BESTSELLER',
    'isFavorite': false,
  },
  {
    'image': '$_specialitiesDir/wpc wall panel.jpeg',
    'name': 'WPC Wall Panel',
    'price': 'From \$38 / sqm',
    'badge': null,
    'isFavorite': false,
  },
  {
    'image': '$_specialitiesDir/pvc wall panel.jpeg',
    'name': 'PVC Wall Panel',
    'price': 'From \$32 / sqm',
    'badge': null,
    'isFavorite': false,
  },
  {
    'image': '$_specialitiesDir/soft stone.jpeg',
    'name': 'Soft Stone',
    'price': 'From \$48 / sqm',
    'badge': null,
    'isFavorite': false,
  },
  {
    'image': '$_specialitiesDir/pu stone.jpeg',
    'name': 'PU Stone',
    'price': 'From \$45 / sqm',
    'badge': null,
    'isFavorite': false,
  },
  {
    'image': '$_specialitiesDir/lights.jpeg',
    'name': 'Lights',
    'price': 'From \$25 / unit',
    'badge': 'NEW',
    'isFavorite': false,
  },
  {
    'image': '$_specialitiesDir/Artificial Grass.jpeg',
    'name': 'Artificial Grass & Carpets',
    'price': 'From \$18 / sqm',
    'badge': null,
    'isFavorite': false,
  },
  {
    'image': '$_specialitiesDir/steel profile.jpeg',
    'name': 'Steel Profile',
    'price': 'From \$12 / m',
    'badge': null,
    'isFavorite': false,
  },
  {
    'image': '$_specialitiesDir/blinds.jpeg',
    'name': 'Blinds',
    'price': 'From \$35 / unit',
    'badge': null,
    'isFavorite': false,
  },
  {
    'image': '$_specialitiesDir/block boards.jpeg',
    'name': 'Block Boards',
    'price': 'From \$40 / sheet',
    'badge': null,
    'isFavorite': false,
  },
];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['ALL', 'FLUTED PANELS', 'WPC PANELS'];
  bool _imagesCached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesCached) {
      for (final m in _materials) {
        // Match the grid's cacheWidth so the warmed entry is reused.
        precacheImage(
          ResizeImage(AssetImage(m['image'] as String), width: 500),
          context,
        );
      }
      _imagesCached = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Fixed header: title + cart button
          Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 0),
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
                  child: const Icon(Icons.shopping_bag_rounded, color: _dark, size: 26),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

          // Scrolling material grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 22,
                childAspectRatio: 0.66,
              ),
              itemCount: _materials.length,
              itemBuilder: (_, i) => _MaterialCard(data: _materials[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _MaterialCard({required this.data});

  @override
  State<_MaterialCard> createState() => _MaterialCardState();
}

class _MaterialCardState extends State<_MaterialCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.data['isFavorite'];
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.data['badge'];
    return GestureDetector(
      onTap: () {},
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
                    child: Image.asset(
                      widget.data['image'],
                      fit: BoxFit.cover,
                      cacheWidth: 500,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
                    ),
                  ),
                ),

                // Badge pill
                if (badge != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                    onTap: () => setState(() => _isFavorite = !_isFavorite),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _white.withOpacity(0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorite ? Iconsax.heart5 : Iconsax.heart,
                        size: 19,
                        color: _isFavorite ? _gold : _dark,
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
            widget.data['name'],
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
            widget.data['price'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _grey,
              fontFamily: 'Satoshi',
            ),
          ),
        ],
      ),
    );
  }
}
