import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _lightGrey = Color(0xFFD8D8D8);
const _gold = Color(0xFFB5945A);

final List<Map<String, dynamic>> _materials = [
  {
    'image': 'assets/images/jean-philippe-delberghe-T5BF4OyQLwU-unsplash.jpg',
    'name': 'Walnut Fluted',
    'category': 'WARM WOOD',
    'price': 42,
    'badge': 'BESTSELLER',
    'isFavorite': false,
  },
  {
    'image': 'assets/images/franco-debartolo-VB6h-h54qIk-unsplash.jpg',
    'name': 'Calacatta Gold',
    'category': 'WHITE & GOLD',
    'price': 56,
    'badge': 'LUXURY',
    'isFavorite': false,
  },
  {
    'image': 'assets/images/inside-weather-Uxqlfigh6oE-unsplash.jpg',
    'name': 'Graphite WPC',
    'category': 'CHARCOAL',
    'price': 38,
    'badge': null,
    'isFavorite': false,
  },
  {
    'image': 'assets/images/franco-debartolo-KLEF4bIFvr0-unsplash.jpg',
    'name': 'Noir Acoustic',
    'category': 'BLACK RIBBED',
    'price': 48,
    'badge': null,
    'isFavorite': false,
  },
  {
    'image': 'assets/images/toa-heftiba-x8f214cQsQk-unsplash.jpg',
    'name': 'Oak Natural',
    'category': 'LIGHT WOOD',
    'price': 45,
    'badge': null,
    'isFavorite': false,
  },
  {
    'image': 'assets/images/makespace-design-vdfUjNhI1PA-unsplash.jpg',
    'name': 'Marble White',
    'category': 'PREMIUM STONE',
    'price': 62,
    'badge': 'LUXURY',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Title & Description
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Explore',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Curated premium materials from Amira.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: _grey,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Filter pills
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
                        color: isActive ? _gold : _white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isActive ? _gold : _lightGrey,
                          width: 1.5,
                        ),
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

            const SizedBox(height: 24),

            // Material Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72,
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
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.05),
                    child: Image.asset(
                      widget.data['image'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Badge
                if (widget.data['badge'] != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.data['badge'],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _gold,
                          fontFamily: 'Satoshi',
                        ),
                      ),
                    ),
                  ),

                // Heart icon
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => setState(() => _isFavorite = !_isFavorite),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorite ? Iconsax.heart5 : Iconsax.heart,
                        size: 18,
                        color: _isFavorite ? _gold : _dark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    widget.data['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _dark,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  widget.data['category'],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _grey,
                    fontFamily: 'Satoshi',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${widget.data['price']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _gold,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                    const Text(
                      '/ sqm',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _grey,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
