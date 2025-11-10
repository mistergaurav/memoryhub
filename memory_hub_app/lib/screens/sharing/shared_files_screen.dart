import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SharedFilesScreen extends StatelessWidget {
  const SharedFilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shared with Me', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 10,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text('Shared File $index', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('Shared by User Name', style: GoogleFonts.inter(fontSize: 13)),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'download', label: 'Download'),
                const PopupMenuItem(value: 'remove', label: 'Remove Access'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
