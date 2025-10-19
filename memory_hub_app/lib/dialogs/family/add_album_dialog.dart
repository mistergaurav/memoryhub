import 'package:flutter/material.dart';

class AddAlbumDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const AddAlbumDialog({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<AddAlbumDialog> createState() => _AddAlbumDialogState();
}

class _AddAlbumDialogState extends State<AddAlbumDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  bool _isLoading = false;

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
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9333EA)]), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(child: Text('Create Album', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
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
                    decoration: const InputDecoration(labelText: 'Album Title *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Create Album', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
