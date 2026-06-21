import 'package:flutter/material.dart';
import '../models/cart_line.dart';
import '../services/order_service.dart';
import '../services/shop_service.dart';
import '../utils/currency.dart';
import '../widgets/product_image.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFB5945A);

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const double _delivery = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
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
                        child: const Icon(Icons.arrow_back,
                            color: _dark, size: 20),
                      ),
                    ),
                  ),
                  const Text(
                    'Cart',
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
              child: StreamBuilder<List<CartLine>>(
                stream: ShopService.instance.watchCart(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: _gold, strokeWidth: 2),
                    );
                  }
                  final items = snapshot.data ?? const <CartLine>[];
                  if (items.isEmpty) return _buildEmptyState();

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (_, i) => _CartTile(item: items[i]),
                        ),
                      ),
                      _buildSummary(context, items),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFFF5EFE3),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.shopping_bag_rounded, color: _gold, size: 38),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _dark,
              fontFamily: 'Satoshi',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Browse Explore to add premium materials.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _grey,
              fontFamily: 'Satoshi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, List<CartLine> items) {
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    final total = subtotal + _delivery;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, 20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _summaryRow('Subtotal', subtotal),
          const SizedBox(height: 10),
          _summaryRow('Delivery', _delivery),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEDEDE8)),
          ),
          _summaryRow('Total', total, isTotal: true),
          const SizedBox(height: 18),
          GestureDetector(
            // Checkout → create an order from the cart, then clear it.
            onTap: () async {
              try {
                await OrderService.instance.placeOrderFromCart(items);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order placed',
                        style: TextStyle(fontFamily: 'Satoshi')),
                    backgroundColor: _dark,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(milliseconds: 1400),
                  ),
                );
                Navigator.of(context).maybePop();
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Couldn\'t place the order. Please try again.',
                        style: TextStyle(fontFamily: 'Satoshi')),
                    backgroundColor: _dark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Center(
                child: Text(
                  'Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _white,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 17 : 15,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            color: isTotal ? _dark : _grey,
            fontFamily: 'Satoshi',
          ),
        ),
        Text(
          formatUgx(value),
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: FontWeight.w700,
            color: isTotal ? _gold : _dark,
            fontFamily: 'Satoshi',
          ),
        ),
      ],
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartLine item;

  const _CartTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 78,
              height: 78,
              child: ProductImage(
                imageUrl: item.imageUrl,
                cacheWidth: 200,
                placeholderIconSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                          fontFamily: 'Satoshi',
                          height: 1.2,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          ShopService.instance.removeFromCart(item.productId),
                      child: const Icon(Icons.close, color: _grey, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatUgx(item.value)} per ${item.unit}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _grey,
                    fontFamily: 'Satoshi',
                  ),
                ),
                if (item.colorName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _cartColor(item.colorHex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withOpacity(0.12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.colorName!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _grey,
                          fontFamily: 'Satoshi',
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatUgx(item.lineTotal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _gold,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                    _QtyStepper(
                      qty: item.qty,
                      onIncrement: () => ShopService.instance
                          .setQty(item.productId, item.qty + 1),
                      onDecrement: () => ShopService.instance
                          .setQty(item.productId, item.qty - 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QtyStepper({
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(Icons.remove, onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$qty',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _dark,
                fontFamily: 'Satoshi',
              ),
            ),
          ),
          _stepBtn(Icons.add, onIncrement),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: _white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: _dark),
      ),
    );
  }
}

Color _cartColor(String? hex) {
  var h = (hex ?? '').trim();
  if (!h.startsWith('#')) h = '#$h';
  if (h.length == 7) {
    final v = int.tryParse(h.substring(1), radix: 16);
    if (v != null) return Color(0xFF000000 | v);
  }
  return const Color(0xFF888888);
}
