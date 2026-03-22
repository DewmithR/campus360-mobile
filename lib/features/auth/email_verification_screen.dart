import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isSending = false;
  bool _canResend = false;
  int  _secondsRemaining = 60;
  bool _isCheckingVerified = false;

  Timer? _resendTimer;
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
    _startVerificationListener();
  }

  void _startResendCooldown() {
    setState(() {
      _canResend        = false;
      _secondsRemaining = 60;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) _secondsRemaining--;
      });
      if (_secondsRemaining <= 0) {
        timer.cancel();
        if (mounted) setState(() => _canResend = true);
      }
    });
  }

  void _startVerificationListener() {
    _verificationTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        timer.cancel();
        return;
      }
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        timer.cancel();
        if (mounted) {
          // AuthWrapper will automatically navigate to dashboard
          setState(() {});
        }
      }
    });
  }

  Future<void> _resendVerification() async {
    setState(() => _isSending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (mounted) {
          _startResendCooldown();
          _showSnackBar(' Verification email sent!');
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Failed to send verification email.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _checkManually() async {
    setState(() => _isCheckingVerified = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && refreshedUser.emailVerified) {
          // AuthWrapper will detect and redirect automatically
          if (mounted) setState(() {});
        } else {
          if (mounted) {
            _showSnackBar('Email not verified yet. Please check your inbox.');
          }
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Could not check verification status.');
    } finally {
      if (mounted) setState(() => _isCheckingVerified = false);
    }
  }

  Future<void> _cancelAndGoBack() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _verificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              //  Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xl,
                  AppSpacing.lg, AppSpacing.xl,
                ),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(AppRadius.xl),
                    bottomRight: Radius.circular(AppRadius.xl),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x30000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Verify Your Email',
                      style: AppTextStyles.heading1.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Campus 360 · NSBM Green University',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withAlpha(200),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              // Body Card
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Container(
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
                      // Email info
                      Text(
                        'Check your inbox. Check the spam/junk folder if you can\'t find the email.',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'We sent a verification link to:',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(10),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(60),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          email,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Steps
                      _StepTile(
                        number: '1',
                        text:   'Open your NSBM student email inbox',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _StepTile(
                        number: '2',
                        text:   'Click the verification link in the email',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _StepTile(
                        number: '3',
                        text:   'Come back and tap "I\'ve Verified" below',
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Check verified button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isCheckingVerified ? null : _checkManually,
                          icon: _isCheckingVerified
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            _isCheckingVerified
                                ? 'Checking...'
                                : "I've Verified My Email",
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Resend verification email button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: (_canResend && !_isSending)
                              ? _resendVerification
                              : null,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            _isSending
                                ? 'Sending...'
                                : _canResend
                                    ? 'Resend Verification Email'
                                    : 'Resend in $_secondsRemaining s',
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Back to login
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _cancelAndGoBack,
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Back to Login'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.neutralMid,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  '© ${DateTime.now().year} Campus 360. All rights reserved.',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Step Tile
class _StepTile extends StatelessWidget {
  final String number;
  final String text;

  const _StepTile({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: AppTextStyles.bodySmall),
        ),
      ],
    );
  }
}
