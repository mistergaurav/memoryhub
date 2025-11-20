import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'qr_code_screen.dart';
import '../../design_system/design_system.dart';
import '../../design_system/layout/padded.dart';

class ShareManagementScreen extends StatefulWidget {
  const ShareManagementScreen({Key? key}) : super(key: key);

  @override
  State<ShareManagementScreen> createState() => _ShareManagementScreenState();
}

class _ShareManagementScreenState extends State<ShareManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _shares = [];

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  Future<void> _loadShares() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Load from API endpoint /api/v1/sharing/my-shares
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _shares = [
          {
            'id': '1',
            'resource_type': 'memory',
            'resource_title': 'Summer Vacation 2024',
            'token': 'abc123xyz',
            'password_protected': true,
            'expires_at': DateTime.now().add(const Duration(days: 7)),
            'max_uses': 10,
            'use_count': 3,
            'created_at': DateTime.now().subtract(const Duration(days: 2)),
          },
          {
            'id': '2',
            'resource_type': 'collection',
            'resource_title': 'Family Photos',
            'token': 'def456uvw',
            'password_protected': false,
            'expires_at': null,
            'max_uses': null,
            'use_count': 15,
            'created_at': DateTime.now().subtract(const Duration(days: 10)),
          },
          {
            'id': '3',
            'resource_type': 'file',
            'resource_title': 'Birthday_Video.mp4',
            'token': 'ghi789rst',
            'password_protected': false,
            'expires_at': DateTime.now().add(const Duration(days: 1)),
            'max_uses': 5,
            'use_count': 5,
            'created_at': DateTime.now().subtract(const Duration(days: 5)),
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeShare(String shareId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Share Link'),
        content: const Text('Are you sure you want to revoke this share link? It will no longer be accessible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // TODO: Call API endpoint DELETE /api/v1/sharing/revoke/{shareId}
      await Future.delayed(const Duration(milliseconds: 500));
      _loadShares();
      if (mounted) {
        AppSnackbar.success(context, 'Share link revoked successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to revoke share: $e');
      }
    }
  }

  void _viewQRCode(Map<String, dynamic> share) {
    final shareUrl = 'https://example.com/share/${share['token']}';
    // Navigate to QR code screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeScreen(
          shareUrl: shareUrl,
          title: share['resource_title'],
          description: 'Shared ${share['resource_type']}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shares'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [MemoryHubColors.indigo500, MemoryHubColors.purple500],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShares,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shares.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, size: 64, color: MemoryHubColors.gray400),
                      VGap.lg(),
                      Text(
                        'No active shares',
                        style: context.text.titleMedium?.copyWith(
                          color: MemoryHubColors.gray600,
                        ),
                      ),
                      VGap.sm(),
                      Text(
                        'Share memories, collections, or files to see them here',
                        style: context.text.bodyMedium?.copyWith(
                          color: MemoryHubColors.gray500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(Spacing.lg),
                  itemCount: _shares.length,
                  itemBuilder: (context, index) {
                    final share = _shares[index];
                    final isExpired = share['expires_at'] != null &&
                        (share['expires_at'] as DateTime).isBefore(DateTime.now());
                    final isMaxedOut = share['max_uses'] != null &&
                        share['use_count'] >= share['max_uses'];
                    final isActive = !isExpired && !isMaxedOut;

                    return Padding(
                      padding: EdgeInsets.only(bottom: Spacing.md),
                      child: AppCard(
                        child: Padded.lg(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _getResourceIcon(share['resource_type']),
                                HGap.md(),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        share['resource_title'],
                                        style: context.text.bodyLarge?.copyWith(
                                          fontWeight: MemoryHubTypography.bold,
                                        ),
                                      ),
                                      Text(
                                        share['resource_type'].toUpperCase(),
                                        style: context.text.bodySmall?.copyWith(
                                          color: MemoryHubColors.gray600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    isActive ? 'Active' : (isExpired ? 'Expired' : 'Maxed Out'),
                                    style: context.text.labelSmall,
                                  ),
                                  backgroundColor: isActive
                                      ? MemoryHubColors.green500.withOpacity(0.1)
                                      : MemoryHubColors.red500.withOpacity(0.1),
                                  labelStyle: TextStyle(
                                    color: isActive ? MemoryHubColors.green600 : MemoryHubColors.red600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: MemoryHubSpacing.xxl),
                            Wrap(
                              spacing: Spacing.lg,
                              runSpacing: Spacing.sm,
                              children: [
                                if (share['password_protected'])
                                  _buildInfoChip(context, Icons.lock, 'Password Protected'),
                                if (share['expires_at'] != null)
                                  _buildInfoChip(
                                    context,
                                    Icons.calendar_today,
                                    'Expires ${DateFormat.yMMMd().format(share['expires_at'])}',
                                  ),
                                if (share['max_uses'] != null)
                                  _buildInfoChip(
                                    context,
                                    Icons.visibility,
                                    '${share['use_count']}/${share['max_uses']} uses',
                                  ),
                                if (share['max_uses'] == null)
                                  _buildInfoChip(
                                    context,
                                    Icons.visibility,
                                    '${share['use_count']} views',
                                  ),
                              ],
                            ),
                            VGap.lg(),
                            Row(
                              children: [
                                Expanded(
                                  child: SecondaryButton(
                                    onPressed: () => _viewQRCode(share),
                                    label: 'QR Code',
                                    leading: const Icon(Icons.qr_code, size: 18),
                                  ),
                                ),
                                HGap.sm(),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _revokeShare(share['id']),
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    label: const Text('Revoke'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: MemoryHubColors.red500,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _getResourceIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'memory':
        icon = Icons.photo_library;
        color = MemoryHubColors.blue500;
        break;
      case 'collection':
        icon = Icons.collections;
        color = MemoryHubColors.purple500;
        break;
      case 'file':
        icon = Icons.insert_drive_file;
        color = MemoryHubColors.amber500;
        break;
      default:
        icon = Icons.share;
        color = MemoryHubColors.gray500;
    }

    return Container(
      padding: EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: MemoryHubBorderRadius.smRadius,
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: context.text.labelSmall),
      backgroundColor: MemoryHubColors.gray100,
      labelPadding: EdgeInsets.symmetric(horizontal: Spacing.xxs),
      visualDensity: VisualDensity.compact,
    );
  }
}
