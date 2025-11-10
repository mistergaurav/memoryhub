import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/vault_file.dart';
import 'package:intl/intl.dart';

class VaultDetailScreen extends StatefulWidget {
  final String fileId;

  const VaultDetailScreen({super.key, required this.fileId});

  @override
  State<VaultDetailScreen> createState() => _VaultDetailScreenState();
}

class _VaultDetailScreenState extends State<VaultDetailScreen> {
  final ApiService _apiService = ApiService();
  VaultFile? _file;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    setState(() => _isLoading = true);
    try {
      final file = await _apiService.getFile(widget.fileId);
      setState(() {
        _file = file;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _downloadFile() {
    if (_file == null) return;
    final downloadUrl = _apiService.getFileDownloadUrl(_file!.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download URL: $downloadUrl'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _file == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'File not found'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadFile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadFile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _getFileTypeColor(_file!.fileType),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getFileTypeIcon(_file!.fileType),
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _file!.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Type', _file!.fileType.toUpperCase()),
            _buildInfoRow('Size', _file!.formattedSize),
            _buildInfoRow('Privacy', _file!.privacy.toUpperCase()),
            _buildInfoRow('Downloads', '${_file!.downloadCount}'),
            _buildInfoRow(
              'Uploaded',
              DateFormat('MMMM d, yyyy').format(_file!.createdAt),
            ),
            if (_file!.description != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _file!.description!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
            if (_file!.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _file!.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.deepPurple.shade50,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloadFile,
                icon: const Icon(Icons.download),
                label: const Text('Download File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'document':
        return Icons.description;
      case 'audio':
        return Icons.audio_file;
      case 'archive':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'image':
        return Colors.blue;
      case 'video':
        return Colors.red;
      case 'document':
        return Colors.green;
      case 'audio':
        return Colors.orange;
      case 'archive':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
