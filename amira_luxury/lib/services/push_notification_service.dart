import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background isolate handler for data/notification messages that arrive while
/// the app is terminated or backgrounded. Must be a top-level function.
///
/// Firebase is already initialised by the plugin in the background isolate, so
/// we only need to acknowledge the message. Display is handled by the OS for
/// "notification" payloads; nothing else is required here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally minimal — the system tray shows the notification payload.
  // Add analytics or local bookkeeping here if needed later.
}

/// Owns everything Firebase Cloud Messaging: permission prompts, token
/// lifecycle (stored under `users/{uid}/fcmTokens/{token}`), topic
/// subscription for broadcasts, and foreground display via a local
/// notification channel.
///
/// Screens/services talk only to [PushNotificationService.instance].
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const String broadcastTopic = 'broadcast';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // Android channel used to surface messages while the app is in the
  // foreground (Android suppresses the tray notification in that state).
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'amira_default',
    'Amira Notifications',
    description: 'Order updates, appointments, and announcements.',
    importance: Importance.high,
  );

  bool _initialised = false;
  StreamSubscription<String>? _tokenRefreshSub;

  /// One-time setup: local-notification plugin, the Android channel, foreground
  /// presentation options, and message listeners. Safe to call more than once.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    // Local notifications (used for foreground display on Android/iOS).
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit, macOS: darwinInit),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // iOS/macOS: show heads-up alerts while in the foreground too.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages → render via the local channel so the user sees them.
    FirebaseMessaging.onMessage.listen(_showForeground);
  }

  /// Prompts for the OS notification permission (Android 13+, iOS/macOS).
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Requests permission, subscribes to the broadcast topic, stores the current
  /// device token for the signed-in user, and watches for token refreshes.
  /// Call after a user is signed in (e.g. entering the app shell).
  Future<void> registerForCurrentUser() async {
    await init();

    final granted = await requestPermission();
    if (!granted) {
      if (kDebugMode) {
        debugPrint('Push: notification permission not granted.');
      }
      // Still safe to subscribe to broadcasts / store a token; the OS simply
      // won't display alerts until the user enables them in settings.
    }

    // Broadcast announcements (admin "Notifications" page → topic push).
    try {
      await _messaging.subscribeToTopic(broadcastTopic);
    } catch (e) {
      if (kDebugMode) debugPrint('Push: subscribeToTopic failed: $e');
    }

    await _saveToken();

    // Persist future token rotations for the current user.
    _tokenRefreshSub ??= _messaging.onTokenRefresh.listen((token) {
      _writeToken(token);
    });
  }

  Future<void> _saveToken() async {
    try {
      // APNs token must exist before an FCM token can be minted on Apple
      // platforms; getToken() handles the wait, but guard against nulls.
      final token = await _messaging.getToken();
      if (token != null) await _writeToken(token);
    } catch (e) {
      if (kDebugMode) debugPrint('Push: getToken failed: $e');
    }
  }

  Future<void> _writeToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
      'token': token,
      'platform': _platformLabel(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Removes the current device token for the signed-in user and unsubscribes
  /// from broadcasts. Call before signing out so stale tokens don't linger.
  Future<void> unregisterCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    try {
      final token = await _messaging.getToken();
      if (uid != null && token != null) {
        await _db
            .collection('users')
            .doc(uid)
            .collection('fcmTokens')
            .doc(token)
            .delete();
      }
      await _messaging.unsubscribeFromTopic(broadcastTopic);
    } catch (e) {
      if (kDebugMode) debugPrint('Push: unregister failed: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['route'] as String?,
    );
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    return 'other';
  }
}
