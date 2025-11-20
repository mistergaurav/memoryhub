import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/layout/gap.dart';
import '../../design_system/layout/padded.dart';
import '../../design_system/components/buttons/primary_button.dart';
import '../../design_system/components/feedback/app_snackbar.dart';
import '../../design_system/components/surfaces/app_card.dart';
import '../../design_system/utils/context_ext.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../config/api_config.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  File? _avatarFile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final user = await _apiService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _emailController.text = user.email;
        _usernameController.text = user.username ?? '';
        _fullNameController.text = user.fullName ?? '';
        _bioController.text = user.bio ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Error loading profile: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (!mounted) return;

      if (result != null && result.files.single.path != null) {
        setState(() {
          _avatarFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Error picking image: $e',
      );
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) setState(() => _isSaving = true);

    try {
      if (_avatarFile != null) {
        await _apiService.uploadAvatar(_avatarFile!);
        if (!mounted) return;
      }

      final userUpdate = UserUpdate(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      );

      await _apiService.updateUser(userUpdate);

      if (!mounted) return;
      
      AppSnackbar.success(context, 'Profile updated successfully!',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(MemoryHubSpacing.lg),
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MemoryHubColors.indigo500,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MemoryHubColors.indigo500.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: context.colors.primary,
                      backgroundImage: _avatarFile != null
                          ? FileImage(_avatarFile!)
                          : (_currentUser?.avatarUrl != null
                              ? NetworkImage(ApiConfig.getAssetUrl(_currentUser!.avatarUrl!))
                              : null) as ImageProvider?,
                      child: _avatarFile == null && _currentUser?.avatarUrl == null
                          ? Text(
                              (_currentUser?.email != null && _currentUser!.email.isNotEmpty)
                                  ? _currentUser!.email.substring(0, 1).toUpperCase()
                                  : 'U',
                              style: context.text.displaySmall?.copyWith(
                                color: context.colors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MemoryHubColors.indigo500,
                        border: Border.all(
                          color: context.colors.surface,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, color: context.colors.onPrimary, size: 20),
                        onPressed: _pickAvatar,
                        tooltip: 'Change Avatar',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            VGap.xxl(),
            AppCard(
              padding: EdgeInsets.all(MemoryHubSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Details',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  VGap.lg(),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: MemoryHubBorderRadius.mdRadius,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  VGap.md(),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: OutlineInputBorder(
                        borderRadius: MemoryHubBorderRadius.mdRadius,
                      ),
                      hintText: 'Choose a unique username',
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        if (value.trim().length > 30) {
                          return 'Username must be less than 30 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value.trim())) {
                          return 'Username can only contain letters, numbers, _ and -';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            VGap.lg(),
            AppCard(
              padding: EdgeInsets.all(MemoryHubSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  VGap.lg(),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: MemoryHubBorderRadius.mdRadius,
                      ),
                    ),
                  ),
                  VGap.md(),
                  TextFormField(
                    controller: _bioController,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      prefixIcon: const Icon(Icons.info_outline),
                      border: OutlineInputBorder(
                        borderRadius: MemoryHubBorderRadius.mdRadius,
                      ),
                      alignLabelWithHint: true,
                      hintText: 'Tell us about yourself...',
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            VGap.xxl(),
            PrimaryButton(
              onPressed: _isSaving ? null : _handleSave,
              isLoading: _isSaving,
              label: 'Save Changes',
              fullWidth: true,
            ),
            VGap.lg(),
          ],
        ),
      ),
    );
  }
}
