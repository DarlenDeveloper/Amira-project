import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';

/// Central entry point for everything auth-related: email/password, Google,
/// phone (OTP), password reset, sign-out, and the user's Firestore profile.
///
/// Screens talk only to [AuthService.instance] — they never touch
/// [FirebaseAuth] or [GoogleSignIn] directly.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Web OAuth client id (client_type 3 from google-services.json). Required on
  /// Android so the Google id token has an audience Firebase will accept.
  static const String _serverClientId =
      '1027356115889-v100ivssopflutc70s0g2olsfnqrj3l4.apps.googleusercontent.com';

  bool _googleReady = false;

  // ── Identity ────────────────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── Email / password ──────────────────────────────────────────────────────────
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String address,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    await _upsertProfile(
      cred.user!,
      name: name,
      email: email,
      address: address,
    );
    return cred;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  // ── Google ──────────────────────────────────────────────────────────────────
  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _googleReady = true;
  }

  /// Returns null if the user cancels the Google sheet; otherwise the signed-in
  /// credential. Throws [FirebaseAuthException] on a real failure.
  Future<UserCredential?> signInWithGoogle() async {
    await _ensureGoogleReady();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'unsupported',
        message: 'Google sign-in is not supported on this device.',
      );
    }

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: e.description ?? 'Google sign-in failed.',
      );
    }

    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCred = await _auth.signInWithCredential(credential);

    await _upsertProfile(
      userCred.user!,
      name: account.displayName,
      email: account.email,
      photoUrl: userCred.user?.photoURL,
    );
    return userCred;
  }

  // ── Phone (OTP) ───────────────────────────────────────────────────────────────
  /// Kicks off SMS verification for [phoneNumber] (E.164, e.g. +256700123456).
  ///
  /// On Android the code can be auto-retrieved, in which case [onAutoVerified]
  /// fires with a ready-to-use credential and no manual entry is needed.
  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  /// Completes phone sign-in from a manually entered [smsCode].
  Future<UserCredential> confirmSmsCode({
    required String verificationId,
    required String smsCode,
    String? name,
    String? address,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return signInWithPhoneCredential(
      credential,
      name: name,
      address: address,
    );
  }

  /// Completes phone sign-in from a [PhoneAuthCredential] (manual or
  /// auto-retrieved) and writes the profile.
  Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential, {
    String? name,
    String? address,
  }) async {
    final userCred = await _auth.signInWithCredential(credential);
    if (name != null && name.isNotEmpty) {
      await userCred.user?.updateDisplayName(name);
    }
    await _upsertProfile(
      userCred.user!,
      name: name,
      address: address,
      phone: userCred.user?.phoneNumber,
    );
    return userCred;
  }

  // ── Session ───────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    if (_googleReady) {
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }

  // ── Profile (Firestore) ─────────────────────────────────────────────────────────
  /// Creates or merges the `users/{uid}` document. Existing fields are never
  /// overwritten with nulls (see [AppUser.toMap]).
  Future<void> _upsertProfile(
    User user, {
    String? name,
    String? email,
    String? phone,
    String? address,
    String? photoUrl,
  }) async {
    final doc = _users.doc(user.uid);
    final profile = AppUser(
      uid: user.uid,
      name: name,
      email: email ?? user.email,
      phone: phone ?? user.phoneNumber,
      address: address,
      photoUrl: photoUrl,
    );
    final snapshot = await doc.get();
    await doc.set({
      ...profile.toMap(),
      if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<AppUser?> profileStream(String uid) {
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromDoc(doc) : null,
        );
  }
}

/// Maps a [FirebaseAuthException] to a warm, human-readable message that fits
/// the Amira tone. Falls back to a calm generic line for unknown codes.
String authErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'That email address doesn\'t look right.';
    case 'user-disabled':
      return 'This account has been disabled. Please contact support.';
    case 'user-not-found':
    case 'invalid-credential':
    case 'wrong-password':
      return 'Those details don\'t match our records.';
    case 'email-already-in-use':
      return 'An account already exists for that email.';
    case 'weak-password':
      return 'Please choose a stronger password (at least 6 characters).';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'invalid-verification-code':
      return 'That code isn\'t correct. Please check and try again.';
    case 'invalid-phone-number':
      return 'That phone number doesn\'t look right.';
    case 'network-request-failed':
      return 'Network issue. Please check your connection.';
    default:
      return e.message ?? 'Something went wrong. Please try again.';
  }
}
