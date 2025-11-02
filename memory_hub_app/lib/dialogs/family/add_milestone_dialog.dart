import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddMilestoneDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const AddMilestoneDialog({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<AddMilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();
  
  String _milestoneType = 'achievement';
  DateTime _milestoneDate = DateTime.now();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _milestoneTypes = [
    {'value': 'birth', 'label': 'Birth', 'icon': Icons.child_care, 'color': Color(0xFFEC4899)},
    {'value': 'graduation', 'label': 'Graduation', 'icon': Icons.school, 'color': Color(0xFF8B5CF6)},
    {'value': 'wedding', 'label': 'Wedding', 'icon': Icons.favorite, 'color': Color(0xFFEF4444)},
    {'value': 'anniversary', 'label': 'Anniversary', 'icon': Icons.cake, 'color': Color(0xFFF59E0B)},
    {'value': 'achievement', 'label': 'Achievement', 'icon': Icons.emoji_events, 'color': Color(0xFFEAB308)},
    {'value': 'first_word', 'label': 'First Word', 'icon': Icons.chat_bubble, 'color': Color(0xFF06B6D4)},
    {'value': 'first_step', 'label': 'First Step', 'icon': Icons.directions_walk, 'color': Color(0xFF10B981)},
    {'value': 'other', 'label': 'Other', 'icon': Icons.star, 'color': Color(0xFF6366F1)},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _personNameController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _milestoneDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _milestoneDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final photos = <String>[];
    if (_photoUrlController.text.trim().isNotEmpty) {
      photos.add(_photoUrlController.text.trim());
    }

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
      'milestone_type': _milestoneType,
      'milestone_date': _milestoneDate.toIso8601String(),
      'photos': photos,
      'auto_generated': false,
    };

    try {
      await widget.onSubmit(data);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create milestone: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.celebration, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Add Milestone', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                        hintText: 'e.g., First Day of School',
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Share details about this milestone...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Milestone Type *',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _milestoneTypes.map((type) {
                        final isSelected = _milestoneType == type['value'];
                        return InkWell(
                          onTap: () => setState(() => _milestoneType = type['value'] as String),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? type['color'] as Color : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? type['color'] as Color : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type['icon'] as IconData,
                                  size: 20,
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type['label'] as String,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[700],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('MMM d, yyyy').format(_milestoneDate)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _photoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Photo URL (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.photo),
                        hintText: 'https://example.com/photo.jpg',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !Uri.tryParse(value)!.isAbsolute) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Add Milestone', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
