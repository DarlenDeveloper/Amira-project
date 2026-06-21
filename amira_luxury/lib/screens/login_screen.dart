import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:country_flags/country_flags.dart';
import '../main.dart';
import '../services/auth_service.dart';

const _dark = Color(0xFF2A2A2A);
const _white = Colors.white;
const _grey = Color(0xFF7E7A74);
const _gold = Color(0xFFC4A464);

const _bgImage = 'assets/images/kam-idris-hYb7kbu4x7E-unsplash.jpg';

// ── Country data for the phone code picker ──────────────────────────────────────
class _Country {
  final String iso; // ISO 3166-1 alpha-2 (drives the flag)
  final String name;
  final String dial;
  const _Country(this.iso, this.name, this.dial);
}

const List<_Country> _countries = [
  _Country('UG', 'Uganda', '+256'),
  _Country('KE', 'Kenya', '+254'),
  _Country('TZ', 'Tanzania', '+255'),
  _Country('RW', 'Rwanda', '+250'),
  _Country('SS', 'South Sudan', '+211'),
];

// Circular SVG country flag.
Widget _circleFlag(String iso, double size) {
  return CountryFlag.fromCountryCode(
    iso,
    theme: ImageTheme(
      shape: const Circle(),
      height: size,
      width: size,
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _usePhone = true;
  bool _isSignup = false;
  final bool _obscurePassword = true;
  _Country _country = _countries.first; // default Uganda
  bool _bgCached = false;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bgCached) {
      precacheImage(const AssetImage(_bgImage), context);
      _bgCached = true;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Whether the identifier (phone or email) is sufficiently filled to reveal
  // the password and the rest of the form.
  bool get _identifierFilled {
    if (_usePhone) return _phoneController.text.trim().length >= 7;
    final email = _emailController.text.trim();
    return email.contains('@') && email.contains('.');
  }

  bool get _canContinue {
    if (!_identifierFilled) return false;
    // Both phone and email use a password (Firebase requires 6+ characters).
    if (_passwordController.text.length < 6) return false;
    if (_isSignup) {
      return _confirmController.text == _passwordController.text &&
          _nameController.text.trim().isNotEmpty &&
          _addressController.text.trim().isNotEmpty;
    }
    return true;
  }

  void _openCountryPicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select country',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 16),
                ..._countries.map(
                  (c) => GestureDetector(
                    onTap: () {
                      setState(() => _country = c);
                      Navigator.of(ctx).pop();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          _circleFlag(c.iso, 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _dark,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                          Text(
                            c.dial,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _grey,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          if (c.dial == _country.dial) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.check_rounded, color: _gold, size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _continue() {
    if (!_canContinue || _loading) return;
    FocusScope.of(context).unfocus();
    if (_usePhone) {
      _continueWithPhone();
    } else {
      _continueWithEmail();
    }
  }

  Future<void> _continueWithEmail() async {
    setState(() => _loading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isSignup) {
        await AuthService.instance.signUpWithEmail(
          email: email,
          password: password,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
        );
      } else {
        await AuthService.instance.signInWithEmail(
          email: email,
          password: password,
        );
      }
      if (mounted) _enterApp();
    } on FirebaseAuthException catch (e) {
      // Logging in with a credential that has no account → nudge to sign up.
      // (With email-enumeration protection on, Firebase returns
      // 'invalid-credential' rather than 'user-not-found'.)
      if (!_isSignup &&
          (e.code == 'user-not-found' || e.code == 'invalid-credential')) {
        _showSignupSuggestion();
      } else {
        _showMessage(authErrorMessage(e));
      }
    } catch (_) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueWithPhone() async {
    setState(() => _loading = true);
    try {
      final phone = '${_country.dial}${_phoneController.text.trim()}';
      final password = _passwordController.text;
      if (_isSignup) {
        await AuthService.instance.signUpWithPhonePassword(
          phone: phone,
          password: password,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
        );
      } else {
        await AuthService.instance.signInWithPhonePassword(
          phone: phone,
          password: password,
        );
      }
      if (mounted) _enterApp();
    } on FirebaseAuthException catch (e) {
      if (!_isSignup &&
          (e.code == 'user-not-found' || e.code == 'invalid-credential')) {
        _showSignupSuggestion();
      } else {
        _showMessage(authErrorMessage(e));
      }
    } catch (_) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
        ),
        backgroundColor: _dark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  // Shown when a login finds no matching account. Offers a one-tap switch into
  // sign-up, keeping whatever email/phone they already typed.
  void _showSignupSuggestion() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'No account found with those details. New to Amira?',
            style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
          ),
          backgroundColor: _dark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Sign up',
            textColor: _gold,
            onPressed: () {
              setState(() {
                _isSignup = true;
                _passwordController.clear();
                _confirmController.clear();
              });
            },
          ),
        ),
      );
  }

  void _enterApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigator()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE9E4DC),
        body: Stack(
          children: [
            // Soft, blurred interior backdrop
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Image.asset(
                  _bgImage,
                  fit: BoxFit.cover,
                  color: Colors.white.withOpacity(0.25),
                  colorBlendMode: BlendMode.lighten,
                ),
              ),
            ),
            // Warm wash for cohesion
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33FFFFFF), Color(0x22000000)],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: _buildGlassCard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Frosted glass auth card ───────────────────────────────────────────────────
  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.28),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Brand + sign-up / log-in switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amira',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _grey,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isSignup = !_isSignup),
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      _isSignup ? 'Log in' : 'Sign up',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _dark,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Headline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _isSignup ? 'Sign up' : 'Log in',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                      fontFamily: 'Plus Jakarta Sans',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Inputs — progressive, animated reveal
              AnimatedSize(
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _usePhone ? _phoneField() : _emailField(),
                    // Password appears once the identifier is entered
                    // (phone and email both use a password now).
                    if (_identifierFilled)
                      _reveal(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 14),
                            _passwordField(),
                          ],
                        ),
                      ),
                    // Sign up adds confirm password + name + address.
                    if (_identifierFilled && _isSignup)
                      _reveal(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 14),
                            _textPill(
                              icon: Iconsax.lock_1,
                              hint: 'confirm password',
                              controller: _confirmController,
                              obscure: true,
                            ),
                            const SizedBox(height: 14),
                            _textPill(
                              icon: Iconsax.user,
                              hint: 'full name',
                              controller: _nameController,
                              keyboard: TextInputType.name,
                            ),
                            const SizedBox(height: 14),
                            _textPill(
                              icon: Iconsax.location,
                              hint: 'address',
                              controller: _addressController,
                              keyboard: TextInputType.streetAddress,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Toggle phone / email
              GestureDetector(
                onTap: () => setState(() => _usePhone = !_usePhone),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  _usePhone ? 'Use email instead' : 'Use phone instead',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _gold,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Fine print + arrow proceed button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'By continuing you agree to Amira\'s Terms & Conditions and Privacy Policy.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _dark,
                        fontFamily: 'Plus Jakarta Sans',
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _ArrowButton(
                    enabled: _canContinue && !_loading,
                    busy: _loading,
                    onTap: _continue,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const Center(
                child: Text(
                  'Designed for refined living.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pill fields ───────────────────────────────────────────────────────────────
  Widget _pillShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(30),
      ),
      child: child,
    );
  }

  Widget _chip({required IconData icon}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 17, color: _dark),
    );
  }

  // Fades + lifts a field into view as it's revealed.
  Widget _reveal({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, t, c) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - t) * 10), child: c),
      ),
      child: child,
    );
  }

  // Generic glass pill text field with a leading icon chip.
  Widget _textPill({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    Widget? trailing,
  }) {
    return _pillShell(
      child: Row(
        children: [
          _chip(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboard,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _dark,
                fontFamily: 'Plus Jakarta Sans',
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF9A958E),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Plus Jakarta Sans',
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _phoneField() {
    return _pillShell(
      child: Row(
        children: [
          GestureDetector(
            onTap: _openCountryPicker,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _circleFlag(_country.iso, 38),
                const SizedBox(width: 8),
                Text(
                  _country.dial,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const Icon(Iconsax.arrow_down_1, size: 14, color: _grey),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _dark,
                fontFamily: 'Plus Jakarta Sans',
              ),
              decoration: const InputDecoration(
                hintText: '700 123 456',
                hintStyle: TextStyle(
                  color: Color(0xFF9A958E),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Plus Jakarta Sans',
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailField() {
    return _textPill(
      icon: Iconsax.sms,
      hint: 'e-mail address',
      controller: _emailController,
      keyboard: TextInputType.emailAddress,
    );
  }

  Widget _passwordField() {
    return _textPill(
      icon: Iconsax.key,
      hint: 'password',
      controller: _passwordController,
      obscure: _obscurePassword,
      // "I forgot" only applies to email login — phone has no reset address.
      trailing: (_isSignup || _usePhone) ? null : _forgotPill(),
    );
  }

  Widget _forgotPill() {
    return GestureDetector(
      onTap: () async {
        final email = _emailController.text.trim();
        if (!email.contains('@') || !email.contains('.')) {
          _showMessage('Enter your email above first, then tap "I forgot".');
          return;
        }
        try {
          await AuthService.instance.sendPasswordReset(email);
          _showMessage('Password reset link sent to $email.');
        } on FirebaseAuthException catch (e) {
          _showMessage(authErrorMessage(e));
        } catch (_) {
          _showMessage('Couldn\'t send reset link. Please try again.');
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'I forgot',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _dark,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ),
    );
  }
}

// ── Dark circular arrow proceed button ──────────────────────────────────────────
class _ArrowButton extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;
  const _ArrowButton({
    required this.enabled,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled || busy ? 1 : 0.45,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(_white),
                  ),
                )
              : const Icon(Icons.arrow_forward_rounded,
                  color: _white, size: 24),
        ),
      ),
    );
  }
}
