import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/gdpr_service.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({Key? key}) : super(key: key);

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _isLoading = false;
  bool _isExporting = false;
  List<Map<String, dynamic>> _exportHistory = [];
  final GdprService _gdprService = GdprService();

  @override
  void initState() {
    super.initState();
    _loadExportHistory();
  }

  Future<void> _loadExportHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _gdprService.getExportHistory();
      setState(() {
        _exportHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _exportHistory = [];
      });
    }
  }

  Future<void> _exportData(String type) async {
    setState(() => _isExporting = true);
    try {
      if (type == 'JSON') {
        await _gdprService.requestDataExport('json');
      } else {
        await _gdprService.requestDataExport('archive');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type export started. You will receive a download link soon.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadExportHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Your Data'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.purple.shade400],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.download, color: Colors.indigo.shade400),
                        const SizedBox(width: 8),
                        const Text(
                          'Data Portability',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Under GDPR Article 20, you have the right to receive your personal data '
                      'in a structured, commonly used, and machine-readable format.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Export Options',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildExportOption(
              title: 'JSON Export',
              description: 'Download all your data in JSON format',
              icon: Icons.code,
              iconColor: Colors.blue,
              onTap: () => _exportData('JSON'),
            ),
            _buildExportOption(
              title: 'Complete Archive',
              description: 'Download all data including files as ZIP',
              icon: Icons.archive,
              iconColor: Colors.orange,
              onTap: () => _exportData('Archive'),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Export History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadExportHistory,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _exportHistory.isEmpty
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'No export history',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _exportHistory.length,
                        itemBuilder: (context, index) {
                          final export = _exportHistory[index];
                          return Card(
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  export['type'] == 'JSON' ? Icons.code : Icons.archive,
                                  color: Colors.green,
                                ),
                              ),
                              title: Text(
                                '${export['type']} Export',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${DateFormat.yMMMd().format(export['date'])} • ${export['size']}',
                              ),
                              trailing: Chip(
                                label: Text(export['status']),
                                backgroundColor: Colors.green.shade50,
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: _isExporting ? null : onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description),
        trailing: _isExporting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
