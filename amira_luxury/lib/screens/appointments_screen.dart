import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../widgets/shimmer.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFB5945A);
const _olive = Color(0xFF556B4A);
const _red = Color(0xFFB23A3A);

({Color bg, Color fg, String label}) _statusStyle(AppointmentStatus s) {
  switch (s) {
    case AppointmentStatus.requested:
      return (bg: const Color(0xFFF0F0EA), fg: _grey, label: 'Requested');
    case AppointmentStatus.confirmed:
      return (bg: const Color(0xFFF5EFE3), fg: _gold, label: 'Confirmed');
    case AppointmentStatus.completed:
      return (bg: const Color(0xFFEAEFE6), fg: _olive, label: 'Completed');
    case AppointmentStatus.cancelled:
      return (bg: const Color(0xFFF6E9E9), fg: _red, label: 'Cancelled');
    case AppointmentStatus.unknown:
      return (bg: const Color(0xFFF0F0EA), fg: _grey, label: 'Appointment');
  }
}

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: StreamBuilder<List<Appointment>>(
                stream: AppointmentService.instance.watchMyAppointments(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _SkeletonList();
                  }
                  final items = snapshot.data ?? const <Appointment>[];
                  if (items.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.calendar_month_rounded,
                      title: 'No appointments yet',
                      body:
                          'Book a consultation from any product to see it here.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _AppointmentCard(item: items[i]),
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
            'Appointments',
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

class _AppointmentCard extends StatelessWidget {
  final Appointment item;
  const _AppointmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(item.status);
    final hasSchedule = item.date.isNotEmpty || item.time.isNotEmpty;
    final schedule = hasSchedule
        ? [if (item.date.isNotEmpty) item.date, if (item.time.isNotEmpty) item.time]
            .join('  ·  ')
        : 'Awaiting schedule';
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
              Expanded(
                child: Text(
                  item.type.isNotEmpty ? item.type : 'Appointment',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(bg: style.bg, fg: style.fg, label: style.label),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 15, color: _grey),
              const SizedBox(width: 6),
              Text(
                schedule,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _grey,
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.note,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _dark,
                fontFamily: 'Satoshi',
                height: 1.4,
              ),
            ),
          ],
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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
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
          height: 104,
          decoration: BoxDecoration(
            color: const Color(0xFFE6E6E0),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
