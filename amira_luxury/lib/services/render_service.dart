import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Handles the Visual Studio room photo: uploading the user's image to
/// `renders/{uid}/…` in Cloud Storage. The AI generation step (Cloud Function)
/// will consume the returned URL in a later phase.
class RenderService {
  RenderService._();
  static final RenderService instance = RenderService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Uploads [file] as the user's room photo and returns its download URL.
  /// [onProgress] reports 0.0–1.0 as the upload proceeds.
  Future<String> uploadRoomImage(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to upload a room photo.',
      );
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('renders/$uid/room_$ts.jpg');
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

  /// Calls the `generateRender` Cloud Function to apply the selected materials
  /// into the uploaded room photo. Returns the generated image's URL.
  Future<String> generateRender({
    required String roomImageUrl,
    List<String> productImageUrls = const [],
    List<String> materialNames = const [],
    String prompt = '',
  }) async {
    final callable = _functions.httpsCallable(
      'generateRender',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );
    final res = await callable.call<Map<String, dynamic>>({
      'roomImageUrl': roomImageUrl,
      'productImageUrls': productImageUrls,
      'materialNames': materialNames,
      'prompt': prompt,
    });
    final url = res.data['resultUrl'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('No render returned.');
    }
    return url;
  }
}
