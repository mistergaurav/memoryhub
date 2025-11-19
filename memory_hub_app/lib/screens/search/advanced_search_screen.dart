import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/layout/gap.dart';

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
        title: Text('Advanced Search', style: GoogleFonts.inter(fontWeight: MemoryHubTypography.bold)),
      ),
      body: ListView(
        padding: EdgeInsets.all(MemoryHubSpacing.xl),
        children: [
          Text('Content Type', style: GoogleFonts.inter(fontSize: 16, fontWeight: MemoryHubTypography.bold)),
          VGap(MemoryHubSpacing.md),
          Wrap(
            spacing: MemoryHubSpacing.sm,
            children: ['all', 'memories', 'files', 'people'].map((type) {
              return ChoiceChip(
                label: Text(type),
                selected: _contentType == type,
                onSelected: (selected) => setState(() => _contentType = type),
              );
            }).toList(),
          ),
          VGap(MemoryHubSpacing.xxl),
          Text('Date Range', style: GoogleFonts.inter(fontSize: 16, fontWeight: MemoryHubTypography.bold)),
          VGap(MemoryHubSpacing.md),
          DropdownButtonFormField<String>(
            value: _dateRange,
            items: ['any', 'today', 'week', 'month', 'year'].map((range) {
              return DropdownMenuItem(value: range, child: Text(range));
            }).toList(),
            onChanged: (value) => setState(() => _dateRange = value!),
          ),
          VGap(MemoryHubSpacing.xxl),
          SwitchListTile(
            title: Text('Has Media', style: GoogleFonts.inter()),
            value: _hasMedia,
            onChanged: (value) => setState(() => _hasMedia = value),
          ),
          VGap(MemoryHubSpacing.xxxl),
          FilledButton(
            onPressed: () {},
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
