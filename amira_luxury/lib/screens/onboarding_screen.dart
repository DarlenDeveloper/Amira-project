import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

const _dark = Color(0xFF2A2A2A);
const _white = Colors.white;
const _gold = Color(0xFFB5945A);

// ── Slide data ────────────────────────────────────────────────────────────────
// Each slide pairs a full-bleed interior with a pillar of the Amira experience.
class _SlideData {
  final String image;
  final String headline;
  final String subtitle;
  const _SlideData({
    required this.image,
    required this.headline,
    required this.subtitle,
  });
}

const List<_SlideData> _slides = [
  _SlideData(
    image: 'assets/images/kam-idris-hYb7kbu4x7E-unsplash.jpg',
    headline: 'Luxury\nInteriors,\nReimagined',
    subtitle:
        'Discover Amira\'s curated finishes, textures, and lighting crafted for timeless East African living.',
  ),
  _SlideData(
    image: 'assets/images/inside-weather-Uxqlfigh6oE-unsplash.jpg',
    headline: 'See It In\nYour Space',
    subtitle:
        'Upload a photo of your room and watch Amira\'s materials come to life with AI visualisation.',
  ),
  _SlideData(
    image: 'assets/images/makespace-design-vdfUjNhI1PA-unsplash.jpg',
    headline: 'Design With\nIntention',
    subtitle:
        'Explore collections, request orders, and create with a personal design assistant by your side.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _imagesCached = false;
  Timer? _autoScrollTimer;

  // Drives the fade+slide entrance of the headline/subtitle. Runs on first
  // load and replays on every slide change for a consistent first impression.
  late final AnimationController _textController;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  // How long each slide rests before advancing on its own.
  static const Duration _autoScrollInterval = Duration(seconds: 5);

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    // Play the intro after the first frame so it reads as an entrance.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _textController.forward();
    });
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesCached) {
      // Warm each slide at full-screen width so the next page paints instantly.
      for (final s in _slides) {
        precacheImage(
          ResizeImage(AssetImage(s.image), width: 1080),
          context,
        );
      }
      _imagesCached = true;
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _textController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Auto-advances through the slides, stopping once the last one is reached.
  // Restarted on any manual interaction so the timer never fights the user.
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      if (!mounted) return;
      if (_currentPage < _slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _autoScrollTimer?.cancel();
      }
    });
  }

  void _next() {
    if (_isLastPage) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _finish() {
    // Onboarding complete → begin auth.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: Stack(
        children: [
          // Full-bleed image carousel
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              _textController.forward(from: 0); // replay text entrance
              _startAutoScroll(); // reset the wait timer after any change
            },
            itemBuilder: (_, i) => _SlideView(data: _slides[i]),
          ),

          // Top bar: brand mark (pinned to top) + skip
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 20, 0),
                  child: Stack(
                    children: [
                      const Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          'AMIRA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _white,
                            fontFamily: 'Satoshi',
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: _isLastPage ? 0 : 1,
                          child: GestureDetector(
                            onTap: _isLastPage ? null : _finish,
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                'Skip',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                  fontFamily: 'Satoshi',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom content: headline, subtitle, progress + proceed
          SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline + subtitle fade and rise in together
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _slides[_currentPage].headline,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w600,
                                color: _white,
                                fontFamily: 'Satoshi',
                                height: 1.05,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.82,
                              child: Text(
                                _slides[_currentPage].subtitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                  fontFamily: 'Satoshi',
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Progress + proceed button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(
                            _slides.length,
                            (i) => _ProgressBar(active: i == _currentPage),
                          ),
                        ),
                        _ProceedButton(
                          onTap: _next,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single slide: image + legibility gradients ──────────────────────────────────
class _SlideView extends StatelessWidget {
  final _SlideData data;
  const _SlideView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark placeholder so the first paint is never an empty flash.
        const ColoredBox(color: Color(0xFF1B1B1B)),
        Image.asset(
          data.image,
          fit: BoxFit.cover,
          cacheWidth: 1080,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: child,
            );
          },
        ),
        // Bottom scrim for headline legibility
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.35, 1.0],
              colors: [Colors.transparent, Color(0xE6171717)],
            ),
          ),
        ),
        // Subtle top scrim for the brand mark
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.25],
              colors: [Color(0x66000000), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Animated segmented progress indicator ───────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final bool active;
  const _ProgressBar({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.only(right: 8),
      width: active ? 28 : 16,
      height: 4,
      decoration: BoxDecoration(
        color: active ? _gold : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ── Circular proceed button — "Go" in gold on pure black ────────────────────────
class _ProceedButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ProceedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          'Go',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _gold,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
    );
  }
}
