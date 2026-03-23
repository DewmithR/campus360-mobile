import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/app_user.dart';
import '../../theme/app_theme.dart';

class FeedbackPage extends StatelessWidget {
  final AppUser user;

  const FeedbackPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Feedback')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
            .where('uid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // Check if student has a pending feedback
          final hasPending = docs.any(
            (doc) =>
                (doc.data() as Map<String, dynamic>)['status'] == 'pending',
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                _InfoBanner(hasPending: hasPending),

                const SizedBox(height: AppSpacing.lg),

                // Submission Form
                if (!hasPending)
                  _FeedbackForm(user: user),

                // Feedback History
                if (docs.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionLabel(label: 'YOUR FEEDBACK HISTORY'),
                  const SizedBox(height: AppSpacing.sm),
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _FeedbackCard(data: data);
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// Info Banner
class _InfoBanner extends StatelessWidget {
  final bool hasPending;
  const _InfoBanner({required this.hasPending});

  @override
  Widget build(BuildContext context) {
    final color = hasPending ? AppColors.warning : AppColors.info;
    final icon = hasPending ? Icons.hourglass_top_rounded : Icons.info_outline_rounded;
    final message = hasPending
        ? 'You have a pending feedback. You can submit a new one once an admin has replied.'
        : 'Submit your feedback below. An admin will review and reply as soon as possible.';

    return Container(
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Feedback Submission Form
class _FeedbackForm extends StatefulWidget {
  final AppUser user;
  const _FeedbackForm({required this.user});

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final _msgCtrl = TextEditingController();

  static const List<String> _categories = [
    'Study Rooms',
    'Leaderboard',
    'App General',
    'Other',
  ];

  String _selectedCategory = 'Study Rooms';
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('feedbacks').add({
        'uid': uid,
        'name': _isAnonymous ? 'Anonymous' : widget.user.name,
        'email': _isAnonymous ? null : widget.user.email,
        'category': _selectedCategory,
        'message': _msgCtrl.text.trim(),
        'status': 'pending',
        'reply': null,
        'repliedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'isAnonymous': _isAnonymous,
      });

      if (mounted) {
        _msgCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit feedback: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.neutralBorder, width: 0.8),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submit Feedback', style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text(
              'We value your feedback to improve things for you.',
              style: AppTextStyles.bodySmall,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Category selector
            Text(
              'CATEGORY',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.neutralLight,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.neutralBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.neutralMid,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Message field
            Text('MESSAGE', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _msgCtrl,
              maxLines: 5,
              maxLength: 500,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Write your feedback here...',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your feedback message';
                }
                if (value.trim().length < 10) {
                  return 'Message must be at least 10 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.sm),

            // Anonymous toggle
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: _isAnonymous
                    ? AppColors.primary.withAlpha(10)
                    : AppColors.neutralLight,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: _isAnonymous
                      ? AppColors.primary.withAlpha(80)
                      : AppColors.neutralBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_off_outlined,
                    size: 18,
                    color: _isAnonymous
                        ? AppColors.primary
                        : AppColors.neutralMid,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submit Anonymously',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isAnonymous
                                ? AppColors.primary
                                : AppColors.neutralDark,
                          ),
                        ),
                        Text(
                          'Your name and email will not be shared',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnonymous,
                    onChanged: (val) => setState(() => _isAnonymous = val),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Feedback Card (history)
class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FeedbackCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final isPending  = status == 'pending';
    final category = data['category'] as String? ?? 'General';
    final message = data['message'] as String? ?? '';
    final reply = data['reply'] as String?;
    final isAnon = data['isAnonymous'] as bool? ?? false;
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final repliedAt  = data['repliedAt'] != null
        ? (data['repliedAt'] as Timestamp).toDate()
        : null;

    final statusColor = isPending ? AppColors.warning : AppColors.success;
    final statusLabel = isPending ? 'Pending' : 'Replied';
    final statusIcon = isPending
        ? Icons.hourglass_top_rounded
        : Icons.check_circle_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withAlpha(60)
              : AppColors.success.withAlpha(60),
          width: 1,
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(10),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xl),
                topRight: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Row(
              children: [
                // Category chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(60),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    category,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                if (isAnon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutralLight,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: AppColors.neutralBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Anonymous',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutralMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const Spacer(),

                // Status badge
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Message
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTextStyles.body.copyWith(fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatDate(createdAt),
                  style: AppTextStyles.caption,
                ),

                // Admin Reply
                if (!isPending && reply != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(10),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.success.withAlpha(60),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.support_agent_rounded,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Admin Reply',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            if (repliedAt != null)
                              Text(
                                _formatDate(repliedAt),
                                style: AppTextStyles.caption,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          reply,
                          style: AppTextStyles.body.copyWith(fontSize: 14),
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
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// Section Label
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.neutralMid,
        letterSpacing: 1.4,
      ),
    );
  }
}