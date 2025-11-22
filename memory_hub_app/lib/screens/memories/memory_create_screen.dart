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
import '../../widgets/memories/visibility_selector.dart';
import '../../widgets/memories/user_selection_sheet.dart';
import '../../widgets/memories/circle_selection_sheet.dart';

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
  
  VisibilityType _visibilityType = VisibilityType.private;
  List<String> _allowedUserIds = [];
  List<String> _familyCircleIds = [];
  
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

  void _showVisibilityOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padded.lg(
            child: Text('Who can see this memory?', style: context.text.titleLarge),
          ),
          const Divider(height: 1),
          _buildVisibilityOption(VisibilityType.private, 'Private', 'Only you', Icons.lock_outline),
          _buildVisibilityOption(VisibilityType.friends, 'Friends', 'Your friends', Icons.people_outline),
          _buildVisibilityOption(VisibilityType.family, 'Family', 'Your family members', Icons.family_restroom),
          _buildVisibilityOption(VisibilityType.familyCircle, 'Family Circle', 'Select specific circles', Icons.diversity_3),
          _buildVisibilityOption(VisibilityType.specificUsers, 'Specific Users', 'Select specific people', Icons.person_add_alt),
          _buildVisibilityOption(VisibilityType.public, 'Public', 'Anyone on MemoryHub', Icons.public),
          VGap.lg(),
        ],
      ),
    );
  }

  Widget _buildVisibilityOption(VisibilityType type, String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: context.colors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context);
        _handleVisibilitySelection(type);
      },
      trailing: _visibilityType == type ? Icon(Icons.check, color: context.colors.primary) : null,
    );
  }

  void _handleVisibilitySelection(VisibilityType type) {
    if (type == VisibilityType.specificUsers) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => UserSelectionSheet(
          initialSelectedIds: _allowedUserIds,
          onSelectionChanged: (ids) {
            setState(() {
              _visibilityType = type;
              _allowedUserIds = ids;
              _familyCircleIds = []; // Clear circles if switching to users
            });
          },
        ),
      );
    } else if (type == VisibilityType.familyCircle) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => CircleSelectionSheet(
          initialSelectedIds: _familyCircleIds,
          onSelectionChanged: (ids) {
            setState(() {
              _visibilityType = type;
              _familyCircleIds = ids;
              _allowedUserIds = []; // Clear users if switching to circles
            });
          },
        ),
      );
    } else {
      setState(() {
        _visibilityType = type;
        _allowedUserIds = [];
        _familyCircleIds = [];
      });
    }
  }

  String _getPrivacyString() {
    switch (_visibilityType) {
      case VisibilityType.private: return 'private';
      case VisibilityType.friends: return 'friends';
      case VisibilityType.public: return 'public';
      case VisibilityType.family: return 'family';
      case VisibilityType.familyCircle: return 'family_circle';
      case VisibilityType.specificUsers: return 'specific_users';
    }
  }

  String? _getSpecificLabel() {
    if (_visibilityType == VisibilityType.specificUsers && _allowedUserIds.isNotEmpty) {
      return '${_allowedUserIds.length} people';
    }
    if (_visibilityType == VisibilityType.familyCircle && _familyCircleIds.isNotEmpty) {
      return '${_familyCircleIds.length} circles';
    }
    return null;
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
        privacy: _getPrivacyString(),
        allowedUserIds: _allowedUserIds,
        familyCircleIds: _familyCircleIds,
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
          padding: const EdgeInsets.all(16),
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
            VGap.lg(),
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
            VGap.lg(),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: 'Tags',
                      border: OutlineInputBorder(
                        borderRadius: Radii.lgRadius,
                      ),
                      hintText: 'travel, family',
                    ),
                    style: context.text.bodyLarge,
                  ),
                ),
                HGap.md(),
                Expanded(
                  child: TextFormField(
                    controller: _moodController,
                    decoration: InputDecoration(
                      labelText: 'Mood',
                      border: OutlineInputBorder(
                        borderRadius: Radii.lgRadius,
                      ),
                      hintText: 'Happy',
                    ),
                    style: context.text.bodyLarge,
                  ),
                ),
              ],
            ),
            VGap.lg(),
            Row(
              children: [
                Text('Visibility:', style: context.text.bodyLarge),
                HGap.md(),
                VisibilitySelector(
                  selectedType: _visibilityType,
                  onTap: _showVisibilityOptions,
                  specificLabel: _getSpecificLabel(),
                ),
              ],
            ),
            VGap.xl(),
            Text(
              'Media Files',
              style: context.text.titleMedium?.copyWith(
                fontWeight: MemoryHubTypography.bold,
              ),
            ),
            VGap.xs(),
            if (_selectedFiles.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
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
                            width: double.infinity,
                            height: double.infinity,
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
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeFile(index),
                          child: Container(
                            padding: EdgeInsets.all(Spacing.xxs),
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
            if (_selectedFiles.isNotEmpty) VGap.xs(),
            SecondaryButton(
              onPressed: _pickFiles,
              label: 'Add Media Files',
              leading: const Icon(Icons.add_photo_alternate),
              fullWidth: true,
            ),
            VGap.xl(),
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
            VGap.lg(),
          ],
        ),
      ),
    );
  }
}
