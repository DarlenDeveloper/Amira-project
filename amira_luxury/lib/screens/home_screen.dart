import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

const _bg = Color(0xFFEFEFE9);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _lightGrey = Color(0xFFD8D8D8);
const _orange = Color(0xFFE8621A);
const _olive = Color(0xFF556B4A);

// Amira's 11 product specialities — drives the Home portfolio swiper.
const _specialitiesDir = 'assets/images/company specilialities';

final List<Map<String, String>> _featuredCards = [
  {
    'image': '$_specialitiesDir/pvc marble sheet.jpeg',
    'tag': 'SPECIALITY',
    'name': 'PVC Marble Sheets',
    'desc': 'Seamless marble-look wall cladding',
  },
  {
    'image': '$_specialitiesDir/bamboo wall panel.jpeg',
    'tag': 'SPECIALITY',
    'name': 'Bamboo Wall Panel',
    'desc': 'Natural, sustainable wall texture',
  },
  {
    'image': '$_specialitiesDir/wpc wall panel.jpeg',
    'tag': 'SPECIALITY',
    'name': 'WPC Wall Panel',
    'desc': 'Durable wood-plastic composite',
  },
  {
    'image': '$_specialitiesDir/pvc wall panel.jpeg',
    'tag': 'SPECIALITY',
    'name': 'PVC Wall Panel',
    'desc': 'Lightweight, easy-fit wall finish',
  },
  {
    'image': '$_specialitiesDir/soft stone.jpeg',
    'tag': 'SPECIALITY',
    'name': 'Soft Stone',
    'desc': 'Flexible natural stone veneer',
  },
  {
    'image': '$_specialitiesDir/pu stone.jpeg',
    'tag': 'SPECIALITY',
    'name': 'PU Stone',
    'desc': 'Lightweight polyurethane stone',
  },
  {
    'image': '$_specialitiesDir/lights.jpeg',
    'tag': 'SPECIALITY',
    'name': 'Lights',
    'desc': 'Ambient & accent lighting',
  },
  {
    'image': '$_specialitiesDir/Artificial Grass.jpeg',
    'tag': 'SPECIALITY',
    'name': 'Artificial Grass & Carpets',
    'desc': 'Soft greens & floor textures',
  },
  {
    'image': '$_specialitiesDir/steel profile.jpeg',
    'tag': 'SPECIALITY',
    'name': 'Steel Profile',
    'desc': 'Precision metal trims & frames',
  },
  {
    'image': '$_specialitiesDir/blinds.jpeg',
    'tag': 'SPECIALITY',
    'name': 'Blinds',
    'desc': 'Tailored window treatments',
  },
  {
    'image': '$_specialitiesDir/block boards.jpeg',
    'tag': 'SPECIALITY',
    'name': 'Block Boards',
    'desc': 'Engineered wood panels',
  },
];

final List<Map<String, String>> _recommendations = [
  {
    'image': 'assets/images/inside-weather-Uxqlfigh6oE-unsplash.jpg',
    'type': 'Living Room Design',
    'price': 'UGX 68,000,000',
    'location': 'Kampala, UG',
    'size': '60 m²',
  },
  {
    'image': 'assets/images/franco-debartolo-KLEF4bIFvr0-unsplash.jpg',
    'type': 'Master Suite Finish',
    'price': 'UGX 51,000,000',
    'location': 'Kololo, KLA',
    'size': '45 m²',
  },
  {
    'image': 'assets/images/toa-heftiba-x8f214cQsQk-unsplash.jpg',
    'type': 'Open Kitchen Concept',
    'price': 'UGX 88,000,000',
    'location': 'Nakasero, KLA',
    'size': '80 m²',
  },
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final CardSwiperController _swiperController = CardSwiperController();
  bool _imagesCached = false;
  late AnimationController _borderAnimationController;

  @override
  void initState() {
    super.initState();
    _initAnimationController();
  }

  void _initAnimationController() {
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesCached) {
      _precacheImages();
      _imagesCached = true;
    }
  }

  void _precacheImages() {
    // Precache at the SAME pixel size the cards render with (their cacheWidth),
    // so the warmed cache entry matches what's displayed and images appear
    // instantly instead of decoding on first paint.
    for (var card in _featuredCards) {
      precacheImage(
        ResizeImage(AssetImage(card['image']!), width: 600),
        context,
      );
    }
    for (var rec in _recommendations) {
      precacheImage(
        ResizeImage(AssetImage(rec['image']!), width: 200),
        context,
      );
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    _borderAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildHeader(),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSearchBar(),
                    ),
            const SizedBox(height: 32),

            // Card swiper — 45% of screen height
            SizedBox(
              height: screenHeight * 0.45,
              child: CardSwiper(
                controller: _swiperController,
                cardsCount: _featuredCards.length,
                onSwipe: (previousIndex, currentIndex, direction) {
                  setState(() {
                    _currentIndex = currentIndex ?? 0;
                  });
                  return true;
                },
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
                scale: 0.92,
                numberOfCardsDisplayed: 3,
                backCardOffset: const Offset(0, -30), // Stack cards upward
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  return _FeaturedCard(data: _featuredCards[index]);
                },
              ),
            ),

            const SizedBox(height: 26),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Our Portfolio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  Icon(Icons.more_vert, color: _grey, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _recommendations.length,
                itemBuilder: (_, i) => _RecommendCard(data: _recommendations[i]),
              ),
            ),
            const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StreamBuilder<AppUser?>(
          stream:
              user == null ? null : AuthService.instance.profileStream(user.uid),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final fullName = (profile?.name?.trim().isNotEmpty ?? false)
                ? profile!.name!.trim()
                : (user?.displayName?.trim().isNotEmpty ?? false)
                    ? user!.displayName!.trim()
                    : 'there';
            // Show just the first name to keep the greeting warm and compact.
            final firstName = fullName.split(' ').first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: _grey,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 20,
                    color: _dark,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ],
            );
          },
        ),
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Iconsax.notification5, color: _dark, size: 22),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE74C3C),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: StreamBuilder<AppUser?>(
                stream: FirebaseAuth.instance.currentUser == null
                    ? null
                    : AuthService.instance
                        .profileStream(FirebaseAuth.instance.currentUser!.uid),
                builder: (context, snapshot) {
                  final photoUrl = snapshot.data?.photoUrl ??
                      FirebaseAuth.instance.currentUser?.photoURL;
                  final ImageProvider avatar =
                      (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : const AssetImage('assets/images/user_avatar.jpg')
                              as ImageProvider;
                  return Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: DecorationImage(image: avatar, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _borderAnimationController,
      builder: (context, child) {
        // Apply easeInOutCubic for smooth acceleration/deceleration
        final curvedValue = Curves.easeInOutCubic.transform(_borderAnimationController.value);
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: SweepGradient(
              colors: const [
                Color(0xFFB5945A), // gold
                Color(0xFFFFFFFF), // white
                Color(0xFF2A2A2A), // black
                Color(0xFFB5945A), // gold
                Color(0xFFE8C88E), // lighter gold
                Color(0xFFB5945A), // back to gold
              ],
              stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              transform: GradientRotation(curvedValue * 2 * 3.14159),
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                // Image attachment icon
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Iconsax.gallery5, color: Color(0xFF8B8B8B), size: 24),
                ),
                const SizedBox(width: 16),
                // Voice icon
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Iconsax.microphone_25, color: Color(0xFF8B8B8B), size: 24),
                ),
                const SizedBox(width: 14),
                // Input field
                const Expanded(
                  child: TextField(
                    style: TextStyle(fontFamily: 'Satoshi', fontSize: 15, fontWeight: FontWeight.w500, color: _dark),
                    decoration: InputDecoration(
                      hintText: 'Ask Amira agent',
                      hintStyle: TextStyle(
                        color: Color(0xFFB8B8B8),
                        fontSize: 15,
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Send button
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_featuredCards.length, (i) {
        final active = i == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? _dark : _lightGrey,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Featured Card ─────────────────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final Map<String, String> data;
  const _FeaturedCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          color: const Color(0xFFD4D4D0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                data['image']!,
                fit: BoxFit.cover,
                cacheWidth: 600,
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

            // Tag
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  data['name']!,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ),
            ),

            // Heart
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.88),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.heart5, size: 17, color: _dark),
              ),
            ),

            // Bottom strip
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['desc']!,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recommendation Card ───────────────────────────────────────────────────────
class _RecommendCard extends StatelessWidget {
  final Map<String, String> data;
  const _RecommendCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              data['image']!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              cacheWidth: 200,
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data['type']!,
                    style: const TextStyle(
                        fontSize: 13, color: _grey,
                        fontWeight: FontWeight.w400, fontFamily: 'Satoshi')),
                const SizedBox(height: 4),
                Text(data['price']!,
                    style: const TextStyle(
                        fontSize: 16, color: _dark,
                        fontWeight: FontWeight.w700, fontFamily: 'Satoshi')),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.location5, size: 13, color: _grey),
                        const SizedBox(width: 4),
                        Text(data['location']!,
                            style: const TextStyle(
                                fontSize: 12, color: _grey, fontFamily: 'Satoshi', fontWeight: FontWeight.w400)),
                      ],
                    ),
                    Text(data['size']!,
                        style: const TextStyle(
                            fontSize: 12, color: _grey, fontFamily: 'Satoshi', fontWeight: FontWeight.w400)),
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
