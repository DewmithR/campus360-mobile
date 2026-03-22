import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/app_user.dart';
import '../../theme/app_theme.dart';
import '../study_rooms/study_rooms_page.dart';
import '../leaderboard/leaderboard_page.dart';
import '../account/account_page.dart';
import '../feedback/feedback_page.dart';
import '../chat/chat_list_page.dart';
import '../events/events_page.dart';
import '../../core/services/event_service.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser user;

  const DashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late AppUser user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  static const List<_FeatureItem> _features = [
    _FeatureItem(
      icon: Icons.meeting_room_rounded,
      label: 'Study Rooms',
      gradient: LinearGradient(
        colors: [Color(0xFF006837), Color(0xFF338A5E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      enabled: true,
    ),
    _FeatureItem(
      icon: Icons.leaderboard_rounded,
      label: 'Leaderboard',
      gradient: LinearGradient(
        colors: [Color(0xFFF9A825), Color(0xFFFFCA28)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      enabled: true,
    ),
    _FeatureItem(
      icon: Icons.event_rounded,
      label: 'Events',
      gradient: LinearGradient(
        colors: [Color(0xFF0277BD), Color(0xFF0288D1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      enabled: true,
    ),
    _FeatureItem(
      icon: Icons.chat_rounded,
      label: 'Chat',
      gradient: LinearGradient(
        colors: [Color(0xFF8DC63F), Color(0xFF9CCC65)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      enabled: true,
    ),
    _FeatureItem(
      icon: Icons.feedback_rounded,
      label: 'Feedback',
      gradient: LinearGradient(
        colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      enabled: true,
    ),
    _FeatureItem(
      icon: Icons.account_circle_rounded,
      label: 'Account',
      gradient: LinearGradient(
        colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      enabled: true,
    ),
  ];

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alert),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirm == true) await FirebaseAuth.instance.signOut();
  }

  // Helper: build updated AppUser preserving ALL fields
  AppUser _buildUpdatedUser({
    String? currentRoomId,
    String? currentRoomFaculty,
  }) {
    return AppUser(
      uid: user.uid,
      name: user.name,
      email: user.email,
      role: user.role,
      sid: user.sid,
      batch: user.batch,
      degree: user.degree,
      faculty: user.faculty,
      phone: user.phone,
      streakCount: user.streakCount,
      lastAdmitDate: user.lastAdmitDate,
      createdAt: user.createdAt,
      currentRoomId: currentRoomId,
      currentRoomFaculty: currentRoomFaculty,
    );
  }

  Future<void> _leaveRoom(String facultyName, String roomId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final roomRef = FirebaseFirestore.instance
          .collection('faculties')
          .doc(facultyName)
          .collection('rooms')
          .doc(roomId);
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await roomRef.set(
        {'currentCapacity': FieldValue.increment(-1)},
        SetOptions(merge: true),
      );
      await userRef.update({
        'currentRoomFaculty': null,
        'currentRoomId': null,
      });

      if (mounted) {
        setState(() {
          user = _buildUpdatedUser(
            currentRoomId: null,
            currentRoomFaculty: null,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the room.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave: $e')),
        );
      }
    }
  }

  void _onFeatureTap(_FeatureItem item) async {
    if (!item.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.label} coming soon...')),
      );
      return;
    }

    if (item.label == 'Study Rooms') {
      final updatedUser = await Navigator.push<AppUser>(
        context,
        MaterialPageRoute(builder: (_) => StudyRoomsPage(user: user)),
      );
      // Guard: only call setState if still mounted and if we got an updated user back
      if (!mounted) return;
      if (updatedUser != null) setState(() => user = updatedUser);
    } else if (item.label == 'Leaderboard') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LeaderboardPage()),
      );
    } else if (item.label == 'Events') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventsPage(user: user)),
      );
    } else if (item.label == 'Chat') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatListPage(user: user)),
      );
    } else if (item.label == 'Feedback') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FeedbackPage(user: user)),
      );
    } else if (item.label == 'Account') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AccountPage(user: user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Banner
            SliverToBoxAdapter(
              child: _WelcomeBanner(user: user),
            ),

            // Active Room Card (live card that listens to Firestore for real-time updates)
            SliverToBoxAdapter(
              child: _ActiveRoomCard(
                uid: user.uid,
                onLeave: _leaveRoom,
              ),
            ),

            // Upcoming Bookings Countdown
            SliverToBoxAdapter(
              child: _UpcomingBookingsCard(uid: user.uid),
            ),

            // Section Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
                ),
                child: Text(
                  'QUICK ACCESS',
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

            // Feature Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _features[index];
                    return _FeatureCard(
                      item: item,
                      onTap: () => _onFeatureTap(item),
                    );
                  },
                  childCount: _features.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.1,
                ),
              ),
            ),

            // Logout
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl,
                ),
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.alert,
                    side: const BorderSide(color: AppColors.alert, width: 1.2),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Active Room Card (live card that listens to Firestore for real-time updates)
class _ActiveRoomCard extends StatelessWidget {
  final String uid;
  final Future<void> Function(String facultyName, String roomId) onLeave;

  const _ActiveRoomCard({required this.uid, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final roomId = data['currentRoomId'] as String?;
        final facultyName = data['currentRoomFaculty'] as String?;

        if (roomId == null || facultyName == null) {
          return const SizedBox.shrink();
        }

        final roomIndex = int.tryParse(roomId.replaceAll('room_', '')) ?? 0;
        final roomName = 'Room ${roomIndex + 1}';

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(12),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.success.withAlpha(100),
                width: 1.5,
              ),
              boxShadow: AppShadows.subtle,
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENTLY CHECKED IN',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$facultyName · $roomName',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                ElevatedButton.icon(
                  onPressed: () => onLeave(facultyName, roomId),
                  icon: const Icon(Icons.logout_rounded, size: 14),
                  label: const Text('Leave'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alert,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Welcome Banner
class _WelcomeBanner extends StatelessWidget {
  final AppUser user;
  const _WelcomeBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40006837),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withAlpha(200),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.name,
                      style: AppTextStyles.heading1.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Role + Faculty badge row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(50),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: AppColors.accent.withAlpha(120),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            user.role.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        if (user.faculty != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: Colors.white.withAlpha(60),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              user.faculty!,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withAlpha(220),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _StreakBadge(
                  uid: user.uid, fallbackStreak: user.streakCount),
            ],
          ),
        ],
      ),
    );
  }
}

// Streak Badge (live from Firestore)
class _StreakBadge extends StatelessWidget {
  final String uid;
  final int fallbackStreak;

  const _StreakBadge({required this.uid, required this.fallbackStreak});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        final streak = snapshot.hasData && snapshot.data!.exists
            ? ((snapshot.data!.data()
                    as Map<String, dynamic>)['streakCount'] ??
                fallbackStreak)
            : fallbackStreak;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: Colors.white.withAlpha(60),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.accent,
                size: 26,
              ),
              const SizedBox(height: 2),
              Text(
                '$streak',
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              Text(
                'streak',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withAlpha(180),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Feature Card
class _FeatureCard extends StatelessWidget {
  final _FeatureItem item;
  final VoidCallback onTap;

  const _FeatureCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.neutralBorder, width: 0.8),
          ),
          boxShadow: AppShadows.subtle,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: item.gradient,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            if (!item.enabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(160),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: BoxDecoration(
                      gradient: item.gradient,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (item.gradient.colors.first).withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 22),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    item.label,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.neutralDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (!item.enabled)
                    Text(
                      'Coming soon',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutralMid,
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

// Data class for feature items
class _FeatureItem {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final bool enabled;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.enabled,
  });
}

// Upcoming Bookings Countdown Cards
class _UpcomingBookingsCard extends StatelessWidget {
  final String uid;
  final EventService _eventService = EventService();

  _UpcomingBookingsCard({required this.uid});

  String _countdown(Timestamp eventDate) {
    final days = eventDate.toDate().difference(DateTime.now()).inDays;
    if (days == 0) return 'Today!';
    if (days == 1) return 'Tomorrow';
    return 'In $days days';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _eventService.streamMyUpcomingBookings(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final bookings = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final eventDate = data['eventDate'] as Timestamp?;
          final status = data['status'] as String? ?? '';
          if (eventDate == null) return false;
          if (status == 'cancelled') return false;
          return eventDate.toDate().isAfter(DateTime.now());
        }).toList();

        if (bookings.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
              ),
              child: Text(
                'Your upcoming events',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutralMid,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            ...bookings.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final eventTitle = data['eventTitle'] as String? ?? '';
              final eventDate = data['eventDate'] as Timestamp;
              final venue = data['venue'] as String? ?? '';
              final type = data['type'] as String? ?? 'free';
              final countdown = _countdown(eventDate);
              final days       = eventDate.toDate()
                  .difference(DateTime.now())
                  .inDays;
              final isUrgent   = days <= 3;

              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? AppColors.alert.withAlpha(10)
                        : AppColors.info.withAlpha(8),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: isUrgent
                          ? AppColors.alert.withAlpha(80)
                          : AppColors.info.withAlpha(60),
                      width: 1.2,
                    ),
                    boxShadow: AppShadows.subtle,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: isUrgent
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.alert,
                                    Color(0xFFEF5350),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    AppColors.info,
                                    Color(0xFF0288D1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              days == 0 ? '🎉' : '$days',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: days == 0 ? 18 : 16,
                              ),
                            ),
                            if (days > 0)
                              Text(
                                days == 1 ? 'day' : 'days',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: AppSpacing.md),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eventTitle,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              venue,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: AppSpacing.sm),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            countdown,
                            style: AppTextStyles.caption.copyWith(
                              color: isUrgent
                                  ? AppColors.alert
                                  : AppColors.info,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: type == 'paid'
                                  ? AppColors.accent.withAlpha(20)
                                  : AppColors.success.withAlpha(20),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              type == 'paid' ? 'Paid' : 'Free',
                              style: AppTextStyles.caption.copyWith(
                                color: type == 'paid'
                                    ? AppColors.warning
                                    : AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}