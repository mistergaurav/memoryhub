import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateVoiceNoteScreen extends StatefulWidget {
  const CreateVoiceNoteScreen({super.key});

  @override
  State<CreateVoiceNoteScreen> createState() => _CreateVoiceNoteScreenState();
}

class _CreateVoiceNoteScreenState extends State<CreateVoiceNoteScreen> {
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record Voice Note', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                ),
              ),
              child: IconButton(
                icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 60, color: Colors.white),
                onPressed: () => setState(() => _isRecording = !_isRecording),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isRecording ? 'Recording...' : 'Tap to record',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
