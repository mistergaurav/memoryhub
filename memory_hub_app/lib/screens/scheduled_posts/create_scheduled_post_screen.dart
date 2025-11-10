import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateScheduledPostScreen extends StatelessWidget {
  const CreateScheduledPostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Post', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title))),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(labelText: 'Content', prefixIcon: Icon(Icons.description)), maxLines: 5),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Schedule for'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                label: 'Schedule',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
