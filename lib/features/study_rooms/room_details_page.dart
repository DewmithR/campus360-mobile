import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/app_user.dart';
import '../../theme/app_theme.dart';
import 'dart:async';

class RoomDetailsPage extends StatefulWidget {
  final String roomName;
  final String imageUrl;
  final int capacity;
  final String facultyName;
  final Color facultyColor;
  final String roomId;
  final AppUser user;

  const RoomDetailsPage({
    super.key,
    required this.roomName,
    required this.imageUrl,
    required this.capacity,
    required this.facultyName,
    required this.facultyColor,
    required this.roomId,
    required this.user,
  });

  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> {
  late AppUser appUser;
  int currentCapacity = 0;
  bool isAdmitted = false;
  bool isBlockedByGroup = false;
  bool _isLoading = false;
  late final Future<void> _initFuture;
  late StreamSubscription<DocumentSnapshot> _roomSubscription;

  @override
  void initState() {
    super.initState();
    appUser = widget.user;
    _initFuture = _loadUser();
    _listenRoomCapacity();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!mounted) return;

    final loadedUser = AppUser.fromMap(doc.data()!, doc.id);
    final admitted = loadedUser.currentRoomId == widget.roomId &&
        loadedUser.currentRoomFaculty == widget.facultyName;

    // Check if SID is in any active group booking
    bool blockedByGroup = false;
    final sid = loadedUser.sid;
    if (sid != null && sid.isNotEmpty && !admitted) {
      blockedByGroup = await _checkGroupBooking(sid);
    }

    if (!mounted) return;
    setState(() {
      appUser = loadedUser;
      isAdmitted = admitted;
      isBlockedByGroup = blockedByGroup;
    });
  }

  // Returns true if the student's SID appears in any active group booking
  // across any faculty's rooms.
  Future<bool> _checkGroupBooking(String sid) async {
    final faculties = ['FOB', 'FOC', 'FOE/FOS', 'Library'];
    for (final faculty in faculties) {
      final roomsSnap = await FirebaseFirestore.instance
          .collection('faculties')
          .doc(faculty)
          .collection('rooms')
          .where('type', isEqualTo: 'group')
          .where('isOccupied', isEqualTo: true)
          .get();

      for (final roomDoc in roomsSnap.docs) {
        final bookingsSnap = await FirebaseFirestore.instance
            .collection('faculties')
            .doc(faculty)
            .collection('rooms')
            .doc(roomDoc.id)
            .collection('bookings')
            .where('status', isEqualTo: 'active')
            .where('studentSids', arrayContains: sid)
            .get();

        if (bookingsSnap.docs.isNotEmpty) return true;
      }
    }
    return false;
  }

  void _listenRoomCapacity() {
    _roomSubscription = FirebaseFirestore.instance
        .collection('faculties')
        .doc(widget.facultyName)
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          currentCapacity = snapshot.data()?['currentCapacity'] ?? 0;
        });
      }
    });
  }

  // Helper to build updated AppUser preserving ALL fields
  AppUser _buildUpdatedUser({
    String? currentRoomId,
    String? currentRoomFaculty,
    int? streakCount,
    DateTime? lastAdmitDate,
  }) {
    return AppUser(
      uid: appUser.uid,
      name: appUser.name,
      email: appUser.email,
      role: appUser.role,
      sid: appUser.sid,
      batch: appUser.batch,
      degree: appUser.degree,
      faculty: appUser.faculty,
      phone: appUser.phone,
      streakCount: streakCount   ?? appUser.streakCount,
      lastAdmitDate: lastAdmitDate ?? appUser.lastAdmitDate,
      createdAt: appUser.createdAt,
      currentRoomId: currentRoomId,
      currentRoomFaculty: currentRoomFaculty,
    );
  }

  Future<void> _admit() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final roomRef = FirebaseFirestore.instance
          .collection('faculties')
          .doc(widget.facultyName)
          .collection('rooms')
          .doc(widget.roomId);

      final roomSnapshot = await roomRef.get();
      if (!roomSnapshot.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This room no longer exists. Please go back.'),
            ),
          );
        }
        return;
      }

      final userSnapshot = await userRef.get();
      final userData = userSnapshot.data() as Map<String, dynamic>;

      final int currentStreak = userData['streakCount'] ?? 0;
      final DateTime? lastAdmit = (userData['lastAdmitDate'] as Timestamp?)?.toDate();
      final now = DateTime.now();
      int newStreak;

      if (lastAdmit == null) {
        newStreak = 1;
      } else {
        final today = DateTime(now.year, now.month, now.day);
        final lastDay = DateTime(
            lastAdmit.year, lastAdmit.month, lastAdmit.day);
        final diff = today.difference(lastDay).inDays;
        if (diff == 0) { newStreak = currentStreak; }
        else if (diff == 1) { newStreak = currentStreak + 1; }
        else { newStreak = 1; }
      }

      await userRef.update({
        'lastAdmitDate': now,
        'streakCount': newStreak,
        'currentRoomFaculty': widget.facultyName,
        'currentRoomId': widget.roomId,
      });

      await roomRef.update({
        'currentCapacity': FieldValue.increment(1),
      });

      if (!mounted) return;
      setState(() {
        appUser    = _buildUpdatedUser(
          currentRoomId: widget.roomId,
          currentRoomFaculty: widget.facultyName,
          streakCount: newStreak,
          lastAdmitDate: now,
        );
        isAdmitted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have been admitted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to admit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _leave() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final roomRef = FirebaseFirestore.instance
          .collection('faculties')
          .doc(widget.facultyName)
          .collection('rooms')
          .doc(widget.roomId);
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await roomRef.set(
        {'currentCapacity': FieldValue.increment(-1)},
        SetOptions(merge: true),
      );
      await userRef.update({
        'currentRoomFaculty': null,
        'currentRoomId': null,
      });

      if (!mounted) return;
      setState(() {
        isAdmitted = false;
        appUser = _buildUpdatedUser(
          currentRoomId: null,
          currentRoomFaculty: null,
        );
      });

      if (mounted) {
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color get _occupancyColor {
    final ratio = currentCapacity / widget.capacity;
    if (ratio >= 1.0)  return AppColors.alert;
    if (ratio >= 0.75) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.roomName)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final fillRatio  = (currentCapacity / widget.capacity).clamp(0.0, 1.0);
        final isFull = currentCapacity >= widget.capacity;
        final canAdmit = !isAdmitted &&
            appUser.currentRoomId == null &&
            !isBlockedByGroup;

        return Scaffold(
          backgroundColor: AppColors.neutralLight,
          appBar: AppBar(
            title: Text(widget.roomName),
            leading: BackButton(
              onPressed: () => Navigator.pop(context, appUser),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Status banners
                if (isAdmitted)
                  _StatusBanner(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    message: "You're currently checked in to this room.",
                  )
                else if (isBlockedByGroup)
                  _StatusBanner(
                    icon: Icons.groups_rounded,
                    color: AppColors.warning,
                    message:
                        'You are currently in a group study room booking. '
                        'Please check out at the front desk before checking in here.',
                  )
                else if (appUser.currentRoomId != null)
                  _StatusBanner(
                    icon: Icons.warning_rounded,
                    color: AppColors.warning,
                    message:
                        "You're already checked in to another room. Leave it first.",
                  )
                else if (isFull)
                  _StatusBanner(
                    icon: Icons.block_rounded,
                    color: AppColors.alert,
                    message: 'This room is currently full.',
                  ),

                if (isAdmitted ||
                    isBlockedByGroup ||
                    appUser.currentRoomId != null ||
                    isFull)
                  const SizedBox(height: AppSpacing.md),

                // Room info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: widget.facultyColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(
                              Icons.meeting_room_rounded,
                              color: widget.facultyColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.facultyName,
                                style: AppTextStyles.caption.copyWith(
                                  color: widget.facultyColor,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                widget.roomName,
                                style: AppTextStyles.heading2,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              label: 'Capacity',
                              value: '${widget.capacity}',
                              icon: Icons.group_rounded,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatBox(
                              label: 'Occupied',
                              value: '$currentCapacity',
                              icon: Icons.person_rounded,
                              color: _occupancyColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatBox(
                              label: 'Available',
                              value:
                                  '${(widget.capacity - currentCapacity).clamp(0, widget.capacity)}',
                              icon: Icons.event_seat_rounded,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Occupancy', style: AppTextStyles.bodySmall),
                          Text(
                            '${(fillRatio * 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _occupancyColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: fillRatio,
                          minHeight: 10,
                          backgroundColor: AppColors.neutralBorder,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_occupancyColor),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Streak card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x30006837),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.accent,
                        size: 36,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Study Streak',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                          Text(
                            '${appUser.streakCount} day${appUser.streakCount == 1 ? '' : 's'}',
                            style: AppTextStyles.heading1.copyWith(
                              color: Colors.white,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Action buttons
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (canAdmit && !isFull) ? _admit : null,
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text('Check In'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isAdmitted ? _leave : null,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Check Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.alert,
                            disabledBackgroundColor: AppColors.neutralBorder,
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _roomSubscription.cancel();
    super.dispose();
  }
}

// Status Banner
class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Stat Box
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm + 2,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withAlpha(50), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
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
      ),
    );
  }
}
