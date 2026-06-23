import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_shell_controller.dart';
import '../models/app_user.dart';
import '../models/portfolio.dart';
import '../services/auth_service.dart';
import '../services/portfolio_service.dart';
import '../widgets/product_image.dart';
import '../widgets/shimmer.dart';
import '../widgets/coachmark.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/notification_service.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

const _bg = Color(0xFFEFEFE9);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _lightGrey = Color(0xFFD8D8D8);

// Amira's 11 product specialities — drives the Home featured swiper (static).
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final CardSwiperController _swiperController = CardSwiperController();
  bool _imagesCached = false;
  late AnimationController _borderAnimationController;
  final TextEditingController _agentSearchCtrl = TextEditingController();

  // Coachmark anchors for the first-run Home tour.
  final GlobalKey _tipNotifKey = GlobalKey();
  final GlobalKey _tipProfileKey = GlobalKey();
  final GlobalKey _tipSearchKey = GlobalKey();
  final GlobalKey _tipSwiperKey = GlobalKey();
  final GlobalKey _tipPortfolioKey = GlobalKey();
  AppShellController? _shell;
  bool _coachPending = false;

  @override
  void initState() {
    super.initState();
    _initAnimationController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesCached) {
      _precacheImages();
      _imagesCached = true;
    }
    final shell = AppShellController.maybeOf(context);
    if (shell != null && shell != _shell) {
      _shell?.removeListener(_onShell);
      _shell = shell;
      _shell!.addListener(_onShell);
      if (shell.currentIndex == 0) _maybeShowCoachmarks();
    }
  }

  void _onShell() {
    if (_shell?.currentIndex == 0) _maybeShowCoachmarks();
  }

  // Shows the Home tooltips once. Only runs while Home is the active tab and
  // front-most route, so it never renders over a pushed screen.
  Future<void> _maybeShowCoachmarks() async {
    if (_coachPending) return;
    if (_shell?.currentIndex != 0) return;
    final replay = _shell?.consumeTutorialReplay() ?? false;
    _coachPending = true;
    try {
      SharedPreferences prefs;
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (_) {
        return;
      }
      if (!replay && (prefs.getBool('coach_home_v3') ?? false)) return;
      if (!_isHomeFrontmost()) return;
      // Let the layout and featured images settle before pointing at them.
      await Future.delayed(const Duration(milliseconds: 700));
      if (!_isHomeFrontmost()) return;
      Coachmarks.show(
        context,
        _homeSteps(),
        onFinish: () => prefs.setBool('coach_home_v3', true),
      );
    } finally {
      _coachPending = false;
    }
  }

  // True only when Home is mounted, the active tab, and no route sits on top.
  bool _isHomeFrontmost() {
    if (!mounted || _shell?.currentIndex != 0) return false;
    final route = ModalRoute.of(context);
    return route != null && route.isCurrent;
  }

  List<CoachStep> _homeSteps() => [
        CoachStep(
          targetKey: _tipNotifKey,
          title: 'Notifications',
          body:
              'Order updates, appointment reminders and Amira news arrive here.',
          radius: 24,
        ),
        CoachStep(
          targetKey: _tipProfileKey,
          title: 'Your profile',
          body:
              'Manage your details, view orders and appointments, and sign out.',
          radius: 26,
        ),
        CoachStep(
          targetKey: _tipSearchKey,
          title: 'Ask Amira',
          body:
              'Ask our AI design assistant anything — or tap the gallery icon to visualise materials in your own space.',
          radius: 30,
        ),
        CoachStep(
          targetKey: _tipSwiperKey,
          title: 'Signature finishes',
          body: 'Swipe through Amira\'s hallmark materials and textures.',
          radius: 26,
        ),
        CoachStep(
          targetKey: _tipPortfolioKey,
          title: 'Our portfolio',
          body: 'Browse real Amira projects and the finishes behind them.',
          radius: 22,
        ),
        CoachStep(
          targetKey: kNavHomeKey,
          title: 'Home',
          body: 'Your starting point — featured finishes, search, and projects.',
          radius: 26,
        ),
        CoachStep(
          targetKey: kNavExploreKey,
          title: 'Explore',
          body: 'Browse the full materials catalogue and build your cart.',
          radius: 26,
        ),
        CoachStep(
          targetKey: kNavStudioKey,
          title: 'Visual Studio',
          body: 'See Amira materials placed in your own room with AI.',
          radius: 26,
        ),
        CoachStep(
          targetKey: kNavAgentKey,
          title: 'Amira Agent',
          body: 'Chat with your personal AI design assistant anytime.',
          radius: 32,
        ),
      ];

  void _initAnimationController() {
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  void _precacheImages() {
    // Precache the static featured cards at their render size so they paint
    // instantly. Portfolio images are remote and load on demand.
    for (var card in _featuredCards) {
      precacheImage(
        ResizeImage(AssetImage(card['image']!), width: 600),
        context,
      );
    }
  }

  @override
  void dispose() {
    _shell?.removeListener(_onShell);
    _agentSearchCtrl.dispose();
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
                  child: KeyedSubtree(
                    key: _tipSearchKey,
                    child: _buildSearchBar(),
                  ),
                ),
                const SizedBox(height: 32),

                // Card swiper — 45% of screen height (static featured cards)
                SizedBox(
                  key: _tipSwiperKey,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    allowedSwipeDirection:
                        const AllowedSwipeDirection.symmetric(horizontal: true),
                    scale: 0.92,
                    numberOfCardsDisplayed: 3,
                    backCardOffset: const Offset(0, -30),
                    cardBuilder: (context, index, percentThresholdX,
                        percentThresholdY) {
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
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      Icon(Icons.more_vert, color: _grey, size: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                KeyedSubtree(
                  key: _tipPortfolioKey,
                  child: _buildPortfolioStrip(),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioStrip() {
    return SizedBox(
      height: 110,
      child: StreamBuilder<List<Portfolio>>(
        stream: PortfolioService.instance.watchPublished(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _PortfolioSkeleton();
          }
          final items = snapshot.data ?? const <Portfolio>[];
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No portfolio projects yet.',
                  style: TextStyle(
                    fontSize: 14,
                    color: _grey,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (_, i) => _RecommendCard(item: items[i]),
          );
        },
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
          stream: user == null
              ? null
              : AuthService.instance.profileStream(user.uid),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final fullName = (profile?.name?.trim().isNotEmpty ?? false)
                ? profile!.name!.trim()
                : (user?.displayName?.trim().isNotEmpty ?? false)
                    ? user!.displayName!.trim()
                    : 'there';
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
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 20,
                    color: _dark,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            );
          },
        ),
        Row(
          children: [
            Stack(
              key: _tipNotifKey,
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
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
                    child: const Icon(Iconsax.notification5,
                        color: _dark, size: 22),
                  ),
                ),
                StreamBuilder<int>(
                  stream: NotificationService.instance.watchUnreadCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    if (count <= 0) return const SizedBox.shrink();
                    return Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE74C3C),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(width: 12),
            GestureDetector(
              key: _tipProfileKey,
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
        final curvedValue = Curves.easeInOutCubic
            .transform(_borderAnimationController.value);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: SweepGradient(
              colors: const [
                Color(0xFFC4A464),
                Color(0xFFFFFFFF),
                Color(0xFF2A2A2A),
                Color(0xFFC4A464),
                Color(0xFFE8C88E),
                Color(0xFFC4A464),
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
                GestureDetector(
                  onTap: () => AppShellController.of(context).openVisualStudio(
                    source: 'home',
                  ),
                  child: const Icon(Iconsax.gallery5,
                      color: Color(0xFF8B8B8B), size: 24),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Iconsax.microphone_25,
                      color: Color(0xFF8B8B8B), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _agentSearchCtrl,
                    onSubmitted: (text) {
                      final t = text.trim();
                      if (t.isEmpty) return;
                      AppShellController.of(context).openAgent(
                        seedMessage: t,
                        source: 'home_search',
                        autoSend: true,
                      );
                      _agentSearchCtrl.clear();
                    },
                    style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _dark),
                    decoration: const InputDecoration(
                      hintText: 'Ask Amira agent',
                      hintStyle: TextStyle(
                        color: Color(0xFFB8B8B8),
                        fontSize: 15,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    final t = _agentSearchCtrl.text.trim();
                    if (t.isEmpty) return;
                    AppShellController.of(context).openAgent(
                      seedMessage: t,
                      source: 'home_search',
                      autoSend: true,
                    );
                    _agentSearchCtrl.clear();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
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

// ── Featured Card (static) ──────────────────────────────────────────────────
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
                frameBuilder:
                    (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ),
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
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          fontFamily: 'Plus Jakarta Sans',
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

// ── Portfolio Card ──────────────────────────────────────────────────────────
// Mirrors the original recommendation card; the slot that showed price now
// shows the product used on the project (per spec).
class _RecommendCard extends StatelessWidget {
  final Portfolio item;
  const _RecommendCard({required this.item});

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
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 80,
              height: 80,
              child: ProductImage(
                imageUrl: item.imageUrl,
                cacheWidth: 200,
                placeholderIconSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      color: _grey,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Plus Jakarta Sans'),
                ),
                const SizedBox(height: 4),
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16,
                      color: _dark,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Plus Jakarta Sans'),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          const Icon(Iconsax.location5, size: 13, color: _grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _grey,
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.size,
                      style: const TextStyle(
                          fontSize: 12,
                          color: _grey,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w400),
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

// ── Portfolio loading skeleton ──────────────────────────────────────────────
class _PortfolioSkeleton extends StatelessWidget {
  const _PortfolioSkeleton();

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.75;
    return Shimmer(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          width: cardWidth,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE6E6E0),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }
}
