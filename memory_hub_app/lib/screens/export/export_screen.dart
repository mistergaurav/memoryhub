import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ApiService _apiService = ApiService();
  bool _isExporting = false;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Export & Backup', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Your Data',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download your memories and files in various formats',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            if (_isExporting) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Exporting... ${(_progress * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _progress),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            _buildExportOption(
              icon: Icons.description,
              title: 'Export Memories (JSON)',
              description: 'Download all your memories as JSON',
              color: Colors.blue,
              onTap: () => _exportMemoriesJson(),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              icon: Icons.folder_zip,
              title: 'Export Files (ZIP)',
              description: 'Download all vault files as a ZIP archive',
              color: Colors.orange,
              onTap: () => _exportFilesZip(),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              icon: Icons.backup,
              title: 'Full Backup',
              description: 'Complete backup including all data and files',
              color: Colors.purple,
              onTap: () => _exportFullBackup(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isExporting ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _exportMemoriesJson() async {
    setState(() {
      _isExporting = true;
      _progress = 0.0;
    });

    try {
      await _apiService.exportMemoriesJson();
      setState(() => _progress = 1.0);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memories exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportFilesZip() async {
    setState(() {
      _isExporting = true;
      _progress = 0.0;
    });

    try {
      await _apiService.exportFilesZip();
      setState(() => _progress = 1.0);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Files exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportFullBackup() async {
    setState(() {
      _isExporting = true;
      _progress = 0.0;
    });

    try {
      await _apiService.exportFullBackup();
      setState(() => _progress = 1.0);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Full backup created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }
}
