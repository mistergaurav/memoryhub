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

class _AddHealthRecordDialogState extends State<AddHealthRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _familyService = FamilyService();
  final _controller = AddHealthRecordController();
  
  // Controllers
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

  // State
  int _currentStep = 0;
  String _recordType = 'medical';
  String _severity = 'low';
  DateTime _selectedDate = DateTime.now();
  bool _isConfidential = true;
  
  // Medication
  String _medicationFrequency = 'daily';
  TimeOfDay? _dailyReminderTime;
  
  // Reminders
  bool _enableReminder = false;
  DateTime? _reminderDueDate;
  String _reminderType = 'custom';
  DateTime? _vaccinationReminderDate;
  DateTime? _labResultReminderDate;

  // Subject Selection
  String _subjectCategory = 'myself';
  String? _selectedUserId;
  String? _selectedFamilyMemberId;
  String? _selectedFriendCircleId;
  UserSearchResult? _selectedUser;
  
  // Data Lists
  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _friendCircles = [];
  bool _loadingMembers = false;
  bool _loadingCircles = false;

  // Constants
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
    _loadFamilyMembers();
    _loadFriendCircles();
  }

  @override
  void dispose() {
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
    if (picked != null) {
      setState(() => _selectedDate = picked);
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
      setState(() => _reminderDueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
      Navigator.of(context).pop(true);
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
      prefixIcon: Icon(icon, color: MemoryHubColors.teal600, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: MemoryHubColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: MemoryHubColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: MemoryHubColors.teal600, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [MemoryHubColors.teal600, MemoryHubColors.cyan500],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.health_and_safety, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Health Record',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Step ${_currentStep + 1} of 3',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Form(
                key: _formKey,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(primary: MemoryHubColors.teal600),
                  ),
                  child: Stepper(
                    type: StepperType.horizontal,
                    currentStep: _currentStep,
                    onStepContinue: () {
                      if (_currentStep < 2) {
                        setState(() => _currentStep += 1);
                      } else {
                        _submit();
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep -= 1);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MemoryHubColors.teal600,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _controller.isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        _currentStep == 2 ? 'Create Record' : 'Continue',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (_currentStep > 0)
                              TextButton(
                                onPressed: details.onStepCancel,
                                child: Text(
                                  'Back',
                                  style: GoogleFonts.inter(
                                    color: MemoryHubColors.gray600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      Step(
                        title: const Text('Who & What'),
                        content: _buildStep1(),
                        isActive: _currentStep >= 0,
                        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                      ),
                      Step(
                        title: const Text('Details'),
                        content: _buildStep2(),
                        isActive: _currentStep >= 1,
                        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                      ),
                      Step(
                        title: const Text('Privacy'),
                        content: _buildStep3(),
                        isActive: _currentStep >= 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who is this record for?',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildChoiceChip('Myself', 'myself', Icons.person),
            _buildChoiceChip('Family Member', 'family', Icons.family_restroom),
            _buildChoiceChip('Another User', 'user', Icons.person_search),
            _buildChoiceChip('Friend Circle', 'friend', Icons.people),
          ],
        ),
        const SizedBox(height: 24),
        
        if (_subjectCategory == 'family') ...[
          _loadingMembers
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  value: _selectedFamilyMemberId,
                  decoration: _buildInputDecoration(
                    label: 'Select Family Member',
                    icon: Icons.person_outline,
                  ),
                  items: _familyMembers.map((m) => DropdownMenuItem(
                    value: m['id']?.toString(),
                    child: Text(m['name'] ?? 'Unknown'),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedFamilyMemberId = v),
                ),
        ],
        
        if (_subjectCategory == 'user') ...[
          UserSearchAutocomplete(
            helpText: 'Search user...',
            onUserSelected: (user) => setState(() {
              _selectedUser = user;
              _selectedUserId = user.id;
            }),
          ),
        ],

        const SizedBox(height: 24),
        Text(
          'Record Type',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _recordType,
          decoration: _buildInputDecoration(
            label: 'Type',
            icon: Icons.category,
          ),
          items: _recordTypes.map((t) => DropdownMenuItem(
            value: t['value'],
            child: Text(t['label']!),
          )).toList(),
          onChanged: (v) => setState(() => _recordType = v!),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: _buildInputDecoration(
            label: 'Title',
            icon: Icons.title,
            helperText: 'e.g., Annual Checkup',
          ),
          validator: _controller.validateTitle,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: _buildInputDecoration(
              label: 'Date',
              icon: Icons.calendar_today,
            ),
            child: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: _buildInputDecoration(
            label: 'Description',
            icon: Icons.description,
          ),
          maxLines: 3,
          validator: _controller.validateDescription,
        ),
        
        // Type Specific Fields
        if (_recordType == 'medication') ...[
          const SizedBox(height: 24),
          TextFormField(
            controller: _dosageController,
            decoration: _buildInputDecoration(label: 'Dosage', icon: Icons.healing),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _medicationFrequency,
            decoration: _buildInputDecoration(label: 'Frequency', icon: Icons.schedule),
            items: _medicationFrequencies.map((f) => DropdownMenuItem(
              value: f['value'],
              child: Text(f['label']!),
            )).toList(),
            onChanged: (v) => setState(() => _medicationFrequency = v!),
          ),
        ],
        
        if (_recordType == 'vaccination') ...[
          const SizedBox(height: 24),
          TextFormField(
            controller: _vaccineNameController,
            decoration: _buildInputDecoration(label: 'Vaccine Name', icon: Icons.medical_services),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        SwitchListTile(
          value: _enableReminder,
          onChanged: (v) => setState(() => _enableReminder = v),
          title: const Text('Enable Reminder'),
          secondary: const Icon(Icons.notifications_active, color: MemoryHubColors.teal600),
          activeColor: MemoryHubColors.teal600,
        ),
        if (_enableReminder) ...[
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectReminderDate,
            child: InputDecorator(
              decoration: _buildInputDecoration(
                label: 'Reminder Date',
                icon: Icons.event,
              ),
              child: Text(
                _reminderDueDate != null
                    ? DateFormat('MMM d, yyyy').format(_reminderDueDate!)
                    : 'Select Date',
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Divider(),
        SwitchListTile(
          value: _isConfidential,
          onChanged: (v) => setState(() => _isConfidential = v),
          title: const Text('Mark as Confidential'),
          subtitle: const Text('Only visible to you and approved viewers'),
          secondary: const Icon(Icons.lock, color: MemoryHubColors.teal600),
          activeColor: MemoryHubColors.teal600,
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, String value, IconData icon) {
    final isSelected = _subjectCategory == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : MemoryHubColors.teal600,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _subjectCategory = value;
            // Reset selections
            _selectedUserId = null;
            _selectedFamilyMemberId = null;
            _selectedFriendCircleId = null;
          });
        }
      },
      selectedColor: MemoryHubColors.teal600,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : MemoryHubColors.teal600,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.transparent : MemoryHubColors.teal600.withOpacity(0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
