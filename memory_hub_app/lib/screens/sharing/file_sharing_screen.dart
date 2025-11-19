import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../design_system/design_system.dart';

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
        title: Text(
          'Shared Files',
          style: context.text.titleLarge?.copyWith(fontWeight: MemoryHubTypography.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sharedFiles.isEmpty
              ? _buildEmptyState(context)
              : _buildFilesList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 80, color: MemoryHubColors.gray500.withOpacity(0.5)),
          const VGap.lg(),
          Text(
            'No Shared Files',
            style: context.text.headlineSmall?.copyWith(
              fontWeight: MemoryHubTypography.bold,
            ),
          ),
          const VGap.sm(),
          Text(
            'Share files with others using secure links',
            style: context.text.bodyLarge?.copyWith(
              color: MemoryHubColors.gray500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.xl),
      itemCount: _sharedFiles.length,
      itemBuilder: (context, index) {
        final file = _sharedFiles[index];
        return _buildFileCard(file);
      },
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: AppCard(
        child: ListTile(
        contentPadding: const EdgeInsets.all(Spacing.lg),
        leading: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colors.primary.withOpacity(0.2),
                context.colors.secondary.withOpacity(0.2),
              ],
            ),
            borderRadius: MemoryHubBorderRadius.mdRadius,
          ),
          child: Icon(
            Icons.share,
            color: context.colors.primary,
            size: 24,
          ),
        ),
        title: Text(
          file['file_name'] ?? 'Untitled',
          style: context.text.bodyLarge?.copyWith(
            fontWeight: MemoryHubTypography.semiBold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VGap.xs(),
            Text(
              'Expires: ${file['expires_at'] ?? 'Never'}',
              style: context.text.bodySmall?.copyWith(
                color: MemoryHubColors.gray500,
              ),
            ),
            const VGap.sm(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xxs,
              ),
              decoration: BoxDecoration(
                color: MemoryHubColors.green500.withOpacity(0.1),
                borderRadius: MemoryHubBorderRadius.smRadius,
              ),
              child: Text(
                '${file['access_count'] ?? 0} views',
                style: context.text.labelSmall?.copyWith(
                  fontWeight: MemoryHubTypography.semiBold,
                  color: MemoryHubColors.green500,
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
      ),
    );
  }

  void _copyShareLink(String link) {
    AppSnackbar.success(context, 'Share link copied to clipboard');
  }
}
