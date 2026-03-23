import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/app_user.dart';
import '../../core/services/auth_service.dart';
import '../../theme/app_theme.dart';

class AccountPage extends StatelessWidget {
  final AppUser user;

  const AccountPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            _ProfileCard(user: user),

            const SizedBox(height: AppSpacing.lg),

            // Section: Student Information
            _SectionLabel(label: 'STUDENT INFORMATION'),
            const SizedBox(height: AppSpacing.sm),
            _InfoCard(user: user),

            const SizedBox(height: AppSpacing.lg),

            // Section: Account Settings
            _SectionLabel(label: 'ACCOUNT SETTINGS'),
            const SizedBox(height: AppSpacing.sm),

            _SettingsTile(
              icon: Icons.phone_outlined,
              iconColor: AppColors.success,
              title: 'Change Phone Number',
              subtitle: 'Update your contact number',
              onTap: () => _showChangePhoneSheet(context),
            ),

            const SizedBox(height: AppSpacing.sm),

            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              iconColor: AppColors.info,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: () => _showChangePasswordSheet(context),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Section: Danger Zone
            _SectionLabel(label: 'DANGER ZONE'),
            const SizedBox(height: AppSpacing.sm),

            _SettingsTile(
              icon: Icons.delete_forever_rounded,
              iconColor: AppColors.alert,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account and data',
              onTap: () => _showDeleteDialog(context),
              isDanger: true,
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _showChangePhoneSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePhoneSheet(currentPhone: user.phone ?? ''),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all your data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alert,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      await AuthService().deleteAccount();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }
}

// Profile Card
class _ProfileCard extends StatelessWidget {
  final AppUser user;
  const _ProfileCard({required this.user});

  String get _initials {
    final parts = user.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha(200),
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.primary,
                fontSize: 28,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            user.name,
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Text(
            user.email,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withAlpha(180),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: Colors.white.withAlpha(40)),
          const SizedBox(height: AppSpacing.md),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProfileStat(
                label: 'Role',
                value: user.role.toUpperCase(),
                icon: Icons.badge_rounded,
              ),
              Container(width: 1, height: 36, color: Colors.white.withAlpha(40)),
              _ProfileStat(
                label: 'Faculty',
                value: user.faculty ?? '—',
                icon: Icons.account_balance_outlined,
              ),
              Container(width: 1, height: 36, color: Colors.white.withAlpha(40)),
              _ProfileStat(
                label: 'Member Since',
                value: _formatDate(user.createdAt),
                icon: Icons.calendar_today_rounded,
              ),
            ],
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
    return '${months[date.month - 1]} ${date.year}';
  }
}

// Profile Stat
class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withAlpha(160),
          ),
        ),
      ],
    );
  }
}

// Info Card to show student details
class _InfoCard extends StatelessWidget {
  final AppUser user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.neutralBorder, width: 0.8),
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Student ID',
            value: user.sid ?? '—',
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.school_outlined,
            label: 'Degree',
            value: user.degree ?? '—',
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.account_balance_outlined,
            label: 'Faculty',
            value: user.faculty ?? '—',
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Batch',
            value: user.batch ?? '—',
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: user.phone ?? '—',
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.neutralMid),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutralDark,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.neutralBorder);
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

// Settings Tile
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDanger
              ? AppColors.alert.withAlpha(8)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDanger
                ? AppColors.alert.withAlpha(60)
                : AppColors.neutralBorder,
            width: isDanger ? 1.2 : 0.8,
          ),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: iconColor.withAlpha(40),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDanger
                          ? AppColors.alert
                          : AppColors.neutralDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDanger ? AppColors.alert : AppColors.neutralMid,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Change Phone number Bottom Sheet
class _ChangePhoneSheet extends StatefulWidget {
  final String currentPhone;
  const _ChangePhoneSheet({required this.currentPhone});

  @override
  State<_ChangePhoneSheet> createState() => _ChangePhoneSheetState();
}

class _ChangePhoneSheetState extends State<_ChangePhoneSheet> {
  late final TextEditingController _phoneController;
  final _formKey  = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'phone': _phoneController.text.trim()});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Phone number updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update phone: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutralBorder,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Text('Change Phone Number', style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text(
              'Enter your new phone number.',
              style: AppTextStyles.bodySmall,
            ),

            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '07XXXXXXXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter a phone number';
                if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) {
                  return 'Enter a valid 10-digit phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Change Password Bottom Sheet
class _ChangePasswordSheet extends StatefulWidget {
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPass = TextEditingController();
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPass.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPass.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPass.text.trim());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final message = e.code == 'wrong-password'
            ? 'Current password is incorrect.'
            : e.message ?? 'Failed to update password.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutralBorder,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Text('Change Password', style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text(
              'Enter your current password then choose a new one.',
              style: AppTextStyles.bodySmall,
            ),

            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _currentPass,
              obscureText: _obscureCurrent,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Enter your current password'
                  : null,
            ),

            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _newPass,
              obscureText: _obscureNew,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? 'Minimum 6 characters'
                  : null,
            ),

            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _confirmPass,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _changePassword(),
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) => v != _newPass.text
                  ? 'Passwords do not match'
                  : null,
            ),

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Update Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}