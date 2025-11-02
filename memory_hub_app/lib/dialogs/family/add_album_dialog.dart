import 'package:flutter/material.dart';
import '../../design_system/design_tokens.dart';

class AddAlbumDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;

  const AddAlbumDialog({
    Key? key,
    required this.onSubmit,
    this.initialData,
  }) : super(key: key);

  @override
  State<AddAlbumDialog> createState() => _AddAlbumDialogState();
}

class _AddAlbumDialogState extends State<AddAlbumDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedPrivacy = 'family_circle';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _privacyOptions = [
    {
      'value': 'private',
      'label': 'Private',
      'subtitle': 'Only you can see this album',
      'icon': Icons.lock,
    },
    {
      'value': 'family_circle',
      'label': 'Family Circle',
      'subtitle': 'Shared with your family circles',
      'icon': Icons.group,
    },
    {
      'value': 'specific_members',
      'label': 'Specific Members',
      'subtitle': 'Select specific family members',
      'icon': Icons.people,
    },
    {
      'value': 'public',
      'label': 'Public',
      'subtitle': 'Anyone can view this album',
      'icon': Icons.public,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _titleController.text = widget.initialData!['title'] ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';
      _selectedPrivacy = widget.initialData!['privacy'] ?? 'family_circle';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'privacy': _selectedPrivacy,
      'family_circle_ids': [],
      'member_ids': [],
    };

    try {
      await widget.onSubmit(data);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.xlRadius),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(MemoryHubSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(MemoryHubSpacing.md),
                    decoration: BoxDecoration(
                      gradient: MemoryHubGradients.albums,
                      borderRadius: MemoryHubBorderRadius.mdRadius,
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: MemoryHubSpacing.md),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Album' : 'Create Album',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: MemoryHubTypography.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: MemoryHubSpacing.xl),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Album Title *',
                        hintText: 'e.g., Summer Vacation 2024',
                        border: OutlineInputBorder(
                          borderRadius: MemoryHubBorderRadius.mdRadius,
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: MemoryHubSpacing.lg),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Add a description for this album...',
                        border: OutlineInputBorder(
                          borderRadius: MemoryHubBorderRadius.mdRadius,
                        ),
                        prefixIcon: const Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: MemoryHubSpacing.lg),
                    Text(
                      'Privacy Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: MemoryHubTypography.semiBold,
                          ),
                    ),
                    const SizedBox(height: MemoryHubSpacing.md),
                    ..._privacyOptions.map((option) {
                      final isSelected = _selectedPrivacy == option['value'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: MemoryHubSpacing.sm),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPrivacy = option['value'];
                            });
                          },
                          borderRadius: MemoryHubBorderRadius.mdRadius,
                          child: Container(
                            padding: const EdgeInsets.all(MemoryHubSpacing.md),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                                  : MemoryHubColors.gray100,
                              borderRadius: MemoryHubBorderRadius.mdRadius,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  option['icon'],
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : MemoryHubColors.gray600,
                                ),
                                const SizedBox(width: MemoryHubSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option['label'],
                                        style: TextStyle(
                                          fontWeight: MemoryHubTypography.semiBold,
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : MemoryHubColors.gray900,
                                        ),
                                      ),
                                      Text(
                                        option['subtitle'],
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).primaryColor,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: MemoryHubSpacing.xl),
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
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: MemoryHubSpacing.xl,
                        vertical: MemoryHubSpacing.md,
                      ),
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
                            isEdit ? 'Update Album' : 'Create Album',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: MemoryHubTypography.semiBold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
