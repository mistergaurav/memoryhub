import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TagsManagementScreen extends StatelessWidget {
  const TagsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Tags', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.tag),
              title: Text('Family', style: GoogleFonts.inter()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
