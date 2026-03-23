import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/app_user.dart';
import '../../core/services/event_service.dart';
import '../../theme/app_theme.dart';
import 'event_details_page.dart';
import 'my_bookings_page.dart';

class EventsPage extends StatelessWidget {
  final AppUser user;
  final EventService _eventService = EventService();

  EventsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyBookingsPage(user: user),
                ),
              ),
              icon: const Icon(
                Icons.bookmark_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                'My Bookings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventService.streamEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState();
          }

          final events = snapshot.data!.docs;

          return CustomScrollView(
            slivers: [
              // Info banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg,
                    AppSpacing.lg, 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.info.withAlpha(15),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.info.withAlpha(80),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.info,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Tickets must be collected physically. '
                            'Uncollected bookings may be cancelled after 3 days.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Section label
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg,
                    AppSpacing.lg, AppSpacing.sm,
                  ),
                  child: Text(
                    'UPCOMING EVENTS',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutralMid,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),

              // Events list
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = events[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _EventCard(
                        eventId: doc.id,
                        data: data,
                        user: user,
                      );
                    },
                    childCount: events.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Event Card
class _EventCard extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> data;
  final AppUser user;

  const _EventCard({
    required this.eventId,
    required this.data,
    required this.user,
  });

  int _daysUntil() {
    final eventDate = (data['date'] as Timestamp).toDate();
    final now = DateTime.now();
    final diff = eventDate.difference(now);
    return diff.inDays;
  }

  String _formatDate() {
    final dt = (data['date'] as Timestamp).toDate();
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
    final title = data['title'] as String? ?? '';
    final flyerUrl = data['flyerUrl'] as String?;
    final type = data['type'] as String? ?? 'free';
    final ticketPrice = (data['ticketPrice'] as num?)?.toDouble() ?? 0.0;
    final totalSeats = data['totalSeats'] as int? ?? 0;
    final bookedSeats = data['bookedSeats'] as int? ?? 0;
    final available = totalSeats - bookedSeats;
    final daysUntil = _daysUntil();
    final isPaid = type == 'paid';
    final isFull = available <= 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailsPage(
            eventId: eventId,
            user:    user,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.neutralBorder, width: 0.8),
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event flyer
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft:  Radius.circular(AppRadius.xl),
                topRight: Radius.circular(AppRadius.xl),
              ),
              child: flyerUrl != null && flyerUrl.isNotEmpty
                  ? Image.network(
                      flyerUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _FlyerPlaceholder(),
                    )
                  : _FlyerPlaceholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: type + countdown
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? AppColors.accent.withAlpha(20)
                              : AppColors.success.withAlpha(20),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: isPaid
                                ? AppColors.accent.withAlpha(80)
                                : AppColors.success.withAlpha(80),
                            width: 1,
                          ),
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

                      const Spacer(),

                      // Countdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: daysUntil <= 3
                              ? AppColors.alert.withAlpha(15)
                              : AppColors.primary.withAlpha(10),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: daysUntil <= 3
                                ? AppColors.alert.withAlpha(60)
                                : AppColors.primary.withAlpha(40),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          daysUntil == 0
                              ? 'Today!'
                              : daysUntil == 1
                                  ? 'Tomorrow'
                                  : 'In $daysUntil days',
                          style: AppTextStyles.caption.copyWith(
                            color: daysUntil <= 3
                                ? AppColors.alert
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Title
                  Text(
                    title,
                    style: AppTextStyles.heading2.copyWith(fontSize: 17),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Date & venue
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: AppColors.neutralMid,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDate(),
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: AppColors.neutralMid,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['venue'] as String? ?? '',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Seats progress bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isFull ? 'Fully Booked' : '$available seats left',
                        style: AppTextStyles.caption.copyWith(
                          color: isFull
                              ? AppColors.alert
                              : AppColors.neutralMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$bookedSeats / $totalSeats',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: totalSeats > 0
                          ? (bookedSeats / totalSeats).clamp(0.0, 1.0)
                          : 0,
                      minHeight: 6,
                      backgroundColor: AppColors.neutralBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFull ? AppColors.alert : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Flyer Placeholder
class _FlyerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.primary.withAlpha(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_rounded,
            size: 48,
            color: AppColors.primary.withAlpha(80),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No flyer available',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutralMid,
            ),
          ),
        ],
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
                Icons.event_busy_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Upcoming Events',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check back later for new events.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}