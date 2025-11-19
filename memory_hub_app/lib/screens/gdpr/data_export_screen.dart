import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/gdpr_service.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/layout/gap.dart';
import '../../design_system/components/surfaces/app_card.dart';

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
            backgroundColor: MemoryHubColors.green500,
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
          decoration: const BoxDecoration(
            gradient: MemoryHubGradients.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MemoryHubSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              padding: EdgeInsets.all(MemoryHubSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.download, color: MemoryHubColors.indigo400),
                      const HGap.xs(),
                      Text(
                        'Data Portability',
                        style: TextStyle(
                          fontSize: MemoryHubTypography.h4,
                          fontWeight: MemoryHubTypography.bold,
                        ),
                      ),
                    ],
                  ),
                  const VGap.sm(),
                  Text(
                    'Under GDPR Article 20, you have the right to receive your personal data '
                    'in a structured, commonly used, and machine-readable format.',
                    style: TextStyle(color: MemoryHubColors.gray600),
                  ),
                ],
              ),
            ),
            const VGap.lg(),
            Text(
              'Export Options',
              style: TextStyle(
                fontSize: MemoryHubTypography.h3,
                fontWeight: MemoryHubTypography.bold,
              ),
            ),
            const VGap.md(),
            _buildExportOption(
              title: 'JSON Export',
              description: 'Download all your data in JSON format',
              icon: Icons.code,
              iconColor: MemoryHubColors.blue500,
              onTap: () => _exportData('JSON'),
            ),
            _buildExportOption(
              title: 'Complete Archive',
              description: 'Download all data including files as ZIP',
              icon: Icons.archive,
              iconColor: MemoryHubColors.amber500,
              onTap: () => _exportData('Archive'),
            ),
            const VGap.xl(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Export History',
                  style: TextStyle(
                    fontSize: MemoryHubTypography.h3,
                    fontWeight: MemoryHubTypography.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadExportHistory,
                ),
              ],
            ),
            const VGap.md(),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _exportHistory.isEmpty
                    ? AppCard(
                        padding: EdgeInsets.all(MemoryHubSpacing.xxl),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: MemoryHubSpacing.xxxl,
                                color: MemoryHubColors.gray400,
                              ),
                              const VGap.xs(),
                              Text(
                                'No export history',
                                style: TextStyle(color: MemoryHubColors.gray600),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _exportHistory.length,
                        itemBuilder: (context, index) {
                          final export = _exportHistory[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: MemoryHubSpacing.sm),
                            child: AppCard(
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(MemoryHubSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: MemoryHubColors.gray100,
                                    borderRadius: MemoryHubBorderRadius.smRadius,
                                  ),
                                  child: Icon(
                                    export['type'] == 'JSON' ? Icons.code : Icons.archive,
                                    color: MemoryHubColors.green500,
                                  ),
                                ),
                                title: Text(
                                  '${export['type']} Export',
                                  style: TextStyle(fontWeight: MemoryHubTypography.semiBold),
                                ),
                                subtitle: Text(
                                  '${DateFormat.yMMMd().format(export['date'])} • ${export['size']}',
                                ),
                                trailing: Chip(
                                  label: Text(export['status']),
                                  backgroundColor: MemoryHubColors.gray100,
                                ),
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
    return Padding(
      padding: EdgeInsets.only(bottom: MemoryHubSpacing.sm),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: _isExporting ? null : onTap,
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(MemoryHubSpacing.md),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: MemoryHubBorderRadius.smRadius,
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: MemoryHubTypography.semiBold),
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
      ),
    );
  }
}
