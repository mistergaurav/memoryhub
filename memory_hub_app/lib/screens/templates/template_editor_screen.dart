import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TemplateEditorScreen extends StatelessWidget {
  const TemplateEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Template Editor', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Template Name', prefixIcon: Icon(Icons.title))),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Add Field'),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                label: 'Save Template',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
