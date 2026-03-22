import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'email_verification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Data
const List<String> kFaculties = ['FOB', 'FOC', 'FOE/FOS'];

const List<String> kDegrees = [
  // Business
  'BBM (Hons) in Business Analytics',
  'Bachelor of Business: Management and Innovation & Supply Chain and Logistics Management',
  'BBM (Hons) in Applied Economics',
  'BBM (Hons) Tourism, Hospitality & Events',
  'BSc in Multimedia',
  'BA in Business Communication',
  'BBM (Hons) in Accounting and Finance',
  'BSc (Hons) Business Communication',
  'BBM (Hons) in International Business',
  'BSc (Hons) Events, Tourism and Hospitality Management',
  'BSc in Business Management (Industrial Management) (Special)',
  'BSc (Hons) Operations and Logistics Management',
  'BSc in Business Management (Project Management) (Special)',
  'BSc (Hons) Marketing Management',
  'BSc in Business Management (Logistics Management) (Special)',
  'BSc (Hons) Accounting and Finance',
  'BSc in Business Management (Human Resource Management) (Special)',
  'BSc (Hons) International Management and Business',
  'Bachelor of Laws (Honours)',
  'LLB (Hons) Law',
  'BBM (Hons) in Marketing Management',
  'BBM (Hons) in Law and Business Studies',
  'BBM (Hons.) in Law and International Trade',
  'BBM (Hons) in Law and E-Commerce',
  'Bachelor of Science in Business Administration (BSBA)',
  'Bachelor of Business',
  // Computing
  'BSc (Hons) in Data Science',
  'BSc (Hons) in Computer Networks',
  'BSc (Hons) in Computer Science',
  'BSc (Hons) in Software Engineering',
  'BSc in Management Information Systems (Special)',
  'Bachelor of Information Technology (Major in Cyber Security)',
  'BSc (Hons) in Technology Management',
  'BSc (Hons) in Computer Security',
  'BSc (Hons) in Artificial Intelligence',
  // Engineering
  'Bachelor of Science of Engineering Honours in Mechatronic Engineering',
  'Bachelor of Science of Engineering Honours in Electrical and Electronic Engineering',
  'Bachelor of Science of Engineering Honours in Computer Engineering',
  'Bachelor of Interior Design',
  'BSc (Hons) in Quantity Surveying',
  'BSc (Hons) in Quantity Surveying Top-Up Degree',
  'BA (Hons) in Interior Design',
  'BEng (Hons) in Electrical, Electronics, and Communication Engineering (Plymouth University United Kingdom)',
  'BEng (Hons) in Civil and Structural Engineering (Plymouth University United Kingdom)',
  'BEng (Hons) in Mechanical and Mechatronics (Plymouth University United Kingdom)',
  'BEng (Hons) in Robotics and Automation Engineering (Plymouth University United Kingdom)',
  'BSc (Hons) in Biomedical Science',
  'BSc (Honours) in Pharmaceutical Science',
  'BSc (Hons) in Nutrition and Health',
  'BSc (Hons) in Psychology',
  'BSc (Hons) in Nursing',
  'BSc (Hons) in Nursing Top up',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _sidController = TextEditingController();
  final _batchController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String? _selectedDegree;
  String? _selectedFaculty;

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _sidController.dispose();
    _batchController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final nsbmRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@students\.nsbm\.ac\.lk$');
    if (!nsbmRegex.hasMatch(value)) return 'Use a valid NSBM student email';
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your phone number';
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value)) return 'Enter a valid 10-digit phone number';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDegree == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your degree')),
      );
      return;
    }
    if (_selectedFaculty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your faculty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
    // Check phone uniqueness
      final phoneQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: _phoneController.text.trim())
          .limit(1)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This phone number is already registered.'),
            ),
          );
        }
        return;
      }

      // Check SID uniqueness
      final sidQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('sid', isEqualTo: _sidController.text.trim())
          .limit(1)
          .get();

      if (sidQuery.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This Student ID is already registered.'),
            ),
          );
        }
        return;
      }
      await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        sid:  _sidController.text.trim(),
        batch: _batchController.text.trim(),
        degree: _selectedDegree!,
        faculty: _selectedFaculty!,
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _RegisterHeader(),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
                ),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create Account', style: AppTextStyles.heading1),
                        const SizedBox(height: 4),
                        Text(
                          'Join Campus 360 with your NSBM student email',
                          style: AppTextStyles.bodySmall,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Section label 
                        _SectionLabel(label: 'PERSONAL INFORMATION'),
                        const SizedBox(height: AppSpacing.sm),

                        // Full name
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Please enter your name'
                              : null,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // SID
                        TextFormField(
                          controller: _sidController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: ' NSBM Student ID',
                            hintText: 'e.g. 36363',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Please enter your Student ID'
                              : null,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: '07XXXXXXXX',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: _phoneValidator,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Section label
                        _SectionLabel(label: 'ACADEMIC INFORMATION'),
                        const SizedBox(height: AppSpacing.sm),

                        // Faculty dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _selectedFaculty,
                          decoration: const InputDecoration(
                            labelText: 'Faculty',
                            prefixIcon: Icon(Icons.account_balance_outlined),
                          ),
                          hint: const Text('Select your faculty'),
                          items: kFaculties.map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedFaculty = v),
                          validator: (v) =>
                              v == null ? 'Please select your faculty' : null,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Batch
                        TextFormField(
                          controller: _batchController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Batch',
                            hintText: 'e.g. 25.1',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Please enter your batch'
                              : null,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Degree dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDegree,
                          decoration: const InputDecoration(
                            labelText: 'Degree Programme',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          hint: const Text('Select your degree'),
                          isExpanded: true,
                          items: kDegrees.map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              d,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedDegree = v),
                          validator: (v) =>
                              v == null ? 'Please select your degree' : null,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Section label
                        _SectionLabel(label: 'ACCOUNT CREDENTIALS'),
                        const SizedBox(height: AppSpacing.sm),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Student Email',
                            hintText: 'you@students.nsbm.ac.lk',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _emailValidator,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePass,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Minimum 6 characters',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Minimum 6 characters'
                              : null,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Confirm password
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Re-enter your password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) => v != _passwordController.text
                              ? 'Passwords do not match'
                              : null,
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // NSBM email note
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm + 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppColors.accent.withAlpha(100),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Only @students.nsbm.ac.lk emails are accepted.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Register button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Create Account'),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Login link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: AppTextStyles.bodySmall,
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  '© ${DateTime.now().year} Campus 360. All rights reserved.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

// Register Header
class _RegisterHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 250,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Campus 360',
            style: AppTextStyles.heading1.copyWith(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Student Registration',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withAlpha(200),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
