import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/render_session.dart';

/// Visual Studio lifecycle: start session → upload room → register → generate.
class RenderService {
  RenderService._();
  static final RenderService instance = RenderService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  String? get _uid => _auth.currentUser?.uid;

  /// Starts a new render session and returns its id.
  Future<String> startSession({
    List<String> productIds = const [],
    List<String> materialNames = const [],
    String source = 'tab',
    String prompt = '',
  }) async {
    final callable = _functions.httpsCallable('startRenderSession');
    final res = await callable.call<Map<String, dynamic>>({
      'productIds': productIds,
      'materialNames': materialNames,
      'source': source,
      'prompt': prompt,
    });
    final id = res.data['renderId'] as String?;
    if (id == null || id.isEmpty) throw Exception('No render session id returned.');
    return id;
  }

  /// Uploads [file] to `visual-studio/{uid}/{renderId}/room.jpg`.
  Future<String> uploadRoomImage(
    String renderId,
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to upload a room photo.',
      );
    }

    final ref = _storage.ref('visual-studio/$uid/$renderId/room.jpg');
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) {
        onProgress?.call(s.bytesTransferred / s.totalBytes);
      }
    });

    await task;
    return ref.getDownloadURL();
  }

  /// Registers the uploaded room photo with the render session.
  Future<void> registerRoomUpload(String renderId, String roomImageUrl) async {
    final callable = _functions.httpsCallable('registerRoomUpload');
    await callable.call<Map<String, dynamic>>({
      'renderId': renderId,
      'roomImageUrl': roomImageUrl,
    });
  }

  /// Generates the AI render for an existing session.
  Future<String> generateRender({
    required String renderId,
    bool forceRetry = false,
  }) async {
    final callable = _functions.httpsCallable(
      'generateRender',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );
    final res = await callable.call<Map<String, dynamic>>({
      'renderId': renderId,
      if (forceRetry) 'forceRetry': true,
    });
    final url = res.data['resultUrl'] as String?;
    if (url == null || url.isEmpty) throw Exception('No render returned.');
    return url;
  }

  /// Live list of the signed-in user's past renders, newest first.
  Stream<List<RenderSession>> watchMyRenders() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _db
        .collection('users')
        .doc(uid)
        .collection('renders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(RenderSession.fromDoc).toList());
  }
}
