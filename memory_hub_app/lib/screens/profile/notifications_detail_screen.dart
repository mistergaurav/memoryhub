import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import '../../widgets/collapsible_settings_group.dart';
import '../../design_system/layout/padded.dart';
import '../../providers/notifications_provider.dart';

class NotificationsDetailScreen extends StatefulWidget {
  const NotificationsDetailScreen({super.key});

  @override
  State<NotificationsDetailScreen> createState() => _NotificationsDetailScreenState();
}

class _NotificationsDetailScreenState extends State<NotificationsDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationsProvider>(context, listen: false).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, child) {
          if (provider.settingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = provider.settings;
          
          // Helper to safely get bool value
          bool getVal(String key) => settings[key] ?? true;
          
          // Helper to update setting
          void update(String key, bool value) {
            final newSettings = Map<String, bool>.from(settings);
            newSettings[key] = value;
            provider.updateSettings(newSettings);
          }

          return Padded.lg(
            child: ListView(
              children: [
                CollapsibleSettingsGroup(
                  title: 'General',
                  icon: Icons.settings,
                  children: [
                    SwitchListTile(
                      title: const Text('Email Notifications'),
                      subtitle: const Text('Receive important updates via email'),
                      value: getVal('email_notifications'),
                      onChanged: (val) => update('email_notifications', val),
                    ),
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Receive notifications on this device'),
                      value: getVal('push_notifications'),
                      onChanged: (val) => update('push_notifications', val),
                    ),
                  ],
                ),
                VGap.md(),
                CollapsibleSettingsGroup(
                  title: 'Activity',
                  icon: Icons.notifications_active,
                  children: [
                    SwitchListTile(
                      title: const Text('Health Updates'),
                      subtitle: const Text('New health records and status changes'),
                      value: getVal('health_updates'),
                      onChanged: (val) => update('health_updates', val),
                    ),
                    SwitchListTile(
                      title: const Text('Family Activity'),
                      subtitle: const Text('New members and family updates'),
                      value: getVal('family_activity'),
                      onChanged: (val) => update('family_activity', val),
                    ),
                    SwitchListTile(
                      title: const Text('Memories'),
                      subtitle: const Text('New memories and comments'),
                      value: getVal('memories'),
                      onChanged: (val) => update('memories', val),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
