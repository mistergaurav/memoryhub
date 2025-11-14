import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/family/family_service.dart';
import '../../design_system/design_tokens.dart';

class AddDocumentDialog extends StatefulWidget {
  const AddDocumentDialog({Key? key}) : super(key: key);

  @override
  State<AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends State<AddDocumentDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _familyService = FamilyService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fileNameController = TextEditingController();
  final _fileSizeController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _issuingAuthorityController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();

  String _documentType = 'birth_certificate';
  DateTime? _expirationDate;
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _tags = [];
  bool _showAdvancedOptions = false;

  late AnimationController _animationController;
  late Animation<double> _advancedAnimation;

  final List<Map<String, dynamic>> _documentTypes = [
    {'value': 'birth_certificate', 'label': 'Birth Certificate', 'icon': Icons.badge},
    {'value': 'passport', 'label': 'Passport', 'icon': Icons.flight},
    {'value': 'drivers_license', 'label': 'Driver\'s License', 'icon': Icons.directions_car},
    {'value': 'ssn_card', 'label': 'SSN Card', 'icon': Icons.credit_card},
    {'value': 'insurance', 'label': 'Insurance', 'icon': Icons.shield},
    {'value': 'will', 'label': 'Will', 'icon': Icons.gavel},
    {'value': 'deed', 'label': 'Deed', 'icon': Icons.home},
    {'value': 'title', 'label': 'Title', 'icon': Icons.description},
    {'value': 'contract', 'label': 'Contract', 'icon': Icons.handshake},
    {'value': 'tax_document', 'label': 'Tax Document', 'icon': Icons.attach_money},
    {'value': 'medical_record', 'label': 'Medical Record', 'icon': Icons.local_hospital},
    {'value': 'education', 'label': 'Education', 'icon': Icons.school},
    {'value': 'other', 'label': 'Other', 'icon': Icons.folder},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: MemoryHubAnimations.fast,
      vsync: this,
    );
    _advancedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _fileNameController.dispose();
    _fileSizeController.dispose();
    _documentNumberController.dispose();
    _issuingAuthorityController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MemoryHubColors.teal600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: MemoryHubColors.gray900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  void _addTag() {
    if (_tagController.text.trim().isNotEmpty) {
      setState(() {
        if (!_tags.contains(_tagController.text.trim())) {
          _tags.add(_tagController.text.trim());
        }
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_fileNameController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please provide a file name';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final int fileSize = int.tryParse(_fileSizeController.text.trim()) ?? 0;

        final Map<String, dynamic> documentData = {
          'document_type': _documentType,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'file_url': 'placeholder://document/${_fileNameController.text.trim()}',
          'file_name': _fileNameController.text.trim(),
          'file_size': fileSize > 0 ? fileSize : 1024,
          'mime_type': 'application/pdf',
          'tags': _tags,
          'notes': _notesController.text.trim(),
          'is_encrypted': false,
          'access_level': 'owner',
        };

        if (_expirationDate != null) {
          documentData['expiration_date'] = DateFormat('yyyy-MM-dd').format(_expirationDate!);
        }

        if (_documentNumberController.text.trim().isNotEmpty) {
          documentData['document_number'] = _documentNumberController.text.trim();
        }

        if (_issuingAuthorityController.text.trim().isNotEmpty) {
          documentData['issuing_authority'] = _issuingAuthorityController.text.trim();
        }

        await _familyService.createDocument(documentData);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: MemoryHubSpacing.md),
                  Text('Document created successfully'),
                ],
              ),
              backgroundColor: MemoryHubColors.teal600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
              margin: const EdgeInsets.all(MemoryHubSpacing.lg),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Container(
        margin: const EdgeInsets.all(MemoryHubSpacing.md),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: MemoryHubColors.teal600.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: MemoryHubColors.teal600),
      ),
      filled: true,
      fillColor: MemoryHubColors.gray50,
      border: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.mdRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.mdRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.mdRadius,
        borderSide: const BorderSide(color: MemoryHubColors.cyan500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.mdRadius,
        borderSide: const BorderSide(color: MemoryHubColors.red500, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: MemoryHubBorderRadius.mdRadius,
        borderSide: const BorderSide(color: MemoryHubColors.red500, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: MemoryHubTypography.body2,
        color: MemoryHubColors.gray900,
      ),
      helperStyle: GoogleFonts.inter(
        fontSize: MemoryHubTypography.caption,
        color: MemoryHubColors.gray500,
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: MemoryHubTypography.caption,
        color: MemoryHubColors.red500,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? helperText,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: MemoryHubBorderRadius.xlRadius,
        boxShadow: const [
          BoxShadow(
            color: MemoryHubColors.cyan600.withOpacity(0.08),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(MemoryHubSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MemoryHubColors.teal600, MemoryHubColors.cyan500],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: MemoryHubSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: MemoryHubTypography.body1,
                        fontWeight: MemoryHubTypography.semiBold,
                        color: MemoryHubColors.gray900,
                      ),
                    ),
                    if (helperText != null) ...[
                      const SizedBox(height: MemoryHubSpacing.xs),
                      Text(
                        helperText,
                        style: GoogleFonts.inter(
                          fontSize: MemoryHubTypography.caption,
                          color: MemoryHubColors.gray500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MemoryHubSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDocumentTypeChip(Map<String, dynamic> type) {
    final bool isSelected = _documentType == type['value'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _documentType = type['value'];
        });
      },
      child: AnimatedContainer(
        duration: MemoryHubAnimations.normal,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [MemoryHubColors.teal600, MemoryHubColors.cyan500],
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: isSelected ? null : Border.all(color: MemoryHubColors.gray200),
          borderRadius: MemoryHubBorderRadius.fullRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type['icon'],
              size: 18,
              color: isSelected ? Colors.white : MemoryHubColors.teal600,
            ),
            const SizedBox(width: MemoryHubSpacing.sm),
            Text(
              type['label'],
              style: GoogleFonts.inter(
                fontSize: MemoryHubTypography.body2,
                fontWeight: MemoryHubTypography.medium,
                color: isSelected ? Colors.white : MemoryHubColors.teal600,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: MemoryHubSpacing.xs),
              const Icon(Icons.check, size: 16, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(MemoryHubSpacing.lg),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: MemoryHubColors.gray50,
          borderRadius: MemoryHubBorderRadius.xxlRadius,
          boxShadow: const [
            BoxShadow(
              color: MemoryHubColors.cyan700.withOpacity(0.12),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 64,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [MemoryHubColors.teal600, MemoryHubColors.cyan500],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(MemoryHubBorderRadius.xxl),
                  topRight: Radius.circular(MemoryHubBorderRadius.xxl),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.xl),
              child: Row(
                children: [
                  const Icon(Icons.folder_special, color: Colors.white, size: 28),
                  const SizedBox(width: MemoryHubSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Document',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: MemoryHubTypography.h3,
                            fontWeight: MemoryHubTypography.semiBold,
                          ),
                        ),
                        Text(
                          'Securely store important documents',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: MemoryHubTypography.body2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              AnimatedContainer(
                duration: MemoryHubAnimations.normal,
                width: double.infinity,
                padding: const EdgeInsets.all(MemoryHubSpacing.md),
                color: MemoryHubColors.red50,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: MemoryHubColors.red500, size: 20),
                    const SizedBox(width: MemoryHubSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          color: MemoryHubColors.red500,
                          fontSize: MemoryHubTypography.body2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _errorMessage = null),
                      color: MemoryHubColors.red500,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(MemoryHubSpacing.xl),
                  children: [
                    _buildSectionCard(
                      title: 'Document Type',
                      icon: Icons.category,
                      helperText: 'Select the type of document you are adding',
                      children: [
                        Wrap(
                          spacing: MemoryHubSpacing.sm,
                          runSpacing: MemoryHubSpacing.sm,
                          children: _documentTypes.map((type) => _buildDocumentTypeChip(type)).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: MemoryHubSpacing.lg),
                    _buildSectionCard(
                      title: 'Document Information',
                      icon: Icons.info,
                      helperText: 'Basic details about the document',
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: _buildInputDecoration(
                            label: 'Document Title',
                            icon: Icons.title,
                            helperText: 'e.g., "John\'s Birth Certificate"',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a document title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: MemoryHubSpacing.lg),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _buildInputDecoration(
                            label: 'Description (Optional)',
                            icon: Icons.description,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: MemoryHubSpacing.lg),
                    _buildSectionCard(
                      title: 'File Details',
                      icon: Icons.upload_file,
                      helperText: 'File upload information (placeholder)',
                      children: [
                        TextFormField(
                          controller: _fileNameController,
                          decoration: _buildInputDecoration(
                            label: 'File Name',
                            icon: Icons.insert_drive_file,
                            helperText: 'e.g., "birth_certificate.pdf"',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a file name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: MemoryHubSpacing.lg),
                        TextFormField(
                          controller: _fileSizeController,
                          decoration: _buildInputDecoration(
                            label: 'File Size (bytes)',
                            icon: Icons.data_usage,
                            helperText: 'e.g., "102400" for 100KB',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    const SizedBox(height: MemoryHubSpacing.lg),
                    _buildSectionCard(
                      title: 'Tags',
                      icon: Icons.label,
                      helperText: 'Add tags to organize your documents',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _tagController,
                                decoration: _buildInputDecoration(
                                  label: 'Add Tag',
                                  icon: Icons.add,
                                ),
                                onFieldSubmitted: (_) => _addTag(),
                              ),
                            ),
                            const SizedBox(width: MemoryHubSpacing.sm),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [MemoryHubColors.teal600, MemoryHubColors.cyan500],
                                ),
                                borderRadius: MemoryHubBorderRadius.mdRadius,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add, color: Colors.white),
                                onPressed: _addTag,
                              ),
                            ),
                          ],
                        ),
                        if (_tags.isNotEmpty) ...[
                          const SizedBox(height: MemoryHubSpacing.md),
                          Wrap(
                            spacing: MemoryHubSpacing.sm,
                            runSpacing: MemoryHubSpacing.sm,
                            children: _tags.map((tag) {
                              return Chip(
                                label: Text(tag),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => _removeTag(tag),
                                backgroundColor: MemoryHubColors.gray50,
                                labelStyle: GoogleFonts.inter(
                                  fontSize: MemoryHubTypography.caption,
                                  color: MemoryHubColors.teal600,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: MemoryHubSpacing.lg),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAdvancedOptions = !_showAdvancedOptions;
                          if (_showAdvancedOptions) {
                            _animationController.forward();
                          } else {
                            _animationController.reverse();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(MemoryHubSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: MemoryHubBorderRadius.mdRadius,
                          border: Border.all(color: MemoryHubColors.cyan500.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [MemoryHubColors.teal600, MemoryHubColors.cyan500],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.settings, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: MemoryHubSpacing.md),
                            Expanded(
                              child: Text(
                                'Advanced Options',
                                style: GoogleFonts.inter(
                                  fontSize: MemoryHubTypography.body1,
                                  fontWeight: MemoryHubTypography.semiBold,
                                  color: MemoryHubColors.gray900,
                                ),
                              ),
                            ),
                            Icon(
                              _showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
                              color: MemoryHubColors.teal600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizeTransition(
                      sizeFactor: _advancedAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(top: MemoryHubSpacing.lg),
                        child: _buildSectionCard(
                          title: 'Optional Details',
                          icon: Icons.edit_note,
                          children: [
                            GestureDetector(
                              onTap: _selectExpirationDate,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: _buildInputDecoration(
                                    label: 'Expiration Date',
                                    icon: Icons.calendar_today,
                                  ),
                                  controller: TextEditingController(
                                    text: _expirationDate != null
                                        ? DateFormat('MMM dd, yyyy').format(_expirationDate!)
                                        : '',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: MemoryHubSpacing.lg),
                            TextFormField(
                              controller: _documentNumberController,
                              decoration: _buildInputDecoration(
                                label: 'Document Number',
                                icon: Icons.confirmation_number,
                              ),
                            ),
                            const SizedBox(height: MemoryHubSpacing.lg),
                            TextFormField(
                              controller: _issuingAuthorityController,
                              decoration: _buildInputDecoration(
                                label: 'Issuing Authority',
                                icon: Icons.account_balance,
                              ),
                            ),
                            const SizedBox(height: MemoryHubSpacing.lg),
                            TextFormField(
                              controller: _notesController,
                              decoration: _buildInputDecoration(
                                label: 'Notes',
                                icon: Icons.note,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: MemoryHubSpacing.xl),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [MemoryHubColors.teal600, MemoryHubColors.cyan500],
                        ),
                        borderRadius: MemoryHubBorderRadius.lgRadius,
                        boxShadow: [
                          BoxShadow(
                            color: MemoryHubColors.teal600.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: MemoryHubBorderRadius.lgRadius,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.save, color: Colors.white),
                                  const SizedBox(width: MemoryHubSpacing.md),
                                  Text(
                                    'Save Document',
                                    style: GoogleFonts.inter(
                                      fontSize: MemoryHubTypography.body1,
                                      fontWeight: MemoryHubTypography.semiBold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
