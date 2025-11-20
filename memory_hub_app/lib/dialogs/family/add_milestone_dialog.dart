import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory_hub_app/design_system/design_tokens.dart';
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
  String _audienceScope = 'friends';

  final List<Map<String, dynamic>> _milestoneTypes = [
    {'value': 'birth', 'label': 'Birth', 'icon': Icons.child_care, 'color': MemoryHubColors.pink500},
    {'value': 'graduation', 'label': 'Graduation', 'icon': Icons.school, 'color': MemoryHubColors.purple500},
    {'value': 'wedding', 'label': 'Wedding', 'icon': Icons.favorite, 'color': MemoryHubColors.red500},
    {'value': 'anniversary', 'label': 'Anniversary', 'icon': Icons.cake, 'color': MemoryHubColors.amber500},
    {'value': 'achievement', 'label': 'Achievement', 'icon': Icons.emoji_events, 'color': MemoryHubColors.amber500},
    {'value': 'first_words', 'label': 'First Words', 'icon': Icons.chat_bubble, 'color': MemoryHubColors.cyan500},
    {'value': 'first_steps', 'label': 'First Steps', 'icon': Icons.directions_walk, 'color': MemoryHubColors.green500},
    {'value': 'other', 'label': 'Other', 'icon': Icons.star, 'color': MemoryHubColors.indigo500},
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
      'photos': _photoUrls,
      'milestone_type': _milestoneType,
      'milestone_date': _milestoneDate.toIso8601String(),
      'family_circle_ids': [], // This should ideally be populated with actual IDs
    };

    if (_celebrationNotesController.text.trim().isNotEmpty) {
      // celebration_details is not in FamilyMilestoneCreate schema either, 
      // but maybe it's handled loosely? 
      // The schema doesn't show it. 
      // For now, I'll comment it out or leave it if it was there before.
      // But to be safe and avoid 422, I should probably omit it if backend doesn't support it.
      // However, the previous code had it. Let's check if I should keep it.
      // The schema definitely doesn't have it.
      // I'll add it to description if needed, or just omit.
      // Let's append it to description for now to preserve data.
      if (data['description'] != null) {
        data['description'] = "${data['description']}\n\nCelebration Notes: ${_celebrationNotesController.text.trim()}";
      } else {
        data['description'] = "Celebration Notes: ${_celebrationNotesController.text.trim()}";
      }
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
      shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.xlRadius),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: EdgeInsets.all(MemoryHubSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  child: const Icon(Icons.celebration, color: Colors.white),
                ),
                SizedBox(width: MemoryHubSpacing.lg),
                Expanded(
                  child: Text(
                    isEdit ? 'Edit Milestone' : 'Add Milestone',
                    style: TextStyle(fontSize: MemoryHubTypography.h2, fontWeight: MemoryHubTypography.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: MemoryHubSpacing.xl),
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
                            borderRadius: MemoryHubBorderRadius.mdRadius,
                          ),
                          prefixIcon: const Icon(Icons.title),
                          hintText: 'e.g., First Day of School',
                          filled: true,
                          fillColor: MemoryHubColors.gray50,
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true ? 'Title is required' : null,
                      ),
                      SizedBox(height: MemoryHubSpacing.lg),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: MemoryHubBorderRadius.mdRadius,
                          ),
                          prefixIcon: const Icon(Icons.description),
                          hintText: 'Share details about this milestone...',
                          filled: true,
                          fillColor: MemoryHubColors.gray50,
                          counterText: '$descriptionLength / $maxDescriptionLength',
                        ),
                        maxLines: 3,
                        maxLength: maxDescriptionLength,
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: MemoryHubSpacing.lg),
                      Text(
                        'Milestone Type *',
                        style: TextStyle(fontSize: MemoryHubTypography.h5, fontWeight: MemoryHubTypography.semiBold),
                      ),
                      SizedBox(height: MemoryHubSpacing.md),
                      Wrap(
                        spacing: MemoryHubSpacing.sm,
                        runSpacing: MemoryHubSpacing.sm,
                        children: _milestoneTypes.map((type) {
                          final isSelected = _milestoneType == type['value'];
                          return InkWell(
                            onTap: () => setState(() => _milestoneType = type['value'] as String),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg, vertical: MemoryHubSpacing.md),
                              decoration: BoxDecoration(
                                color: isSelected ? type['color'] as Color : MemoryHubColors.gray100,
                                borderRadius: MemoryHubBorderRadius.mdRadius,
                                border: Border.all(
                                  color: isSelected ? type['color'] as Color : MemoryHubColors.gray300,
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
                                    color: isSelected ? Colors.white : MemoryHubColors.gray700,
                                  ),
                                  SizedBox(width: MemoryHubSpacing.sm),
                                  Text(
                                    type['label'] as String,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : MemoryHubColors.gray700,
                                      fontWeight: isSelected ? MemoryHubTypography.bold : MemoryHubTypography.regular,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: MemoryHubSpacing.lg),
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date *',
                            border: OutlineInputBorder(
                              borderRadius: MemoryHubBorderRadius.mdRadius,
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: MemoryHubColors.gray50,
                          ),
                          child: Text(DateFormat('MMM d, yyyy').format(_milestoneDate)),
                        ),
                      ),
                      SizedBox(height: MemoryHubSpacing.lg),
                      Text(
                        'Importance Level',
                        style: TextStyle(fontSize: MemoryHubTypography.h5, fontWeight: MemoryHubTypography.semiBold),
                      ),
                      SizedBox(height: MemoryHubSpacing.sm),
                      Container(
                        padding: EdgeInsets.all(MemoryHubSpacing.lg),
                        decoration: BoxDecoration(
                          color: MemoryHubColors.amber500.withOpacity(0.05),
                          borderRadius: MemoryHubBorderRadius.mdRadius,
                          border: Border.all(color: MemoryHubColors.amber400),
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
                                    color: index < _importance ? MemoryHubColors.amber700 : MemoryHubColors.gray400,
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
                                fontSize: MemoryHubTypography.bodyMedium,
                                fontWeight: MemoryHubTypography.semiBold,
                                color: MemoryHubColors.amber900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: MemoryHubSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _photoUrlController,
                              decoration: InputDecoration(
                                labelText: 'Photo URL (optional)',
                                border: OutlineInputBorder(
                                  borderRadius: MemoryHubBorderRadius.mdRadius,
                                ),
                                prefixIcon: const Icon(Icons.photo),
                                hintText: 'https://example.com/photo.jpg',
                                filled: true,
                                fillColor: MemoryHubColors.gray50,
                              ),
                            ),
                          ),
                          SizedBox(width: MemoryHubSpacing.sm),
                          ElevatedButton(
                            onPressed: _addPhotoUrl,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MemoryHubColors.amber500,
                              padding: EdgeInsets.all(MemoryHubSpacing.lg),
                              shape: RoundedRectangleBorder(
                                borderRadius: MemoryHubBorderRadius.mdRadius,
                              ),
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                      if (_photoUrls.isNotEmpty) ...[
                        SizedBox(height: MemoryHubSpacing.md),
                        Container(
                          padding: EdgeInsets.all(MemoryHubSpacing.md),
                          decoration: BoxDecoration(
                            color: MemoryHubColors.blue500.withOpacity(0.05),
                            borderRadius: MemoryHubBorderRadius.mdRadius,
                            border: Border.all(color: MemoryHubColors.blue200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Photos to be attached:',
                                style: TextStyle(
                                  fontSize: MemoryHubTypography.bodyMedium,
                                  fontWeight: MemoryHubTypography.semiBold,
                                ),
                              ),
                              SizedBox(height: MemoryHubSpacing.sm),
                              ...List.generate(_photoUrls.length, (index) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: MemoryHubSpacing.sm),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: MemoryHubBorderRadius.smRadius,
                                        child: Image.network(
                                          _photoUrls[index],
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color: MemoryHubColors.gray300,
                                              child: const Icon(Icons.broken_image, size: 30),
                                            );
                                          },
                                        ),
                                      ),
                                      SizedBox(width: MemoryHubSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          _photoUrls[index],
                                          style: TextStyle(fontSize: MemoryHubTypography.bodySmall),
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
                      SizedBox(height: MemoryHubSpacing.lg),
                      TextFormField(
                        controller: _celebrationNotesController,
                        decoration: InputDecoration(
                          labelText: 'Celebration Notes (optional)',
                          border: OutlineInputBorder(
                            borderRadius: MemoryHubBorderRadius.mdRadius,
                          ),
                          prefixIcon: const Icon(Icons.party_mode),
                          hintText: 'Add special celebration details...',
                          filled: true,
                          fillColor: MemoryHubColors.purple500.withOpacity(0.05),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: MemoryHubSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
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
