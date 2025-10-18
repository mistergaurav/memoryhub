import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _loadConsentSettings();
  }

  Future<void> _loadConsentSettings() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Load from API
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _analyticsConsent = true;
        _marketingConsent = false;
        _personalizationConsent = true;
        _dataSharingConsent = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
      // TODO: Save to API endpoint /api/v1/gdpr/consent
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consent settings saved successfully'),
            backgroundColor: Colors.green,
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.purple.shade400],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade400),
                              const SizedBox(width: 8),
                              const Text(
                                'About Your Privacy',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your privacy matters to us. You have full control over how your data is used. '
                            'Review and manage your consent preferences below.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Data Usage Permissions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Your Rights',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can withdraw your consent at any time. '
                            'You also have the right to access, export, and delete your data.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveConsentSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Preferences',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value ? Colors.indigo.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: value ? Colors.indigo : Colors.grey.shade600,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          description,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.indigo,
      ),
    );
  }
}
