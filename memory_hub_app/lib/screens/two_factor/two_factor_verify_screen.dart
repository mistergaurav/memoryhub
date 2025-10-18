import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TwoFactorVerifyScreen extends StatelessWidget {
  const TwoFactorVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify 2FA Code', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: const InputDecoration(hintText: '000000'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
