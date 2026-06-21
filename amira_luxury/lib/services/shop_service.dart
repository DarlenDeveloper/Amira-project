import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_line.dart';
import '../models/product.dart';
import '../utils/product_colors.dart';

/// Per-user shopping state: the cart and favourites.
///
/// Both live under `users/{uid}/…` and are owner-only (existing rules already
/// cover the user subtree). Screens use [ShopService.instance].
class ShopService {
  ShopService._();
  static final ShopService instance = ShopService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  // ── Favourites ───────────────────────────────────────────────────────────
  // users/{uid}/favourites/{productId} → { addedAt }

  CollectionReference<Map<String, dynamic>>? get _favourites =>
      _userDoc?.collection('favourites');

  /// Live set of favourited product ids. Emits an empty set when signed out.
  Stream<Set<String>> watchFavouriteIds() {
    final col = _favourites;
    if (col == null) return Stream.value(const <String>{});
    return col.snapshots().map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Future<void> setFavourite(String productId, bool isFavourite) async {
    final col = _favourites;
    if (col == null) return;
    if (isFavourite) {
      await col.doc(productId).set({'addedAt': FieldValue.serverTimestamp()});
    } else {
      await col.doc(productId).delete();
    }
  }

  // ── Cart ─────────────────────────────────────────────────────────────────
  // users/{uid}/cart/{productId} → { name, imageKey, unit, value, qty }

  CollectionReference<Map<String, dynamic>>? get _cart =>
      _userDoc?.collection('cart');

  /// Live cart lines. Emits empty when signed out.
  Stream<List<CartLine>> watchCart() {
    final col = _cart;
    if (col == null) return Stream.value(const <CartLine>[]);
    return col.snapshots().map(
          (snap) => snap.docs.map(CartLine.fromDoc).toList(),
        );
  }

  /// Adds [qty] of [product] to the cart, merging with any existing line.
  Future<void> addToCart(Product product, {int qty = 1, ProductColor? color}) async {
    final col = _cart;
    if (col == null) return;
    final ref = col.doc(cartLineId(product.id, color));
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final existingQty =
          snap.exists ? ((snap.data()?['qty'] as num?)?.toInt() ?? 0) : 0;
      final line = CartLine.fromProduct(product, qty: existingQty + qty, color: color);
      tx.set(ref, line.toMap(), SetOptions(merge: true));
    });
  }

  /// Sets an absolute quantity; removes the line when [qty] <= 0.
  Future<void> setQty(String productId, int qty) async {
    final col = _cart;
    if (col == null) return;
    if (qty <= 0) {
      await col.doc(productId).delete();
      return;
    }
    await col.doc(productId).set(
      {'qty': qty, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> removeFromCart(String productId) async {
    await _cart?.doc(productId).delete();
  }

  Future<void> clearCart() async {
    final col = _cart;
    if (col == null) return;
    final snap = await col.get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
