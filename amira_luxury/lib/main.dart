import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/visual_studio_screen.dart';
import 'screens/ai_agent_screen.dart';
import 'app_shell_controller.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/custom_bottom_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Debug-only: lets phone-auth OTP be tested on emulators without the Play
  // Integrity / reCAPTCHA app-verification gate that fails on non-genuine
  // devices. Release builds keep full verification — this never runs there.
  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  runApp(const AmiraApp());
}

class AmiraApp extends StatelessWidget {
  const AmiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amira Luxury',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Satoshi',
        scaffoldBackgroundColor: const Color(0xFFF2F2EE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C2C2C),
          brightness: Brightness.light,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Decides the entry screen on cold start: signed-in users land in the app,
/// everyone else starts at onboarding. In-session transitions (login / logout)
/// are handled explicitly by their screens.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _BrandSplash();
        }
        if (snapshot.hasData) {
          return const MainNavigator();
        }
        return const OnboardingScreen();
      },
    );
  }
}

/// Minimal warm splash shown while the first auth state resolves. Mirrors the
/// native splash (white field + logo) so the handoff is seamless.
class _BrandSplash extends StatelessWidget {
  const _BrandSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/icon/app_icon_foreground.png',
          width: 160,
          height: 160,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  late final AppShellController _shell;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _shell = AppShellController(
      onTabChange: (index) => _pageController.jumpToPage(index),
    );
  }

  @override
  void dispose() {
    _shell.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return AppShellScope(
      controller: _shell,
      child: Scaffold(
        extendBody: true,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            HomeScreen(),
            ExploreScreen(),
            VisualStudioScreen(),
            AIAgentScreen(),
          ],
        ),
        bottomNavigationBar: keyboardOpen
            ? null
            : Container(
                color: Colors.transparent,
                child: ListenableBuilder(
                  listenable: _shell,
                  builder: (context, _) => CustomBottomNav(
                    currentIndex: _shell.currentIndex,
                    onTap: _shell.goToTab,
                  ),
                ),
              ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2EE),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
    );
  }
}
