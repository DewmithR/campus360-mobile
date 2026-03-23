import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/app_user.dart';
import '../../core/services/event_service.dart';
import '../../theme/app_theme.dart';
import 'event_details_page.dart';

class MyBookingsPage extends StatelessWidget {
  final AppUser user;
  final EventService _eventService = EventService();

  MyBookingsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('My Bookings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventService.streamMyBookings(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState();
          }

          final bookings = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: bookings.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final doc = bookings[index];
              final data = doc.data() as Map<String, dynamic>;
              return _BookingCard(
                bookingId: doc.id,
                data: data,
                user: user,
              );
            },
          );
        },
      ),
    );
  }
}

// Booking Card
class _BookingCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> data;
  final AppUser user;

  const _BookingCard({
    required this.bookingId,
    required this.data,
    required this.user,
  });

  Color get _statusColor {
    switch (data['status'] as String? ?? '') {
      case 'reserved':  return AppColors.primary;
      case 'collected': return AppColors.success;
      case 'cancelled': return AppColors.alert;
      default: return AppColors.neutralMid;
    }
  }

  IconData get _statusIcon {
    switch (data['status'] as String? ?? '') {
      case 'reserved':  return Icons.bookmark_rounded;
      case 'collected': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  String get _statusLabel {
    switch (data['status'] as String? ?? '') {
      case 'reserved':  return 'Reserved';
      case 'collected': return 'Collected';
      case 'cancelled': return 'Cancelled';
      default: return 'Unknown';
    }
  }

  String _formatDate(Timestamp ts) {
    final dt = ts.toDate();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final eventTitle = data['eventTitle'] as String? ?? '';
    final eventDate = data['eventDate'] as Timestamp?;
    final venue = data['venue'] as String? ?? '';
    final type = data['type'] as String? ?? 'free';
    final ticketPrice = (data['ticketPrice'] as num?)?.toDouble() ?? 0.0;
    final bookedAt = data['bookedAt'] as Timestamp?;
    final status = data['status'] as String? ?? '';
    final adminNote = data['adminNote'] as String?;
    final isCancelled = status == 'cancelled';
    final isPaid = type == 'paid';
    final eventId = data['eventId'] as String? ?? '';

    return GestureDetector(
      onTap: isCancelled
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailsPage(
                    eventId: eventId,
                    user:    user,
                  ),
                ),
              ),
      child: Container(
        decoration: BoxDecoration(
          color: isCancelled
              ? AppColors.neutralLight
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isCancelled
                ? AppColors.neutralBorder
                : _statusColor.withAlpha(60),
            width: isCancelled ? 0.8 : 1.2,
          ),
          boxShadow: isCancelled ? null : AppShadows.subtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: _statusColor.withAlpha(10),
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(AppRadius.xl),
                  topRight: Radius.circular(AppRadius.xl),
                ),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon, size: 16, color: _statusColor),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _statusLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.accent.withAlpha(20)
                          : AppColors.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      isPaid
                          ? 'LKR ${ticketPrice.toStringAsFixed(0)}'
                          : 'Free',
                      style: AppTextStyles.caption.copyWith(
                        color: isPaid
                            ? AppColors.warning
                            : AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventTitle,
                    style: AppTextStyles.heading2.copyWith(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (eventDate != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.neutralMid,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(eventDate),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],

                  if (venue.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: AppColors.neutralMid,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            venue,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (bookedAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.neutralMid,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Booked on ${_formatDate(bookedAt)}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],

                  // Admin cancellation note
                  if (isCancelled && adminNote != null &&
                      adminNote.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        color: AppColors.alert.withAlpha(10),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.alert.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Note',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.alert,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            adminNote,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutralMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Empty State
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Bookings Yet',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Browse upcoming events and reserve your seat.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}