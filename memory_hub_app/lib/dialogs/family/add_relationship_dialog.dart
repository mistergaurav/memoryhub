import 'package:flutter/material.dart';

class AddRelationshipDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final List<Map<String, dynamic>> persons;

  const AddRelationshipDialog({
    Key? key,
    required this.onSubmit,
    required this.persons,
  }) : super(key: key);

  @override
  State<AddRelationshipDialog> createState() => _AddRelationshipDialogState();
}

class _AddRelationshipDialogState extends State<AddRelationshipDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _person1Id;
  String? _person2Id;
  String _relationshipType = 'parent';
  bool _isLoading = false;

  final List<Map<String, String>> _relationshipTypes = [
    {'value': 'parent', 'label': 'Parent'},
    {'value': 'child', 'label': 'Child'},
    {'value': 'spouse', 'label': 'Spouse'},
    {'value': 'sibling', 'label': 'Sibling'},
    {'value': 'grandparent', 'label': 'Grandparent'},
    {'value': 'grandchild', 'label': 'Grandchild'},
    {'value': 'aunt_uncle', 'label': 'Aunt/Uncle'},
    {'value': 'niece_nephew', 'label': 'Niece/Nephew'},
    {'value': 'cousin', 'label': 'Cousin'},
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_person1Id == null || _person2Id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both persons'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_person1Id == _person2Id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot create a relationship with the same person'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'person1_id': _person1Id!,
      'person2_id': _person2Id!,
      'relationship_type': _relationshipType,
    };

    try {
      await widget.onSubmit(data);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getPersonLabel(Map<String, dynamic> person) {
    final firstName = person['first_name'] ?? '';
    final lastName = person['last_name'] ?? '';
    return '$firstName $lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.link,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Add Relationship',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _person1Id,
                    decoration: const InputDecoration(
                      labelText: 'First Person *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: widget.persons.map((person) {
                      return DropdownMenuItem<String>(
                        value: person['id'],
                        child: Text(_getPersonLabel(person)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _person1Id = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a person';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _relationshipType,
                    decoration: const InputDecoration(
                      labelText: 'Relationship Type *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.family_restroom),
                    ),
                    items: _relationshipTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['value']!,
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _relationshipType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _person2Id,
                    decoration: const InputDecoration(
                      labelText: 'Second Person *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: widget.persons.map((person) {
                      return DropdownMenuItem<String>(
                        value: person['id'],
                        child: Text(_getPersonLabel(person)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _person2Id = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a person';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      : const Text(
                          'Add Relationship',
                          style: TextStyle(color: Colors.white),
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
