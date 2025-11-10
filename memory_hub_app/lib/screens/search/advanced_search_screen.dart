import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  String _contentType = 'all';
  String _dateRange = 'any';
  bool _hasMedia = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Search', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Content Type', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['all', 'memories', 'files', 'people'].map((type) {
              return ChoiceChip(
                label: Text(type),
                selected: _contentType == type,
                onSelected: (selected) => setState(() => _contentType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Date Range', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _dateRange,
            items: ['any', 'today', 'week', 'month', 'year'].map((range) {
              return DropdownMenuItem(value: range, child: Text(range));
            }).toList(),
            onChanged: (value) => setState(() => _dateRange = value!),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: Text('Has Media', style: GoogleFonts.inter()),
            value: _hasMedia,
            onChanged: (value) => setState(() => _hasMedia = value),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {},
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
