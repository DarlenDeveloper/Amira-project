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

  static const String _dir = 'assets/images/company specilialities';

  // Full catalog the user can pick from.
  static const List<Map<String, String>> _catalog = [
    {'image': '$_dir/pvc marble sheet.jpeg', 'name': 'PVC Marble Sheets'},
    {'image': '$_dir/bamboo wall panel.jpeg', 'name': 'Bamboo Wall Panel'},
    {'image': '$_dir/wpc wall panel.jpeg', 'name': 'WPC Wall Panel'},
    {'image': '$_dir/pvc wall panel.jpeg', 'name': 'PVC Wall Panel'},
    {'image': '$_dir/soft stone.jpeg', 'name': 'Soft Stone'},
    {'image': '$_dir/pu stone.jpeg', 'name': 'PU Stone'},
    {'image': '$_dir/lights.jpeg', 'name': 'Lights'},
    {'image': '$_dir/Artificial Grass.jpeg', 'name': 'Artificial Grass & Carpets'},
    {'image': '$_dir/steel profile.jpeg', 'name': 'Steel Profile'},
    {'image': '$_dir/blinds.jpeg', 'name': 'Blinds'},
    {'image': '$_dir/block boards.jpeg', 'name': 'Block Boards'},
  ];

  // Materials the user wants the AI to generate into their room.
  final List<Map<String, String>> _selectedMaterials = [
    {'image': '$_dir/bamboo wall panel.jpeg', 'name': 'Bamboo Wall Panel'},
    {'image': '$_dir/lights.jpeg', 'name': 'Lights'},
  ];

  void _removeMaterial(int index) {
    setState(() => _selectedMaterials.removeAt(index));
  }

  void _openMaterialPicker() {
    final available = _catalog
        .where((c) => !_selectedMaterials.any((s) => s['name'] == c['name']))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add materials',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                  fontFamily: 'Satoshi',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pick what the AI should place in your room.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _grey,
                  fontFamily: 'Satoshi',
                ),
              ),
              const SizedBox(height: 16),
              if (available.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'All materials added.',
                      style: TextStyle(
                        fontSize: 14,
                        color: _grey,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: available.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final m = available[i];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedMaterials.add(m));
                          Navigator.of(ctx).pop();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                m['image']!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                cacheWidth: 150,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                m['name']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _dark,
                                  fontFamily: 'Satoshi',
                                ),
                              ),
                            ),
                            const Icon(Icons.add, color: _gold, size: 22),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

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
                // Upload Drop Zone (tap to start)
                GestureDetector(
                  onTap: () => setState(() => _isUploading = true),
                  child: Container(
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

              // Description text area (pill-shaped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(30),
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

              // Materials to visualise
              const Text(
                'Materials to visualise',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                  fontFamily: 'Satoshi',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add the materials you want the AI to place in your room.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _grey,
                  fontFamily: 'Satoshi',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (int i = 0; i < _selectedMaterials.length; i++)
                      _MaterialThumb(
                        data: _selectedMaterials[i],
                        onRemove: () => _removeMaterial(i),
                      ),
                    // Add tile
                    GestureDetector(
                      onTap: _openMaterialPicker,
                      child: Container(
                        width: 88,
                        height: 88,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _lightGrey, width: 1.5),
                        ),
                        child: const Icon(Icons.add, color: _gold, size: 30),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons (only while uploading)
              if (_isUploading)
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
                          borderRadius: BorderRadius.circular(32),
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
                            borderRadius: BorderRadius.circular(32),
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

class _MaterialThumb extends StatelessWidget {
  final Map<String, String> data;
  final VoidCallback onRemove;

  const _MaterialThumb({required this.data, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 96,
        child: Stack(
          children: [
            // Thumbnail with name label
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    Image.asset(
                      data['image']!,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      cacheWidth: 200,
                    ),
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          data['name']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Satoshi',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Remove button
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 15, color: _dark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
