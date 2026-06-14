import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _lightGrey = Color(0xFFE8E8E8);
const _gold = Color(0xFFB5945A);

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

  @override
  void initState() {
    super.initState();
    _initAnimationController();
  }

  void _initAnimationController() {
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({
        'text': _textController.text,
        'isUser': true,
      });
      _textController.clear();
      
      // Simulate AI response
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _messages.add({
            'text': 'I\'m here to help you explore Amira\'s luxury interior designs. What would you like to know?',
            'isUser': false,
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _borderAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
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
                            fontFamily: 'Satoshi',
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
                    itemBuilder: (_, i) => _MessageBubble(
                      text: _messages[i]['text'],
                      isUser: _messages[i]['isUser'],
                    ),
                  ),
                ),
              ] else ...[
                // Spacer to push search bar down, leaving room above bottom nav
                const Expanded(child: SizedBox()),
              ],

              // Search bar positioned just above bottom nav when no messages
              Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 30),
                child: _buildSearchBar(),
              ),
              
              // Fixed space for bottom nav area when no messages
              if (_messages.isEmpty)
                const SizedBox(height: 100),
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
                Color(0xFFB5945A),
                Color(0xFFFFFFFF),
                Color(0xFF2A2A2A),
                Color(0xFFB5945A),
                Color(0xFFE8C88E),
                Color(0xFFB5945A),
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
                      fontFamily: 'Satoshi',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _dark,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ask Amira agent',
                      hintStyle: TextStyle(
                        color: Color(0xFFB8B8B8),
                        fontSize: 15,
                        fontFamily: 'Satoshi',
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

  const _MessageBubble({
    required this.text,
    required this.isUser,
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  fontFamily: 'Satoshi',
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
