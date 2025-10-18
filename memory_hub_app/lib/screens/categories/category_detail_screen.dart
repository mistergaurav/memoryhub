import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Category', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 10,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            title: Text('Memory $index', style: GoogleFonts.inter()),
            subtitle: const Text('In this category'),
          ),
        ),
      ),
    );
  }
}
