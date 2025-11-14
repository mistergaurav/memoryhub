import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory_hub_app/design_system/design_tokens.dart';

class AddPersonDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;

  const AddPersonDialog({
    Key? key,
    required this.onSubmit,
    this.initialData,
  }) : super(key: key);

  @override
  State<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends State<AddPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _maidenNameController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _deathPlaceController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  String _selectedGender = 'male';
  DateTime? _birthDate;
  DateTime? _deathDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _firstNameController.text = widget.initialData!['first_name'] ?? '';
      _lastNameController.text = widget.initialData!['last_name'] ?? '';
      _maidenNameController.text = widget.initialData!['maiden_name'] ?? '';
      _birthPlaceController.text = widget.initialData!['birth_place'] ?? '';
      _deathPlaceController.text = widget.initialData!['death_place'] ?? '';
      _occupationController.text = widget.initialData!['occupation'] ?? '';
      _bioController.text = widget.initialData!['bio'] ?? '';
      _selectedGender = widget.initialData!['gender'] ?? 'male';
      if (widget.initialData!['birth_date'] != null) {
        _birthDate = DateTime.parse(widget.initialData!['birth_date']);
      }
      if (widget.initialData!['death_date'] != null) {
        _deathDate = DateTime.parse(widget.initialData!['death_date']);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _maidenNameController.dispose();
    _birthPlaceController.dispose();
    _deathPlaceController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBirthDate 
          ? (_birthDate ?? DateTime.now())
          : (_deathDate ?? DateTime.now()),
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _birthDate = picked;
        } else {
          _deathDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'gender': _selectedGender,
    };

    if (_maidenNameController.text.trim().isNotEmpty) {
      data['maiden_name'] = _maidenNameController.text.trim();
    }
    if (_birthDate != null) {
      data['birth_date'] = _birthDate!.toIso8601String();
    }
    if (_birthPlaceController.text.trim().isNotEmpty) {
      data['birth_place'] = _birthPlaceController.text.trim();
    }
    if (_deathDate != null) {
      data['death_date'] = _deathDate!.toIso8601String();
    }
    if (_deathPlaceController.text.trim().isNotEmpty) {
      data['death_place'] = _deathPlaceController.text.trim();
    }
    if (_occupationController.text.trim().isNotEmpty) {
      data['occupation'] = _occupationController.text.trim();
    }
    if (_bioController.text.trim().isNotEmpty) {
      data['bio'] = _bioController.text.trim();
    }

    try {
      await widget.onSubmit(data);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: MemoryHubBorderRadius.xlRadius,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: EdgeInsets.all(MemoryHubSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(MemoryHubSpacing.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MemoryHubColors.amber500, MemoryHubColors.amber400],
                    ),
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: MemoryHubSpacing.lg),
                Expanded(
                  child: Text(
                    widget.initialData == null ? 'Add Person' : 'Edit Person',
                    style: TextStyle(
                      fontSize: MemoryHubTypography.h2,
                      fontWeight: MemoryHubTypography.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: MemoryHubSpacing.xl),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: MemoryHubSpacing.lg),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MemoryHubSpacing.lg),
                    TextFormField(
                      controller: _maidenNameController,
                      decoration: const InputDecoration(
                        labelText: 'Maiden Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGender = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Birth Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.cake),
                        ),
                        child: Text(
                          _birthDate != null
                              ? DateFormat('MMM d, yyyy').format(_birthDate!)
                              : 'Select date',
                          style: TextStyle(
                            color: _birthDate != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _birthPlaceController,
                      decoration: const InputDecoration(
                        labelText: 'Birth Place',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Death Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event_busy),
                        ),
                        child: Text(
                          _deathDate != null
                              ? DateFormat('MMM d, yyyy').format(_deathDate!)
                              : 'Select date',
                          style: TextStyle(
                            color: _deathDate != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deathPlaceController,
                      decoration: const InputDecoration(
                        labelText: 'Death Place',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Occupation',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Biography',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: MemoryHubSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                SizedBox(width: MemoryHubSpacing.md),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MemoryHubColors.amber500,
                    padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.xxl, vertical: MemoryHubSpacing.lg),
                    shape: RoundedRectangleBorder(
                      borderRadius: MemoryHubBorderRadius.mdRadius,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.initialData == null ? 'Add Person' : 'Update',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
