import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_line.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'auth_service.dart';
import 'shop_service.dart';

/// Creates and reads the current user's orders (`orders` collection).
///
/// Orders are user-authored as [OrderStatus.pending]; the admin advances the
/// status. See `.kiro/steering/data-model.md`.
class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const double deliveryFee = 30;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  /// Live list of the signed-in user's orders, newest first.
  Stream<List<CustomerOrder>> watchMyOrders() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    // Equality-only query (no composite index needed); sort client-side.
    return _orders.where('uid', isEqualTo: uid).snapshots().map((snap) {
      final orders = snap.docs.map(CustomerOrder.fromDoc).toList();
      orders.sort((a, b) {
        final ad = a.createdAt ?? DateTime(0);
        final bd = b.createdAt ?? DateTime(0);
        return bd.compareTo(ad);
      });
      return orders;
    });
  }

  /// Places an order for every line in the cart (adds delivery), then clears it.
  Future<void> placeOrderFromCart(List<CartLine> lines) async {
    if (lines.isEmpty) return;
    final items = lines.map(OrderItem.fromCartLine).toList();
    final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);
    await _create(items, subtotal + deliveryFee);
    await ShopService.instance.clearCart();
  }

  /// Places an order for a single product at the chosen quantity.
  Future<void> placeOrderForProduct(Product product, int qty) async {
    final item = OrderItem.fromProduct(product, qty);
    await _create([item], item.lineTotal);
  }

  Future<void> _create(List<OrderItem> items, double total) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to place an order.',
      );
    }
    final profile = await AuthService.instance.fetchProfile(user.uid);
    final customer = (profile?.name?.trim().isNotEmpty ?? false)
        ? profile!.name!.trim()
        : (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!.trim()
            : 'Amira Member';
    final email = profile?.email ?? profile?.phone ?? user.email ?? '';

    await _orders.add({
      'orderId': _newOrderRef(),
      'uid': user.uid,
      'customer': customer,
      'email': email,
      'items': items.map((i) => i.toMap()).toList(),
      'itemCount': items.fold<int>(0, (s, i) => s + i.qty),
      'total': total,
      'status': OrderStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Human-friendly reference. The Firestore doc id remains the true key.
  String _newOrderRef() {
    final n = DateTime.now().millisecondsSinceEpoch % 100000;
    return 'AM-${n.toString().padLeft(5, '0')}';
  }
}
