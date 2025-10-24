import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/family/family_service.dart';

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

  static const Color _primaryTeal = Color(0xFF0E7C86);
  static const Color _accentAqua = Color(0xFF1FB7C9);
  static const Color _supportLight = Color(0xFFF2FBFC);
  static const Color _typographyDark = Color(0xFF0B1F32);
  static const Color _background = Color(0xFFF8FAFB);
  static const Color _errorRed = Color(0xFFE63946);
  static const Color _successGreen = Color(0xFF10B981);

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
      duration: const Duration(milliseconds: 300),
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
              primary: _primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _typographyDark,
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
                  SizedBox(width: 12),
                  Text('Document created successfully'),
                ],
              ),
              backgroundColor: _primaryTeal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
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
        margin: const EdgeInsets.all(12),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: _primaryTeal.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: _primaryTeal),
      ),
      filled: true,
      fillColor: _supportLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accentAqua, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorRed, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        color: _typographyDark,
      ),
      helperStyle: GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF6B7280),
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: 12,
        color: _errorRed,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140E7C86),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryTeal, _accentAqua],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _typographyDark,
                      ),
                    ),
                    if (helperText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        helperText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [_primaryTeal, _accentAqua],
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: isSelected ? null : Border.all(color: const Color(0xFFD1E8EC)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type['icon'],
              size: 18,
              color: isSelected ? Colors.white : _primaryTeal,
            ),
            const SizedBox(width: 8),
            Text(
              type['label'],
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : _primaryTeal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
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
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F0C5A6E),
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
                  colors: [_primaryTeal, _accentAqua],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.folder_special, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Document',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Securely store important documents',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
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
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFFDEBEC),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: _errorRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          color: _errorRed,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _errorMessage = null),
                      color: _errorRed,
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
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSectionCard(
                      title: 'Document Type',
                      icon: Icons.category,
                      helperText: 'Select the type of document you are adding',
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _documentTypes.map((type) => _buildDocumentTypeChip(type)).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryTeal, _accentAqua],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add, color: Colors.white),
                                onPressed: _addTag,
                              ),
                            ),
                          ],
                        ),
                        if (_tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tags.map((tag) {
                              return Chip(
                                label: Text(tag),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => _removeTag(tag),
                                backgroundColor: _supportLight,
                                labelStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _primaryTeal,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _accentAqua.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryTeal, _accentAqua],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.settings, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Advanced Options',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _typographyDark,
                                ),
                              ),
                            ),
                            Icon(
                              _showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
                              color: _primaryTeal,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizeTransition(
                      sizeFactor: _advancedAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _documentNumberController,
                              decoration: _buildInputDecoration(
                                label: 'Document Number',
                                icon: Icons.confirmation_number,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _issuingAuthorityController,
                              decoration: _buildInputDecoration(
                                label: 'Issuing Authority',
                                icon: Icons.account_balance,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                    const SizedBox(height: 24),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryTeal, _accentAqua],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryTeal.withOpacity(0.4),
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
                            borderRadius: BorderRadius.circular(16),
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
                                  const SizedBox(width: 12),
                                  Text(
                                    'Save Document',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
