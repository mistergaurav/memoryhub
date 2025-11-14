import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_hub_app/design_system/design_tokens.dart';
import '../../services/family/family_service.dart';
import '../../widgets/user_search_autocomplete.dart';
import '../../models/user_search_result.dart';
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
  
  final _dosageController = TextEditingController();
  final _vaccineNameController = TextEditingController();
  final _doseNumberController = TextEditingController();
  final _testNameController = TextEditingController();
  final _resultsController = TextEditingController();

  String _recordType = 'medical';
  String _severity = 'low';
  DateTime _selectedDate = DateTime.now();
  bool _isConfidential = true;
  
  String _medicationFrequency = 'daily';
  TimeOfDay? _dailyReminderTime;
  DateTime? _vaccinationReminderDate;
  DateTime? _labResultReminderDate;

  String _subjectCategory = 'myself';
  String? _selectedUserId;
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
  
  final List<Map<String, String>> _medicationFrequencies = [
    {'value': 'daily', 'label': 'Daily'},
    {'value': 'twice_daily', 'label': 'Twice Daily'},
    {'value': 'three_times_daily', 'label': 'Three Times Daily'},
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'as_needed', 'label': 'As Needed'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: MemoryHubAnimations.normal,
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
    _dosageController.dispose();
    _vaccineNameController.dispose();
    _doseNumberController.dispose();
    _testNameController.dispose();
    _resultsController.dispose();
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
        _reminderDueDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final subjectValidation = _controller.validateSubjectSelection(
      subjectCategory: _subjectCategory,
      selectedUserId: _selectedUserId,
      selectedFamilyMemberId: _selectedFamilyMemberId,
      selectedFriendCircleId: _selectedFriendCircleId,
    );

    if (subjectValidation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: MemoryHubSpacing.md),
              Expanded(child: Text(subjectValidation)),
            ],
          ),
          backgroundColor: MemoryHubColors.red500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
          margin: EdgeInsets.all(MemoryHubSpacing.lg),
        ),
      );
      return;
    }

    final reminderValidation = _controller.validateReminderDate(
      enableReminder: _enableReminder,
      reminderDueDate: _reminderDueDate,
    );

    if (reminderValidation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: MemoryHubSpacing.md),
              Expanded(child: Text(reminderValidation)),
            ],
          ),
          backgroundColor: MemoryHubColors.red500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
          margin: EdgeInsets.all(MemoryHubSpacing.lg),
        ),
      );
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
      subjectCategory: _subjectCategory,
      selectedUserId: _selectedUserId,
      selectedFamilyMemberId: _selectedFamilyMemberId,
      selectedFriendCircleId: _selectedFriendCircleId,
      enableReminder: _enableReminder,
      reminderDueDate: _reminderDueDate,
      reminderType: _reminderType,
      dosage: _dosageController.text,
      medicationFrequency: _medicationFrequency,
      dailyReminderTime: _dailyReminderTime?.format(context),
      vaccineName: _vaccineNameController.text,
      doseNumber: _doseNumberController.text,
      vaccinationReminderDate: _vaccinationReminderDate,
      testName: _testNameController.text,
      results: _resultsController.text,
      labResultReminderDate: _labResultReminderDate,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: MemoryHubSpacing.md),
              Expanded(
                child: Text('Health record created successfully'),
              ),
            ],
          ),
          backgroundColor: MemoryHubColors.green500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
          margin: EdgeInsets.all(MemoryHubSpacing.lg),
        ),
      );
      
      await Future.delayed(MemoryHubAnimations.slow);
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
      dosage: _dosageController.text,
      medicationFrequency: _medicationFrequency,
      dailyReminderTime: _dailyReminderTime?.format(context),
      vaccineName: _vaccineNameController.text,
      doseNumber: _doseNumberController.text,
      vaccinationReminderDate: _vaccinationReminderDate,
      testName: _testNameController.text,
      results: _resultsController.text,
      labResultReminderDate: _labResultReminderDate,
      provider: _providerController.text,
      location: _locationController.text,
      severity: _severity,
      notes: _notesController.text,
      isConfidential: _isConfidential,
      subjectCategory: _subjectCategory,
      selectedUserId: _selectedUserId,
      selectedFamilyMemberId: _selectedFamilyMemberId,
      selectedFriendCircleId: _selectedFriendCircleId,
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
              SizedBox(width: MemoryHubSpacing.md),
              Expanded(
                child: Text('Health record created successfully'),
              ),
            ],
          ),
          backgroundColor: MemoryHubColors.green500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
          margin: EdgeInsets.all(MemoryHubSpacing.lg),
        ),
      );
      
      await Future.delayed(MemoryHubAnimations.slow);
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
        margin: EdgeInsets.all(MemoryHubSpacing.md),
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
        fontSize: MemoryHubTypography.bodyMedium,
        color: MemoryHubColors.gray900,
      ),
      helperStyle: GoogleFonts.inter(
        fontSize: MemoryHubTypography.bodySmall,
        color: MemoryHubColors.gray500,
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: MemoryHubTypography.bodySmall,
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
        boxShadow: [
          BoxShadow(
            color: MemoryHubColors.teal600.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(MemoryHubSpacing.xl),
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
              SizedBox(width: MemoryHubSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: MemoryHubTypography.h5,
                        fontWeight: MemoryHubTypography.semiBold,
                        color: MemoryHubColors.gray900,
                      ),
                    ),
                    if (helperText != null) ...[
                      SizedBox(height: MemoryHubSpacing.xs),
                      Text(
                        helperText,
                        style: GoogleFonts.inter(
                          fontSize: MemoryHubTypography.bodySmall,
                          color: MemoryHubColors.gray500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: MemoryHubSpacing.lg),
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
        duration: MemoryHubAnimations.fast,
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [MemoryHubColors.teal600, MemoryHubColors.cyan500],
                )
              : null,
          color: selected ? null : Colors.white,
          border: selected ? null : Border.all(color: MemoryHubColors.gray200),
          borderRadius: MemoryHubBorderRadius.fullRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : MemoryHubColors.teal600,
            ),
            SizedBox(width: MemoryHubSpacing.sm),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: MemoryHubTypography.bodyMedium,
                fontWeight: MemoryHubTypography.medium,
                color: selected ? Colors.white : MemoryHubColors.teal600,
              ),
            ),
            if (selected) ...[
              SizedBox(width: MemoryHubSpacing.xs),
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
      insetPadding: EdgeInsets.all(MemoryHubSpacing.lg),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: MemoryHubColors.gray50,
          borderRadius: MemoryHubBorderRadius.xxlRadius,
          boxShadow: [
            BoxShadow(
              color: MemoryHubColors.teal600.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
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
              padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.xl),
              child: Row(
                children: [
                  const Icon(Icons.health_and_safety, color: Colors.white, size: 28),
                  SizedBox(width: MemoryHubSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Health Record',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: MemoryHubTypography.h3,
                            fontWeight: MemoryHubTypography.semiBold,
                          ),
                        ),
                        Text(
                          'Track health details with clarity',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: MemoryHubTypography.bodyMedium,
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
                    duration: MemoryHubAnimations.fast,
                    width: double.infinity,
                    padding: EdgeInsets.all(MemoryHubSpacing.lg),
                    decoration: BoxDecoration(
                      color: MemoryHubColors.red500.withOpacity(0.05),
                      border: Border(
                        bottom: BorderSide(
                          color: MemoryHubColors.red500.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(MemoryHubSpacing.xs * 1.5),
                          decoration: BoxDecoration(
                            color: MemoryHubColors.red500.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.error_outline, color: MemoryHubColors.red500, size: 20),
                        ),
                        SizedBox(width: MemoryHubSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Submission Failed',
                                style: GoogleFonts.inter(
                                  color: MemoryHubColors.red500,
                                  fontSize: MemoryHubTypography.bodyMedium,
                                  fontWeight: MemoryHubTypography.semiBold,
                                ),
                              ),
                              SizedBox(height: MemoryHubSpacing.xs),
                              Text(
                                _controller.errorMessage!,
                                style: GoogleFonts.inter(
                                  color: MemoryHubColors.red500.withOpacity(0.9),
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
                                    backgroundColor: MemoryHubColors.red500,
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
                          color: MemoryHubColors.red500,
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
                      title: 'Who is this health record about?',
                      icon: Icons.person,
                      helperText: 'Select who this health record belongs to',
                      children: [
                        Text(
                          'This record is for:',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: MemoryHubColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildChoiceChip(
                              label: 'Myself',
                              icon: Icons.person,
                              selected: _subjectCategory == 'myself',
                              onTap: () {
                                setState(() {
                                  _subjectCategory = 'myself';
                                  _selectedUserId = null;
                                  _selectedUser = null;
                                  _selectedFamilyMemberId = null;
                                  _selectedFriendCircleId = null;
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: 'Another user',
                              icon: Icons.person_search,
                              selected: _subjectCategory == 'user',
                              onTap: () {
                                setState(() {
                                  _subjectCategory = 'user';
                                  _selectedUserId = null;
                                  _selectedUser = null;
                                  _selectedFamilyMemberId = null;
                                  _selectedFriendCircleId = null;
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: 'A family member',
                              icon: Icons.family_restroom,
                              selected: _subjectCategory == 'family',
                              onTap: () {
                                setState(() {
                                  _subjectCategory = 'family';
                                  _selectedUserId = null;
                                  _selectedUser = null;
                                  _selectedFamilyMemberId = null;
                                  _selectedFriendCircleId = null;
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: 'Someone in my friend circle',
                              icon: Icons.people,
                              selected: _subjectCategory == 'friend',
                              onTap: () {
                                setState(() {
                                  _subjectCategory = 'friend';
                                  _selectedUserId = null;
                                  _selectedUser = null;
                                  _selectedFamilyMemberId = null;
                                  _selectedFriendCircleId = null;
                                });
                              },
                            ),
                          ],
                        ),
                        if (_subjectCategory == 'myself') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: MemoryHubColors.teal500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: MemoryHubColors.teal500.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: MemoryHubColors.teal500,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This record will be created for your account',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: MemoryHubColors.gray900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_subjectCategory == 'user') ...[
                          const SizedBox(height: 16),
                          UserSearchAutocomplete(
                            helpText: 'Search for any user by name, email, or username',
                            onUserSelected: (UserSearchResult user) {
                              setState(() {
                                _selectedUser = user;
                                _selectedUserId = user.id;
                              });
                            },
                          ),
                          if (_selectedUser != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: MemoryHubColors.green500.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: MemoryHubColors.green500.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: MemoryHubColors.green500,
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
                                          'Selected user: ${_selectedUser!.fullName}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: MemoryHubColors.gray900,
                                          ),
                                        ),
                                        if (_selectedUser!.email != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            _selectedUser!.email!,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: MemoryHubColors.gray900.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                        if (_subjectCategory == 'family') ...[
                          const SizedBox(height: 16),
                          _loadingMembers
                              ? const Center(child: CircularProgressIndicator(color: MemoryHubColors.cyan300))
                              : DropdownButtonFormField<String>(
                                  value: _selectedFamilyMemberId,
                                  decoration: _buildInputDecoration(
                                    label: 'Select Family Member *',
                                    icon: Icons.person_outline,
                                    helperText: 'Choose which family member this record is for',
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
                                ),
                        ],
                        if (_subjectCategory == 'friend') ...[
                          const SizedBox(height: 16),
                          _loadingCircles
                              ? const Center(child: CircularProgressIndicator(color: MemoryHubColors.cyan300))
                              : DropdownButtonFormField<String>(
                                  value: _selectedFriendCircleId,
                                  decoration: _buildInputDecoration(
                                    label: 'Select Friend Circle *',
                                    icon: Icons.group_outlined,
                                    helperText: 'Choose which friend circle member this record is for',
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
                                ),
                        ],
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
                                      style: GoogleFonts.inter(color: MemoryHubColors.gray900),
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
                                          style: GoogleFonts.inter(color: MemoryHubColors.gray900),
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
                                    style: GoogleFonts.inter(color: MemoryHubColors.gray900),
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
                                        style: GoogleFonts.inter(color: MemoryHubColors.gray900),
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
                    if (_recordType == 'medication') ...[
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Medication Details',
                        icon: Icons.medication,
                        helperText: 'Specific information about this medication',
                        children: [
                          TextFormField(
                            controller: _dosageController,
                            decoration: _buildInputDecoration(
                              label: 'Dosage *',
                              icon: Icons.healing,
                              helperText: 'e.g., 500mg, 1 tablet',
                            ),
                            style: GoogleFonts.inter(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Dosage is required for medications';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _medicationFrequency,
                            decoration: _buildInputDecoration(
                              label: 'Frequency *',
                              icon: Icons.schedule,
                              helperText: 'How often to take this medication',
                            ),
                            style: GoogleFonts.inter(color: MemoryHubColors.gray900),
                            items: _medicationFrequencies.map((freq) {
                              return DropdownMenuItem(
                                value: freq['value'],
                                child: Text(freq['label']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _medicationFrequency = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: _dailyReminderTime ?? TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: MemoryHubColors.teal500,
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
                                  _dailyReminderTime = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: _buildInputDecoration(
                                label: 'Daily Reminder Time (optional)',
                                icon: Icons.alarm,
                                helperText: 'Set a time for daily reminder',
                              ),
                              child: Text(
                                _dailyReminderTime != null
                                    ? _dailyReminderTime!.format(context)
                                    : 'Tap to set reminder time',
                                style: GoogleFonts.inter(
                                  color: _dailyReminderTime != null
                                      ? MemoryHubColors.gray900
                                      : MemoryHubColors.gray500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_recordType == 'vaccination') ...[
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Vaccination Details',
                        icon: Icons.vaccines,
                        helperText: 'Information about this vaccination',
                        children: [
                          TextFormField(
                            controller: _vaccineNameController,
                            decoration: _buildInputDecoration(
                              label: 'Vaccine Name *',
                              icon: Icons.medical_services,
                              helperText: 'e.g., COVID-19, Flu, MMR',
                            ),
                            style: GoogleFonts.inter(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vaccine name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _doseNumberController,
                            decoration: _buildInputDecoration(
                              label: 'Dose Number',
                              icon: Icons.numbers,
                              helperText: 'e.g., 1st dose, 2nd dose, booster',
                            ),
                            style: GoogleFonts.inter(),
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _vaccinationReminderDate ?? DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: MemoryHubColors.teal500,
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
                                  _vaccinationReminderDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: _buildInputDecoration(
                                label: 'Next Dose Reminder (optional)',
                                icon: Icons.event_available,
                                helperText: 'Set reminder for next dose',
                              ),
                              child: Text(
                                _vaccinationReminderDate != null
                                    ? DateFormat('MMM d, yyyy').format(_vaccinationReminderDate!)
                                    : 'Tap to set reminder date',
                                style: GoogleFonts.inter(
                                  color: _vaccinationReminderDate != null
                                      ? MemoryHubColors.gray900
                                      : MemoryHubColors.gray500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_recordType == 'lab_result') ...[
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Lab Result Details',
                        icon: Icons.science,
                        helperText: 'Details about this lab test',
                        children: [
                          TextFormField(
                            controller: _testNameController,
                            decoration: _buildInputDecoration(
                              label: 'Test Name *',
                              icon: Icons.biotech,
                              helperText: 'e.g., Blood Test, X-Ray, MRI',
                            ),
                            style: GoogleFonts.inter(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Test name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _resultsController,
                            decoration: _buildInputDecoration(
                              label: 'Test Results *',
                              icon: Icons.assignment_turned_in,
                              helperText: 'Enter the lab test results',
                            ),
                            style: GoogleFonts.inter(),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Test results are required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _labResultReminderDate ?? DateTime.now().add(const Duration(days: 90)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: MemoryHubColors.teal500,
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
                                  _labResultReminderDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: _buildInputDecoration(
                                label: 'Follow-up Reminder (optional)',
                                icon: Icons.event_repeat,
                                helperText: 'Set reminder for follow-up test',
                              ),
                              child: Text(
                                _labResultReminderDate != null
                                    ? DateFormat('MMM d, yyyy').format(_labResultReminderDate!)
                                    : 'Tap to set reminder date',
                                style: GoogleFonts.inter(
                                  color: _labResultReminderDate != null
                                      ? MemoryHubColors.gray900
                                      : MemoryHubColors.gray500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                            iconColor: MemoryHubColors.teal500,
                            textColor: MemoryHubColors.gray900,
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
                                colors: [MemoryHubColors.teal500, MemoryHubColors.cyan300],
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
                              color: MemoryHubColors.gray900,
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
                                          color: MemoryHubColors.gray900,
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
                                                        colors: [MemoryHubColors.teal500, MemoryHubColors.cyan300],
                                                      )
                                                    : null,
                                                color: isSelected ? null : MemoryHubColors.gray200,
                                                borderRadius: BorderRadius.circular(20),
                                                border: isSelected ? null : Border.all(color: const Color(0xFFD1E8EC)),
                                              ),
                                              child: Text(
                                                level['label']!,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: isSelected ? Colors.white : MemoryHubColors.teal500,
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
                              color: MemoryHubColors.gray900,
                            ),
                          ),
                          subtitle: Text(
                            'Get notified about this record',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          activeColor: MemoryHubColors.cyan300,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_enableReminder)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: MemoryHubColors.gray200,
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
                                  style: GoogleFonts.inter(color: MemoryHubColors.gray900),
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
                                        color: _reminderDueDate != null ? MemoryHubColors.gray900 : MemoryHubColors.gray500,
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
                            foregroundColor: MemoryHubColors.teal500,
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
                            backgroundColor: MemoryHubColors.teal500,
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
