import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import '../../widgets/collapsible_settings_group.dart';
import '../../widgets/modern_list_tile.dart';
import '../../design_system/layout/padded.dart';

class AccountSecurityScreen extends StatelessWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Security'),
        elevation: 0,
      ),
      body: Padded.lg(
        child: ListView(
          children: [
          CollapsibleSettingsGroup(
            title: 'Authentication',
            icon: Icons.lock_outline,
            children: [
              VGap.sm(),
              ModernListTile(
                icon: Icons.vpn_key,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () => _navigateToChangePassword(context),
              ),
              VGap.sm(),
              ModernListTile(
                icon: Icons.security,
                title: 'Two-Factor Authentication',
                subtitle: 'Add extra security to your account',
                onTap: () => _navigateToTwoFactor(context),
              ),
              VGap.sm(),
            ],
          ),
          VGap.md(),
          CollapsibleSettingsGroup(
            title: 'Privacy Control',
            icon: Icons.visibility_outlined,
            children: [
              VGap.sm(),
              ModernListTile(
                icon: Icons.block,
                title: 'Blocked Users',
                subtitle: 'Manage blocked accounts',
                onTap: () => _navigateToBlockedUsers(context),
              ),
              VGap.sm(),
              ModernListTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Settings',
                subtitle: 'Control your privacy preferences',
                onTap: () => _navigateToPrivacySettings(context),
              ),
              VGap.sm(),
            ],
          ),
          VGap.md(),
          CollapsibleSettingsGroup(
            title: 'Account Management',
            icon: Icons.manage_accounts,
            children: [
              VGap.sm(),
              ModernListTile(
                icon: Icons.person,
                title: 'Edit Profile',
                subtitle: 'Update your profile information',
                onTap: () => _navigateToEditProfile(context),
              ),
              VGap.sm(),
            ],
          ),
        ],
        ),
      ),
    );
  }

  static void _navigateToChangePassword(BuildContext context) {
    Navigator.pushNamed(context, '/profile/password');
  }

  static void _navigateToTwoFactor(BuildContext context) {
    Navigator.pushNamed(context, '/2fa/setup');
  }

  static void _navigateToBlockedUsers(BuildContext context) {
    Navigator.pushNamed(context, '/privacy/blocked');
  }

  static void _navigateToPrivacySettings(BuildContext context) {
    Navigator.pushNamed(context, '/privacy/settings');
  }

  static void _navigateToEditProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile/edit');
  }
}
