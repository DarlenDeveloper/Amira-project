import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

const _dark = Color(0xFF2A2A2A);
const _white = Colors.white;
const _grey = Color(0xFF7E7A74);
const _gold = Color(0xFFB5945A);

const _bgImage = 'assets/images/kam-idris-hYb7kbu4x7E-unsplash.jpg';
const _codeLength = 6;

/// SMS code verification, styled to match the frosted-glass login card.
///
/// Pops `true` once the phone number is verified and the user is signed in.
class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isSignup;
  final String? name;
  final String? address;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.isSignup = false,
    this.name,
    this.address,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocus = FocusNode();

  String? _verificationId;
  bool _sending = true; // requesting the code
  bool _verifying = false; // confirming the entered code
  String? _error;

  // Resend cooldown
  Timer? _resendTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  String get _code => _codeController.text;
  bool get _canConfirm =>
      _code.length == _codeLength && !_verifying && _verificationId != null;

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    await AuthService.instance.verifyPhone(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _sending = false;
        });
        _startResendCooldown();
        _codeFocus.requestFocus();
      },
      onFailed: (e) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _error = authErrorMessage(e);
        });
      },
      onAutoVerified: (credential) async {
        // Android auto-retrieval — sign in without manual entry.
        await _completeWith(() => AuthService.instance.signInWithPhoneCredential(
              credential,
              name: widget.name,
              address: widget.address,
            ));
      },
    );
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    FocusScope.of(context).unfocus();
    await _completeWith(() => AuthService.instance.confirmSmsCode(
          verificationId: _verificationId!,
          smsCode: _code,
          name: widget.name,
          address: widget.address,
        ));
  }

  /// Runs a sign-in action, manages the spinner, and pops `true` on success.
  Future<void> _completeWith(Future<UserCredential> Function() action) async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = authErrorMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = 45);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
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
                  child: _buildGlassCard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amira',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _grey,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(false),
                    behavior: HitTestBehavior.opaque,
                    child: const Text(
                      'Change number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dark,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Verify\nyour number',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                  fontFamily: 'Satoshi',
                  height: 1.05,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _sending
                    ? 'Sending a code to ${widget.phoneNumber}…'
                    : 'Enter the 6-digit code sent to ${widget.phoneNumber}.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _dark,
                  fontFamily: 'Satoshi',
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),

              _CodeField(
                controller: _codeController,
                focusNode: _codeFocus,
                enabled: !_sending && !_verifying,
                onChanged: (_) => setState(() {}),
                onCompleted: (_) => _confirm(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB23A3A),
                    fontFamily: 'Satoshi',
                  ),
                ),
              ],

              const SizedBox(height: 22),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _resendControl()),
                  const SizedBox(width: 16),
                  _ConfirmButton(
                    enabled: _canConfirm,
                    busy: _verifying,
                    onTap: _confirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resendControl() {
    if (_sending) {
      return const Text(
        'Sending code…',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _grey,
          fontFamily: 'Satoshi',
        ),
      );
    }
    if (_secondsLeft > 0) {
      return Text(
        'Resend code in ${_secondsLeft}s',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _grey,
          fontFamily: 'Satoshi',
        ),
      );
    }
    return GestureDetector(
      onTap: _sendCode,
      behavior: HitTestBehavior.opaque,
      child: const Text(
        'Resend code',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _gold,
          fontFamily: 'Satoshi',
        ),
      ),
    );
  }
}

/// Six-box code entry. A single hidden field captures input while the boxes
/// mirror each digit, keeping native paste / autofill behaviour intact.
class _CodeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  const _CodeField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => focusNode.requestFocus() : null,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Hidden input — drives the visible boxes.
          Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_codeLength),
              ],
              onChanged: (v) {
                onChanged(v);
                if (v.length == _codeLength) onCompleted(v);
              },
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([controller, focusNode]),
            builder: (context, _) {
              final code = controller.text;
              final activeIndex = code.length.clamp(0, _codeLength - 1);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_codeLength, (i) {
                  final filled = i < code.length;
                  final isActive = focusNode.hasFocus && i == activeIndex;
                  return Container(
                    width: 46,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? _gold
                            : Colors.white.withOpacity(0.6),
                        width: isActive ? 1.6 : 1.0,
                      ),
                    ),
                    child: Text(
                      filled ? code[i] : '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Dark circular confirm button — mirrors the login arrow button, with a busy
/// spinner state for the verification round-trip.
class _ConfirmButton extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  const _ConfirmButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
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
