import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:memory_hub_app/design_system/design_tokens.dart';
import 'package:memory_hub_app/design_system/layout/gap.dart';
import 'package:memory_hub_app/design_system/layout/padded.dart';
import 'package:memory_hub_app/design_system/components/buttons/primary_button.dart';
import 'package:memory_hub_app/design_system/components/buttons/secondary_button.dart';
import 'package:memory_hub_app/design_system/components/feedback/app_snackbar.dart';
import 'package:memory_hub_app/design_system/utils/context_ext.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: MemoryHubAnimations.slow,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: MemoryHubAnimations.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: MemoryHubAnimations.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signup(
        _emailController.text.trim(),
        _passwordController.text,
        _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
      );

      if (mounted) {
        AppSnackbar.success(
          context,
          'Welcome! Your account has been created successfully.',
        );
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MemoryHubSpacing.lg,
        vertical: MemoryHubSpacing.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.lgRadius,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.lgRadius,
        borderSide: BorderSide(
          color: context.colors.outline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.lgRadius,
        borderSide: BorderSide(
          color: context.colors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.lgRadius,
        borderSide: BorderSide(
          color: context.colors.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.lgRadius,
        borderSide: BorderSide(
          color: context.colors.error,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.colors.surface,
              context.colors.secondaryContainer.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padded.lg(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(MemoryHubSpacing.lg),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: MemoryHubGradients.secondary,
                            ),
                            child: Icon(
                              Icons.person_add,
                              size: 64,
                              color: context.colors.onPrimary,
                            ),
                          ),
                          const VGap.lg(),
                          Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: context.text.headlineMedium?.copyWith(
                              fontWeight: MemoryHubTypography.bold,
                              color: context.colors.onSurface,
                            ),
                          ),
                          const VGap.xs(),
                          Text(
                            'Join us and start preserving your memories',
                            textAlign: TextAlign.center,
                            style: context.text.bodyLarge?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          const VGap.xl(),
                          TextFormField(
                            controller: _fullNameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            decoration: _buildInputDecoration(
                              label: 'Full Name',
                              icon: Icons.person,
                              hint: 'Optional',
                            ),
                          ),
                          const VGap.md(),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: kIsWeb ? TextInputType.text : TextInputType.emailAddress,
                            decoration: _buildInputDecoration(
                              label: 'Email',
                              icon: Icons.email,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const VGap.md(),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _buildInputDecoration(
                              label: 'Password',
                              icon: Icons.lock,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                                return 'Password must contain at least one letter';
                              }
                              if (!RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                                return 'Password must contain a number or special character';
                              }
                              return null;
                            },
                          ),
                          const VGap.lg(),
                          PrimaryButton(
                            onPressed: _handleSignup,
                            label: 'Sign Up',
                            isLoading: _isLoading,
                            fullWidth: true,
                          ),
                          const VGap.md(),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              const HGap.md(),
                              Text(
                                'OR',
                                style: context.text.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              const HGap.md(),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const VGap.md(),
                          SecondaryButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    AppSnackbar.info(
                                      context,
                                      'Google Sign In coming soon! Please add your Google OAuth credentials to enable this feature.',
                                    );
                                  },
                            label: 'Continue with Google',
                            leading: const Icon(Icons.login),
                            fullWidth: true,
                          ),
                          const VGap.md(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: context.text.bodyMedium,
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context).pop();
                                      },
                                child: const Text('Login'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
