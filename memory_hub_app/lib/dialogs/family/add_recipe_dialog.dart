import 'package:flutter/material.dart';
import '../../design_system/design_tokens.dart';

class IngredientItem {
  final TextEditingController nameController;
  final TextEditingController amountController;
  final TextEditingController unitController;

  IngredientItem()
      : nameController = TextEditingController(),
        amountController = TextEditingController(),
        unitController = TextEditingController();

  void dispose() {
    nameController.dispose();
    amountController.dispose();
    unitController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': nameController.text.trim(),
      'amount': amountController.text.trim(),
      if (unitController.text.trim().isNotEmpty)
        'unit': unitController.text.trim(),
    };
  }
}

class StepItem {
  final TextEditingController instructionController;
  int stepNumber;

  StepItem(this.stepNumber)
      : instructionController = TextEditingController();

  void dispose() {
    instructionController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'step_number': stepNumber,
      'instruction': instructionController.text.trim(),
    };
  }
}

class AddRecipeDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const AddRecipeDialog({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<AddRecipeDialog> createState() => _AddRecipeDialogState();
}

class _AddRecipeDialogState extends State<AddRecipeDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _cookTimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _familyNotesController = TextEditingController();
  final TextEditingController _originStoryController = TextEditingController();

  String _category = 'main_course';
  String _difficulty = 'medium';
  bool _isLoading = false;

  List<IngredientItem> _ingredients = [IngredientItem()];
  List<StepItem> _steps = [StepItem(1)];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _familyNotesController.dispose();
    _originStoryController.dispose();
    for (var ingredient in _ingredients) {
      ingredient.dispose();
    }
    for (var step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(IngredientItem());
    });
  }

  void _removeIngredient(int index) {
    if (_ingredients.length > 1) {
      setState(() {
        _ingredients[index].dispose();
        _ingredients.removeAt(index);
      });
    }
  }

  void _addStep() {
    setState(() {
      _steps.add(StepItem(_steps.length + 1));
    });
  }

  void _removeStep(int index) {
    if (_steps.length > 1) {
      setState(() {
        _steps[index].dispose();
        _steps.removeAt(index);
        // Renumber steps
        for (int i = 0; i < _steps.length; i++) {
          _steps[i].stepNumber = i + 1;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate at least one ingredient and one step
    final hasValidIngredient = _ingredients.any(
      (ing) => ing.nameController.text.trim().isNotEmpty,
    );
    final hasValidStep = _steps.any(
      (step) => step.instructionController.text.trim().isNotEmpty,
    );

    if (!hasValidIngredient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one ingredient'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!hasValidStep) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one instruction step'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Build ingredients list
    final ingredients = _ingredients
        .where((ing) => ing.nameController.text.trim().isNotEmpty)
        .map((ing) => ing.toJson())
        .toList();

    // Build steps list
    final steps = _steps
        .where((step) => step.instructionController.text.trim().isNotEmpty)
        .map((step) => step.toJson())
        .toList();

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      'category': _category,
      'difficulty': _difficulty,
      'prep_time_minutes': int.tryParse(_prepTimeController.text),
      'cook_time_minutes': int.tryParse(_cookTimeController.text),
      'servings': int.tryParse(_servingsController.text),
      'ingredients': ingredients,
      'steps': steps,
      'photos': [],
      if (_familyNotesController.text.trim().isNotEmpty)
        'family_notes': _familyNotesController.text.trim(),
      if (_originStoryController.text.trim().isNotEmpty)
        'origin_story': _originStoryController.text.trim(),
      'family_circle_ids': [],
    };

    try {
      await widget.onSubmit(data);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.xlRadius),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        padding: EdgeInsets.all(MemoryHubSpacing.xl),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(MemoryHubSpacing.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MemoryHubColors.red500, MemoryHubColors.red400],
                    ),
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                  child: const Icon(Icons.restaurant_menu, color: Colors.white),
                ),
                const SizedBox(width: MemoryHubSpacing.lg),
                const Expanded(
                  child: Text(
                    'Add Family Recipe',
                    style: TextStyle(fontSize: MemoryHubTypography.h2, fontWeight: MemoryHubTypography.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: MemoryHubSpacing.xl),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Basic Info Section
                    _buildSectionHeader('Basic Information', Icons.info_outline),
                    const SizedBox(height: MemoryHubSpacing.md),
                    TextFormField(
                      controller: _titleController,
                      decoration: _buildInputDecoration(
                        label: 'Recipe Title *',
                        hint: 'e.g., Grandma\'s Apple Pie',
                        icon: Icons.title,
                      ),
                      validator: (v) =>
                          v?.trim().isEmpty ?? true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: MemoryHubSpacing.md),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _buildInputDecoration(
                        label: 'Description',
                        hint: 'Brief description of this recipe',
                        icon: Icons.description,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: MemoryHubSpacing.lg),

                    // Category & Difficulty
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            decoration: _buildInputDecoration(
                              label: 'Category *',
                              icon: Icons.category,
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'appetizer', child: Text('Appetizer')),
                              DropdownMenuItem(
                                  value: 'main_course',
                                  child: Text('Main Course')),
                              DropdownMenuItem(
                                  value: 'dessert', child: Text('Dessert')),
                              DropdownMenuItem(
                                  value: 'beverage', child: Text('Beverage')),
                              DropdownMenuItem(value: 'snack', child: Text('Snack')),
                              DropdownMenuItem(
                                  value: 'breakfast', child: Text('Breakfast')),
                              DropdownMenuItem(value: 'salad', child: Text('Salad')),
                              DropdownMenuItem(value: 'soup', child: Text('Soup')),
                              DropdownMenuItem(value: 'sauce', child: Text('Sauce')),
                              DropdownMenuItem(value: 'baking', child: Text('Baking')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                        ),
                        const SizedBox(width: MemoryHubSpacing.md),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _difficulty,
                            decoration: _buildInputDecoration(
                              label: 'Difficulty *',
                              icon: Icons.bar_chart,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'easy', child: Text('Easy')),
                              DropdownMenuItem(
                                  value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'hard', child: Text('Hard')),
                            ],
                            onChanged: (v) => setState(() => _difficulty = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MemoryHubSpacing.lg),

                    // Time & Servings
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _prepTimeController,
                            decoration: _buildInputDecoration(
                              label: 'Prep Time (min)',
                              icon: Icons.timer_outlined,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: MemoryHubSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _cookTimeController,
                            decoration: _buildInputDecoration(
                              label: 'Cook Time (min)',
                              icon: Icons.timer,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: MemoryHubSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _servingsController,
                            decoration: _buildInputDecoration(
                              label: 'Servings',
                              icon: Icons.people,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MemoryHubSpacing.xl),

                    // Ingredients Section
                    _buildSectionHeader('Ingredients', Icons.kitchen),
                    const SizedBox(height: MemoryHubSpacing.md),
                    ..._buildIngredientsList(),
                    TextButton.icon(
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add Ingredient'),
                      style: TextButton.styleFrom(
                        foregroundColor: MemoryHubColors.red500,
                      ),
                    ),
                    const SizedBox(height: MemoryHubSpacing.xl),

                    // Instructions Section
                    _buildSectionHeader('Instructions', Icons.list_alt),
                    const SizedBox(height: MemoryHubSpacing.md),
                    ..._buildStepsList(),
                    TextButton.icon(
                      onPressed: _addStep,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add Step'),
                      style: TextButton.styleFrom(
                        foregroundColor: MemoryHubColors.red500,
                      ),
                    ),
                    const SizedBox(height: MemoryHubSpacing.xl),

                    // Optional Notes
                    _buildSectionHeader('Optional Details', Icons.notes),
                    const SizedBox(height: MemoryHubSpacing.md),
                    TextFormField(
                      controller: _familyNotesController,
                      decoration: _buildInputDecoration(
                        label: 'Family Notes',
                        hint: 'Special tips or family traditions',
                        icon: Icons.family_restroom,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: MemoryHubSpacing.md),
                    TextFormField(
                      controller: _originStoryController,
                      decoration: _buildInputDecoration(
                        label: 'Origin Story',
                        hint: 'Where did this recipe come from?',
                        icon: Icons.history_edu,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
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
                    backgroundColor: MemoryHubColors.red500,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
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
                      : const Text(
                          'Add Recipe',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MemoryHubTypography.bodyLarge,
                            fontWeight: MemoryHubTypography.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: MemoryHubColors.red500, size: 20),
        const SizedBox(width: MemoryHubSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            fontSize: MemoryHubTypography.h4,
            fontWeight: MemoryHubTypography.bold,
            color: MemoryHubColors.red500,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.mdRadius,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.mdRadius,
        borderSide: BorderSide(color: MemoryHubColors.gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.mdRadius,
        borderSide: const BorderSide(color: MemoryHubColors.red500, width: 2),
      ),
    );
  }

  List<Widget> _buildIngredientsList() {
    return List.generate(_ingredients.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _ingredients[index].nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Flour',
                  border: OutlineInputBorder(
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                ),
              ),
            ),
            const SizedBox(width: MemoryHubSpacing.sm),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _ingredients[index].amountController,
                decoration: InputDecoration(
                  hintText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                ),
              ),
            ),
            const SizedBox(width: MemoryHubSpacing.sm),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _ingredients[index].unitController,
                decoration: InputDecoration(
                  hintText: 'Unit',
                  border: OutlineInputBorder(
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: _ingredients.length > 1 ? Colors.red : Colors.grey,
              ),
              onPressed:
                  _ingredients.length > 1 ? () => _removeIngredient(index) : null,
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildStepsList() {
    return List.generate(_steps.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: MemoryHubColors.red500,
                borderRadius: MemoryHubBorderRadius.smRadius,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: MemoryHubTypography.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: MemoryHubSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _steps[index].instructionController,
                decoration: InputDecoration(
                  hintText: 'Describe this step...',
                  border: OutlineInputBorder(
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                ),
                maxLines: 2,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: _steps.length > 1 ? Colors.red : Colors.grey,
              ),
              onPressed: _steps.length > 1 ? () => _removeStep(index) : null,
            ),
          ],
        ),
      );
    });
  }
}
