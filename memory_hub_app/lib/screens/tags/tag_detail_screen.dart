import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/components/surfaces/app_card.dart';

class TagDetailScreen extends StatelessWidget {
  final String tag;

  const TagDetailScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('#$tag', style: GoogleFonts.inter(fontWeight: MemoryHubTypography.bold)),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(MemoryHubSpacing.xl),
        itemCount: 10,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: MemoryHubSpacing.md),
          child: AppCard(
            child: ListTile(
              title: Text('Memory $index', style: GoogleFonts.inter()),
              subtitle: Text('Tagged with $tag'),
            ),
          ),
        ),
      ),
    );
  }
}
