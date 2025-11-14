import 'package:flutter/material.dart';
import '../../design_system/design_tokens.dart';

class AddTraditionDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const AddTraditionDialog({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<AddTraditionDialog> createState() => _AddTraditionDialogState();
}

class _AddTraditionDialogState extends State<AddTraditionDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  
  String _category = 'holiday';
  String _frequency = 'yearly';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _category,
      'frequency': _frequency,
      'origin': _originController.text.trim(),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.xlRadius),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(MemoryHubSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(MemoryHubSpacing.md),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [MemoryHubColors.green500, MemoryHubColors.green400]), borderRadius: MemoryHubBorderRadius.mdRadius),
                  child: const Icon(Icons.local_florist, color: Colors.white),
                ),
                const SizedBox(width: MemoryHubSpacing.lg),
                const Expanded(child: Text('Add Tradition', style: TextStyle(fontSize: MemoryHubTypography.h2, fontWeight: MemoryHubTypography.bold))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: MemoryHubSpacing.xl),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: MemoryHubSpacing.lg),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                    maxLines: 3,
                  ),
                  const SizedBox(height: MemoryHubSpacing.lg),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'holiday', child: Text('Holiday')),
                      DropdownMenuItem(value: 'celebration', child: Text('Celebration')),
                      DropdownMenuItem(value: 'ritual', child: Text('Ritual')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: MemoryHubSpacing.lg),
                  DropdownButtonFormField<String>(
                    value: _frequency,
                    decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                    ],
                    onChanged: (v) => setState(() => _frequency = v!),
                  ),
                  const SizedBox(height: MemoryHubSpacing.lg),
                  TextFormField(
                    controller: _originController,
                    decoration: const InputDecoration(labelText: 'Origin/History', border: OutlineInputBorder(), prefixIcon: Icon(Icons.history)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MemoryHubSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: MemoryHubSpacing.md),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: MemoryHubColors.green500, padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.xxl, vertical: MemoryHubSpacing.lg)),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Add Tradition', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
