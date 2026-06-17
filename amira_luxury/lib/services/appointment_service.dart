import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/appointment.dart';
import '../models/product.dart';
import 'auth_service.dart';

/// Creates and reads the current user's appointment requests
/// (`appointments` collection).
///
/// Created by the app as [AppointmentStatus.requested]; the admin schedules and
/// advances the status. See `.kiro/steering/data-model.md`.
class AppointmentService {
  AppointmentService._();
  static final AppointmentService instance = AppointmentService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('appointments');

  /// Live list of the signed-in user's appointments, newest first.
  Stream<List<Appointment>> watchMyAppointments() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _appointments.where('uid', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(Appointment.fromDoc).toList();
      list.sort((a, b) {
        final ad = a.createdAt ?? DateTime(0);
        final bd = b.createdAt ?? DateTime(0);
        return bd.compareTo(ad);
      });
      return list;
    });
  }

  /// Creates an appointment request. The admin fills in the schedule; the app
  /// only sends the intent and (optionally) which product prompted it.
  Future<void> requestAppointment({
    String type = 'Design Consultation',
    Product? aboutProduct,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to book an appointment.',
      );
    }
    final profile = await AuthService.instance.fetchProfile(user.uid);
    final customer = (profile?.name?.trim().isNotEmpty ?? false)
        ? profile!.name!.trim()
        : (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!.trim()
            : 'Amira Member';
    final email = profile?.email ?? profile?.phone ?? user.email ?? '';

    await _appointments.add({
      'appointmentId': _newRef(),
      'uid': user.uid,
      'customer': customer,
      'email': email,
      'type': type,
      'date': '',
      'time': '',
      'note': aboutProduct != null
          ? 'Enquiry about ${aboutProduct.name}'
          : 'Appointment request from the app',
      'status': AppointmentStatus.requested.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _newRef() {
    final n = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'AP-${n.toString().padLeft(4, '0')}';
  }
}
