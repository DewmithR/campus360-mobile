import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/app_user.dart';
import '../../theme/app_theme.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('streakCount', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No leaderboard data yet.'));
          }

          final users = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return AppUser.fromMap(data, doc.id);
          }).toList();

          // Dense ranking — group by streak
          final List<_RankGroup> groups = [];
          int currentRank = 1;
          for (int i = 0; i < users.length;) {
            final streak = users[i].streakCount;
            final group = <AppUser>[];
            int j = i;
            while (j < users.length && users[j].streakCount == streak) {
              group.add(users[j]);
              j++;
            }
            groups.add(_RankGroup(
              rank: currentRank,
              streak: streak,
              users: group,
            ));
            currentRank += 1;
            i = j;
          }

          // Current user's rank for the sticky banner
          _RankGroup? myGroup;
          for (final g in groups) {
            if (g.containsUid(currentUid)) {
              myGroup = g;
              break;
            }
          }

          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _LeaderboardHeader(
                  totalStudents: users.length,
                  myGroup:       myGroup,
                  currentUid:    currentUid,
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
                    'RANKINGS',
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

              // Ranked list
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _RankGroupTile(
                      group: groups[index],
                      currentUid: currentUid,
                    ),
                    childCount: groups.length,
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

// Data class
class _RankGroup {
  final int rank;
  final int streak;
  final List<AppUser> users;

  const _RankGroup({
    required this.rank,
    required this.streak,
    required this.users,
  });

  bool containsUid(String? uid) => users.any((u) => u.uid == uid);
}

// Header — summary + current user rank banner
class _LeaderboardHeader extends StatelessWidget {
  final int totalStudents;
  final _RankGroup? myGroup;
  final String? currentUid;

  const _LeaderboardHeader({
    required this.totalStudents,
    required this.myGroup,
    required this.currentUid,
  });

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
        children: [
          // Title row
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study Streak Leaderboard',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$totalStudents students ranked',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (myGroup != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 1,
              color: Colors.white.withAlpha(40),
            ),
            const SizedBox(height: AppSpacing.md),

            // My rank card
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: Colors.white.withAlpha(60),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Rank badge
                  _RankBadge(
                    rank: myGroup!.rank,
                    isCompact: true,
                    lightMode: true,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your current rank',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withAlpha(180),
                        ),
                      ),
                      Text(
                        myGroup!.users.length > 1
                            ? 'Tied with ${myGroup!.users.length - 1} other${myGroup!.users.length > 2 ? 's' : ''}'
                            : 'Keep it up! 🔥',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // The streak count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(50),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: AppColors.accent.withAlpha(120),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${myGroup!.streak}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          ' days',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Rank Badge
class _RankBadge extends StatelessWidget {
  final int rank;
  final bool isCompact;
  final bool lightMode;

  const _RankBadge({
    required this.rank,
    this.isCompact = false,
    this.lightMode = false,
  });

  // Special colors for top 3
  Color get _badgeColor {
    switch (rank) {
      case 1: return const Color(0xFFFFCA28);
      case 2: return const Color(0xFFB0BEC5);
      case 3: return const Color(0xFFBCAAA4);
      default: return lightMode
          ? Colors.white.withAlpha(40)
          : AppColors.primary.withAlpha(15);
    }
  }

  Color get _textColor {
    switch (rank) {
      case 1:
      case 2:
      case 3: return Colors.white;
      default: return lightMode ? Colors.white : AppColors.neutralMid;
    }
  }

  String get _label {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = isCompact ? 40.0 : 48.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _badgeColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: _badgeColor.withAlpha(150),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: rank <= 3
          ? Text(
              _label,
              style: TextStyle(fontSize: isCompact ? 20 : 24),
            )
          : Text(
              _label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w800,
                color: _textColor,
              ),
            ),
    );
  }
}

// Rank Group Tile
class _RankGroupTile extends StatefulWidget {
  final _RankGroup group;
  final String? currentUid;

  const _RankGroupTile({
    required this.group,
    required this.currentUid,
  });

  @override
  State<_RankGroupTile> createState() => _RankGroupTileState();
}

class _RankGroupTileState extends State<_RankGroupTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final isMeInGroup = group.containsUid(widget.currentUid);
    final isTied = group.users.length > 1;
    final isTop3 = group.rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isMeInGroup
            ? AppColors.primary.withAlpha(10)
            : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isMeInGroup
              ? AppColors.primary.withAlpha(80)
              : isTop3
                  ? _top3BorderColor(group.rank)
                  : AppColors.neutralBorder,
          width: isMeInGroup || isTop3 ? 1.5 : 0.8,
        ),
        boxShadow: isTop3 ? AppShadows.card : AppShadows.subtle,
      ),
      child: Column(
        children: [
          //Main row
          InkWell(
            onTap: isTied
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Rank badge
                  _RankBadge(rank: group.rank),

                  const SizedBox(width: AppSpacing.md),

                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isMeInGroup
                          ? AppColors.primaryGradient
                          : null,
                      color: isMeInGroup
                          ? null
                          : AppColors.primary.withAlpha(15),
                      border: Border.all(
                        color: isMeInGroup
                            ? AppColors.primary
                            : AppColors.neutralBorder,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isTied
                        ? Text(
                            '${group.users.length}',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isMeInGroup
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          )
                        : Text(
                            _getInitials(group.users.first.name),
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isMeInGroup
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Name / tied label + You badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isTied
                                    ? '${group.users.length} students tied'
                                    : group.users.first.name,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMeInGroup) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.full),
                                ),
                                child: Text(
                                  isTied ? 'incl. you' : 'You',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (isTied)
                          Text(
                            'Tap to ${_expanded ? 'collapse' : 'see all'}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutralMid,
                            ),
                          )
                        else
                          Text(
                            group.users.first.faculty ?? '',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutralMid,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Streak badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _streakBgColor(group.rank),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: _streakBorderColor(group.rank),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 15,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${group.streak}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.neutralDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isTied) ...[
                        const SizedBox(height: 4),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.neutralMid,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded tied list
          if (isTied && _expanded)
            Container(
              decoration: BoxDecoration(
                color: AppColors.neutralLight.withAlpha(120),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.lg),
                  bottomRight:Radius.circular(AppRadius.lg),
                ),
              ),
              child: Column(
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding:const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm,
                      AppSpacing.md, AppSpacing.sm,
                    ),
                    child: Column(
                      children: group.users.map((u) {
                        final isMe = u.uid == widget.currentUid;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs),
                          child: Row(
                            children: [
                              const SizedBox(width: 48 + AppSpacing.md),
                              Container(
                                width:  34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isMe
                                      ? AppColors.primaryGradient
                                      : null,
                                  color: isMe
                                      ? null
                                      : AppColors.primary.withAlpha(12),
                                  border: Border.all(
                                    color: isMe
                                        ? AppColors.primary
                                        : AppColors.neutralBorder,
                                    width: 1.2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _getInitials(u.name),
                                  style: TextStyle(
                                    fontFamily:  'Roboto',
                                    fontSize:    11,
                                    fontWeight:  FontWeight.w700,
                                    color: isMe
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u.name,
                                      style:
                                          AppTextStyles.bodySmall.copyWith(
                                        fontWeight: isMe
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (u.faculty != null)
                                      Text(
                                        u.faculty!,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.neutralMid,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isMe)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.full),
                                  ),
                                  child: Text(
                                    'You',
                                    style: AppTextStyles.caption.copyWith(
                                      color:      Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _top3BorderColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFCA28).withAlpha(150);
      case 2: return const Color(0xFFB0BEC5).withAlpha(150);
      case 3: return const Color(0xFFBCAAA4).withAlpha(150);
      default: return AppColors.neutralBorder;
    }
  }

  Color _streakBgColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFCA28).withAlpha(30);
      case 2: return const Color(0xFFB0BEC5).withAlpha(30);
      case 3: return const Color(0xFFBCAAA4).withAlpha(30);
      default: return AppColors.accentLight;
    }
  }

  Color _streakBorderColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFCA28).withAlpha(120);
      case 2: return const Color(0xFFB0BEC5).withAlpha(120);
      case 3: return const Color(0xFFBCAAA4).withAlpha(120);
      default: return AppColors.accent.withAlpha(80);
    }
  }
}

// Helpers
String _getInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
    return parts[0][0].toUpperCase();
  }
  return '?';
}