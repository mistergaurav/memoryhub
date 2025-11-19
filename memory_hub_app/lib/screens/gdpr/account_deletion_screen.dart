import 'package:flutter/material.dart';
import '../../services/gdpr_service.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/components/buttons/danger_button.dart';
import '../../design_system/components/buttons/primary_button.dart';
import '../../design_system/components/inputs/text_field_x.dart';
import '../../design_system/layout/gap.dart';
import '../../design_system/components/surfaces/app_card.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({Key? key}) : super(key: key);

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  bool _isProcessing = false;
  bool _hasPendingDeletion = false;
  DateTime? _deletionScheduledDate;
  final TextEditingController _confirmationController = TextEditingController();
  final GdprService _gdprService = GdprService();

  @override
  void initState() {
    super.initState();
    _checkDeletionStatus();
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _checkDeletionStatus() async {
    try {
      final status = await _gdprService.getDeletionStatus();
      setState(() {
        _hasPendingDeletion = status['pending'] ?? false;
        if (status['scheduled_date'] != null) {
          _deletionScheduledDate = DateTime.parse(status['scheduled_date']);
        }
      });
    } catch (e) {
      setState(() {
        _hasPendingDeletion = false;
        _deletionScheduledDate = null;
      });
    }
  }

  Future<void> _requestDeletion() async {
    if (_confirmationController.text.toLowerCase() != 'delete my account') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please type the confirmation text exactly as shown'),
          backgroundColor: MemoryHubColors.red500,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Are you absolutely sure? This action will permanently delete '
          'your account and all associated data after 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: MemoryHubColors.red500,
            ),
            child: const Text('Yes, Delete My Account'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await _gdprService.requestAccountDeletion();
      setState(() {
        _hasPendingDeletion = true;
        _deletionScheduledDate = DateTime.now().add(const Duration(days: 30));
        _isProcessing = false;
        _confirmationController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deletion scheduled. You have 30 days to cancel.'),
            backgroundColor: MemoryHubColors.amber500,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule deletion: $e')),
        );
      }
    }
  }

  Future<void> _cancelDeletion() async {
    setState(() => _isProcessing = true);
    try {
      await _gdprService.cancelAccountDeletion();
      setState(() {
        _hasPendingDeletion = false;
        _deletionScheduledDate = null;
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deletion cancelled successfully'),
            backgroundColor: MemoryHubColors.green500,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel deletion: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        elevation: 0,
        backgroundColor: MemoryHubColors.red600,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MemoryHubSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasPendingDeletion) ...[
              AppCard(
                color: MemoryHubColors.amber50,
                padding: EdgeInsets.all(MemoryHubSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: MemoryHubColors.amber700,
                          size: MemoryHubSpacing.xxl,
                        ),
                        const HGap.sm(),
                        Expanded(
                          child: Text(
                            'Deletion Scheduled',
                            style: TextStyle(
                              fontSize: MemoryHubTypography.h4,
                              fontWeight: MemoryHubTypography.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const VGap.sm(),
                    Text(
                      'Your account is scheduled for deletion on '
                      '${_deletionScheduledDate != null ? _deletionScheduledDate.toString().substring(0, 10) : 'N/A'}.',
                      style: TextStyle(fontSize: MemoryHubTypography.bodyMedium),
                    ),
                    const VGap.xs(),
                    Text(
                      'You can cancel this request anytime before the deletion date.',
                      style: TextStyle(fontSize: MemoryHubTypography.bodySmall),
                    ),
                    const VGap.md(),
                    PrimaryButton(
                      onPressed: _isProcessing ? null : _cancelDeletion,
                      label: 'Cancel Deletion Request',
                      leading: const Icon(Icons.cancel),
                      isLoading: _isProcessing,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
              const VGap.lg(),
            ] else ...[
              AppCard(
                color: MemoryHubColors.red50,
                padding: EdgeInsets.all(MemoryHubSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: MemoryHubColors.red600,
                          size: MemoryHubSpacing.xxl,
                        ),
                        const HGap.sm(),
                        Expanded(
                          child: Text(
                            'Warning',
                            style: TextStyle(
                              fontSize: MemoryHubTypography.h4,
                              fontWeight: MemoryHubTypography.bold,
                              color: MemoryHubColors.red500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const VGap.sm(),
                    Text(
                      'Deleting your account is permanent and cannot be undone.',
                      style: TextStyle(
                        fontSize: MemoryHubTypography.bodyMedium,
                        fontWeight: MemoryHubTypography.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const VGap.lg(),
              Text(
                'What happens when you delete your account?',
                style: TextStyle(
                  fontSize: MemoryHubTypography.h4,
                  fontWeight: MemoryHubTypography.bold,
                ),
              ),
              const VGap.md(),
              _buildInfoItem(
                icon: Icons.delete_forever,
                title: 'All data will be deleted',
                description: 'Memories, files, collections, and all personal data',
              ),
              _buildInfoItem(
                icon: Icons.schedule,
                title: '30-day grace period',
                description: 'You can cancel the deletion within 30 days',
              ),
              _buildInfoItem(
                icon: Icons.lock,
                title: 'Account deactivation',
                description: 'Your account will be immediately deactivated',
              ),
              _buildInfoItem(
                icon: Icons.no_accounts,
                title: 'No recovery',
                description: 'After 30 days, recovery will be impossible',
              ),
              const VGap.xl(),
              Text(
                'Type "DELETE MY ACCOUNT" to confirm:',
                style: TextStyle(
                  fontSize: MemoryHubTypography.h5,
                  fontWeight: MemoryHubTypography.semiBold,
                ),
              ),
              const VGap.sm(),
              TextFieldX(
                controller: _confirmationController,
                hint: 'DELETE MY ACCOUNT',
              ),
              const VGap.lg(),
              DangerButton(
                onPressed: _isProcessing ? null : _requestDeletion,
                label: 'Request Account Deletion',
                isLoading: _isProcessing,
                fullWidth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: MemoryHubSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(MemoryHubSpacing.sm),
            decoration: BoxDecoration(
              color: MemoryHubColors.red50,
              borderRadius: MemoryHubBorderRadius.smRadius,
            ),
            child: Icon(
              icon,
              color: MemoryHubColors.red600,
              size: MemoryHubSpacing.xl,
            ),
          ),
          const HGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: MemoryHubTypography.semiBold,
                    fontSize: MemoryHubTypography.bodyMedium,
                  ),
                ),
                const VGap.xxs(),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: MemoryHubTypography.bodySmall,
                    color: MemoryHubColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
