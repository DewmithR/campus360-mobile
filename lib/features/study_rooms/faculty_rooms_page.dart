import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import 'room_details_page.dart';
import '../../core/models/app_user.dart';

class FacultyRoomsPage extends StatefulWidget {
  final String facultyName;
  final Color facultyColor;
  final AppUser user;

  const FacultyRoomsPage({
    super.key,
    required this.facultyName,
    required this.facultyColor,
    required this.user,
  });

  @override
  State<FacultyRoomsPage> createState() => _FacultyRoomsPageState();
}

class _FacultyRoomsPageState extends State<FacultyRoomsPage> {
  late AppUser _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  void _onUserUpdated(AppUser updatedUser) {
    setState(() => _currentUser = updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLibrary = widget.facultyName == 'Library';

    return DefaultTabController(
      length: isLibrary ? 1 : 2,
      child: Scaffold(
        backgroundColor: AppColors.neutralLight,
        appBar: AppBar(
          title: Text(widget.facultyName),
          leading: BackButton(
            onPressed: () => Navigator.pop(context, _currentUser),
          ),
          bottom: isLibrary
              ? null
              : TabBar(
                  indicatorColor: widget.facultyColor,
                  labelColor: widget.facultyColor,
                  unselectedLabelColor: const Color.fromARGB(255, 255, 255, 255),
                  tabs: const [
                    Tab(text: 'Common Rooms'),
                    Tab(text: 'Group Rooms'),
                  ],
                ),
        ),
        body: isLibrary
            ? _RoomsList(
                facultyName: widget.facultyName,
                facultyColor: widget.facultyColor,
                roomType: 'group',
                user:  _currentUser,
                onUserUpdated: _onUserUpdated,
              )
            : TabBarView(
                children: [
                  _RoomsList(
                    facultyName: widget.facultyName,
                    facultyColor: widget.facultyColor,
                    roomType: 'common',
                    user: _currentUser,
                    onUserUpdated: _onUserUpdated,
                  ),
                  _RoomsList(
                    facultyName: widget.facultyName,
                    facultyColor: widget.facultyColor,
                    roomType: 'group',
                    user:  _currentUser,
                    onUserUpdated: _onUserUpdated,
                  ),
                ],
              ),
      ),
    );
  }
}

// Rooms List (per type)
class _RoomsList extends StatelessWidget {
  final String facultyName;
  final Color facultyColor;
  final String roomType;
  final AppUser user;
  final ValueChanged<AppUser> onUserUpdated;

  const _RoomsList({
    required this.facultyName,
    required this.facultyColor,
    required this.roomType,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final roomsRef = FirebaseFirestore.instance
        .collection('faculties')
        .doc(facultyName)
        .collection('rooms')
        .where('type', isEqualTo: roomType)
        .orderBy('name');

    return StreamBuilder<QuerySnapshot>(
      stream: roomsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong.\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.meeting_room_outlined, size: 48,
                    color: AppColors.neutralMid),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No $roomType rooms available',
                  style: AppTextStyles.heading2.copyWith(
                      color: AppColors.neutralMid),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Rooms will appear here once added by an admin.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
                ),
                child: Text(
                  roomType == 'common'
                      ? 'COMMON STUDY ROOMS'
                      : 'GROUP STUDY ROOMS',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutralMid,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),

            if (roomType == 'group')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color: facultyColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: facultyColor.withAlpha(60), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: facultyColor),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Group rooms are managed by admins. '
                            'Check in and out is done at the front desk.',
                            style: AppTextStyles.caption.copyWith(
                                color: facultyColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl,
              ),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final roomId = doc.id;
                    final roomName = data['name'] as String? ?? roomId;
                    final capacity = (data['capacity'] as num?)?.toInt() ?? 50;
                    final type = data['type'] as String? ?? 'common';

                    if (type == 'common') {
                      final current = (data['currentCapacity'] as num?)?.toInt() ?? 0;
                      final isFull = current >= capacity;
                      final isMyRoom = user.currentRoomId == roomId &&
                          user.currentRoomFaculty == facultyName;

                      return _CommonRoomCard(
                        roomName: roomName,
                        roomId: roomId,
                        facultyName: facultyName,
                        facultyColor: facultyColor,
                        current: current,
                        capacity: capacity,
                        isFull: isFull,
                        isMyRoom: isMyRoom,
                        user: user,
                        onUserUpdated: onUserUpdated,
                      );
                    } else {
                      final isOccupied = data['isOccupied'] as bool? ?? false;
                      final occupantCount =
                          (data['occupantCount'] as num?)?.toInt() ?? 0;

                      return _GroupRoomCard(
                        roomName: roomName,
                        roomId: roomId,
                        facultyName: facultyName,
                        facultyColor: facultyColor,
                        isOccupied: isOccupied,
                        occupantCount: occupantCount,
                        user: user,
                      );
                    }
                  },
                  childCount: docs.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.95,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Common Room Card
class _CommonRoomCard extends StatelessWidget {
  final String roomName;
  final String roomId;
  final String facultyName;
  final Color facultyColor;
  final int current;
  final int capacity;
  final bool isFull;
  final bool isMyRoom;
  final AppUser user;
  final ValueChanged<AppUser> onUserUpdated;

  const _CommonRoomCard({
    required this.roomName,
    required this.roomId,
    required this.facultyName,
    required this.facultyColor,
    required this.current,
    required this.capacity,
    required this.isFull,
    required this.isMyRoom,
    required this.user,
    required this.onUserUpdated,
  });

  Color get _statusColor {
    if (isMyRoom) return AppColors.primary;
    if (isFull) return AppColors.alert;
    final ratio = current / capacity;
    if (ratio >= 0.75) return AppColors.warning;
    return AppColors.success;
  }

  String get _statusLabel {
    if (isMyRoom) return 'My Room';
    if (isFull) return 'Full';
    final ratio = current / capacity;
    if (ratio >= 0.75) return 'Busy';
    return 'Available';
  }

  @override
  Widget build(BuildContext context) {
    final fillRatio = (current / capacity).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () async {
        final updatedUser = await Navigator.push<AppUser>(
          context,
          MaterialPageRoute(
            builder: (_) => RoomDetailsPage(
              roomName: roomName,
              imageUrl: 'assets/images/room_placeholder.jpg',
              capacity: capacity,
              facultyName: facultyName,
              facultyColor: facultyColor,
              roomId: roomId,
              user: user,
            ),
          ),
        );
        // Update state in place — don't pop
        if (updatedUser != null) {
          onUserUpdated(updatedUser);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isMyRoom
              ? AppColors.primary.withAlpha(10)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isMyRoom
                ? AppColors.primary.withAlpha(100)
                : AppColors.neutralBorder,
            width: isMyRoom ? 1.5 : 0.8,
          ),
          boxShadow: AppShadows.subtle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: facultyColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.meeting_room_rounded,
                        color: facultyColor, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                          color: _statusColor.withAlpha(80), width: 1),
                    ),
                    child: Text(
                      _statusLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              Text(
                roomName,
                style: AppTextStyles.heading2.copyWith(fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              Text('$current / $capacity occupied',
                  style: AppTextStyles.caption),

              const SizedBox(height: AppSpacing.sm),

              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: fillRatio,
                  minHeight: 6,
                  backgroundColor: AppColors.neutralBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Group Room Card (read-only for students)
class _GroupRoomCard extends StatelessWidget {
  final String roomName;
  final String roomId;
  final String facultyName;
  final Color facultyColor;
  final bool isOccupied;
  final int occupantCount;
  final AppUser user;

  const _GroupRoomCard({
    required this.roomName,
    required this.roomId,
    required this.facultyName,
    required this.facultyColor,
    required this.isOccupied,
    required this.occupantCount,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOccupied ? AppColors.alert : AppColors.success;
    final statusLabel = isOccupied ? 'Occupied' : 'Free';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.neutralBorder, width: 0.8),
        boxShadow: AppShadows.subtle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: facultyColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.groups_rounded,
                      color: facultyColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                        color: statusColor.withAlpha(80), width: 1),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            Text(
              roomName,
              style: AppTextStyles.heading2.copyWith(fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            Text(
              isOccupied
                  ? '$occupantCount student${occupantCount == 1 ? '' : 's'} inside'
                  : 'Available for booking',
              style: AppTextStyles.caption,
            ),

            const SizedBox(height: AppSpacing.sm),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.neutralBorder.withAlpha(80),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: Text(
                'Admin Check-in Only',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.neutralMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
