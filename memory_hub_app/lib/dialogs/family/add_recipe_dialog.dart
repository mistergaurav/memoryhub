import 'package:flutter/material.dart';

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
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _cookTimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  
  String _difficulty = 'medium';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'ingredients': _ingredientsController.text.trim().split('\n').where((e) => e.isNotEmpty).toList(),
      'instructions': _instructionsController.text.trim().split('\n').where((e) => e.isNotEmpty).toList(),
      'prep_time': int.tryParse(_prepTimeController.text) ?? 0,
      'cook_time': int.tryParse(_cookTimeController.text) ?? 0,
      'servings': int.tryParse(_servingsController.text) ?? 4,
      'difficulty': _difficulty,
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF87171)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant_menu, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(child: Text('Add Recipe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _prepTimeController,
                            decoration: const InputDecoration(labelText: 'Prep (min)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cookTimeController,
                            decoration: const InputDecoration(labelText: 'Cook (min)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _servingsController,
                            decoration: const InputDecoration(labelText: 'Servings', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _difficulty,
                      decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'easy', child: Text('Easy')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'hard', child: Text('Hard')),
                      ],
                      onChanged: (v) => setState(() => _difficulty = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ingredientsController,
                      decoration: const InputDecoration(labelText: 'Ingredients (one per line)', border: OutlineInputBorder()),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(labelText: 'Instructions (one step per line)', border: OutlineInputBorder()),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Add Recipe', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
