import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_shell_controller.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/render_service.dart';
import '../services/shop_service.dart';
import '../widgets/product_image.dart';
import '../widgets/coachmark.dart';
import 'item_details_screen.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _lightGrey = Color(0xFFE8E8E8);
const _gold = Color(0xFFC4A464);
const _lightGold = Color(0xFFF5EFE3);

// Maximum number of materials/products that can be tagged onto a single render.
const _maxMaterials = 3;

class VisualStudioScreen extends StatefulWidget {
  const VisualStudioScreen({super.key});

  @override
  State<VisualStudioScreen> createState() => _VisualStudioScreenState();
}

class _VisualStudioScreenState extends State<VisualStudioScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _picked;
  int _fileBytes = 0;
  bool _uploading = false;
  double _progress = 0;
  String? _uploadedUrl;
  bool _generating = false;
  String? _resultUrl;
  bool _saving = false;
  String _mode = 'enhance'; // 'standard' | 'enhance'
  bool _descExpanded = false;
  final TextEditingController _descCtrl = TextEditingController();

  // Live catalogue from Firestore + the user's current selection.
  final List<Product> _catalog = [];
  StreamSubscription<List<Product>>? _catalogSub;
  final List<Product> _selected = [];

  String? _renderId;
  String _source = 'tab';
  int _appliedIntentToken = 0;
  bool _disposed = false;
  AppShellController? _shell;

  // Coachmark anchors + trigger state.
  final GlobalKey _tipUploadKey = GlobalKey();
  final GlobalKey _tipDescKey = GlobalKey();
  final GlobalKey _tipMaterialsKey = GlobalKey();
  bool _coachTriggered = false;

  @override
  void initState() {
    super.initState();
    _catalogSub = ProductService.instance.watchProducts().listen((products) {
      if (!mounted || _disposed) return;
      setState(() {
        _catalog
          ..clear()
          ..addAll(products);
        _selected.removeWhere((s) => !products.any((p) => p.id == s.id));
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shell = AppShellController.maybeOf(context);
    if (shell != null && shell != _shell) {
      _shell?.removeListener(_onShellChange);
      _shell = shell;
      _shell!.addListener(_onShellChange);
      _applyShellIntent();
      if (shell.currentIndex == 2) _maybeShowCoachmarks();
    }
  }

  void _onShellChange() {
    if (_shell?.currentIndex == 2) {
      _applyShellIntent();
      _maybeShowCoachmarks();
    }
  }

  // Shows the Visual Studio tooltips once, the first time the tab is opened.
  Future<void> _maybeShowCoachmarks() async {
    if (_coachTriggered) return;
    _coachTriggered = true;
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return;
    }
    if (prefs.getBool('coach_studio_v1') ?? false) return;
    if (!mounted || _disposed) return;
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _disposed) return;
    Coachmarks.show(
      context,
      [
        CoachStep(
          targetKey: _tipUploadKey,
          title: 'Start with your room',
          body: 'Upload or take a photo of the space you want to redesign.',
          radius: 30,
        ),
        CoachStep(
          targetKey: _tipDescKey,
          title: 'Choose your mode',
          body: 'Standard installs materials as-is. Enhance adds professional lighting and integration.',
          radius: 28,
        ),
        CoachStep(
          targetKey: _tipMaterialsKey,
          title: 'Choose materials',
          body:
              'Add the Amira finishes to place in your room, then generate your render.',
          radius: 20,
        ),
      ],
      onFinish: () => prefs.setBool('coach_studio_v1', true),
    );
  }

  void _applyShellIntent() {
    final shell = _shell;
    if (shell == null) return;
    final intent = shell.consumeVisualStudioIntent();
    if (intent == null || intent.token == _appliedIntentToken) return;
    if (!mounted || _disposed) return;
    setState(() {
      _appliedIntentToken = intent.token;
      _source = intent.source;
      // Add the incoming product to the selection (up to the max), without
      // dropping anything the user already picked.
      for (final p in intent.products) {
        if (_selected.length >= _maxMaterials) break;
        if (!_selected.any((s) => s.id == p.id)) _selected.add(p);
      }
    });
  }

  void _removeMaterial(int index) {
    setState(() => _selected.removeAt(index));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
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
      // Auto-upload as soon as a photo is chosen — no manual Upload step.
      _upload();
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
          fontFamily: 'Plus Jakarta Sans',
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
    // The room photo is uploaded exactly once per picked image. Bail if there's
    // nothing to upload, an upload is already running, or this photo is already
    // uploaded — tagging materials or re-generating must never re-upload.
    if (picked == null || _uploading || _uploadedUrl != null) return;

    final token = _shell?.sessionToken ?? 0;
    bool stale() =>
        !mounted || _disposed || (_shell?.sessionToken ?? 0) != token;

    setState(() {
      _uploading = true;
      _progress = 0;
    });
    try {
      // A fresh session per upload attempt keeps us safe against the
      // create-only Storage rule: each attempt writes room.jpg to its own
      // session folder, so a retry never collides with an existing object.
      // Material selection + prompt are decoupled and re-sent at generate time.
      final renderId = await RenderService.instance.startSession(
        source: _source,
        mode: _mode,
      );
      if (stale()) return;

      final url = await RenderService.instance.uploadRoomImage(
        renderId,
        File(picked.path),
        onProgress: (p) {
          if (mounted && !_disposed) setState(() => _progress = p);
        },
      );
      if (stale()) return;

      await RenderService.instance.registerRoomUpload(renderId, url);
      if (stale()) return;

      setState(() {
        _renderId = renderId;
        _uploadedUrl = url;
        _progress = 1;
      });
      _snack('Room photo uploaded');
    } catch (_) {
      if (mounted && !_disposed) _snack('Upload failed. Please try again.');
    } finally {
      // Always clear the in-flight flag so the UI can't get stuck on
      // "Uploading…" or be tricked into firing a second upload.
      if (mounted && !_disposed) setState(() => _uploading = false);
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
      _renderId = null;
    });
  }

  Future<void> _generate({bool forceRetry = false}) async {
    final renderId = _renderId;
    if (renderId == null || _generating) return;
    if (_selected.isEmpty) {
      _snack('Add at least one material to visualise.');
      return;
    }
    final token = _shell?.sessionToken ?? 0;
    setState(() => _generating = true);
    try {
      final url = await RenderService.instance.generateRender(
        renderId: renderId,
        forceRetry: forceRetry,
        productIds: _selected.map((p) => p.id).toList(),
        materialNames: _selected.map((p) => p.name).toList(),
        prompt: _descCtrl.text.trim(),
        mode: _mode,
      );
      if (!mounted || _disposed || (_shell?.sessionToken ?? 0) != token) return;
      setState(() {
        _resultUrl = url;
        _generating = false;
      });
    } catch (_) {
      if (!mounted || _disposed) return;
      setState(() => _generating = false);
      _snack('Couldn\'t generate the render. Please try again.');
    }
  }

  Future<void> _saveResult() async {
    final url = _resultUrl;
    if (url == null || _saving) return;
    setState(() => _saving = true);
    try {
      final hasAccess = await Gal.requestAccess(toAlbum: true);
      if (!hasAccess) {
        if (!mounted || _disposed) return;
        setState(() => _saving = false);
        _snack('Allow photo access to save the render.');
        return;
      }
      final bytes = await RenderService.instance.fetchRenderBytes(url);
      await Gal.putImageBytes(
        bytes,
        album: 'Amira',
        name: 'amira_render_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted || _disposed) return;
      setState(() => _saving = false);
      _snack('Saved to your gallery');
    } catch (_) {
      if (!mounted || _disposed) return;
      setState(() => _saving = false);
      _snack('Couldn\'t save the render. Please try again.');
    }
  }

  /// Opens the render in a full-screen, pinch-to-zoom viewer.
  void _openFullScreen(String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => _FullScreenImageViewer(imageUrl: url),
      ),
    );
  }

  Future<void> _addSelectedToCart() async {
    if (_selected.isEmpty) return;
    for (final p in _selected) {
      await ShopService.instance.addToCart(p);
    }
    if (!mounted) return;
    _snack('Added ${_selected.length} material(s) to cart');
  }

  @override
  void dispose() {
    _disposed = true;
    _shell?.removeListener(_onShellChange);
    _catalogSub?.cancel();
    _descCtrl.dispose();
    super.dispose();
  }

  /// Groups the catalogue by category for the collapsible picker.
  Map<String, List<Product>> get _groupedCatalog {
    final map = <String, List<Product>>{};
    for (final p in _catalog) {
      final cat = p.category.isNotEmpty ? p.category : 'Other';
      map.putIfAbsent(cat, () => []).add(p);
    }
    return map;
  }

  void _openMaterialPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final grouped = _groupedCatalog;
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20, 20, 20, 20 + MediaQuery.of(ctx).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Choose a material',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Browse by category and pick what to place in your room.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _grey,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      children: [
                        for (final entry in grouped.entries)
                          _CategorySection(
                            category: entry.key,
                            products: entry.value,
                            selected: _selected,
                            maxMaterials: _maxMaterials,
                            onSelect: (product) {
                              if (_selected.length >= _maxMaterials) {
                                _snack('You can add up to $_maxMaterials materials per render.');
                                return;
                              }
                              setState(() => _selected.add(product));
                              Navigator.of(ctx).pop();
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
                  key: _tipUploadKey,
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
                          fontFamily: 'Plus Jakarta Sans',
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
                          fontFamily: 'Plus Jakarta Sans',
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
                                    fontFamily: 'Plus Jakarta Sans',
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
                                    fontFamily: 'Plus Jakarta Sans',
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
                  const _ShimmerLoading(height: 320)
                else
                  GestureDetector(
                    onTap: () => _openFullScreen(_resultUrl!),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Hero(
                            tag: 'render-result',
                            child: CachedNetworkImage(
                              imageUrl: _resultUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const _ShimmerLoading(height: 300),
                              errorWidget: (context, url, error) => Container(
                                height: 300,
                                color: const Color(0xFFEDEDE8),
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      size: 40, color: Color(0xFFB8B8B2)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Subtle "tap to expand" affordance.
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.fullscreen_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_resultUrl != null && !_generating) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _saving ? null : _saveResult,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: _lightGrey, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: _saving
                                ? const CircularProgressIndicator(
                                    color: _gold, strokeWidth: 2)
                                : const Icon(Icons.download_rounded,
                                    size: 18, color: _gold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _saving ? 'Saving…' : 'Save to device',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _dark,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],

              // Result actions
              if (_resultUrl != null && _selected.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _addSelectedToCart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _dark,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Center(
                            child: Text(
                              'Add to cart',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _white,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => AppShellController.of(context).openExplore(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: _lightGrey),
                          ),
                          child: const Center(
                            child: Text(
                              'View in Explore',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _dark,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in _selected)
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemDetailsScreen(product: p),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _lightGold,
                            borderRadius: BorderRadius.circular(20),
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

              const SizedBox(height: 24),

              // Mode selector (Standard / Enhance)
              Container(
                key: _tipDescKey,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: _lightGrey, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = 'standard'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _mode == 'standard' ? _gold : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Center(
                            child: Text(
                              'Standard',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _mode == 'standard' ? _white : _grey,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = 'enhance'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _mode == 'enhance' ? _gold : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Center(
                            child: Text(
                              'Enhance',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _mode == 'enhance' ? _white : _grey,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _mode == 'standard'
                      ? 'Install materials exactly as they are — no creative changes.'
                      : 'Enhance lighting and integration for a professional finish.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _grey,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Collapsible description (optional)
              GestureDetector(
                onTap: () => setState(() => _descExpanded = !_descExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _lightGrey, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes_rounded, size: 18, color: _grey),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Add description (optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _grey,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _descExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 22, color: _grey),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _lightGrey, width: 1.5),
                    ),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: _dark,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Describe your design preferences...',
                        hintStyle: TextStyle(
                          color: _grey,
                          fontSize: 14,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                crossFadeState: _descExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),

              const SizedBox(height: 24),

              // Material to visualise
              const Text(
                'Material to visualise',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add the material you want the AI to place in your room.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _grey,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                key: _tipMaterialsKey,
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (int i = 0; i < _selected.length; i++)
                      _MaterialThumb(
                        product: _selected[i],
                        onRemove: () => _removeMaterial(i),
                      ),
                    // Add tile — hidden once the per-render cap is reached.
                    if (_selected.length < _maxMaterials)
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
                              fontFamily: 'Plus Jakarta Sans',
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
                          : (_uploadedUrl == null
                              ? _upload
                              : () => _generate(forceRetry: _resultUrl != null)),
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
                                fontFamily: 'Plus Jakarta Sans',
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
                            fontFamily: 'Plus Jakarta Sans',
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

/// ChatGPT-style generating placeholder: a warm shimmer sweep with a caption,
/// shown while the AI render is being produced (and while it loads in).
class _ShimmerLoading extends StatefulWidget {
  final double height;
  const _ShimmerLoading({this.height = 300});

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [
                        Color(0xFFEDE4D2),
                        Color(0xFFFBF7EF),
                        Color(0xFFEDE4D2),
                      ],
                      stops: const [0.1, 0.3, 0.4],
                      transform:
                          _SlidingGradientTransform(_controller.value * 2 - 1),
                    ),
                  ),
                );
              },
            ),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Visualising your room…',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen render viewer: tap the result to expand it here. Supports
/// pinch-to-zoom / pan (InteractiveViewer), tap-outside or the close button to
/// dismiss, and shares a Hero transition with the inline thumbnail.
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Tap anywhere on the backdrop to dismiss.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Center(
            child: Hero(
              tag: 'render-result',
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: _gold, strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image_rounded,
                        size: 48, color: Color(0xFFB8B8B2)),
                  ),
                ),
              ),
            ),
          ),
          // Close button.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 24, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// Collapsible category section for the material picker bottom sheet.
class _CategorySection extends StatefulWidget {
  final String category;
  final List<Product> products;
  final List<Product> selected;
  final int maxMaterials;
  final void Function(Product) onSelect;

  const _CategorySection({
    required this.category,
    required this.products,
    required this.selected,
    required this.maxMaterials,
    required this.onSelect,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final available = widget.products
        .where((p) => !widget.selected.any((s) => s.id == p.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.category,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
                Text(
                  '${available.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _grey,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: _grey),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              if (available.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'All added',
                    style: TextStyle(
                      fontSize: 13,
                      color: _grey,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                )
              else
                ...available.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => widget.onSelect(m),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: ProductImage(
                                  imageUrl: m.imageUrl,
                                  cacheWidth: 150,
                                  placeholderIconSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                m.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _dark,
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ),
                            const Icon(Icons.add_circle_outline_rounded,
                                color: _gold, size: 20),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        const Divider(height: 1, color: _lightGrey),
      ],
    );
  }
}
