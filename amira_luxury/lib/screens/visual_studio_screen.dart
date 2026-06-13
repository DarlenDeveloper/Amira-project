import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _lightGrey = Color(0xFFE8E8E8);
const _gold = Color(0xFFB5945A);
const _lightGold = Color(0xFFF5EFE3);

class VisualStudioScreen extends StatefulWidget {
  const VisualStudioScreen({super.key});

  @override
  State<VisualStudioScreen> createState() => _VisualStudioScreenState();
}

class _VisualStudioScreenState extends State<VisualStudioScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isUploading) ...[
                // Upload Drop Zone
                Container(
                  height: 380,
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: _lightGrey,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Gold circle with upload icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _lightGold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Iconsax.arrow_up_3,
                          color: _gold,
                          size: 48,
                        ),
                      ),
                      const Spacer(),
                      // Text
                      const Text(
                        'Drop your room image',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: _dark,
                          fontFamily: 'Satoshi',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'For best results, image uploads should be at least\n1080p (1920 x 1080 pixels) in JPG or PNG format.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _grey,
                          fontFamily: 'Satoshi',
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ] else ...[
                // Upload Progress
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _lightGold,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Iconsax.gallery5,
                              color: _gold,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Room interior.jpg',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _dark,
                                    fontFamily: 'Satoshi',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'JPG • 3.2 MB • 2 sec left',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: _grey,
                                    fontFamily: 'Satoshi',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isUploading = false),
                            child: Icon(Icons.close, color: _grey, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.7,
                          minHeight: 8,
                          backgroundColor: _lightGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(_gold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Description text area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _lightGrey, width: 1.5),
                ),
                child: TextField(
                  maxLines: 4,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: _dark,
                    fontFamily: 'Satoshi',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a description (optional)\nDescribe your design preferences...',
                    hintStyle: TextStyle(
                      color: _grey,
                      fontSize: 15,
                      fontFamily: 'Satoshi',
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isUploading = !_isUploading);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _lightGrey, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            _isUploading ? 'Cancel' : 'Browse Files',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _dark,
                              fontFamily: 'Satoshi',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isUploading) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: _gold,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Upload',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _white,
                                fontFamily: 'Satoshi',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
