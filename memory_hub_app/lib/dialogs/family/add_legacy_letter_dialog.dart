import 'package:flutter/material.dart';

class AddLegacyLetterDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const AddLegacyLetterDialog({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<AddLegacyLetterDialog> createState() => _AddLegacyLetterDialogState();
}

class _AddLegacyLetterDialogState extends State<AddLegacyLetterDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _recipientNameController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _recipientNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'recipient_name': _recipientNameController.text.trim(),
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
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.mail, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(child: Text('Write Legacy Letter', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
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
                      decoration: const InputDecoration(labelText: 'Letter Title *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _recipientNameController,
                      decoration: const InputDecoration(labelText: 'Recipient Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Letter Content *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit),
                        alignLabelWithHint: true,
                        hintText: 'Write your heartfelt message here...',
                      ),
                      maxLines: 15,
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Content is required' : null,
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
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Save Letter', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
