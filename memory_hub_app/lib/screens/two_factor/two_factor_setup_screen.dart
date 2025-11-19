import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import 'package:memory_hub_app/design_system/design_tokens.dart';
import '../../services/api_service.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _codeController = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _setupData;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _check2FAStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _check2FAStatus() async {
    try {
      final status = await _apiService.get2FAStatus();
      setState(() {
        _isEnabled = status['enabled'] ?? false;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _enable2FA() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.enable2FA();
      setState(() {
        _setupData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackbar.error(context, 'Error: ${e.toString()}');
      }
    }
  }

  Future<void> _verify2FA() async {
    if (_codeController.text.length != 6) {
      AppSnackbar.info(context, 'Please enter a 6-digit code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.verifyEnable2FA(_codeController.text);
      if (mounted) {
        AppSnackbar.success(context, '2FA enabled successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackbar.error(context, 'Verification failed: ${e.toString()}');
      }
    }
  }

  Future<void> _disable2FA() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Disable 2FA?',
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to disable two-factor authentication?',
          style: context.text.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.disable2FA();
        if (mounted) {
          AppSnackbar.success(context, '2FA disabled');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.error(context, 'Error: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Two-Factor Authentication',
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padded.lg(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEnabled && _setupData == null) ...[
                _buildEnabledView(),
              ] else if (_setupData != null) ...[
                _buildSetupView(),
              ] else ...[
                _buildInitialView(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(MemoryHubSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colors.primary.withOpacity(0.1),
                context.colors.secondary.withOpacity(0.1),
              ],
            ),
            borderRadius: MemoryHubBorderRadius.xlRadius,
          ),
          child: Column(
            children: [
              Icon(
                Icons.security,
                size: 64,
                color: context.colors.primary,
              ),
              const VGap.md(),
              Text(
                'Secure Your Account',
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const VGap.xs(),
              Text(
                'Add an extra layer of security to your account with two-factor authentication',
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const VGap.xl(),
        Text(
          'How it works',
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const VGap.md(),
        _buildStep(1, 'Scan QR Code', 'Use an authenticator app to scan the QR code'),
        _buildStep(2, 'Enter Code', 'Enter the 6-digit code from your app'),
        _buildStep(3, 'All Set!', 'Your account is now extra secure'),
        const VGap.xl(),
        PrimaryButton(
          onPressed: _isLoading ? null : _enable2FA,
          label: 'Enable 2FA',
          leading: const Icon(Icons.shield),
          isLoading: _isLoading,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSetupView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Scan QR Code',
          style: context.text.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const VGap.xs(),
        Text(
          'Use Google Authenticator or similar app',
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const VGap.lg(),
        if (_setupData?['qr_code'] != null)
          Container(
            padding: const EdgeInsets.all(MemoryHubSpacing.lg),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: MemoryHubBorderRadius.xlRadius,
              boxShadow: [
                BoxShadow(
                  color: context.colors.shadow.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  color: context.colors.surfaceVariant,
                  child: Center(
                    child: Text(
                      'QR Code Here',
                      style: context.text.bodyMedium,
                    ),
                  ),
                ),
                const VGap.md(),
                Text(
                  'Secret Key',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const VGap.xxs(),
                Container(
                  padding: const EdgeInsets.all(MemoryHubSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                  child: Text(
                    _setupData?['secret'] ?? '',
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        const VGap.xl(),
        Text(
          'Enter Verification Code',
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const VGap.md(),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: context.text.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
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
        ),
        const VGap.lg(),
        PrimaryButton(
          onPressed: _isLoading ? null : _verify2FA,
          label: 'Verify and Enable',
          isLoading: _isLoading,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildEnabledView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(MemoryHubSpacing.xxl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colors.primaryContainer,
                context.colors.primaryContainer.withOpacity(0.5),
              ],
            ),
            borderRadius: MemoryHubBorderRadius.xlRadius,
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: context.colors.primary,
              ),
              const VGap.md(),
              Text(
                '2FA is Enabled',
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const VGap.xs(),
              Text(
                'Your account is protected with two-factor authentication',
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const VGap.xl(),
        SecondaryButton(
          onPressed: _disable2FA,
          label: 'Disable 2FA',
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStep(int number, String title, String description) {
    return Padded.only(
      bottom: MemoryHubSpacing.lg,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
          const HGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
