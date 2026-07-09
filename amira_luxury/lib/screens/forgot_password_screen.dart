import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import '../services/auth_service.dart';

const _dark = Color(0xFF2A2A2A);
const _white = Colors.white;
const _grey = Color(0xFF7E7A74);
const _gold = Color(0xFFC4A464);
const _bgImage = 'assets/images/kam-idris-hYb7kbu4x7E-unsplash.jpg';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailCtrl;
  bool _loading = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _validEmail {
    final e = _emailCtrl.text.trim();
    return e.contains('@') && e.contains('.');
  }

  Future<void> _send() async {
    if (!_validEmail || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await AuthService.instance.sendPasswordReset(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      _showMessage(authErrorMessage(e));
    } catch (_) {
      _showMessage('Couldn\'t send reset link. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
        backgroundColor: _dark,
        behavior: SnackBarBehavior.floating,
      ),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.45),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Back button
                            GestureDetector(
                              onTap: () => Navigator.of(context).maybePop(),
                              child: const Icon(Icons.arrow_back, color: _dark, size: 22),
                            ),
                            const SizedBox(height: 22),

                            const Text(
                              'Reset password',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: _dark,
                                fontFamily: 'Plus Jakarta Sans',
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Enter your email and we\'ll send you a link to reset your password.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: _grey,
                                fontFamily: 'Plus Jakarta Sans',
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),

                            if (_sent) ...[
                              // Success state
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Iconsax.tick_circle5, color: _gold, size: 28),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        'Reset link sent to ${_emailCtrl.text.trim()}. Check your inbox.',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: _dark,
                                          fontFamily: 'Plus Jakarta Sans',
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: () => Navigator.of(context).maybePop(),
                                child: Container(
                                  width: double.infinity,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: _dark,
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Back to login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _white,
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Email field
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(Iconsax.sms, size: 17, color: _dark),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _emailCtrl,
                                        keyboardType: TextInputType.emailAddress,
                                        onChanged: (_) => setState(() {}),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _dark,
                                          fontFamily: 'Plus Jakarta Sans',
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'your@email.com',
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
                              ),
                              const SizedBox(height: 24),

                              // Send button
                              GestureDetector(
                                onTap: _validEmail && !_loading ? _send : null,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _validEmail ? 1.0 : 0.45,
                                  child: Container(
                                    width: double.infinity,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: _dark,
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    alignment: Alignment.center,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor: AlwaysStoppedAnimation(_white),
                                            ),
                                          )
                                        : const Text(
                                            'Send reset link',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: _white,
                                              fontFamily: 'Plus Jakarta Sans',
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],

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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
