import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TagDetailScreen extends StatelessWidget {
  final String tag;

  const TagDetailScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('#$tag', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 10,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Memory $index', style: GoogleFonts.inter()),
            subtitle: Text('Tagged with $tag'),
          ),
        ),
      ),
    );
  }
}
