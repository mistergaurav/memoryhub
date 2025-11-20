import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import '../../services/api_service.dart';

class PasswordResetRequestScreen extends StatefulWidget {
  const PasswordResetRequestScreen({super.key});

  @override
  State<PasswordResetRequestScreen> createState() => _PasswordResetRequestScreenState();
}

class _PasswordResetRequestScreenState extends State<PasswordResetRequestScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.requestPasswordReset(_emailController.text);
      setState(() => _emailSent = true);
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
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        child: Padded.lg(
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
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
            Icons.lock_reset,
            size: 80,
            color: context.colors.primary,
          ),
          const VGap.md(),
          Text(
            'Forgot your password?',
            style: context.text.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const VGap.sm(),
          Text(
            'Enter your email address and we\'ll send you instructions to reset your password.',
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const VGap.xl(),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'your@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
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
              filled: true,
              fillColor: context.colors.surfaceVariant.withOpacity(0.3),
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
          const VGap.lg(),
          PrimaryButton(
            onPressed: _handleSubmit,
            label: _isLoading ? 'Sending...' : 'Send Reset Link',
            leading: _isLoading ? null : const Icon(Icons.send),
            isLoading: _isLoading,
            fullWidth: true,
          ),
          const VGap.md(),
          SecondaryButton(
            onPressed: () => Navigator.pop(context),
            label: 'Back to Login',
            leading: const Icon(Icons.arrow_back),
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const VGap.xl(),
        Padded.xl(
          child: Container(
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
        ),
        const VGap.lg(),
        Text(
          'Check your email!',
          style: context.text.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const VGap.sm(),
        Text(
          'We\'ve sent password reset instructions to:',
          style: context.text.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const VGap.xs(),
        Text(
          _emailController.text,
          style: context.text.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
        ),
        const VGap.xl(),
        Padded.lg(
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.tertiaryContainer,
              borderRadius: MemoryHubBorderRadius.lgRadius,
              border: Border.all(color: context.colors.tertiary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: context.colors.tertiary),
                const HGap.sm(),
                Expanded(
                  child: Text(
                    'The link will expire in 1 hour for security reasons.',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const VGap.lg(),
        SecondaryButton(
          onPressed: () => Navigator.pop(context),
          label: 'Back to Login',
          leading: const Icon(Icons.arrow_back),
          fullWidth: true,
        ),
        const VGap.md(),
        TextButton(
          onPressed: () {
            setState(() => _emailSent = false);
          },
          child: const Text('Try a different email'),
        ),
      ],
    );
  }
}
