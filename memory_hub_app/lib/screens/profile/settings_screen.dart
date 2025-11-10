import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memory_hub_app/design_system/design_system.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkMode = false;
  String _privacyLevel = 'public';
  bool _showOnlineStatus = true;
  bool _allowTagging = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _privacyLevel = prefs.getString('privacy_level') ?? 'public';
      _showOnlineStatus = prefs.getBool('show_online_status') ?? true;
      _allowTagging = prefs.getBool('allow_tagging') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setString('privacy_level', _privacyLevel);
    await prefs.setBool('show_online_status', _showOnlineStatus);
    await prefs.setBool('allow_tagging', _allowTagging);
    
    if (mounted) {
      AppSnackbar.success(context, 'Settings saved successfully',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSection(
            'Notifications',
            Icons.notifications,
            [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive all notifications'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive notifications via email'),
                value: _emailNotifications,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _emailNotifications = value);
                      }
                    : null,
              ),
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive push notifications'),
                value: _pushNotifications,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _pushNotifications = value);
                      }
                    : null,
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            'Appearance',
            Icons.palette,
            [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                },
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            'Security',
            Icons.security,
            [
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Two-Factor Authentication'),
                subtitle: const Text('Add extra security to your account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/2fa/setup'),
              ),
              ListTile(
                leading: const Icon(Icons.vpn_key),
                title: const Text('Change Password'),
                subtitle: const Text('Update your password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/profile/password'),
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Blocked Users'),
                subtitle: const Text('Manage blocked accounts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/privacy/blocked'),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            'Privacy',
            Icons.privacy_tip,
            [
              ListTile(
                title: const Text('Profile Privacy'),
                subtitle: Text(_privacyLevel == 'public' 
                    ? 'Everyone can see your profile'
                    : _privacyLevel == 'friends' 
                        ? 'Only friends can see your profile'
                        : 'Only you can see your profile'),
                trailing: DropdownButton<String>(
                  value: _privacyLevel,
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                    DropdownMenuItem(value: 'friends', child: Text('Friends')),
                    DropdownMenuItem(value: 'private', child: Text('Private')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _privacyLevel = value);
                    }
                  },
                ),
              ),
              SwitchListTile(
                title: const Text('Show Online Status'),
                subtitle: const Text('Let others see when you\'re online'),
                value: _showOnlineStatus,
                onChanged: (value) {
                  setState(() => _showOnlineStatus = value);
                },
              ),
              SwitchListTile(
                title: const Text('Allow Tagging'),
                subtitle: const Text('Let others tag you in memories'),
                value: _allowTagging,
                onChanged: (value) {
                  setState(() => _allowTagging = value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Advanced Privacy Settings'),
                subtitle: const Text('Manage detailed privacy controls'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/privacy/settings'),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            'GDPR & Data Rights',
            Icons.gavel,
            [
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Export My Data'),
                subtitle: const Text('Download a copy of your data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/gdpr/export'),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Consent Management'),
                subtitle: const Text('Manage your data usage consent'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/gdpr/consent'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Permanently delete your account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/gdpr/delete'),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            'Content & Creation',
            Icons.create,
            [
              ListTile(
                leading: const Icon(Icons.auto_stories),
                title: const Text('Stories'),
                subtitle: const Text('Create and view 24-hour stories'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/stories'),
              ),
              ListTile(
                leading: const Icon(Icons.mic),
                title: const Text('Voice Notes'),
                subtitle: const Text('Record voice memories'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/voice-notes'),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Memory Templates'),
                subtitle: const Text('Use and create templates'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/templates'),
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Scheduled Posts'),
                subtitle: const Text('View and manage scheduled content'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/scheduled-posts'),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            'Organization & Discovery',
            Icons.apps,
            [
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Advanced Search'),
                subtitle: const Text('Search all your content'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/search'),
              ),
              ListTile(
                leading: const Icon(Icons.label),
                title: const Text('Tags Management'),
                subtitle: const Text('Organize and manage your tags'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/tags/management'),
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Categories'),
                subtitle: const Text('Manage content categories'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/categories'),
              ),
              ListTile(
                leading: const Icon(Icons.place),
                title: const Text('Places & Locations'),
                subtitle: const Text('Manage your places'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/places'),
              ),
              ListTile(
                leading: const Icon(Icons.comment),
                title: const Text('Comments'),
                subtitle: const Text('View and manage comments'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/comments', arguments: {'targetId': '', 'targetType': 'all'}),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            'Social & Community',
            Icons.groups,
            [
              ListTile(
                leading: const Icon(Icons.hub),
                title: const Text('Social Hubs'),
                subtitle: const Text('Join and manage hubs'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/social/hubs'),
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('User Search'),
                subtitle: const Text('Find and connect with people'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/social/search'),
              ),
              ListTile(
                leading: const Icon(Icons.collections),
                title: const Text('Collections'),
                subtitle: const Text('Organize your memories'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/collections'),
              ),
              ListTile(
                leading: const Icon(Icons.feed),
                title: const Text('Activity Feed'),
                subtitle: const Text('See what\'s happening'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/activity'),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('Reactions'),
                subtitle: const Text('View reactions on content'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/reactions', arguments: {'targetId': '', 'targetType': 'all'}),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            'Sharing & Notifications',
            Icons.notifications,
            [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Sharing & Links'),
                subtitle: const Text('Manage your shared content'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/sharing/management'),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('Reminders'),
                subtitle: const Text('Manage your reminders'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/reminders'),
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Analytics'),
                subtitle: const Text('View your statistics'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/analytics'),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            'Family Hub',
            Icons.family_restroom,
            [
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Family Dashboard'),
                subtitle: const Text('Main family hub'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/family'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_album),
                title: const Text('Family Albums'),
                subtitle: const Text('Shared photo albums'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/family/albums'),
              ),
              ListTile(
                leading: const Icon(Icons.timeline),
                title: const Text('Family Timeline'),
                subtitle: const Text('View family history'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/family/timeline'),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Family Calendar'),
                subtitle: const Text('Events and birthdays'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/family/calendar'),
              ),
              ListTile(
                leading: const Icon(Icons.stars),
                title: const Text('Family Milestones'),
                subtitle: const Text('Important life events'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/family/milestones'),
              ),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Family Recipes'),
                subtitle: const Text('Shared recipe collection'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/family/recipes'),
              ),
              ListTile(
                leading: const Icon(Icons.mail),
                title: const Text('Legacy Letters'),
                subtitle: const Text('Letters to the future'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/family/letters'),
              ),
              ListTile(
                leading: const Icon(Icons.celebration),
                title: const Text('Family Traditions'),
                subtitle: const Text('Family customs and traditions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/family/traditions'),
              ),
              ListTile(
                leading: const Icon(Icons.account_tree),
                title: const Text('Genealogy Tree'),
                subtitle: const Text('Explore your family tree'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/family/genealogy'),
              ),
              ListTile(
                leading: const Icon(Icons.health_and_safety),
                title: const Text('Health Records'),
                subtitle: const Text('Family health information'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/family/health'),
              ),
              ListTile(
                leading: const Icon(Icons.folder_special),
                title: const Text('Document Vault'),
                subtitle: const Text('Important family documents'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/family/vault'),
              ),
              ListTile(
                leading: const Icon(Icons.child_care),
                title: const Text('Parental Controls'),
                subtitle: const Text('Manage family safety'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/family/parental-controls'),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            'Data & Storage',
            Icons.storage,
            [
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Export & Backup'),
                subtitle: const Text('Export your memories and files'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/export'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Clear Cache'),
                subtitle: const Text('Free up storage space'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Cache'),
                      content: const Text('This will clear all cached data. Continue?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cache cleared successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            'About',
            Icons.info,
            [
              ListTile(
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showAboutDialog();
                },
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoonDialog('Terms of Service');
                },
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoonDialog('Privacy Policy');
                },
              ),
              ListTile(
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoonDialog('Help & Support');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: Spacing.edgeInsetsOnly(left: Spacing.md, top: Spacing.lg, right: Spacing.md, bottom: Spacing.xs),
          child: Row(
            children: [
              Icon(icon, size: 20, color: context.colors.primary),
              const HGap.sm(),
              Text(
                title,
                style: context.text.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About The Memory Hub'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            VGap.sm(),
            Text('The Memory Hub - Your Family\'s Digital Legacy'),
            VGap.md(),
            Text('A platform to preserve and share your precious memories with loved ones.'),
          ],
        ),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.pop(context),
            label: 'Close',
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.pop(context),
            label: 'OK',
          ),
        ],
      ),
    );
  }
}
