import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight view of an Amira user, backed by the `users/{uid}` Firestore
/// document. Kept intentionally small — UI screens read from this, while
/// auth/identity lives in [FirebaseAuth].
class AppUser {
  final String uid;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? photoUrl;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.photoUrl,
    this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final created = data['createdAt'];
    return AppUser(
      uid: doc.id,
      name: data['name'] as String?,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  /// Map for writing to Firestore. Null values are dropped so a merge write
  /// never clobbers existing fields with nulls.
  Map<String, dynamic> toMap() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}
