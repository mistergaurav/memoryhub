import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import '../../services/api_service.dart';

class PasswordResetConfirmScreen extends StatefulWidget {
  final String? token;

  const PasswordResetConfirmScreen({super.key, this.token});

  @override
  State<PasswordResetConfirmScreen> createState() => _PasswordResetConfirmScreenState();
}

class _PasswordResetConfirmScreenState extends State<PasswordResetConfirmScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _resetSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _tokenController.text = widget.token!;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.resetPassword(
        _tokenController.text,
        _passwordController.text,
      );
      setState(() => _resetSuccess = true);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Error: ${e.toString()}',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set New Password'),
      ),
      body: SingleChildScrollView(
        child: Padded.lg(
          child: _resetSuccess ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VGap.xl(),
          Icon(
            Icons.vpn_key,
            size: 80,
            color: context.colors.primary,
          ),
          const VGap.md(),
          Text(
            'Create new password',
            style: context.text.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const VGap.sm(),
          Text(
            'Your new password must be different from previously used passwords.',
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const VGap.xl(),
          TextFormField(
            controller: _tokenController,
            decoration: InputDecoration(
              labelText: 'Reset Token',
              hintText: 'Enter the token from your email',
              prefixIcon: const Icon(Icons.confirmation_number),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: Radii.lgRadius,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: Radii.lgRadius,
                borderSide: BorderSide(
                  color: context.colors.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: Radii.lgRadius,
                borderSide: BorderSide(
                  color: context.colors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: context.colors.surfaceVariant.withOpacity(0.3),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the reset token';
              }
              return null;
            },
          ),
          const VGap.md(),
          TextFormField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: 'At least 8 characters',
              prefixIcon: const Icon(Icons.lock_outline),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: Radii.lgRadius,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: Radii.lgRadius,
                borderSide: BorderSide(
                  color: context.colors.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: Radii.lgRadius,
                borderSide: BorderSide(
                  color: context.colors.primary,
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _passwordVisible = !_passwordVisible);
                },
              ),
              filled: true,
              fillColor: context.colors.surfaceVariant.withOpacity(0.3),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const VGap.md(),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_confirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: Radii.lgRadius,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: Radii.lgRadius,
                borderSide: BorderSide(
                  color: context.colors.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: Radii.lgRadius,
                borderSide: BorderSide(
                  color: context.colors.primary,
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _confirmPasswordVisible = !_confirmPasswordVisible);
                },
              ),
              filled: true,
              fillColor: context.colors.surfaceVariant.withOpacity(0.3),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const VGap.lg(),
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: context.colors.secondaryContainer,
              borderRadius: Radii.lgRadius,
              border: Border.all(color: context.colors.secondary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tips_and_updates, color: context.colors.secondary, size: 20),
                    const HGap.xs(),
                    Text(
                      'Password Tips:',
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
                const VGap.xs(),
                _buildPasswordTip('At least 8 characters'),
                _buildPasswordTip('Include upper & lowercase letters'),
                _buildPasswordTip('Include numbers and symbols'),
              ],
            ),
          ),
          const VGap.lg(),
          PrimaryButton(
            onPressed: _handleSubmit,
            label: _isLoading ? 'Resetting...' : 'Reset Password',
            leading: _isLoading ? null : const Icon(Icons.check),
            isLoading: _isLoading,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: Spacing.xxs, top: Spacing.xxs),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: context.colors.secondary),
          const HGap.xs(),
          Text(
            text,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const VGap.xl(),
        Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 80,
            color: context.colors.primary,
          ),
        ),
        const VGap.lg(),
        Text(
          'Password Reset!',
          style: context.text.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const VGap.sm(),
        Text(
          'Your password has been successfully reset.',
          style: context.text.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const VGap.xl(),
        PrimaryButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          },
          label: 'Go to Login',
          leading: const Icon(Icons.login),
          fullWidth: true,
        ),
      ],
    );
  }
}
