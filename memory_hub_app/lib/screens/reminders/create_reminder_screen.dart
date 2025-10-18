import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Reminder', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date & Time'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Create Reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
