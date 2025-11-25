import 'package:flutter/material.dart';
import '../../design_system/design_tokens.dart';
import '../../services/family/genealogy/persons_service.dart';

class TreeOnboardingDialog extends StatefulWidget {
  const TreeOnboardingDialog({Key? key}) : super(key: key);

  @override
  State<TreeOnboardingDialog> createState() => _TreeOnboardingDialogState();
}

class _TreeOnboardingDialogState extends State<TreeOnboardingDialog> {
  final GenealogyPersonsService _personsService = GenealogyPersonsService();
  bool _isCreating = false;

  Future<void> _createSelfPerson() async {
    setState(() => _isCreating = true);

    try {
      final person = await _personsService.createSelfPerson();
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your profile has been created! You can now add family members.'),
            backgroundColor: MemoryHubColors.green600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: MemoryHubColors.red600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: MemoryHubBorderRadius.xxlRadius,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(MemoryHubSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(MemoryHubSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [MemoryHubColors.yellow500, MemoryHubColors.yellow400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_tree,
                size: 48,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: MemoryHubSpacing.xl),
            
            // Title
            const Text(
              'Start Your Family Tree',
              style: TextStyle(
                fontSize: MemoryHubTypography.h3,
                fontWeight: MemoryHubTypography.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: MemoryHubSpacing.md),
            
            // Description
            Text(
              'Begin by creating your own profile in the family tree. You can then add family members and build your genealogy.',
              style: TextStyle(
                fontSize: MemoryHubTypography.bodyMedium,
                color: MemoryHubColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: MemoryHubSpacing.xl),
            
            // Features
            _buildFeature(
              Icons.person,
              'Your Profile',
              'We\'ll create your profile using your account information',
            ),
            SizedBox(height: MemoryHubSpacing.md),
            _buildFeature(
              Icons.edit,
              'Customize Later',
              'You can edit your bio, dates, and photos anytime',
            ),
            SizedBox(height: MemoryHubSpacing.md),
            _buildFeature(
              Icons.people,
              'Add Family',
              'Start adding parents, siblings, and other relatives',
            ),
            
            SizedBox(height: MemoryHubSpacing.xxl),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCreating ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: MemoryHubSpacing.lg),
                      side: const BorderSide(color: MemoryHubColors.gray300),
                    ),
                    child: const Text('Maybe Later'),
                  ),
                ),
                SizedBox(width: MemoryHubSpacing.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createSelfPerson,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: MemoryHubSpacing.lg),
                      backgroundColor: MemoryHubColors.yellow500,
                      foregroundColor: Colors.white,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create My Profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(MemoryHubSpacing.sm),
          decoration: BoxDecoration(
            color: MemoryHubColors.yellow50,
            borderRadius: MemoryHubBorderRadius.mdRadius,
          ),
          child: Icon(
            icon,
            size: 20,
            color: MemoryHubColors.yellow600,
          ),
        ),
        SizedBox(width: MemoryHubSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: MemoryHubTypography.bodyMedium,
                  fontWeight: MemoryHubTypography.semiBold,
                ),
              ),
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
    );
  }
}
