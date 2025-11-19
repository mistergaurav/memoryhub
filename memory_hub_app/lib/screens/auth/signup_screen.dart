import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padded.lg(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.person_add,
                      size: 80,
                      color: context.colors.primary,
                    ),
                    const VGap.md(),
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: context.text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const VGap.xl(),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: kIsWeb ? TextInputType.text : TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
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
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email';
                        return null;
                      },
                    ),
                    const VGap.md(),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
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
                        suffixIcon: IconButton(
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
                        // Check for at least one letter
                        if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                          return 'Password must contain at least one letter';
                        }
                        // Check for at least one number or special character
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
                        Padded.symmetric(horizontal: MemoryHubSpacing.lg, child: Text(
                          'OR',
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        )),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const VGap.md(),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : () {
                        AppSnackbar.info(
                          context,
                          'Google Sign In coming soon! Please add your Google OAuth credentials to enable this feature.',
                        );
                      },
                      icon: Icon(Icons.login, color: context.colors.primary),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MemoryHubSpacing.lg,
                          vertical: MemoryHubSpacing.lg,
                        ),
                        side: BorderSide(color: context.colors.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: MemoryHubBorderRadius.lgRadius,
                        ),
                      ),
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
                          onPressed: () {
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
    );
  }
}
