import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _apiService.getPrivacySettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings() async {
    try {
      await _apiService.updatePrivacySettings(_settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Settings', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Profile Visibility',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            title: 'Public Profile',
            subtitle: 'Anyone can view your profile',
            value: _settings['profile_visibility'] == 'public',
            onChanged: (value) {
              setState(() {
                _settings['profile_visibility'] = value ? 'public' : 'private';
              });
              _updateSettings();
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Activity Visibility',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            title: 'Show Activity',
            subtitle: 'Let others see your activity',
            value: _settings['show_activity'] ?? false,
            onChanged: (value) {
              setState(() {
                _settings['show_activity'] = value;
              });
              _updateSettings();
            },
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            title: 'Show Followers',
            subtitle: 'Display your followers list',
            value: _settings['show_followers'] ?? true,
            onChanged: (value) {
              setState(() {
                _settings['show_followers'] = value;
              });
              _updateSettings();
            },
          ),
          const SizedBox(height: 24),
          _buildBlockedUsersCard(),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBlockedUsersCard() {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/privacy/blocked');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.block, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blocked Users',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage blocked users',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
