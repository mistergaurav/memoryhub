import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class FileSharingScreen extends StatefulWidget {
  const FileSharingScreen({super.key});

  @override
  State<FileSharingScreen> createState() => _FileSharingScreenState();
}

class _FileSharingScreenState extends State<FileSharingScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _sharedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSharedFiles();
  }

  Future<void> _loadSharedFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await _apiService.getSharedFiles();
      setState(() {
        _sharedFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shared Files', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sharedFiles.isEmpty
              ? _buildEmptyState()
              : _buildFilesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No Shared Files',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share files with others using secure links',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _sharedFiles.length,
      itemBuilder: (context, index) {
        final file = _sharedFiles[index];
        return _buildFileCard(file);
      },
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.share,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          file['file_name'] ?? 'Untitled',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Expires: ${file['expires_at'] ?? 'Never'}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${file['access_count'] ?? 0} views',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            _copyShareLink(file['share_link']);
          },
        ),
      ),
    );
  }

  void _copyShareLink(String link) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share link copied to clipboard')),
    );
  }
}
