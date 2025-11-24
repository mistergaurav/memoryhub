import 'package:flutter/material.dart';
import '../../models/family/genealogy_person.dart';
import '../../design_system/design_tokens.dart';
import 'package:intl/intl.dart';

class EditPersonDialog extends StatefulWidget {
  final GenealogyPerson person;
  final Function(String personId, Map<String, dynamic> data) onSubmit;

  const EditPersonDialog({
    Key? key,
    required this.person,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<EditPersonDialog> createState() => _EditPersonDialogState();
}

class _EditPersonDialogState extends State<EditPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _maidenNameController;
  late TextEditingController _birthPlaceController;
  late TextEditingController _deathPlaceController;
  late TextEditingController _occupationController;
  late TextEditingController _biographyController;

  late String _gender;
  late bool _isAlive;
  String? _birthDate;
  String? _deathDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.person.firstName);
    _lastNameController = TextEditingController(text: widget.person.lastName);
    _maidenNameController = TextEditingController(text: widget.person.maidenName ?? '');
    _birthPlaceController = TextEditingController(text: widget.person.placeOfBirth ?? '');
    _deathPlaceController = TextEditingController(text: widget.person.placeOfDeath ?? '');
    _occupationController = TextEditingController(text: widget.person.occupation ?? '');
    _biographyController = TextEditingController(text: widget.person.biography ?? '');

    _gender = widget.person.gender;
    _isAlive = !widget.person.isDeceased; // Convert isDeceased to isAlive
    _birthDate = widget.person.dateOfBirth?.toIso8601String().split('T')[0]; // Convert DateTime to YYYY-MM-DD
    _deathDate = widget.person.dateOfDeath?.toIso8601String().split('T')[0]; // Convert DateTime to YYYY-MM-DD
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _maidenNameController.dispose();
    _birthPlaceController.dispose();
    _deathPlaceController.dispose();
    _occupationController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'maiden_name': _maidenNameController.text.trim().isEmpty ? null : _maidenNameController.text.trim(),
      'gender': _gender,
      'birth_date': _birthDate,
      'place_of_birth': _birthPlaceController.text.trim().isEmpty ? null : _birthPlaceController.text.trim(),
      'death_date': _deathDate,
      'place_of_death': _deathPlaceController.text.trim().isEmpty ? null : _deathPlaceController.text.trim(),
      'is_deceased': !_isAlive, // Convert isAlive back to isDeceased
      'occupation': _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
      'biography': _biographyController.text.trim().isEmpty ? null : _biographyController.text.trim(),
    };

    try {
      await widget.onSubmit(widget.person.id, data);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update person: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.xlRadius),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: EdgeInsets.all(MemoryHubSpacing.xl),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(MemoryHubSpacing.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                const SizedBox(width: MemoryHubSpacing.lg),
                const Expanded(
                  child: Text(
                    'Edit Person',
                    style: TextStyle(fontSize: MemoryHubTypography.h2, fontWeight: MemoryHubTypography.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: MemoryHubSpacing.lg),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name *',
                        border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
                      ),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'First name is required' : null,
                    ),
                    const SizedBox(height: MemoryHubSpacing.md),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name *',
                        border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
                      ),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Last name is required' : null,
                    ),
                    const SizedBox(height: MemoryHubSpacing.md),
                    TextFormField(
                      controller: _maidenNameController,
                      decoration: InputDecoration(
                        labelText: 'Maiden Name',
                        border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
                      ),
                    ),
                    const SizedBox(height: MemoryHubSpacing.md),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                        DropdownMenuItem(value: 'unknown', child: Text('Prefer not to say')),
                      ],
                      onChanged: (value) => setState(() => _gender = value ?? 'unknown'),
                    ),
                    const SizedBox(height: MemoryHubSpacing.md),
                    SwitchListTile(
                      title: const Text('Status'),
                      subtitle: Text(_isAlive ? 'Alive' : 'Deceased'),
                      value: _isAlive,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (value) => setState(() => _isAlive = value),
                    ),
                    const SizedBox(height: MemoryHubSpacing.md),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Birth Date (YYYY-MM-DD)',
                        hintText: '1990-01-15',
                        border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _birthDate != null 
                                  ? DateTime.tryParse(_birthDate!) ?? DateTime.now()
                                  : DateTime.now(),
                              firstDate: DateTime(1800),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _birthDate = DateFormat('yyyy-MM-dd').format(date));
                            }
                          },
                        ),
                      ),
                      controller: TextEditingController(text: _birthDate),
                      onChanged: (value) => setState(() => _birthDate = value.isEmpty ? null : value),
                    ),
                    const SizedBox(height: MemoryHubSpacing.md),
                    TextFormField(
                      controller: _birthPlaceController,
                      decoration: InputDecoration(
                        labelText: 'Birth Place',
                        border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
                      ),
                    ),
                    if (!_isAlive) ...[ 
                      const SizedBox(height: MemoryHubSpacing.md),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Death Date (YYYY-MM-DD)',
                          hintText: '2020-05-20',
                          border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _deathDate != null
                                    ? DateTime.tryParse(_deathDate!) ?? DateTime.now()
                                    : DateTime.now(),
                                firstDate: DateTime(1800),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _deathDate = DateFormat('yyyy-MM-dd').format(date));
                              }
                            },
                          ),
                        ),
                        controller: TextEditingController(text: _deathDate),
                        onChanged: (value) => setState(() => _deathDate = value.isEmpty ? null : value),
                      ),
                      const SizedBox(height: MemoryHubSpacing.md),
                      TextFormField(
                        controller: _deathPlaceController,
                        decoration: InputDecoration(
                          labelText: 'Death Place',
                          border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
                        ),
                      ),
                    ],
                    const SizedBox(height: MemoryHubSpacing.md),
                    TextFormField(
                      controller: _occupationController,
                      decoration: InputDecoration(
                        labelText: 'Occupation',
                        border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
                      ),
                    ),
                    const SizedBox(height: MemoryHubSpacing.md),
                    TextFormField(
                      controller: _biographyController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Biography',
                        hintText: 'Brief life story...',
                        border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MemoryHubSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: MemoryHubSpacing.md),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    padding: EdgeInsets.symmetric(
                      horizontal: MemoryHubSpacing.xxl,
                      vertical: MemoryHubSpacing.lg,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
