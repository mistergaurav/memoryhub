import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _verify2FA() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.verifyEnable2FA(_codeController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA enabled successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _disable2FA() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disable 2FA?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to disable two-factor authentication?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.disable2FA();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('2FA disabled')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Two-Factor Authentication', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
    );
  }

  Widget _buildInitialView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                Icons.security,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Secure Your Account',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add an extra layer of security to your account with two-factor authentication',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'How it works',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildStep(1, 'Scan QR Code', 'Use an authenticator app to scan the QR code'),
        _buildStep(2, 'Enter Code', 'Enter the 6-digit code from your app'),
        _buildStep(3, 'All Set!', 'Your account is now extra secure'),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _enable2FA,
            icon: const Icon(Icons.shield),
            label: const Text('Enable 2FA'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
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
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use Google Authenticator or similar app',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        if (_setupData?['qr_code'] != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                  color: Colors.grey[300],
                  child: const Center(
                    child: Text('QR Code Here'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Secret Key',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _setupData?['secret'] ?? '',
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 32),
        Text(
          'Enter Verification Code',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isLoading ? null : _verify2FA,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Verify and Enable'),
          ),
        ),
      ],
    );
  }

  Widget _buildEnabledView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.1),
                Colors.green.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                '2FA is Enabled',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account is protected with two-factor authentication',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _disable2FA,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: const BorderSide(color: Colors.red),
            ),
            child: Text(
              'Disable 2FA',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey,
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
