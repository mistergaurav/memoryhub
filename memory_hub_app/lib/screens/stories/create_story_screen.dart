import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateStoryScreen extends StatelessWidget {
  const CreateStoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Create Story', style: GoogleFonts.inter(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 80, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
