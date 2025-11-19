import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/components/surfaces/app_card.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Category', style: GoogleFonts.inter(fontWeight: MemoryHubTypography.bold)),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(MemoryHubSpacing.xl),
        itemCount: 10,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: MemoryHubSpacing.md),
          child: AppCard(
            child: ListTile(
              title: Text('Memory $index', style: GoogleFonts.inter()),
              subtitle: const Text('In this category'),
            ),
          ),
        ),
      ),
    );
  }
}
