import 'package:cloud_firestore/cloud_firestore.dart';

/// Appointment lifecycle — created by the app as [requested], scheduled and
/// advanced by the admin.
enum AppointmentStatus { requested, confirmed, completed, cancelled, unknown }

AppointmentStatus appointmentStatusFrom(String? s) {
  return AppointmentStatus.values.firstWhere(
    (e) => e.name == s,
    orElse: () => AppointmentStatus.unknown,
  );
}

/// An appointment request, backed by `appointments/{docId}`.
class Appointment {
  final String id; // Firestore doc id
  final String appointmentId; // human ref, e.g. AP-2042
  final String uid;
  final String customer;
  final String email;
  final String type;
  final String date;
  final String time;
  final String note;
  final AppointmentStatus status;
  final DateTime? createdAt;

  const Appointment({
    required this.id,
    required this.appointmentId,
    required this.uid,
    required this.customer,
    required this.email,
    required this.type,
    required this.date,
    required this.time,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  factory Appointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final created = data['createdAt'];
    return Appointment(
      id: doc.id,
      appointmentId: (data['appointmentId'] as String?) ?? doc.id,
      uid: (data['uid'] as String?) ?? '',
      customer: (data['customer'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      type: (data['type'] as String?) ?? '',
      date: (data['date'] as String?) ?? '',
      time: (data['time'] as String?) ?? '',
      note: (data['note'] as String?) ?? '',
      status: appointmentStatusFrom(data['status'] as String?),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
