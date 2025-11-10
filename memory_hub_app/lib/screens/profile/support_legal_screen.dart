import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import '../../widgets/collapsible_settings_group.dart';
import '../../widgets/modern_list_tile.dart';

class SupportLegalScreen extends StatelessWidget {
  const SupportLegalScreen({super.key});

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Memory Hub',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.auto_awesome, size: 48),
      children: const [
        Text('A beautiful place to preserve and share your memories.'),
      ],
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    AppDialog.info(
      context,
      title: feature,
      message: 'This feature is coming soon!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Legal'),
      ),
      body: ListView(
        padding: Spacing.edgeInsetsAll(Spacing.lg),
        children: [
          CollapsibleSettingsGroup(
            title: 'Data Rights (GDPR)',
            icon: Icons.gavel,
            children: [
              const VGap.sm(),
              ModernListTile(
                icon: Icons.file_download,
                title: 'Export My Data',
                subtitle: 'Download a copy of your data',
                onTap: () => Navigator.pushNamed(context, '/gdpr/export'),
              ),
              const VGap.sm(),
              ModernListTile(
                icon: Icons.check_circle,
                title: 'Consent Management',
                subtitle: 'Manage your data usage consent',
                onTap: () => Navigator.pushNamed(context, '/gdpr/consent'),
              ),
              const VGap.sm(),
              ModernListTile(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                isDestructive: true,
                onTap: () => Navigator.pushNamed(context, '/gdpr/delete'),
              ),
              const VGap.sm(),
            ],
          ),
          const VGap.md(),
          CollapsibleSettingsGroup(
            title: 'Help & Support',
            icon: Icons.help_outline,
            children: [
              const VGap.sm(),
              ModernListTile(
                icon: Icons.contact_support,
                title: 'Help & Support',
                subtitle: 'Get help with Memory Hub',
                onTap: () => _showComingSoonDialog(context, 'Help & Support'),
              ),
              const VGap.sm(),
              ModernListTile(
                icon: Icons.bug_report,
                title: 'Report a Bug',
                subtitle: 'Help us improve Memory Hub',
                onTap: () => _showComingSoonDialog(context, 'Bug Report'),
              ),
              const VGap.sm(),
            ],
          ),
          const VGap.md(),
          CollapsibleSettingsGroup(
            title: 'Legal & About',
            icon: Icons.info_outline,
            children: [
              const VGap.sm(),
              ModernListTile(
                icon: Icons.description,
                title: 'Terms of Service',
                onTap: () => _showComingSoonDialog(context, 'Terms of Service'),
              ),
              const VGap.sm(),
              ModernListTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                onTap: () => _showComingSoonDialog(context, 'Privacy Policy'),
              ),
              const VGap.sm(),
              ModernListTile(
                icon: Icons.info,
                title: 'About Memory Hub',
                subtitle: 'Version 1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
              const VGap.sm(),
            ],
          ),
        ],
      ),
    );
  }
}
