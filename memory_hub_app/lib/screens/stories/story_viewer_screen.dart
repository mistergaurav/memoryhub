import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StoryViewerScreen extends StatelessWidget {
  final String storyId;

  const StoryViewerScreen({super.key, required this.storyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            Center(child: Text('Story Content', style: GoogleFonts.inter(color: Colors.white, fontSize: 24))),
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: LinearProgressIndicator(value: 0.5, backgroundColor: Colors.white.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }
}
