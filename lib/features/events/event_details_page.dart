import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/app_user.dart';
import '../../core/services/event_service.dart';
import '../../theme/app_theme.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  final AppUser user;

  const EventDetailsPage({
    super.key,
    required this.eventId,
    required this.user,
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final EventService _eventService = EventService();
  bool _isLoading = false;
  String? _bookingId;
  String _bookingStatus = '';

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final doc = await _eventService.getBooking(widget.eventId);
    if (doc != null && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _bookingId = doc.id;
        _bookingStatus = data['status'] as String? ?? '';
      });
    }
  }

  Future<void> _book(Map<String, dynamic> eventData) async {
    setState(() => _isLoading = true);
    try {
      await _eventService.bookEvent(
        eventId: widget.eventId,
        eventTitle: eventData['title'] as String,
        eventDate: eventData['date'] as Timestamp,
        userName: widget.user.name,
        userEmail: widget.user.email,
        venue: eventData['venue'] as String? ?? '',
        type: eventData['type'] as String? ?? 'free',
        ticketPrice: (eventData['ticketPrice'] as num?)?.toDouble() ?? 0.0,
      );
      await _loadBooking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel() async {
    if (_bookingId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alert,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isLoading = true);

    try {
      await _eventService.cancelBooking(_bookingId!, widget.eventId);
      if (mounted) {
        setState(() {
          _bookingId = null;
          _bookingStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(Timestamp ts) {
    final dt = ts.toDate();
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December',
    ];
    const days = [
      'Monday','Tuesday','Wednesday','Thursday',
      'Friday','Saturday','Sunday',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year} at $h:$m';
  }

  int _daysUntil(Timestamp ts) {
    return ts.toDate().difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _eventService.streamEvent(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Scaffold(
              body: Center(child: Text('Event not found.')),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final title = data['title'] as String? ?? '';
          final description = data['description'] as String? ?? '';
          final flyerUrl = data['flyerUrl'] as String?;
          final venue = data['venue'] as String? ?? '';
          final type = data['type'] as String? ?? 'free';
          final ticketPrice = (data['ticketPrice'] as num?)?.toDouble() ?? 0.0;
          final totalSeats = data['totalSeats'] as int? ?? 0;
          final bookedSeats = data['bookedSeats'] as int? ?? 0;
          final eventDate = data['date'] as Timestamp;
          final available = totalSeats - bookedSeats;
          final isFull = available <= 0;
          final isPaid = type == 'paid';
          final daysUntil = _daysUntil(eventDate);
          final isBooked = _bookingId != null && _bookingStatus != 'cancelled';
          final canCancel = isBooked &&
              _eventService.canCancel(eventDate);
          final fillRatio = totalSeats > 0
              ? (bookedSeats / totalSeats).clamp(0.0, 1.0)
              : 0.0;

          return CustomScrollView(
            slivers: [
              // Flyer App Bar
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: flyerUrl != null && flyerUrl.isNotEmpty
                      ? Image.network(
                          flyerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _buildFlyerPlaceholder(),
                        )
                      : _buildFlyerPlaceholder(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking status banner
                      if (isBooked)
                        _BookingBanner(
                          canCancel: canCancel,
                          bookingId: _bookingId!,
                          isCollected: _bookingStatus == 'collected',
                        ),

                      if (isBooked) const SizedBox(height: AppSpacing.md),

                      // Title & badges
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.heading1.copyWith(
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
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
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Event info
                      _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        text: _formatDate(eventDate),
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.location_on_rounded,
                        text: venue,
                        color: AppColors.alert,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: daysUntil <= 3
                            ? Icons.alarm_rounded
                            : Icons.hourglass_top_rounded,
                        text: daysUntil == 0
                            ? 'Happening today!'
                            : daysUntil == 1
                                ? 'Tomorrow'
                                : 'In $daysUntil days',
                        color: daysUntil <= 3
                            ? AppColors.alert
                            : AppColors.info,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Seats card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: const Border.fromBorderSide(
                            BorderSide(
                                color: AppColors.neutralBorder, width: 0.8),
                          ),
                          boxShadow: AppShadows.subtle,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _SeatStat(
                                    label: 'Total',
                                    value: '$totalSeats',
                                    color: AppColors.info,
                                    icon: Icons.group_rounded,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.neutralBorder,
                                ),
                                Expanded(
                                  child: _SeatStat(
                                    label: 'Booked',
                                    value: '$bookedSeats',
                                    color: AppColors.warning,
                                    icon: Icons.bookmark_rounded,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.neutralBorder,
                                ),
                                Expanded(
                                  child: _SeatStat(
                                    label: 'Available',
                                    value: '$available',
                                    color: isFull
                                        ? AppColors.alert
                                        : AppColors.success,
                                    icon: Icons.event_seat_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              child: LinearProgressIndicator(
                                value: fillRatio,
                                minHeight: 8,
                                backgroundColor: AppColors.neutralBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isFull
                                      ? AppColors.alert
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              isFull
                                  ? 'This event is fully booked'
                                  : '$available of $totalSeats seats available',
                              style: AppTextStyles.caption.copyWith(
                                color: isFull
                                    ? AppColors.alert
                                    : AppColors.neutralMid,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Description
                      if (description.isNotEmpty) ...[
                        const Text(
                          'ABOUT THIS EVENT',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutralMid,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          description,
                          style: AppTextStyles.body.copyWith(
                            height: 1.6,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Collection note
                      if (isPaid)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withAlpha(10),
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: AppColors.warning.withAlpha(60),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.warning,
                                size: 18,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Collect and pay for your ticket physically '
                                  'within 3 days of booking. Uncollected '
                                  'bookings will be cancelled.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: AppSpacing.lg),

                      // Action buttons
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (isBooked)
                        Column(
                          children: [
                            if (canCancel)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: _cancel,
                                  icon: const Icon(
                                    Icons.cancel_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Cancel Booking'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.alert,
                                    side: const BorderSide(
                                      color: AppColors.alert,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.neutralLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                  border: const Border.fromBorderSide(
                                    BorderSide(
                                        color: AppColors.neutralBorder,
                                        width: 1),
                                  ),
                                ),
                                child: Text(
                                  'Cancellation deadline has passed (5 days before event)',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.neutralMid,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: isFull
                                ? null
                                : () => _book(data),
                            icon: const Icon(
                              Icons.bookmark_add_rounded,
                              size: 18,
                            ),
                            label: Text(
                              isFull
                                  ? 'Fully Booked'
                                  : isPaid
                                      ? 'Reserve Ticket — LKR ${ticketPrice.toStringAsFixed(0)}'
                                      : 'Reserve Free Seat',
                            ),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFlyerPlaceholder() {
    return Container(
      color: AppColors.primary.withAlpha(20),
      child: const Center(
        child: Icon(
          Icons.event_rounded,
          size: 64,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// Booking Banner
class _BookingBanner extends StatelessWidget {
  final bool canCancel;
  final String bookingId;
  final bool isCollected;

  const _BookingBanner({
    required this.canCancel,
    required this.bookingId,
    required this.isCollected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCollected ? AppColors.success : AppColors.primary;
    final icon = isCollected
        ? Icons.check_circle_rounded
        : Icons.bookmark_rounded;
    final label = isCollected ? 'Ticket Collected' : 'Seat Reserved';
    final sub = isCollected
        ? 'Your ticket has been collected.'
        : canCancel
            ? 'You can cancel up to 5 days before the event.'
            : 'Cancellation deadline has passed.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withAlpha(80), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(sub, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Info Row
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: AppTextStyles.bodySmall),
        ),
      ],
    );
  }
}

// Seat Stat
class _SeatStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SeatStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(
            color: color,
            fontSize: 18,
          ),
        ),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}