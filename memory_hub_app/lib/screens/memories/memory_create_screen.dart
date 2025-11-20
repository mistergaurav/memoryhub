import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../models/memory.dart';
import '../../design_system/layout/gap.dart';
import '../../design_system/layout/padded.dart';
import '../../design_system/components/buttons/primary_button.dart';
import '../../design_system/components/buttons/secondary_button.dart';
import '../../design_system/components/inputs/text_field_x.dart';
import '../../design_system/utils/context_ext.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';

class MemoryCreateScreen extends StatefulWidget {
  const MemoryCreateScreen({super.key});

  @override
  State<MemoryCreateScreen> createState() => _MemoryCreateScreenState();
}

class _MemoryCreateScreenState extends State<MemoryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _moodController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  String _privacy = 'private';
  List<File> _selectedFiles = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(
            result.paths.where((path) => path != null).map((path) => File(path!)),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        context.showSnackbar('Error picking files: $e', isError: true);
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final memoryCreate = MemoryCreate(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: tags,
        privacy: _privacy,
        mood: _moodController.text.trim().isEmpty ? null : _moodController.text.trim(),
      );

      await _apiService.createMemory(
        memoryCreate,
        _selectedFiles.isEmpty ? null : _selectedFiles,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        context.showSnackbar('Memory created successfully!');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackbar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Memory', style: context.text.titleLarge),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: Radii.lgRadius,
                ),
              ),
              style: context.text.bodyLarge,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const VGap.lg(),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(
                  borderRadius: Radii.lgRadius,
                ),
                alignLabelWithHint: true,
              ),
              style: context.text.bodyLarge,
              maxLines: 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter content';
                }
                return null;
              },
            ),
            const VGap.lg(),
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(
                  borderRadius: Radii.lgRadius,
                ),
                hintText: 'travel, family, vacation',
              ),
              style: context.text.bodyLarge,
            ),
            const VGap.lg(),
            TextFormField(
              controller: _moodController,
              decoration: InputDecoration(
                labelText: 'Mood (optional)',
                border: OutlineInputBorder(
                  borderRadius: Radii.lgRadius,
                ),
                hintText: 'Happy, Excited, Nostalgic',
              ),
              style: context.text.bodyLarge,
            ),
            const VGap.lg(),
            DropdownButtonFormField<String>(
              value: _privacy,
              decoration: InputDecoration(
                labelText: 'Privacy',
                border: OutlineInputBorder(
                  borderRadius: Radii.lgRadius,
                ),
              ),
              style: context.text.bodyLarge,
              items: const [
                DropdownMenuItem(value: 'private', child: Text('Private')),
                DropdownMenuItem(value: 'friends', child: Text('Friends')),
                DropdownMenuItem(value: 'public', child: Text('Public')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _privacy = value);
                }
              },
            ),
            const VGap.xl(),
            Text(
              'Media Files',
              style: context.text.titleMedium?.copyWith(
                fontWeight: MemoryHubTypography.bold,
              ),
            ),
            const VGap.xs(),
            if (_selectedFiles.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: Spacing.xs),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: context.colors.outline,
                            ),
                            borderRadius: Radii.smRadius,
                          ),
                          child: ClipRRect(
                            borderRadius: Radii.smRadius,
                            child: Image.file(
                              _selectedFiles[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.file_present,
                                    color: context.colors.outline,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeFile(index),
                            child: Container(
                              padding: const EdgeInsets.all(Spacing.xxs),
                              decoration: BoxDecoration(
                                color: MemoryHubColors.red500,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: context.colors.onError,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (_selectedFiles.isNotEmpty) const VGap.xs(),
            SecondaryButton(
              onPressed: _pickFiles,
              label: 'Add Media Files',
              leading: const Icon(Icons.add_photo_alternate),
              fullWidth: true,
            ),
            const VGap.xl(),
            PrimaryButton(
              onPressed: _isLoading ? null : _handleCreate,
              label: _isLoading ? 'Posting...' : 'Post Memory',
              leading: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send),
              isLoading: _isLoading,
              fullWidth: true,
            ),
            const VGap.lg(),
          ],
        ),
      ),
    );
  }
}
