import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Talks to the Amira AI agent. The behaviour (persona, model, greeting,
/// suggestions, on/off) is controlled from the admin dashboard via the
/// `config/agent` document; this service just reads that config for display and
/// calls the `chatAgent` Cloud Function, which owns the conversation thread.
class AgentService {
  AgentService._();
  static final AgentService instance = AgentService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads a chat image to `ai-agent/{uid}/{conversationId}/{ts}.jpg` and
  /// returns its download URL. Uses a temporary folder when the conversation
  /// hasn't been created yet (first message).
  Future<String> uploadChatImage(File file, {String? conversationId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to send a photo.',
      );
    }
    final convo = conversationId ?? 'new-${DateTime.now().millisecondsSinceEpoch}';
    final ref = _storage.ref(
      'ai-agent/$uid/$convo/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Admin-tuned presentation config for the welcome screen.
  Future<AgentConfig> loadConfig() async {
    try {
      final snap = await _db.collection('config').doc('agent').get();
      final data = snap.data() ?? const {};
      return AgentConfig(
        enabled: data['enabled'] != false,
        greeting: (data['greeting'] as String?)?.trim().isNotEmpty == true
            ? (data['greeting'] as String).trim()
            : AgentConfig.defaultGreeting,
        suggestions: (data['suggestions'] as List?)
                ?.whereType<String>()
                .where((s) => s.trim().isNotEmpty)
                .toList() ??
            const [],
      );
    } catch (_) {
      return const AgentConfig();
    }
  }

  /// Sends [message] to the agent. Pass the [conversationId] from a previous
  /// reply to continue the same thread (null starts a new one). Returns the
  /// agent's reply and the conversation id to reuse next time.
  Future<AgentReply> sendMessage({
    required String message,
    String? conversationId,
    String? productId,
    String source = 'typed',
    String? suggestionLabel,
    String? imageUrl,
  }) async {
    final callable = _functions.httpsCallable(
      'chatAgent',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );
    final res = await callable.call<Map<String, dynamic>>({
      'message': message,
      if (conversationId != null) 'conversationId': conversationId,
      if (productId != null) 'productId': productId,
      'source': source,
      if (suggestionLabel != null) 'suggestionLabel': suggestionLabel,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    final data = res.data;
    return AgentReply(
      conversationId: data['conversationId'] as String?,
      reply: (data['reply'] as String?)?.trim() ?? '',
    );
  }
}

class AgentConfig {
  final bool enabled;
  final String greeting;
  final List<String> suggestions;

  const AgentConfig({
    this.enabled = true,
    this.greeting = defaultGreeting,
    this.suggestions = const [],
  });

  static const String defaultGreeting =
      'Ask me anything about Amira collections, design ideas, or personalized recommendations';
}

class AgentReply {
  final String? conversationId;
  final String reply;

  const AgentReply({required this.conversationId, required this.reply});
}
