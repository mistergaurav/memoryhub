import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/family/family_service.dart';

class AddHealthRecordDialog extends StatefulWidget {
  const AddHealthRecordDialog({Key? key}) : super(key: key);

  @override
  State<AddHealthRecordDialog> createState() => _AddHealthRecordDialogState();
}

class _AddHealthRecordDialogState extends State<AddHealthRecordDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _familyService = FamilyService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _providerController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String _recordType = 'medical';
  String _severity = 'low';
  DateTime _selectedDate = DateTime.now();
  bool _isConfidential = true;
  bool _isLoading = false;
  String? _errorMessage;

  String _subjectType = 'self';
  String? _selectedFamilyMemberId;
  String? _selectedFriendCircleId;
  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _friendCircles = [];
  bool _loadingMembers = false;
  bool _loadingCircles = false;

  bool _enableReminder = false;
  DateTime? _reminderDueDate;
  String _reminderType = 'custom';
  bool _showOptionalDetails = false;

  late AnimationController _animationController;
  late Animation<double> _dropdownAnimation;

  static const Color _primaryTeal = Color(0xFF0E7C86);
  static const Color _accentAqua = Color(0xFF1FB7C9);
  static const Color _supportLight = Color(0xFFF2FBFC);
  static const Color _typographyDark = Color(0xFF0B1F32);
  static const Color _background = Color(0xFFF8FAFB);
  static const Color _errorRed = Color(0xFFE63946);
  static const Color _successGreen = Color(0xFF10B981);

  final List<Map<String, String>> _recordTypes = [
    {'value': 'medical', 'label': 'Medical'},
    {'value': 'vaccination', 'label': 'Vaccination'},
    {'value': 'allergy', 'label': 'Allergy'},
    {'value': 'medication', 'label': 'Medication'},
    {'value': 'condition', 'label': 'Condition'},
    {'value': 'procedure', 'label': 'Procedure'},
    {'value': 'lab_result', 'label': 'Lab Result'},
    {'value': 'appointment', 'label': 'Appointment'},
  ];

  final List<Map<String, String>> _severityLevels = [
    {'value': 'low', 'label': 'Low'},
    {'value': 'moderate', 'label': 'Moderate'},
    {'value': 'high', 'label': 'High'},
    {'value': 'critical', 'label': 'Critical'},
  ];

  final List<Map<String, String>> _reminderTypes = [
    {'value': 'appointment', 'label': 'Appointment'},
    {'value': 'medication', 'label': 'Medication'},
    {'value': 'vaccination', 'label': 'Vaccination'},
    {'value': 'lab_test', 'label': 'Lab Test'},
    {'value': 'checkup', 'label': 'Checkup'},
    {'value': 'refill', 'label': 'Refill'},
    {'value': 'custom', 'label': 'Custom'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dropdownAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadFamilyMembers();
    _loadFriendCircles();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _providerController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyMembers() async {
    setState(() => _loadingMembers = true);
    try {
      final members = await _familyService.getFamilyMembers();
      setState(() {
        _familyMembers = members;
        _loadingMembers = false;
      });
    } catch (e) {
      setState(() => _loadingMembers = false);
    }
  }

  Future<void> _loadFriendCircles() async {
    setState(() => _loadingCircles = true);
    try {
      final circles = await _familyService.getFriendCircles();
      setState(() {
        _friendCircles = circles;
        _loadingCircles = false;
      });
    } catch (e) {
      setState(() => _loadingCircles = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectReminderDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reminderDueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        _reminderDueDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_subjectType == 'family' && _selectedFamilyMemberId == null) {
        setState(() {
          _errorMessage = 'Please select a family member';
        });
        return;
      }
      
      if (_subjectType == 'friend' && _selectedFriendCircleId == null) {
        setState(() {
          _errorMessage = 'Please select a friend circle';
        });
        return;
      }

      if (_enableReminder && _reminderDueDate == null) {
        setState(() {
          _errorMessage = 'Please select a reminder due date';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userId = await _authService.getCurrentUserId();
        if (userId == null) {
          throw Exception('Unable to get user information. Please try logging in again.');
        }

        final Map<String, dynamic> recordData = {
          'record_type': _recordType,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'provider': _providerController.text.trim(),
          'location': _locationController.text.trim(),
          'severity': _severity,
          'notes': _notesController.text.trim(),
          'medications': [],
          'attachments': [],
          'is_confidential': _isConfidential,
          'subject_type': _subjectType,
        };

        if (_subjectType == 'self') {
          recordData['subject_user_id'] = userId;
        } else if (_subjectType == 'family') {
          recordData['subject_family_member_id'] = _selectedFamilyMemberId;
        } else if (_subjectType == 'friend') {
          recordData['subject_friend_circle_id'] = _selectedFriendCircleId;
        }

        await _familyService.createHealthRecord(recordData);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Health record created successfully'),
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

  Widget _buildChoiceChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [_primaryTeal, _accentAqua],
                )
              : null,
          color: selected ? null : Colors.white,
          border: selected ? null : Border.all(color: const Color(0xFFD1E8EC)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : _primaryTeal,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : _primaryTeal,
              ),
            ),
            if (selected) ...[
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
                  const Icon(Icons.health_and_safety, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Health Record',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Track health details with clarity',
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
                      title: 'Who is this record for?',
                      icon: Icons.person,
                      helperText: 'Select the subject of this health record',
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildChoiceChip(
                              label: 'Self',
                              icon: Icons.person,
                              selected: _subjectType == 'self',
                              onTap: () {
                                setState(() {
                                  _subjectType = 'self';
                                  _selectedFamilyMemberId = null;
                                  _selectedFriendCircleId = null;
                                  _animationController.reverse();
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: 'Family Member',
                              icon: Icons.family_restroom,
                              selected: _subjectType == 'family',
                              onTap: () {
                                setState(() {
                                  _subjectType = 'family';
                                  _selectedFriendCircleId = null;
                                  _animationController.forward();
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: 'Friend Circle',
                              icon: Icons.people,
                              selected: _subjectType == 'friend',
                              onTap: () {
                                setState(() {
                                  _subjectType = 'friend';
                                  _selectedFamilyMemberId = null;
                                  _animationController.forward();
                                });
                              },
                            ),
                          ],
                        ),
                        if (_subjectType != 'self')
                          SizeTransition(
                            sizeFactor: _dropdownAnimation,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: _subjectType == 'family'
                                  ? (_loadingMembers
                                      ? const Center(child: CircularProgressIndicator(color: _accentAqua))
                                      : DropdownButtonFormField<String>(
                                          value: _selectedFamilyMemberId,
                                          decoration: _buildInputDecoration(
                                            label: 'Select Family Member',
                                            icon: Icons.person_outline,
                                            helperText: 'Choose who this record is for',
                                          ),
                                          items: _familyMembers.map((member) {
                                            return DropdownMenuItem(
                                              value: member['id']?.toString(),
                                              child: Text(member['name'] ?? 'Unknown'),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedFamilyMemberId = value;
                                            });
                                          },
                                        ))
                                  : (_loadingCircles
                                      ? const Center(child: CircularProgressIndicator(color: _accentAqua))
                                      : DropdownButtonFormField<String>(
                                          value: _selectedFriendCircleId,
                                          decoration: _buildInputDecoration(
                                            label: 'Select Friend Circle',
                                            icon: Icons.group_outlined,
                                            helperText: 'Choose which circle this record is for',
                                          ),
                                          items: _friendCircles.map((circle) {
                                            return DropdownMenuItem(
                                              value: circle['id']?.toString(),
                                              child: Text(circle['name'] ?? 'Unknown'),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedFriendCircleId = value;
                                            });
                                          },
                                        )),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Basic Information',
                      icon: Icons.assignment,
                      helperText: 'Core details about this health record',
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: _buildInputDecoration(
                            label: 'Title *',
                            icon: Icons.title,
                            helperText: 'Brief description of the record',
                          ),
                          style: GoogleFonts.inter(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 500) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _recordType,
                                      decoration: _buildInputDecoration(
                                        label: 'Record Type',
                                        icon: Icons.category,
                                        helperText: 'Type of health record',
                                      ),
                                      style: GoogleFonts.inter(color: _typographyDark),
                                      items: _recordTypes.map((type) {
                                        return DropdownMenuItem(
                                          value: type['value'],
                                          child: Text(type['label']!),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _recordType = value!;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _selectDate,
                                      child: InputDecorator(
                                        decoration: _buildInputDecoration(
                                          label: 'Date',
                                          icon: Icons.calendar_today,
                                          helperText: 'When did this occur',
                                        ),
                                        child: Text(
                                          DateFormat('MMM d, yyyy').format(_selectedDate),
                                          style: GoogleFonts.inter(color: _typographyDark),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _recordType,
                                    decoration: _buildInputDecoration(
                                      label: 'Record Type',
                                      icon: Icons.category,
                                      helperText: 'Type of health record',
                                    ),
                                    style: GoogleFonts.inter(color: _typographyDark),
                                    items: _recordTypes.map((type) {
                                      return DropdownMenuItem(
                                        value: type['value'],
                                        child: Text(type['label']!),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _recordType = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  InkWell(
                                    onTap: _selectDate,
                                    child: InputDecorator(
                                      decoration: _buildInputDecoration(
                                        label: 'Date',
                                        icon: Icons.calendar_today,
                                        helperText: 'When did this occur',
                                      ),
                                      child: Text(
                                        DateFormat('MMM d, yyyy').format(_selectedDate),
                                        style: GoogleFonts.inter(color: _typographyDark),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _buildInputDecoration(
                            label: 'Description',
                            icon: Icons.description,
                            helperText: 'Additional details about the record',
                          ),
                          style: GoogleFonts.inter(),
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
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
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          expansionTileTheme: ExpansionTileThemeData(
                            iconColor: _primaryTeal,
                            textColor: _typographyDark,
                            collapsedIconColor: const Color(0xFF6B7280),
                          ),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: _showOptionalDetails,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _showOptionalDetails = expanded;
                            });
                          },
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primaryTeal, _accentAqua],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            'Additional Details (optional)',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _typographyDark,
                            ),
                          ),
                          subtitle: Text(
                            'Provider, location, severity, and notes',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _providerController,
                                    decoration: _buildInputDecoration(
                                      label: 'Healthcare Provider',
                                      icon: Icons.local_hospital,
                                      helperText: 'Doctor or clinic name',
                                    ),
                                    style: GoogleFonts.inter(),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _locationController,
                                    decoration: _buildInputDecoration(
                                      label: 'Location',
                                      icon: Icons.location_on,
                                      helperText: 'Where this occurred',
                                    ),
                                    style: GoogleFonts.inter(),
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Severity Level',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: _typographyDark,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _severityLevels.map((level) {
                                          final isSelected = _severity == level['value'];
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _severity = level['value']!;
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                gradient: isSelected
                                                    ? const LinearGradient(
                                                        colors: [_primaryTeal, _accentAqua],
                                                      )
                                                    : null,
                                                color: isSelected ? null : _supportLight,
                                                borderRadius: BorderRadius.circular(20),
                                                border: isSelected ? null : Border.all(color: const Color(0xFFD1E8EC)),
                                              ),
                                              child: Text(
                                                level['label']!,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: isSelected ? Colors.white : _primaryTeal,
                                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _notesController,
                                    decoration: _buildInputDecoration(
                                      label: 'Notes',
                                      icon: Icons.notes,
                                      helperText: 'Any additional notes or observations',
                                    ),
                                    style: GoogleFonts.inter(),
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Reminder Settings',
                      icon: Icons.notifications_active,
                      children: [
                        SwitchListTile(
                          value: _enableReminder,
                          onChanged: (value) {
                            setState(() {
                              _enableReminder = value;
                              if (!_enableReminder) {
                                _reminderDueDate = null;
                              }
                            });
                          },
                          title: Text(
                            'Add a reminder',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _typographyDark,
                            ),
                          ),
                          subtitle: Text(
                            'Get notified about this record',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          activeColor: _accentAqua,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_enableReminder)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _supportLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _reminderType,
                                  decoration: _buildInputDecoration(
                                    label: 'Reminder Type',
                                    icon: Icons.notification_important,
                                    helperText: 'What kind of reminder is this',
                                  ),
                                  style: GoogleFonts.inter(color: _typographyDark),
                                  items: _reminderTypes.map((type) {
                                    return DropdownMenuItem(
                                      value: type['value'],
                                      child: Text(type['label']!),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _reminderType = value!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: _selectReminderDate,
                                  child: InputDecorator(
                                    decoration: _buildInputDecoration(
                                      label: 'Reminder Date *',
                                      icon: Icons.calendar_month,
                                      helperText: 'When should we remind you',
                                    ),
                                    child: Text(
                                      _reminderDueDate != null
                                          ? DateFormat('MMMM d, yyyy').format(_reminderDueDate!)
                                          : 'Select reminder date',
                                      style: GoogleFonts.inter(
                                        color: _reminderDueDate != null ? _typographyDark : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEDF7F8),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryTeal,
                      minimumSize: const Size(88, 44),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _submit,
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryTeal, _accentAqua],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Save Record',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
