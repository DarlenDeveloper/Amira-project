import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/shimmer.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFB5945A);
const _olive = Color(0xFF556B4A);
const _red = Color(0xFFB23A3A);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime? d) {
  if (d == null) return '';
  return '${_months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
}

({Color bg, Color fg, String label}) _orderStatusStyle(OrderStatus s) {
  switch (s) {
    case OrderStatus.pending:
      return (bg: const Color(0xFFF0F0EA), fg: _grey, label: 'Pending');
    case OrderStatus.processing:
      return (bg: const Color(0xFFF5EFE3), fg: _gold, label: 'Processing');
    case OrderStatus.paid:
      return (bg: const Color(0xFFEAEFE6), fg: _olive, label: 'Paid');
    case OrderStatus.shipped:
      return (bg: const Color(0xFFEDEDE8), fg: _dark, label: 'Shipped');
    case OrderStatus.delivered:
      return (bg: const Color(0xFFEAEFE6), fg: _olive, label: 'Delivered');
    case OrderStatus.cancelled:
      return (bg: const Color(0xFFF6E9E9), fg: _red, label: 'Cancelled');
    case OrderStatus.unknown:
      return (bg: const Color(0xFFF0F0EA), fg: _grey, label: 'Order');
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: StreamBuilder<List<CustomerOrder>>(
                stream: OrderService.instance.watchMyOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _SkeletonList();
                  }
                  final orders = snapshot.data ?? const <CustomerOrder>[];
                  if (orders.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.shopping_bag_rounded,
                      title: 'No orders yet',
                      body: 'Your orders will appear here once you place one.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _OrderCard(order: orders[i]),
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
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
                decoration:
                    const BoxDecoration(color: _white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: _dark, size: 20),
              ),
            ),
          ),
          const Text(
            'Orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _dark,
              fontFamily: 'Satoshi',
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final CustomerOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final style = _orderStatusStyle(order.status);
    final itemLabel = order.itemCount == 1 ? '1 item' : '${order.itemCount} items';
    final date = _formatDate(order.createdAt);
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderId,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                  fontFamily: 'Satoshi',
                ),
              ),
              _StatusPill(bg: style.bg, fg: style.fg, label: style.label),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [if (date.isNotEmpty) date, itemLabel].join('  ·  '),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _grey,
              fontFamily: 'Satoshi',
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEDEDE8)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _grey,
                  fontFamily: 'Satoshi',
                ),
              ),
              Text(
                '\$${order.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _gold,
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Color bg;
  final Color fg;
  final String label;
  const _StatusPill({required this.bg, required this.fg, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
          fontFamily: 'Satoshi',
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Icon(icon, color: _gold, size: 38),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _dark,
              fontFamily: 'Satoshi',
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _grey,
                fontFamily: 'Satoshi',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 116,
          decoration: BoxDecoration(
            color: const Color(0xFFE6E6E0),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
