import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_shell_controller.dart';
import '../models/product.dart';
import '../services/agent_service.dart';
import '../services/product_service.dart';
import '../widgets/coachmark.dart';
import 'item_details_screen.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _lightGrey = Color(0xFFE8E8E8);
const _gold = Color(0xFFC4A464);
const _lightGold = Color(0xFFF5EFE3);

class AIAgentScreen extends StatefulWidget {
  const AIAgentScreen({super.key});

  @override
  State<AIAgentScreen> createState() => _AIAgentScreenState();
}

class _AIAgentScreenState extends State<AIAgentScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  AnimationController? _borderAnimationController;

  // Image attachment state for photo-in-chat.
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  String? _uploadedImageUrl;
  bool _uploadingImage = false;
  bool _uploadFailed = false;

  // Live conversation state.
  String? _conversationId;
  bool _sending = false;
  bool _agentEnabled = true;
  // Human-intervention state: once an admin takes over, the AI is paused and
  // it's just the customer and the Amira team.
  bool _intervened = false;
  StreamSubscription? _convoSub;
  StreamSubscription? _messagesSub;
  final Set<String> _seenAdminMsgIds = {};
  List<String> _suggestions = [];
  List<Product> _catalog = [];
  String? _pendingProductId;
  int _appliedIntentToken = 0;
  AppShellController? _shell;

  // Coachmark anchors + trigger state.
  final GlobalKey _tipAgentInputKey = GlobalKey();
  final GlobalKey _tipAgentSuggestKey = GlobalKey();
  bool _coachTriggered = false;
  String _displayedText = '';
  int _currentTextIndex = 0;
  final List<String> _typewriterTexts = [
    'Amira Agent',
    'Your luxury interior design assistant',
    'Ask me anything about Amira collections, design ideas, or personalized recommendations',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimationController();
    _loadConfig();
    ProductService.instance.watchProducts().listen((products) {
      if (!mounted) return;
      setState(() => _catalog = products);
    });
    _focusNode.addListener(() {
      setState(() {}); // Rebuild when focus changes
    });
    // Start typewriter animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTypewriter();
    });
  }

  // Pulls the admin-tuned greeting so the welcome line matches what the brand
  // configured in the dashboard.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shell = AppShellController.maybeOf(context);
    if (shell != null && shell != _shell) {
      _shell?.removeListener(_onShellChange);
      _shell = shell;
      _shell!.addListener(_onShellChange);
      _applyShellIntent();
      if (shell.currentIndex == 3) _maybeShowCoachmarks();
    }
  }

  void _onShellChange() {
    if (_shell?.currentIndex == 3) {
      _applyShellIntent();
      _maybeShowCoachmarks();
    }
  }

  // Shows the Agent tooltips once, the first time the tab is opened in its
  // welcome state (not over an active or auto-started conversation).
  Future<void> _maybeShowCoachmarks() async {
    if (_coachTriggered) return;
    _coachTriggered = true;
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return;
    }
    if (prefs.getBool('coach_agent_v1') ?? false) return;
    if (!mounted || _messages.isNotEmpty) return;
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _messages.isNotEmpty) return;
    Coachmarks.show(
      context,
      [
        CoachStep(
          targetKey: _tipAgentInputKey,
          title: 'Ask Amira anything',
          body:
              'Ask about finishes, design ideas, pricing, or your order — Amira replies instantly.',
          radius: 30,
        ),
        CoachStep(
          targetKey: _tipAgentSuggestKey,
          title: 'Quick starts',
          body: 'New here? Tap a suggestion to begin the conversation.',
          radius: 18,
        ),
      ],
      onFinish: () => prefs.setBool('coach_agent_v1', true),
    );
  }

  void _applyShellIntent() {
    final shell = _shell;
    if (shell == null) return;
    final intent = shell.consumeAgentIntent();
    if (intent == null || intent.token == _appliedIntentToken) return;
    if (!mounted) return;
    _appliedIntentToken = intent.token;
    _pendingProductId = intent.productId;
    if (intent.seedMessage != null && intent.seedMessage!.isNotEmpty) {
      _textController.text = intent.seedMessage!;
      if (intent.autoSend) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _sendMessage());
      }
    }
  }

  void _loadConfig() {
    AgentService.instance.loadConfig().then((config) {
      if (!mounted) return;
      setState(() {
        _typewriterTexts[2] = config.greeting;
        _suggestions = config.suggestions;
        _agentEnabled = config.enabled;
      });
    });
  }

  void _startTypewriter() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _typeText();
      }
    });
  }

  void _typeText() {
    if (!mounted) return;
    
    final currentText = _typewriterTexts[_currentTextIndex];
    if (_displayedText.length < currentText.length) {
      setState(() {
        _displayedText = currentText.substring(0, _displayedText.length + 1);
      });
      // Vary speed: faster for spaces, slower for letters
      final delay = _displayedText.isNotEmpty && currentText[_displayedText.length - 1] == ' ' ? 30 : 80;
      Future.delayed(Duration(milliseconds: delay), _typeText);
    } else {
      // Finished typing current text, move to next after pause
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        if (_currentTextIndex < _typewriterTexts.length - 1) {
          setState(() {
            _currentTextIndex++;
            _displayedText = '';
          });
          Future.delayed(const Duration(milliseconds: 300), _typeText);
        }
      });
    }
  }

  void _initAnimationController() {
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  Future<void> _sendMessage({
    String? overrideText,
    String source = 'typed',
    String? suggestionLabel,
  }) async {
    final text = (overrideText ?? _textController.text).trim();
    final imageUrl = _uploadedImageUrl;
    // Need either text or an attached image; never send while still uploading.
    if ((text.isEmpty && imageUrl == null) || _sending || _uploadingImage) {
      return;
    }

    final productId = _pendingProductId;
    final msgSource = suggestionLabel != null ? 'suggestion' : source;

    setState(() {
      _messages.add({'text': text, 'isUser': true, 'imageUrl': imageUrl});
      if (overrideText == null) _textController.clear();
      _pickedImage = null;
      _uploadedImageUrl = null;
      // No AI typing indicator while a human is handling the thread.
      _sending = !_intervened;
    });
    _scrollToBottom();

    try {
      final res = await AgentService.instance.sendMessage(
        message: text,
        conversationId: _conversationId,
        productId: productId,
        source: msgSource,
        suggestionLabel: suggestionLabel,
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      final newId = res.conversationId ?? _conversationId;
      setState(() {
        _conversationId = newId;
        // In human mode the agent doesn't reply — the specialist's messages
        // arrive over the live listener instead, so don't add an empty bubble.
        if (!_intervened && res.reply.isNotEmpty) {
          _messages.add({'text': res.reply, 'isUser': false, 'animate': true});
        }
        _sending = false;
        _pendingProductId = null;
      });
      // Begin watching the thread once it exists, so admin replies and the
      // intervention banner appear live.
      if (newId != null && _messagesSub == null) {
        _subscribeToThread(newId);
      }
      _scrollToBottom();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'text': e.code == 'failed-precondition'
              ? (e.message ?? 'The Amira Agent is currently unavailable.')
              : "Sorry, I couldn't respond just now. Please try again.",
          'isUser': false,
        });
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'text': "Sorry, I couldn't respond just now. Please try again.",
          'isUser': false,
        });
        _sending = false;
      });
    }
  }

  // Lets the user attach a room photo from camera or gallery, then uploads it
  // in the background so it's ready to send with the next message.
  void _chooseImageSource() {
    if (!_agentEnabled) {
      _showUnavailable('The Amira Agent');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Iconsax.camera5, color: _gold),
              title: const Text('Take a photo',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _dark,
                      fontFamily: 'Plus Jakarta Sans')),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.gallery5, color: _gold),
              title: const Text('Choose from gallery',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _dark,
                      fontFamily: 'Plus Jakarta Sans')),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 88,
      );
      if (file == null) return;
      setState(() {
        _pickedImage = file;
        _uploadedImageUrl = null;
        _uploadFailed = false;
        _uploadingImage = true;
      });
      await _uploadPicked();
    } catch (_) {
      // Picker itself failed (rare). Keep things quiet; no snackbar.
    }
  }

  // Uploads the currently picked image in the background. On failure the
  // thumbnail stays put with an inline retry — ChatGPT-style, no snackbar.
  Future<void> _uploadPicked() async {
    final picked = _pickedImage;
    if (picked == null) return;
    setState(() {
      _uploadingImage = true;
      _uploadFailed = false;
    });
    try {
      final url = await AgentService.instance.uploadChatImage(
        File(picked.path),
        conversationId: _conversationId,
      );
      if (!mounted) return;
      setState(() {
        _uploadedImageUrl = url;
        _uploadingImage = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploadedImageUrl = null;
        _uploadingImage = false;
        _uploadFailed = true;
      });
    }
  }

  void _clearPickedImage() {
    setState(() {
      _pickedImage = null;
      _uploadedImageUrl = null;
      _uploadingImage = false;
      _uploadFailed = false;
    });
  }

  List<Product> _linkedProducts(String text) {
    if (_catalog.isEmpty) return const [];
    final found = <Product>[];
    for (final p in _catalog) {
      if (found.length >= 3) break;
      if (p.name.isNotEmpty && text.contains(p.name)) {
        found.add(p);
      }
    }
    return found;
  }

  @override
  void dispose() {
    _shell?.removeListener(_onShellChange);
    _convoSub?.cancel();
    _messagesSub?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _borderAnimationController?.dispose();
    super.dispose();
  }

  // Watches the live thread once it exists: the conversation doc (for the
  // intervention/`mode` flag) and the messages subcollection (to surface the
  // Amira team's replies, which don't return through the chat round-trip).
  void _subscribeToThread(String conversationId) {
    _convoSub?.cancel();
    _messagesSub?.cancel();
    _convoSub =
        AgentService.instance.watchConversation(conversationId).listen((doc) {
      if (!mounted) return;
      final mode = (doc.data()?['mode'] as String?) ?? 'agent';
      final human = mode == 'human';
      if (human != _intervened) {
        setState(() {
          _intervened = human;
          if (human) _sending = false; // no AI is going to answer
        });
      }
    });
    _messagesSub =
        AgentService.instance.watchMessages(conversationId).listen((snap) {
      if (!mounted) return;
      final incoming = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = d.data();
        if (data['from'] == 'admin' && !_seenAdminMsgIds.contains(d.id)) {
          _seenAdminMsgIds.add(d.id);
          incoming.add({
            'text': (data['text'] as String?) ?? '',
            'isUser': false,
            'isAdmin': true,
          });
        }
      }
      if (incoming.isNotEmpty) {
        setState(() => _messages.addAll(incoming));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // Keeps the view pinned to the newest content as the reply types out.
  void _followBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Drive layout off the actual keyboard height, NOT focus — the keyboard
    // animates in a moment after focus, so keying off focus makes the input bar
    // jump to the bottom before the keyboard is there (colliding with the nav).
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (_messages.isNotEmpty) ...[
                // Chat header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _messages.clear();
                          });
                          _focusNode.unfocus();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: _dark, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Amira Agent',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _dark,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Intervention banner — a specialist has taken over the thread.
                if (_intervened)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _lightGold,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _gold.withOpacity(0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.user, color: _gold, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'An Amira specialist has joined the conversation',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _dark.withOpacity(0.8),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Chat messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= _messages.length) {
                        return const _TypingIndicator();
                      }
                      final msg = _messages[i];
                      final isUser = msg['isUser'] as bool;
                      final isAdmin = msg['isAdmin'] == true;
                      final text = msg['text'] as String;
                      if (!isUser && msg['animate'] == true) {
                        return _StreamingAgentBubble(
                          text: text,
                          linkedProducts: _linkedProducts(text),
                          onTick: _followBottom,
                          onDone: () {
                            if (!mounted) return;
                            setState(() => msg['animate'] = false);
                          },
                        );
                      }
                      return _MessageBubble(
                        text: text,
                        isUser: isUser,
                        isAdmin: isAdmin,
                        imageUrl: msg['imageUrl'] as String?,
                        linkedProducts:
                            (isUser || isAdmin) ? const [] : _linkedProducts(text),
                      );
                    },
                  ),
                ),
              ] else ...[
                // Typewriter animation welcome state
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Typewriter text display
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_displayedText.isNotEmpty)
                                Flexible(
                                  child: Text(
                                    _displayedText,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: _currentTextIndex == 0 ? 32 : (_currentTextIndex == 1 ? 18 : 15),
                                      fontWeight: _currentTextIndex == 0 ? FontWeight.w700 : (_currentTextIndex == 1 ? FontWeight.w600 : FontWeight.w400),
                                      color: _currentTextIndex == 0 ? _dark : (_currentTextIndex == 1 ? _dark : _grey),
                                      fontFamily: 'Plus Jakarta Sans',
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              // Blinking cursor
                              if (_displayedText.length < _typewriterTexts[_currentTextIndex].length)
                                Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: _BlinkingCursor(),
                                ),
                            ],
                          ),
                          if (!_agentEnabled) ...[
                            const SizedBox(height: 20),
                            Text(
                              'The Amira Agent is currently unavailable.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: _grey.withOpacity(0.9),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                          if (_suggestions.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            Column(
                              key: _tipAgentSuggestKey,
                              children: [
                                ..._suggestions.take(6).map(
                                      (s) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: _SuggestionChip(
                                          text: s,
                                          icon: Iconsax.message_text5,
                                          onTap: () => _sendMessage(
                                            overrideText: s,
                                            source: 'suggestion',
                                            suggestionLabel: s,
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Search bar — keep it clear of the floating bottom nav until the
              // keyboard is actually up, then let it ride just above the keyboard.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  keyboardOpen ? 12 : 116, // 116 clears the floating nav
                ),
                child: KeyedSubtree(
                  key: _tipAgentInputKey,
                  child: _buildSearchBar(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnavailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature is unavailable for the moment.',
          style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
        ),
        backgroundColor: _dark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSearchBar() {
    if (_borderAnimationController == null) {
      return const SizedBox();
    }
    
    return AnimatedBuilder(
      animation: _borderAnimationController!,
      builder: (context, child) {
        final curvedValue = Curves.easeInOutCubic.transform(_borderAnimationController!.value);
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: SweepGradient(
              colors: const [
                Color(0xFFC4A464),
                Color(0xFFFFFFFF),
                Color(0xFF2A2A2A),
                Color(0xFFC4A464),
                Color(0xFFE8C88E),
                Color(0xFFC4A464),
              ],
              stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              transform: GradientRotation(curvedValue * 2 * 3.14159),
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_pickedImage != null) _buildImagePreview(),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _chooseImageSource,
                      child: const Icon(Iconsax.gallery,
                          color: Color(0xFF8B8B8B), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        onSubmitted: (_) => _sendMessage(),
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _dark,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Ask Amira agent',
                          hintStyle: TextStyle(
                            color: Color(0xFFB8B8B8),
                            fontSize: 15,
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Attached photo shown above the composer, ChatGPT-style: a rounded thumbnail
  // with a ✕ badge on its corner, an upload spinner while it uploads, and a
  // tap-to-retry overlay if the upload failed. No snackbars.
  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_pickedImage!.path),
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                ),
              ),
              if (_uploadingImage)
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                ),
              if (_uploadFailed)
                GestureDetector(
                  onTap: _uploadPicked,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.refresh, color: Colors.white, size: 26),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: _clearPickedImage,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _dark,
                      shape: BoxShape.circle,
                      border: Border.all(color: _white, width: 1.5),
                    ),
                    child: const Icon(Icons.close, size: 13, color: _white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isAdmin;
  final String? imageUrl;
  final List<Product> linkedProducts;

  const _MessageBubble({
    required this.text,
    required this.isUser,
    this.isAdmin = false,
    this.imageUrl,
    this.linkedProducts = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isAdmin ? _gold : _gold.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAdmin ? Iconsax.user : Iconsax.message_text5,
                color: isAdmin ? _white : _gold,
                size: 16,
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (isAdmin)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      'Amira Team',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _gold,
                        letterSpacing: 0.3,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                if (imageUrl != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: text.isNotEmpty ? 8 : 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        imageUrl!,
                        width: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 200,
                            height: 200,
                            color: _lightGrey,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: _gold, strokeWidth: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (text.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: isUser ? _dark : (isAdmin ? _lightGold : _white),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: isUser ? _white : _dark,
                        fontFamily: 'Plus Jakarta Sans',
                        height: 1.35,
                      ),
                    ),
                  ),
                if (!isUser && linkedProducts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final p in linkedProducts)
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ItemDetailsScreen(product: p),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _lightGold,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _dark,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// Animated three-dot "agent is typing" indicator, styled as an agent bubble.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.message_text5, color: _gold, size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    // Stagger each dot's phase for a left-to-right wave.
                    final t = (_controller.value - i * 0.18) % 1.0;
                    final wave = (sin(t * 2 * pi) + 1) / 2; // 0..1
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      child: Transform.translate(
                        offset: Offset(0, -3 * wave),
                        child: Opacity(
                          opacity: 0.35 + 0.65 * wave,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Streams an agent reply in character-by-character, like live typing, then
// settles into the same static bubble look once complete.
class _StreamingAgentBubble extends StatefulWidget {
  final String text;
  final List<Product> linkedProducts;
  final VoidCallback onTick;
  final VoidCallback onDone;

  const _StreamingAgentBubble({
    required this.text,
    required this.linkedProducts,
    required this.onTick,
    required this.onDone,
  });

  @override
  State<_StreamingAgentBubble> createState() => _StreamingAgentBubbleState();
}

class _StreamingAgentBubbleState extends State<_StreamingAgentBubble> {
  int _revealed = 0;
  bool _done = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_revealed >= widget.text.length) {
        t.cancel();
        setState(() => _done = true);
        widget.onDone();
        return;
      }
      // Reveal a couple of characters per tick for a natural typing pace.
      setState(() => _revealed = min(widget.text.length, _revealed + 2));
      widget.onTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.text.substring(0, _revealed);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.message_text5, color: _gold, size: 16),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    shown,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: _dark,
                      fontFamily: 'Plus Jakarta Sans',
                      height: 1.35,
                    ),
                  ),
                ),
                if (_done && widget.linkedProducts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final p in widget.linkedProducts)
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ItemDetailsScreen(product: p),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _lightGold,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _dark,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Suggestion Chip Widget
class _SuggestionChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _lightGrey, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _gold,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _dark,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: _grey,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}


// Blinking Cursor Widget
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Text(
        '|',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          color: _gold,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }
}
