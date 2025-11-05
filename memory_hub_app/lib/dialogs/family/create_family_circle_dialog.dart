import 'package:flutter/material.dart';
import '../../design_system/design_tokens.dart';
import '../../models/family/family_circle.dart';

class CreateFamilyCircleDialog extends StatefulWidget {
  final Function(FamilyCircleCreate) onSubmit;
  final FamilyCircle? initialCircle;

  const CreateFamilyCircleDialog({
    Key? key,
    required this.onSubmit,
    this.initialCircle,
  }) : super(key: key);

  @override
  State<CreateFamilyCircleDialog> createState() => _CreateFamilyCircleDialogState();
}

class _CreateFamilyCircleDialogState extends State<CreateFamilyCircleDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCircleType = 'custom';
  String? _selectedColor;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _circleTypes = [
    {
      'value': 'immediate_family',
      'label': 'Immediate Family',
      'subtitle': 'Parents, children, siblings',
      'icon': Icons.family_restroom,
    },
    {
      'value': 'extended_family',
      'label': 'Extended Family',
      'subtitle': 'Grandparents, aunts, uncles, cousins',
      'icon': Icons.people,
    },
    {
      'value': 'close_friends',
      'label': 'Close Friends',
      'subtitle': 'Best friends and close companions',
      'icon': Icons.favorite,
    },
    {
      'value': 'work_friends',
      'label': 'Work Friends',
      'subtitle': 'Colleagues and professional network',
      'icon': Icons.work,
    },
    {
      'value': 'custom',
      'label': 'Custom',
      'subtitle': 'Create your own circle type',
      'icon': Icons.tune,
    },
  ];

  final List<Map<String, dynamic>> _colorOptions = [
    {'value': '#8B5CF6', 'color': const Color(0xFF8B5CF6), 'name': 'Purple'},
    {'value': '#EC4899', 'color': const Color(0xFFEC4899), 'name': 'Pink'},
    {'value': '#06B6D4', 'color': const Color(0xFF06B6D4), 'name': 'Cyan'},
    {'value': '#10B981', 'color': const Color(0xFF10B981), 'name': 'Green'},
    {'value': '#F59E0B', 'color': const Color(0xFFF59E0B), 'name': 'Amber'},
    {'value': '#EF4444', 'color': const Color(0xFFEF4444), 'name': 'Red'},
    {'value': '#6366F1', 'color': const Color(0xFF6366F1), 'name': 'Indigo'},
    {'value': '#14B8A6', 'color': const Color(0xFF14B8A6), 'name': 'Teal'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCircle != null) {
      _nameController.text = widget.initialCircle!.name;
      _descriptionController.text = widget.initialCircle!.description ?? '';
      _selectedCircleType = widget.initialCircle!.circleType;
      _selectedColor = widget.initialCircle!.color;
    } else {
      _selectedColor = _colorOptions[0]['value'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final circleData = FamilyCircleCreate(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      circleType: _selectedCircleType,
      color: _selectedColor,
    );

    try {
      await widget.onSubmit(circleData);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialCircle != null;
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
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          MemoryHubColors.purple500,
                          MemoryHubColors.pink500,
                        ],
                      ),
                      borderRadius: MemoryHubBorderRadius.mdRadius,
                    ),
                    child: const Icon(Icons.groups, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: MemoryHubSpacing.md),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Circle' : 'Create Circle',
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
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Circle Name *',
                        hintText: 'e.g., Immediate Family, Best Friends',
                        border: OutlineInputBorder(
                          borderRadius: MemoryHubBorderRadius.mdRadius,
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: MemoryHubSpacing.lg),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Add a description for this circle...',
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
                      'Circle Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: MemoryHubTypography.semiBold,
                          ),
                    ),
                    const SizedBox(height: MemoryHubSpacing.md),
                    ..._circleTypes.map((type) {
                      final isSelected = _selectedCircleType == type['value'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: MemoryHubSpacing.sm),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCircleType = type['value'];
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
                                  type['icon'],
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
                                        type['label'],
                                        style: TextStyle(
                                          fontWeight: MemoryHubTypography.semiBold,
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : MemoryHubColors.gray900,
                                        ),
                                      ),
                                      Text(
                                        type['subtitle'],
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
                    const SizedBox(height: MemoryHubSpacing.lg),
                    Text(
                      'Circle Color',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: MemoryHubTypography.semiBold,
                          ),
                    ),
                    const SizedBox(height: MemoryHubSpacing.md),
                    Wrap(
                      spacing: MemoryHubSpacing.md,
                      runSpacing: MemoryHubSpacing.md,
                      children: _colorOptions.map((option) {
                        final isSelected = _selectedColor == option['value'];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedColor = option['value'];
                            });
                          },
                          borderRadius: MemoryHubBorderRadius.fullRadius,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: option['color'],
                              borderRadius: MemoryHubBorderRadius.fullRadius,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? option['color'].withOpacity(0.5)
                                      : Colors.transparent,
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 32,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Update' : 'Create'),
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
