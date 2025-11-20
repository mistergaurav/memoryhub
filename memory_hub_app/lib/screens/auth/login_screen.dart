import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_tokens.dart';
import 'package:memory_hub_app/design_system/layout/gap.dart';
import 'package:memory_hub_app/design_system/layout/padded.dart';
import 'package:memory_hub_app/design_system/components/buttons/primary_button.dart';
import 'package:memory_hub_app/design_system/components/buttons/secondary_button.dart';
import 'package:memory_hub_app/design_system/components/feedback/app_snackbar.dart';
import 'package:memory_hub_app/design_system/utils/context_ext.dart';
import '../../services/auth_service.dart';
import '../../design_system/layout/padded.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
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
  }) {
    return InputDecoration(
      labelText: label,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.surface,
              context.colors.primaryContainer.withValues(alpha: 0.1),
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
                            padding: EdgeInsets.all(MemoryHubSpacing.lg),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: MemoryHubGradients.primary,
                            ),
                            child: Icon(
                              Icons.memory,
                              size: 64,
                              color: context.colors.onPrimary,
                            ),
                          ),
                          VGap.lg(),
                          Text(
                            'The Memory Hub',
                            textAlign: TextAlign.center,
                            style: context.text.displaySmall?.copyWith(
                              fontWeight: MemoryHubTypography.bold,
                              color: context.colors.onSurface,
                            ),
                          ),
                          VGap.xs(),
                          Text(
                            'Welcome back! Login to continue',
                            textAlign: TextAlign.center,
                            style: context.text.bodyLarge?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          VGap.xxl(),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
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
                          VGap.md(),
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
                              return null;
                            },
                          ),
                          VGap.lg(),
                          PrimaryButton(
                            onPressed: _handleLogin,
                            label: 'Login',
                            isLoading: _isLoading,
                            fullWidth: true,
                          ),
                          VGap.md(),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              HGap.md(),
                              Text(
                                'OR',
                                style: context.text.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              HGap.md(),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          VGap.md(),
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
                          VGap.md(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: context.text.bodyMedium,
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context).pushNamed('/signup');
                                      },
                                child: const Text('Sign Up'),
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
