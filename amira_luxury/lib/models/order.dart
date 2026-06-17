import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_line.dart';
import 'product.dart';

/// Order lifecycle — created by the app as [pending], advanced by the admin.
enum OrderStatus {
  pending,
  processing,
  paid,
  shipped,
  delivered,
  cancelled,
  unknown,
}

OrderStatus orderStatusFrom(String? s) {
  return OrderStatus.values.firstWhere(
    (e) => e.name == s,
    orElse: () => OrderStatus.unknown,
  );
}

/// A single line within an order (snapshot of the product at order time).
class OrderItem {
  final String productId;
  final String name;
  final String? imageUrl;
  final String unit;
  final double value;
  final int qty;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unit,
    required this.value,
    required this.qty,
  });

  double get lineTotal => value * qty;

  factory OrderItem.fromCartLine(CartLine l) => OrderItem(
        productId: l.productId,
        name: l.name,
        imageUrl: l.imageUrl,
        unit: l.unit,
        value: l.value,
        qty: l.qty,
      );

  factory OrderItem.fromProduct(Product p, int qty) => OrderItem(
        productId: p.id,
        name: p.name,
        imageUrl: p.imageUrl,
        unit: p.unit,
        value: p.value,
        qty: qty,
      );

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: (m['productId'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        imageUrl: m['imageUrl'] as String?,
        unit: (m['unit'] as String?) ?? 'unit',
        value: (m['value'] as num?)?.toDouble() ?? 0,
        qty: (m['qty'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'unit': unit,
        'value': value,
        'qty': qty,
      };
}

/// An order placed from the app, backed by `orders/{docId}`.
class CustomerOrder {
  final String id; // Firestore doc id
  final String orderId; // human ref, e.g. AM-10248
  final String uid;
  final String customer;
  final String email;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final DateTime? createdAt;

  const CustomerOrder({
    required this.id,
    required this.orderId,
    required this.uid,
    required this.customer,
    required this.email,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.qty);

  factory CustomerOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final rawItems = (data['items'] as List?) ?? const [];
    final created = data['createdAt'];
    return CustomerOrder(
      id: doc.id,
      orderId: (data['orderId'] as String?) ?? doc.id,
      uid: (data['uid'] as String?) ?? '',
      customer: (data['customer'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromMap)
          .toList(),
      total: (data['total'] as num?)?.toDouble() ?? 0,
      status: orderStatusFrom(data['status'] as String?),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
