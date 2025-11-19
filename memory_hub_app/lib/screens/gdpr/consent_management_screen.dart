import 'package:flutter/material.dart';
import '../../services/gdpr_service.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/components/buttons/primary_button.dart';
import '../../design_system/layout/gap.dart';
import '../../design_system/components/surfaces/app_card.dart';

class ConsentManagementScreen extends StatefulWidget {
  const ConsentManagementScreen({Key? key}) : super(key: key);

  @override
  State<ConsentManagementScreen> createState() => _ConsentManagementScreenState();
}

class _ConsentManagementScreenState extends State<ConsentManagementScreen> {
  bool _analyticsConsent = false;
  bool _marketingConsent = false;
  bool _personalizationConsent = false;
  bool _dataSharingConsent = false;
  bool _isLoading = true;
  bool _isSaving = false;
  final GdprService _gdprService = GdprService();

  @override
  void initState() {
    super.initState();
    _loadConsentSettings();
  }

  Future<void> _loadConsentSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _gdprService.getConsentSettings();
      setState(() {
        _analyticsConsent = settings['analytics'] ?? false;
        _marketingConsent = settings['marketing'] ?? false;
        _personalizationConsent = settings['personalization'] ?? false;
        _dataSharingConsent = settings['data_sharing'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _analyticsConsent = false;
        _marketingConsent = false;
        _personalizationConsent = false;
        _dataSharingConsent = false;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load consent settings: $e')),
        );
      }
    }
  }

  Future<void> _saveConsentSettings() async {
    setState(() => _isSaving = true);
    try {
      await _gdprService.updateConsentSettings({
        'analytics': _analyticsConsent,
        'marketing': _marketingConsent,
        'personalization': _personalizationConsent,
        'data_sharing': _dataSharingConsent,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Consent settings saved successfully'),
            backgroundColor: MemoryHubColors.green500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Consent'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: MemoryHubGradients.primary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(MemoryHubSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    padding: EdgeInsets.all(MemoryHubSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: MemoryHubColors.blue400,
                            ),
                            const HGap.xs(),
                            Text(
                              'About Your Privacy',
                              style: TextStyle(
                                fontSize: MemoryHubTypography.h4,
                                fontWeight: MemoryHubTypography.bold,
                              ),
                            ),
                          ],
                        ),
                        const VGap.sm(),
                        Text(
                          'Your privacy matters to us. You have full control over how your data is used. '
                          'Review and manage your consent preferences below.',
                          style: TextStyle(color: MemoryHubColors.gray600),
                        ),
                      ],
                    ),
                  ),
                  const VGap.lg(),
                  Text(
                    'Data Usage Permissions',
                    style: TextStyle(
                      fontSize: MemoryHubTypography.h3,
                      fontWeight: MemoryHubTypography.bold,
                    ),
                  ),
                  const VGap.md(),
                  _buildConsentSwitch(
                    title: 'Analytics',
                    description: 'Allow us to collect anonymous usage data to improve our service',
                    icon: Icons.analytics,
                    value: _analyticsConsent,
                    onChanged: (value) => setState(() => _analyticsConsent = value),
                  ),
                  _buildConsentSwitch(
                    title: 'Marketing Communications',
                    description: 'Receive updates about new features and special offers',
                    icon: Icons.email,
                    value: _marketingConsent,
                    onChanged: (value) => setState(() => _marketingConsent = value),
                  ),
                  _buildConsentSwitch(
                    title: 'Personalization',
                    description: 'Allow us to personalize your experience based on your activity',
                    icon: Icons.tune,
                    value: _personalizationConsent,
                    onChanged: (value) => setState(() => _personalizationConsent = value),
                  ),
                  _buildConsentSwitch(
                    title: 'Data Sharing',
                    description: 'Share anonymized data with trusted partners for research',
                    icon: Icons.share,
                    value: _dataSharingConsent,
                    onChanged: (value) => setState(() => _dataSharingConsent = value),
                  ),
                  const VGap.lg(),
                  AppCard(
                    color: MemoryHubColors.amber50,
                    padding: EdgeInsets.all(MemoryHubSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: MemoryHubColors.amber700,
                            ),
                            const HGap.xs(),
                            Text(
                              'Your Rights',
                              style: TextStyle(
                                fontWeight: MemoryHubTypography.bold,
                                color: MemoryHubColors.amber900,
                              ),
                            ),
                          ],
                        ),
                        const VGap.xs(),
                        Text(
                          'You can withdraw your consent at any time. '
                          'You also have the right to access, export, and delete your data.',
                          style: TextStyle(
                            fontSize: MemoryHubTypography.bodySmall,
                            color: MemoryHubColors.amber900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VGap.lg(),
                  PrimaryButton(
                    onPressed: _isSaving ? null : _saveConsentSettings,
                    label: 'Save Preferences',
                    isLoading: _isSaving,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildConsentSwitch({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: MemoryHubSpacing.sm),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: SwitchListTile(
          secondary: Container(
            padding: EdgeInsets.all(MemoryHubSpacing.sm),
            decoration: BoxDecoration(
              color: value ? MemoryHubColors.blue50 : MemoryHubColors.gray100,
              borderRadius: MemoryHubBorderRadius.smRadius,
            ),
            child: Icon(
              icon,
              color: value ? MemoryHubColors.indigo500 : MemoryHubColors.gray600,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: MemoryHubTypography.semiBold),
          ),
          subtitle: Text(
            description,
            style: TextStyle(
              fontSize: MemoryHubTypography.bodySmall,
              color: MemoryHubColors.gray600,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: MemoryHubColors.indigo500,
        ),
      ),
    );
  }
}
