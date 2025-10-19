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
  
  String _category = 'achievement';
  DateTime _milestoneDate = DateTime.now();
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'achievement', 'label': 'Achievement'},
    {'value': 'birthday', 'label': 'Birthday'},
    {'value': 'graduation', 'label': 'Graduation'},
    {'value': 'anniversary', 'label': 'Anniversary'},
    {'value': 'first', 'label': 'First Time'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _personNameController.dispose();
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

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _category,
      'milestone_date': _milestoneDate.toIso8601String(),
      'person_name': _personNameController.text.trim(),
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
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
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
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((cat) => DropdownMenuItem(
                      value: cat['value'],
                      child: Text(cat['label']!),
                    )).toList(),
                    onChanged: (value) => setState(() => _category = value!),
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
                    controller: _personNameController,
                    decoration: const InputDecoration(
                      labelText: 'Person Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ],
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
