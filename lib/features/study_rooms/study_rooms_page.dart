import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'faculty_rooms_page.dart';
import '../../core/models/app_user.dart';

class StudyRoomsPage extends StatelessWidget {
  final AppUser user;

  const StudyRoomsPage({super.key, required this.user});

  static const Map<String, Map<String, dynamic>> _facultyMeta = {
    'FOB': {
      'icon': Icons.business_center_rounded,
      'color': Color(0xFF006837),
    },
    'FOC': {
      'icon': Icons.computer_rounded,
      'color': Color(0xFF1565C0),
    },
    'FOE': {
      'icon': Icons.precision_manufacturing_rounded,
      'color': Color(0xFFF57C00),
    },
    'Library': {
      'icon': Icons.local_library_rounded,
      'color': Color(0xFF6A1B9A),
    },
  };

  List<Map<String, dynamic>> _visibleFaculties(AppUser user) {
    final List<Map<String, dynamic>> result = [];

    // Show the user's own faculty first
    final userFaculty = user.faculty;
    if (userFaculty != null && _facultyMeta.containsKey(userFaculty)) {
      result.add({
        'name': userFaculty,
        ..._facultyMeta[userFaculty]!,
      });
    }

    // Library
    if (user.role == 'student') {
      result.add({
        'name': 'Library',
        ..._facultyMeta['Library']!,
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final faculties = _visibleFaculties(user);

    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Study Rooms')),
      body: CustomScrollView(
        slivers: [

          // Section label
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
              ),
              child: Text(
                'SELECT A FACULTY',
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

          // Faculty Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final faculty = faculties[index];
                  return _FacultyCard(
                    faculty: faculty,
                    user: user,
                  );
                },
                childCount: faculties.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Faculty Card
class _FacultyCard extends StatelessWidget {
  final Map<String, dynamic> faculty;
  final AppUser user;

  const _FacultyCard({required this.faculty, required this.user});

  @override
  Widget build(BuildContext context) {
    final color = faculty['color'] as Color;
    final name = faculty['name'] as String;

    return GestureDetector(
      onTap: () async {
        final updatedUser = await Navigator.push<AppUser>(
          context,
          MaterialPageRoute(
            builder: (_) => FacultyRoomsPage(
              facultyName: name,
              facultyColor: color,
              user: user,
            ),
          ),
        );
        if (updatedUser != null) {
          Navigator.pop(context, updatedUser);
        }
      },
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
            // The background blob
            Positioned(
              top: -16,
              right: -16,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: color.withAlpha(60),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      faculty['icon'] as IconData,
                      color: color,
                      size: 24,
                    ),
                  ),

                  const Spacer(),

                  // Faculty name
                  Text(
                    name,
                    style: AppTextStyles.heading2.copyWith(fontSize: 16),
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    name == 'Library'
                        ? 'Group study rooms'
                        : 'Common & group rooms',
                    style: AppTextStyles.caption,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // View button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: color.withAlpha(15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: color.withAlpha(60),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'View Rooms',
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
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
