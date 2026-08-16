import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/social_login_button.dart';
import '../../data/services/auth_api_service.dart';
import 'widgets/auth_header.dart';
import 'widgets/terms_checkbox.dart';

/// "Create Account" registration screen.
///
/// Mirrors [LoginScreen]'s structure (shared [AuthHeader], form card,
/// social sign-in, footer link) but with the extra fields/validation a
/// sign-up form needs: full name, confirm-password matching, and a
/// required terms-of-service acknowledgement.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthApiService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;
  final bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final formValid = _formKey.currentState!.validate();

    if (!_agreedToTerms) {
      _showError('Please agree to the Terms of Service and Privacy Policy.');
      return;
    }
    if (!formValid) return;

    setState(() => _isSubmitting = true);
    try {
      await _authService.signUp(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Signup Screen → Login Screen (after successful signup). Uses
      // pushReplacementNamed so the signup form isn't left on the stack.
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Cannot reach server. Is the backend running?');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign-in coming soon. Use email/password for now.')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email address is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Include at least one uppercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Include at least one digit';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(
                title: 'Create Account',
                subtitle: 'Join us and start planning your EV routes',
              ),

              Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow(theme.brightness),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Full Name',
                          hint: 'John Doe',
                          prefixIcon: Icons.person_outline_rounded,
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          validator: _validateName,
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          label: 'Email Address',
                          hint: 'your.email@example.com',
                          prefixIcon: Icons.mail_outline_rounded,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          label: 'Password',
                          hint: 'Create a strong password',
                          prefixIcon: Icons.lock_outline_rounded,
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: theme.hintColor,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
                          prefixIcon: Icons.lock_outline_rounded,
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          validator: _validateConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: theme.hintColor,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TermsCheckbox(
                          value: _agreedToTerms,
                          onChanged: (v) => setState(() => _agreedToTerms = v),
                          onTermsTap: () => _showInfoSnackBar('Terms of Service'),
                          onPrivacyTap: () => _showInfoSnackBar('Privacy Policy'),
                        ),
                        const SizedBox(height: 18),
                        PrimaryButton(
                          label: 'Sign Up',
                          isLoading: _isSubmitting,
                          onPressed: _handleSignUp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ---- Social sign-in + footer link ----
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    const OrDivider(label: 'or sign up with'),
                    const SizedBox(height: 18),
                    SocialLoginButton(
                      label: 'Continue with Google',
                      isLoading: _isGoogleLoading,
                      onPressed: _handleGoogleSignIn,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: theme.textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Login',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoSnackBar(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label coming soon.')),
    );
  }
}
