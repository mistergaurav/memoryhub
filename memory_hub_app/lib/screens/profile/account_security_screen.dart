import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/collapsible_settings_group.dart';
import '../../widgets/modern_list_tile.dart';

class AccountSecurityScreen extends StatelessWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Security'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CollapsibleSettingsGroup(
            title: 'Authentication',
            icon: Icons.lock_outline,
            children: [
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.vpn_key,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () => Navigator.pushNamed(context, '/profile/password'),
              ),
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.security,
                title: 'Two-Factor Authentication',
                subtitle: 'Add extra security to your account',
                onTap: () => Navigator.pushNamed(context, '/2fa/setup'),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 16),
          CollapsibleSettingsGroup(
            title: 'Privacy Control',
            icon: Icons.visibility_outlined,
            children: [
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.block,
                title: 'Blocked Users',
                subtitle: 'Manage blocked accounts',
                onTap: () => Navigator.pushNamed(context, '/privacy/blocked'),
              ),
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Settings',
                subtitle: 'Control your privacy preferences',
                onTap: () => Navigator.pushNamed(context, '/privacy/settings'),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 16),
          CollapsibleSettingsGroup(
            title: 'Account Management',
            icon: Icons.manage_accounts,
            children: [
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.person,
                title: 'Edit Profile',
                subtitle: 'Update your profile information',
                onTap: () => Navigator.pushNamed(context, '/profile/edit'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }
}
