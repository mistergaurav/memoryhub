import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/family/family_service.dart';
import '../../models/user_search_result.dart';
import '../../widgets/user_search_autocomplete.dart';
import 'controllers/add_health_record_controller.dart';

class AddHealthRecordDialog extends StatefulWidget {
  const AddHealthRecordDialog({Key? key}) : super(key: key);

  @override
  State<AddHealthRecordDialog> createState() => _AddHealthRecordDialogState();
}

class _AddHealthRecordDialogState extends State<AddHealthRecordDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _familyService = FamilyService();
  final _controller = AddHealthRecordController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _providerController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String _recordType = 'medical';
  String _severity = 'low';
  DateTime _selectedDate = DateTime.now();
  bool _isConfidential = true;

  String _subjectType = 'self';
  String? _selectedFamilyMemberId;
  String? _selectedFriendCircleId;
  UserSearchResult? _selectedUser;
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
    _controller.dispose();
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final subjectValidation = _controller.validateSubjectSelection(
      subjectType: _subjectType,
      selectedFamilyMemberId: _selectedFamilyMemberId,
      selectedFriendCircleId: _selectedFriendCircleId,
      selectedUser: _selectedUser,
    );

    if (subjectValidation != null) {
      setState(() {});
      return;
    }

    final reminderValidation = _controller.validateReminderDate(
      enableReminder: _enableReminder,
      reminderDueDate: _reminderDueDate,
    );

    if (reminderValidation != null) {
      setState(() {});
      return;
    }

    final success = await _controller.submitHealthRecord(
      recordType: _recordType,
      title: _titleController.text,
      description: _descriptionController.text,
      selectedDate: _selectedDate,
      provider: _providerController.text,
      location: _locationController.text,
      severity: _severity,
      notes: _notesController.text,
      isConfidential: _isConfidential,
      subjectType: _subjectType,
      selectedFamilyMemberId: _selectedFamilyMemberId,
      selectedFriendCircleId: _selectedFriendCircleId,
      selectedUser: _selectedUser,
      enableReminder: _enableReminder,
      reminderDueDate: _reminderDueDate,
      reminderType: _reminderType,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Health record created successfully'),
              ),
            ],
          ),
          backgroundColor: _successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _retrySubmit() async {
    final success = await _controller.retrySubmission(
      recordType: _recordType,
      title: _titleController.text,
      description: _descriptionController.text,
      selectedDate: _selectedDate,
      provider: _providerController.text,
      location: _locationController.text,
      severity: _severity,
      notes: _notesController.text,
      isConfidential: _isConfidential,
      subjectType: _subjectType,
      selectedFamilyMemberId: _selectedFamilyMemberId,
      selectedFriendCircleId: _selectedFriendCircleId,
      selectedUser: _selectedUser,
      enableReminder: _enableReminder,
      reminderDueDate: _reminderDueDate,
      reminderType: _reminderType,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Health record created successfully'),
              ),
            ],
          ),
          backgroundColor: _successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop(true);
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
                    onPressed: _controller.isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.errorMessage != null) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDEBEC),
                      border: Border(
                        bottom: BorderSide(
                          color: _errorRed.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _errorRed.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.error_outline, color: _errorRed, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Submission Failed',
                                style: GoogleFonts.inter(
                                  color: _errorRed,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _controller.errorMessage!,
                                style: GoogleFonts.inter(
                                  color: _errorRed.withOpacity(0.9),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              if (_controller.canRetry) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _retrySubmit,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: Text(
                                    'Retry',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _errorRed,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _controller.clearError();
                          },
                          color: _errorRed,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
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
                                  _selectedUser = null;
                                  _animationController.forward();
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: 'Other User',
                              icon: Icons.person_search,
                              selected: _subjectType == 'user',
                              onTap: () {
                                setState(() {
                                  _subjectType = 'user';
                                  _selectedFamilyMemberId = null;
                                  _selectedFriendCircleId = null;
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
                              child: _subjectType == 'user'
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        UserSearchAutocomplete(
                                          onUserSelected: (user) {
                                            setState(() => _selectedUser = user);
                                          },
                                          helpText: 'Search by name or email to find users in your family circle',
                                        ),
                                        if (_selectedUser != null) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: _successGreen.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _successGreen.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: _successGreen,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Selected User',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 12,
                                                          color: const Color(0xFF6B7280),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _selectedUser!.fullName,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: _typographyDark,
                                                        ),
                                                      ),
                                                      if (_selectedUser!.email != null)
                                                        Text(
                                                          _selectedUser!.email!,
                                                          style: GoogleFonts.inter(
                                                            fontSize: 13,
                                                            color: const Color(0xFF6B7280),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close, color: _errorRed),
                                                  onPressed: () {
                                                    setState(() => _selectedUser = null);
                                                  },
                                                  tooltip: 'Remove selection',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    )
                                  : _subjectType == 'family'
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
                          validator: _controller.validateTitle,
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
                            label: 'Description *',
                            icon: Icons.description,
                            helperText: 'Additional details about the record (minimum 10 characters)',
                          ),
                          style: GoogleFonts.inter(),
                          maxLines: 2,
                          validator: _controller.validateDescription,
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
                                      helperText: 'Doctor or clinic name (optional)',
                                    ),
                                    style: GoogleFonts.inter(),
                                    validator: _controller.validateProvider,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _locationController,
                                    decoration: _buildInputDecoration(
                                      label: 'Location',
                                      icon: Icons.location_on,
                                      helperText: 'Where this occurred (optional)',
                                    ),
                                    style: GoogleFonts.inter(),
                                    validator: _controller.validateLocation,
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
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Semantics(
                        label: 'Cancel button, closes the dialog without saving',
                        button: true,
                        enabled: !_controller.isSubmitting,
                        child: TextButton(
                          onPressed: _controller.isSubmitting ? null : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: _primaryTeal,
                            minimumSize: const Size(88, 48),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Semantics(
                        label: 'OK button, saves the health record',
                        button: true,
                        enabled: !_controller.isSubmitting,
                        child: ElevatedButton(
                          onPressed: _controller.isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryTeal,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(120, 48),
                          ),
                          child: _controller.isSubmitting
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Saving...',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Save Record',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
