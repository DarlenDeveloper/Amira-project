import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:iconsax/iconsax.dart';
import '../app_shell_controller.dart';
import '../models/product.dart';
import '../services/agent_service.dart';
import '../services/product_service.dart';
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
  final List<Map<String, dynamic>> _messages = [];
  AnimationController? _borderAnimationController;

  // Live conversation state.
  String? _conversationId;
  bool _sending = false;
  bool _agentEnabled = true;
  List<String> _suggestions = [];
  List<Product> _catalog = [];
  String? _pendingProductId;
  int _appliedIntentToken = 0;
  AppShellController? _shell;
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
    }
  }

  void _onShellChange() {
    if (_shell?.currentIndex == 3) _applyShellIntent();
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
    if (text.isEmpty || _sending) return;

    final productId = _pendingProductId;
    final msgSource = suggestionLabel != null ? 'suggestion' : source;

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      if (overrideText == null) _textController.clear();
      _sending = true;
    });

    try {
      final res = await AgentService.instance.sendMessage(
        message: text,
        conversationId: _conversationId,
        productId: productId,
        source: msgSource,
        suggestionLabel: suggestionLabel,
      );
      if (!mounted) return;
      setState(() {
        _conversationId = res.conversationId ?? _conversationId;
        _messages.add({'text': res.reply, 'isUser': false});
        _sending = false;
        _pendingProductId = null;
      });
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
    _textController.dispose();
    _focusNode.dispose();
    _borderAnimationController?.dispose();
    super.dispose();
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

                // Chat messages
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      return _MessageBubble(
                        text: msg['text'] as String,
                        isUser: msg['isUser'] as bool,
                        linkedProducts: msg['isUser'] as bool
                            ? const []
                            : _linkedProducts(msg['text'] as String),
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
                            ..._suggestions.take(6).map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
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
                child: _buildSearchBar(),
              ),
            ],
          ),
        ),
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
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Iconsax.gallery, color: Color(0xFF8B8B8B), size: 24),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Iconsax.microphone, color: Color(0xFF8B8B8B), size: 24),
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
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final List<Product> linkedProducts;

  const _MessageBubble({
    required this.text,
    required this.isUser,
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
                color: _gold.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.message_text5,
                color: _gold,
                size: 16,
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? _dark : _white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: isUser ? _white : _dark,
                      fontFamily: 'Plus Jakarta Sans',
                      height: 1.4,
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
