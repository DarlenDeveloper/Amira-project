import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../models/product.dart';
import '../models/render_session.dart';
import '../services/product_service.dart';
import '../services/render_service.dart';
import '../services/shop_service.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFB5945A);

class RendersScreen extends StatelessWidget {
  const RendersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: _white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: _dark, size: 20),
                      ),
                    ),
                  ),
                  const Text(
                    'My Renders',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<RenderSession>>(
                stream: RenderService.instance.watchMyRenders(),
                builder: (context, snapshot) {
                  final renders = snapshot.data ?? const <RenderSession>[];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _gold, strokeWidth: 2),
                    );
                  }
                  if (renders.isEmpty) {
                    return const Center(
                      child: Text(
                        'No renders yet.\nTry Visual Studio to visualise a room.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: _grey,
                          fontFamily: 'Satoshi',
                          height: 1.5,
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: renders.length,
                    itemBuilder: (_, i) => _RenderTile(session: renders[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RenderTile extends StatelessWidget {
  final RenderSession session;

  const _RenderTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final imageUrl = session.resultUrl ?? session.roomImageUrl;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _RenderDetailScreen(session: session),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFE8E8E8),
                      child: const Icon(Iconsax.image, color: _grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.materialNames.isNotEmpty
                        ? session.materialNames.join(', ')
                        : 'Visual Studio',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _dark,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.status,
                    style: TextStyle(
                      fontSize: 11,
                      color: session.status == 'completed' ? _gold : _grey,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RenderDetailScreen extends StatefulWidget {
  final RenderSession session;
  const _RenderDetailScreen({required this.session});

  @override
  State<_RenderDetailScreen> createState() => _RenderDetailScreenState();
}

class _RenderDetailScreenState extends State<_RenderDetailScreen> {
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    ProductService.instance.watchProducts().first.then((all) {
      if (!mounted) return;
      setState(() {
        _products = all
            .where((p) => widget.session.productIds.contains(p.id))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _dark),
        title: const Text(
          'Render',
          style: TextStyle(
            color: _dark,
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (s.roomImageUrl != null) ...[
            const Text('Room', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(s.roomImageUrl!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
          ],
          if (s.resultUrl != null) ...[
            const Text('Result', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(s.resultUrl!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
          ],
          if (_products.isNotEmpty)
            FilledButton(
              onPressed: () async {
                for (final p in _products) {
                  await ShopService.instance.addToCart(p);
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added materials to cart')),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _dark,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Add materials to cart',
                  style: TextStyle(fontFamily: 'Satoshi')),
            ),
        ],
      ),
    );
  }
}
