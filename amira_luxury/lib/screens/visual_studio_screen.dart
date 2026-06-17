import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/render_service.dart';
import '../widgets/product_image.dart';

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
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descCtrl = TextEditingController();
  XFile? _picked;
  int _fileBytes = 0;
  bool _uploading = false;
  double _progress = 0;
  String? _uploadedUrl;
  bool _generating = false;
  String? _resultUrl;

  // Live catalogue from Firestore + the user's current selection.
  final List<Product> _catalog = [];
  StreamSubscription<List<Product>>? _catalogSub;
  final List<Product> _selected = [];

  @override
  void initState() {
    super.initState();
    _catalogSub = ProductService.instance.watchProducts().listen((products) {
      if (!mounted) return;
      setState(() {
        _catalog
          ..clear()
          ..addAll(products);
        // Drop any selected items that no longer exist in the catalogue.
        _selected.removeWhere((s) => !products.any((p) => p.id == s.id));
      });
    });
  }

  void _removeMaterial(int index) {
    setState(() => _selected.removeAt(index));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Satoshi')),
        backgroundColor: _dark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  Future<void> _pickFrom(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 88,
      );
      if (file == null) return;
      final length = await file.length();
      setState(() {
        _picked = file;
        _fileBytes = length;
        _uploadedUrl = null;
        _progress = 0;
      });
    } catch (_) {
      _snack('Couldn\'t open that image. Please try again.');
    }
  }

  void _chooseSource() {
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
            _sourceTile(ctx, Iconsax.camera5, 'Take a photo', ImageSource.camera),
            _sourceTile(ctx, Iconsax.gallery5, 'Choose from gallery',
                ImageSource.gallery),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sourceTile(
      BuildContext ctx, IconData icon, String label, ImageSource source) {
    return ListTile(
      leading: Icon(icon, color: _gold),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _dark,
          fontFamily: 'Satoshi',
        ),
      ),
      onTap: () {
        Navigator.of(ctx).pop();
        _pickFrom(source);
      },
    );
  }

  Future<void> _upload() async {
    final picked = _picked;
    if (picked == null || _uploading) return;
    setState(() {
      _uploading = true;
      _progress = 0;
    });
    try {
      final url = await RenderService.instance.uploadRoomImage(
        File(picked.path),
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _uploadedUrl = url;
        _uploading = false;
        _progress = 1;
      });
      _snack('Room photo uploaded');
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _snack('Upload failed. Please try again.');
    }
  }

  void _clearPhoto() {
    setState(() {
      _picked = null;
      _fileBytes = 0;
      _uploading = false;
      _progress = 0;
      _uploadedUrl = null;
      _resultUrl = null;
    });
  }

  Future<void> _generate() async {
    final roomUrl = _uploadedUrl;
    if (roomUrl == null || _generating) return;
    setState(() => _generating = true);
    try {
      final names = _selected.map((m) => m.name).toList(growable: false);
      final urls = _selected
          .where((m) => m.imageUrl != null && m.imageUrl!.isNotEmpty)
          .map((m) => m.imageUrl!)
          .toList(growable: false);
      final url = await RenderService.instance.generateRender(
        roomImageUrl: roomUrl,
        productImageUrls: urls,
        materialNames: names,
        prompt: _descCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _resultUrl = url;
        _generating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _generating = false);
      _snack('Couldn\'t generate the render. Please try again.');
    }
  }

  @override
  void dispose() {
    _catalogSub?.cancel();
    _descCtrl.dispose();
    super.dispose();
  }

  void _openMaterialPicker() {
    final available = _catalog
        .where((c) => !_selected.any((s) => s.id == c.id))
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
                          setState(() => _selected.add(m));
                          Navigator.of(ctx).pop();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 52,
                                height: 52,
                                child: ProductImage(
                                  imageUrl: m.imageUrl,
                                  cacheWidth: 150,
                                  placeholderIconSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                m.name,
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_picked == null) ...[
                // Upload Drop Zone (tap to choose camera / gallery)
                GestureDetector(
                  onTap: _chooseSource,
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
                // Selected room photo — preview + upload state
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_picked!.path),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _picked!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _dark,
                                    fontFamily: 'Satoshi',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _uploadedUrl != null
                                      ? '${_formatSize(_fileBytes)} • Uploaded'
                                      : _uploading
                                          ? '${_formatSize(_fileBytes)} • ${(_progress * 100).round()}%'
                                          : '${_formatSize(_fileBytes)} • Ready to upload',
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
                            onTap: _clearPhoto,
                            child: Icon(
                              _uploadedUrl != null
                                  ? Icons.check_circle_rounded
                                  : Icons.close,
                              color: _uploadedUrl != null ? _gold : _grey,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      if (_uploading || _uploadedUrl != null) ...[
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _uploadedUrl != null ? 1 : _progress,
                            minHeight: 8,
                            backgroundColor: _lightGrey,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_gold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // AI result / generating state
              if (_generating || _resultUrl != null) ...[
                const SizedBox(height: 20),
                if (_generating)
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _lightGrey, width: 1.5),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _gold, strokeWidth: 2),
                          SizedBox(height: 18),
                          Text(
                            'Visualising your room…',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _dark,
                              fontFamily: 'Satoshi',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This can take up to a minute.',
                            style: TextStyle(
                              fontSize: 13,
                              color: _grey,
                              fontFamily: 'Satoshi',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      _resultUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 300,
                          color: _white,
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: _gold, strokeWidth: 2),
                          ),
                        );
                      },
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
                  controller: _descCtrl,
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
                    for (int i = 0; i < _selected.length; i++)
                      _MaterialThumb(
                        product: _selected[i],
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

              // Action buttons (only once a photo is picked)
              if (_picked != null)
                Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _clearPhoto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: _lightGrey, width: 1.5),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: (_uploading || _generating)
                          ? null
                          : (_uploadedUrl == null ? _upload : _generate),
                      child: Opacity(
                        opacity: (_uploading || _generating) ? 0.7 : 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: _gold,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Center(
                            child: Text(
                              _uploading
                                  ? 'Uploading…'
                                  : _generating
                                      ? 'Visualising…'
                                      : _uploadedUrl == null
                                          ? 'Upload'
                                          : _resultUrl == null
                                              ? 'Visualise with AI'
                                              : 'Visualise again',
                              style: const TextStyle(
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _MaterialThumb extends StatelessWidget {
  final Product product;
  final VoidCallback onRemove;

  const _MaterialThumb({required this.product, required this.onRemove});

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
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: ProductImage(
                        imageUrl: product.imageUrl,
                        cacheWidth: 200,
                        placeholderIconSize: 18,
                      ),
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
                          product.name,
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
