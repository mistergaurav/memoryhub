import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/family/family_milestone.dart';

class AddMilestoneDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final FamilyMilestone? milestone;

  const AddMilestoneDialog({
    Key? key,
    required this.onSubmit,
    this.milestone,
  }) : super(key: key);

  @override
  State<AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<AddMilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();
  final TextEditingController _celebrationNotesController = TextEditingController();
  
  String _milestoneType = 'achievement';
  DateTime _milestoneDate = DateTime.now();
  int _importance = 3;
  bool _isLoading = false;
  final List<String> _photoUrls = [];

  final List<Map<String, dynamic>> _milestoneTypes = [
    {'value': 'birth', 'label': 'Birth', 'icon': Icons.child_care, 'color': Color(0xFFEC4899)},
    {'value': 'graduation', 'label': 'Graduation', 'icon': Icons.school, 'color': Color(0xFF8B5CF6)},
    {'value': 'wedding', 'label': 'Wedding', 'icon': Icons.favorite, 'color': Color(0xFFEF4444)},
    {'value': 'anniversary', 'label': 'Anniversary', 'icon': Icons.cake, 'color': Color(0xFFF59E0B)},
    {'value': 'achievement', 'label': 'Achievement', 'icon': Icons.emoji_events, 'color': Color(0xFFEAB308)},
    {'value': 'first_words', 'label': 'First Words', 'icon': Icons.chat_bubble, 'color': Color(0xFF06B6D4)},
    {'value': 'first_steps', 'label': 'First Steps', 'icon': Icons.directions_walk, 'color': Color(0xFF10B981)},
    {'value': 'other', 'label': 'Other', 'icon': Icons.star, 'color': Color(0xFF6366F1)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.milestone != null) {
      _titleController.text = widget.milestone!.title;
      _descriptionController.text = widget.milestone!.description ?? '';
      _milestoneType = widget.milestone!.category;
      _milestoneDate = widget.milestone!.milestoneDate;
      if (widget.milestone!.photoUrl != null) {
        _photoUrls.add(widget.milestone!.photoUrl!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _photoUrlController.dispose();
    _celebrationNotesController.dispose();
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

  void _addPhotoUrl() {
    if (_photoUrlController.text.trim().isNotEmpty) {
      final url = _photoUrlController.text.trim();
      if (Uri.tryParse(url)?.isAbsolute == true) {
        setState(() {
          _photoUrls.add(url);
          _photoUrlController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid URL')),
        );
      }
    }
  }

  void _removePhotoUrl(int index) {
    setState(() {
      _photoUrls.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
      'milestone_type': _milestoneType,
      'milestone_date': _milestoneDate.toIso8601String(),
      'photos': _photoUrls,
      'auto_generated': false,
    };

    if (_celebrationNotesController.text.trim().isNotEmpty) {
      data['celebration_details'] = {
        'notes': _celebrationNotesController.text.trim(),
        'importance': _importance,
      };
    }

    try {
      await widget.onSubmit(data);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save milestone: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.milestone != null;
    final descriptionLength = _descriptionController.text.length;
    final maxDescriptionLength = 500;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
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
                Expanded(
                  child: Text(
                    isEdit ? 'Edit Milestone' : 'Add Milestone',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.title),
                          hintText: 'e.g., First Day of School',
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.description),
                          hintText: 'Share details about this milestone...',
                          filled: true,
                          fillColor: Colors.grey[50],
                          counterText: '$descriptionLength / $maxDescriptionLength',
                        ),
                        maxLines: 3,
                        maxLength: maxDescriptionLength,
                        onChanged: (value) {
                          setState(() {});
                        },
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
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: (type['color'] as Color).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : null,
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
                          decoration: InputDecoration(
                            labelText: 'Date *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          child: Text(DateFormat('MMM d, yyyy').format(_milestoneDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Importance Level',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return IconButton(
                                  icon: Icon(
                                    index < _importance ? Icons.star : Icons.star_border,
                                    size: 32,
                                    color: index < _importance ? Colors.amber[700] : Colors.grey[400],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _importance = index + 1;
                                    });
                                  },
                                );
                              }),
                            ),
                            Text(
                              _getImportanceLabel(_importance),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _photoUrlController,
                              decoration: InputDecoration(
                                labelText: 'Photo URL (optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.photo),
                                hintText: 'https://example.com/photo.jpg',
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addPhotoUrl,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                      if (_photoUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Photos to be attached:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(_photoUrls.length, (index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _photoUrls[index],
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.broken_image, size: 30),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _photoUrls[index],
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removePhotoUrl(index),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _celebrationNotesController,
                        decoration: InputDecoration(
                          labelText: 'Celebration Notes (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.party_mode),
                          hintText: 'Add special celebration details...',
                          filled: true,
                          fillColor: Colors.purple[50],
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
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
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          isEdit ? 'Update Milestone' : 'Add Milestone',
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

  String _getImportanceLabel(int level) {
    switch (level) {
      case 1:
        return 'Minor';
      case 2:
        return 'Notable';
      case 3:
        return 'Important';
      case 4:
        return 'Very Important';
      case 5:
        return 'Major Milestone';
      default:
        return 'Important';
    }
  }
}
