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
    await _writeProfileSafely(
      () => _upsertProfile(
        cred.user!,
        name: name,
        email: email,
        address: address,
        isNew: true,
      ),
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

    await _writeProfileSafely(
      () => _upsertProfile(
        userCred.user!,
        name: account.displayName,
        email: account.email,
        photoUrl: userCred.user?.photoURL,
        isNew: userCred.additionalUserInfo?.isNewUser ?? false,
      ),
    );
    return userCred;
  }

  // ── Phone (number + password) ───────────────────────────────────────────────
  // Firebase email/password auth doesn't take phone numbers directly, so a phone
  // is mapped to a stable internal credential email (digits@phone domain). The
  // user only ever sees their phone number; the real E.164 value is saved on the
  // profile. No SMS / OTP involved.
  static const String _phoneEmailDomain = 'phone.amira.app';

  static String _phoneToEmail(String phoneE164) {
    final digits = phoneE164.replaceAll(RegExp(r'[^0-9]'), '');
    return '$digits@$_phoneEmailDomain';
  }

  Future<UserCredential> signInWithPhonePassword({
    required String phone,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: _phoneToEmail(phone),
      password: password,
    );
  }

  Future<UserCredential> signUpWithPhonePassword({
    required String phone,
    required String password,
    required String name,
    required String address,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: _phoneToEmail(phone),
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    await _writeProfileSafely(
      () => _upsertProfile(
        cred.user!,
        name: name,
        phone: phone,
        address: address,
        isNew: true,
      ),
    );
    return cred;
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
  /// overwritten with nulls (see [AppUser.toMap]). The internal phone-credential
  /// email is treated as "no email" so it never shows up in the UI.
  Future<void> _upsertProfile(
    User user, {
    String? name,
    String? email,
    String? phone,
    String? address,
    String? photoUrl,
    bool isNew = false,
  }) {
    final resolvedEmail = email ?? user.email;
    final isInternalEmail =
        resolvedEmail != null && resolvedEmail.endsWith('@$_phoneEmailDomain');
    final profile = AppUser(
      uid: user.uid,
      name: name,
      email: isInternalEmail ? null : resolvedEmail,
      phone: phone ?? user.phoneNumber,
      address: address,
      photoUrl: photoUrl,
    );
    // No pre-read: a blocking get() can hang while the device is briefly
    // offline. createdAt is written only on first creation (callers pass isNew).
    return _users.doc(user.uid).set({
      ...profile.toMap(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Runs a profile write without letting it block the auth flow. Firestore
  /// persists the write locally and syncs when connectivity returns, so a slow
  /// or briefly-offline backend never stalls sign-in/sign-up.
  Future<void> _writeProfileSafely(Future<void> Function() write) async {
    try {
      await write().timeout(const Duration(seconds: 6));
    } catch (_) {
      // Timed out or transient error — the write stays queued offline.
    }
  }

  Stream<AppUser?> profileStream(String uid) {
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromDoc(doc) : null,
        );
  }

  Future<AppUser?> fetchProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  /// Updates editable profile fields for the current user. Only non-null values
  /// are written (merge), and the auth displayName is kept in sync with [name].
  Future<void> updateProfile({
    String? name,
    String? address,
    String? phone,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to update your profile.',
      );
    }
    if (name != null && name.isNotEmpty) {
      await user.updateDisplayName(name);
    }
    await _users.doc(user.uid).set({
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
