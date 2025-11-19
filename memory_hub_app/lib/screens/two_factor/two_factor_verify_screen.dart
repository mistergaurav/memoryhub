import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import 'package:memory_hub_app/design_system/design_tokens.dart';

class TwoFactorVerifyScreen extends StatelessWidget {
  const TwoFactorVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verify 2FA Code',
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padded.lg(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: context.colors.primary,
            ),
            const VGap.lg(),
            Text(
              'Enter Verification Code',
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const VGap.sm(),
            Text(
              'Enter the 6-digit code from your authenticator app',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const VGap.xl(),
            TextField(
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: context.text.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: MemoryHubSpacing.lg,
                  vertical: MemoryHubSpacing.xl,
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
            const VGap.xl(),
            PrimaryButton(
              onPressed: () {},
              label: 'Verify',
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
