import 'package:flutter/material.dart';
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
      children: [
        const Text('A beautiful place to preserve and share your memories.'),
      ],
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Legal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CollapsibleSettingsGroup(
            title: 'Data Rights (GDPR)',
            icon: Icons.gavel,
            children: [
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.file_download,
                title: 'Export My Data',
                subtitle: 'Download a copy of your data',
                onTap: () => Navigator.pushNamed(context, '/gdpr/export'),
              ),
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.check_circle,
                title: 'Consent Management',
                subtitle: 'Manage your data usage consent',
                onTap: () => Navigator.pushNamed(context, '/gdpr/consent'),
              ),
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                isDestructive: true,
                onTap: () => Navigator.pushNamed(context, '/gdpr/delete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 16),
          CollapsibleSettingsGroup(
            title: 'Help & Support',
            icon: Icons.help_outline,
            children: [
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.contact_support,
                title: 'Help & Support',
                subtitle: 'Get help with Memory Hub',
                onTap: () => _showComingSoonDialog(context, 'Help & Support'),
              ),
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.bug_report,
                title: 'Report a Bug',
                subtitle: 'Help us improve Memory Hub',
                onTap: () => _showComingSoonDialog(context, 'Bug Report'),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 16),
          CollapsibleSettingsGroup(
            title: 'Legal & About',
            icon: Icons.info_outline,
            children: [
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.description,
                title: 'Terms of Service',
                onTap: () => _showComingSoonDialog(context, 'Terms of Service'),
              ),
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                onTap: () => _showComingSoonDialog(context, 'Privacy Policy'),
              ),
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.info,
                title: 'About Memory Hub',
                subtitle: 'Version 1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }
}
