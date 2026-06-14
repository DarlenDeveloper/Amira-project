import 'package:flutter/material.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFB5945A);

const _specialitiesDir = 'assets/images/company specilialities';

class CartItem {
  final String image;
  final String name;
  final String unit;
  final double price;
  int qty;

  CartItem({
    required this.image,
    required this.name,
    required this.unit,
    required this.price,
    this.qty = 1,
  });
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<CartItem> _items = [
    CartItem(
      image: '$_specialitiesDir/pvc marble sheet.jpeg',
      name: 'PVC Marble Sheets',
      unit: 'per sqm',
      price: 56,
      qty: 2,
    ),
    CartItem(
      image: '$_specialitiesDir/bamboo wall panel.jpeg',
      name: 'Bamboo Wall Panel',
      unit: 'per sqm',
      price: 42,
      qty: 3,
    ),
    CartItem(
      image: '$_specialitiesDir/lights.jpeg',
      name: 'Lights',
      unit: 'per unit',
      price: 25,
      qty: 4,
    ),
  ];

  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.price * item.qty);

  static const double _delivery = 30;

  void _changeQty(int index, int delta) {
    setState(() {
      final newQty = _items[index].qty + delta;
      if (newQty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].qty = newQty;
      }
    });
  }

  void _remove(int index) {
    setState(() => _items.removeAt(index));
  }

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
                        child: const Icon(Icons.arrow_back, color: _dark, size: 20),
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
              child: _items.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _CartTile(
                        item: _items[i],
                        onIncrement: () => _changeQty(i, 1),
                        onDecrement: () => _changeQty(i, -1),
                        onRemove: () => _remove(i),
                      ),
                    ),
            ),

            if (_items.isNotEmpty) _buildSummary(),
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
            child: const Icon(Icons.shopping_bag_rounded, color: _gold, size: 38),
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

  Widget _buildSummary() {
    final total = _subtotal + _delivery;
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
          _summaryRow('Subtotal', _subtotal),
          const SizedBox(height: 10),
          _summaryRow('Delivery', _delivery),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEDEDE8)),
          ),
          _summaryRow('Total', total, isTotal: true),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {},
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
          '\$${value.toStringAsFixed(0)}',
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
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

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
            child: Image.asset(
              item.image,
              width: 78,
              height: 78,
              fit: BoxFit.cover,
              cacheWidth: 200,
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
                      onTap: onRemove,
                      child: const Icon(Icons.close, color: _grey, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${item.price.toStringAsFixed(0)} ${item.unit}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _grey,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${(item.price * item.qty).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _gold,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                    _QtyStepper(
                      qty: item.qty,
                      onIncrement: onIncrement,
                      onDecrement: onDecrement,
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
