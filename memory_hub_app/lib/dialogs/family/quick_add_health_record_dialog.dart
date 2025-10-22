import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/family/family_service.dart';
import '../../services/auth_service.dart';

class QuickAddHealthRecordDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const QuickAddHealthRecordDialog({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<QuickAddHealthRecordDialog> createState() => _QuickAddHealthRecordDialogState();
}

class _QuickAddHealthRecordDialogState extends State<QuickAddHealthRecordDialog> {
  final _familyService = FamilyService();
  final _authService = AuthService();
  final PageController _pageController = PageController();
  
  int _currentStep = 0;
  
  String? _selectedPersonId;
  String? _selectedPersonName;
  String _selectedRecordType = 'medical';
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _providerController = TextEditingController();
  final _locationController = TextEditingController();
  final _medicationsController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _severity = 'low';
  bool _isConfidential = false;
  bool _showAdvancedDetails = false;
  
  List<Map<String, dynamic>> _familyMembers = [];
  bool _isLoadingMembers = true;
  
  final List<Map<String, dynamic>> _recordTypes = [
    {
      'value': 'medical',
      'label': 'Medical',
      'icon': Icons.medical_services,
      'color': Color(0xFF3B82F6),
      'defaultTitle': 'Medical Checkup',
    },
    {
      'value': 'allergy',
      'label': 'Allergy',
      'icon': Icons.coronavirus,
      'color': Color(0xFFEF4444),
      'defaultTitle': 'Allergy Record',
    },
    {
      'value': 'condition',
      'label': 'Condition',
      'icon': Icons.sick,
      'color': Color(0xFFF59E0B),
      'defaultTitle': 'Medical Condition',
    },
    {
      'value': 'surgery',
      'label': 'Surgery',
      'icon': Icons.local_hospital,
      'color': Color(0xFF8B5CF6),
      'defaultTitle': 'Surgical Procedure',
    },
    {
      'value': 'emergency',
      'label': 'Emergency',
      'icon': Icons.emergency,
      'color': Color(0xFFDC2626),
      'defaultTitle': 'Emergency Visit',
    },
    {
      'value': 'vaccination',
      'label': 'Vaccination',
      'icon': Icons.vaccines,
      'color': Color(0xFF10B981),
      'defaultTitle': 'Vaccination',
    },
  ];
  
  final List<Map<String, dynamic>> _severityLevels = [
    {'value': 'low', 'label': 'Low', 'color': Color(0xFF10B981)},
    {'value': 'moderate', 'label': 'Moderate', 'color': Color(0xFFF59E0B)},
    {'value': 'high', 'label': 'High', 'color': Color(0xFFEF4444)},
    {'value': 'critical', 'label': 'Critical', 'color': Color(0xFFDC2626)},
  ];

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
    _setDefaultTitle();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _providerController.dispose();
    _locationController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyMembers() async {
    try {
      final persons = await _familyService.getPersons();
      final currentUserId = await _authService.getCurrentUserId();
      
      setState(() {
        _familyMembers = persons;
        _isLoadingMembers = false;
        
        if (_familyMembers.isNotEmpty && _selectedPersonId == null) {
          final currentUserPerson = _familyMembers.firstWhere(
            (p) => p['linked_user_id'] == currentUserId,
            orElse: () => _familyMembers[0],
          );
          _selectedPersonId = currentUserPerson['id'] ?? currentUserPerson['_id'];
          _selectedPersonName = '${currentUserPerson['first_name']} ${currentUserPerson['last_name']}'.trim();
        }
      });
    } catch (e) {
      setState(() => _isLoadingMembers = false);
    }
  }

  void _setDefaultTitle() {
    final recordType = _recordTypes.firstWhere(
      (type) => type['value'] == _selectedRecordType,
      orElse: () => _recordTypes[0],
    );
    _titleController.text = recordType['defaultTitle'] as String;
  }

  void _onRecordTypeChanged(String newType) {
    setState(() {
      _selectedRecordType = newType;
      _setDefaultTitle();
    });
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedPersonId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a family member'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() => _currentStep = 1);
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep == 1) {
      setState(() => _currentStep = 0);
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = {
      'genealogy_person_id': _selectedPersonId,
      'record_type': _selectedRecordType,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'severity': _severity,
      if (_providerController.text.trim().isNotEmpty)
        'provider': _providerController.text.trim(),
      if (_locationController.text.trim().isNotEmpty)
        'location': _locationController.text.trim(),
      if (_medicationsController.text.trim().isNotEmpty)
        'medications': _medicationsController.text.trim().split(',').map((e) => e.trim()).toList(),
      'is_confidential': _isConfidential,
      'attachments': [],
    };

    widget.onSubmit(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Quick Add Health Record',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepIndicator(0, 'Person & Type'),
          Container(
            width: 40,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: _currentStep >= 1 ? const Color(0xFFEF4444) : Colors.grey.shade300,
          ),
          _buildStepIndicator(1, 'Details'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive || isCompleted ? const Color(0xFFEF4444) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFFEF4444) : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Family Member',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_isLoadingMembers)
            const Center(child: CircularProgressIndicator())
          else if (_familyMembers.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No family members found. Please add family members in the Genealogy section first.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedPersonId,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.person),
                ),
                items: _familyMembers.map((person) {
                  final personId = (person['id'] ?? person['_id']) as String;
                  final name = '${person['first_name']} ${person['last_name']}'.trim();
                  return DropdownMenuItem<String>(
                    value: personId,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (value) {
                  final selectedPerson = _familyMembers.firstWhere(
                    (p) => (p['id'] ?? p['_id']) == value,
                  );
                  setState(() {
                    _selectedPersonId = value;
                    _selectedPersonName = '${selectedPerson['first_name']} ${selectedPerson['last_name']}'.trim();
                  });
                },
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Select Record Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
            ),
            itemCount: _recordTypes.length,
            itemBuilder: (context, index) {
              final type = _recordTypes[index];
              final isSelected = _selectedRecordType == type['value'];
              
              return InkWell(
                onTap: () => _onRecordTypeChanged(type['value'] as String),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (type['color'] as Color).withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? type['color'] as Color
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        size: 32,
                        color: isSelected
                            ? type['color'] as Color
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? type['color'] as Color
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(
                DateFormat('MMMM d, yyyy').format(_selectedDate),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description/Notes',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Severity (Optional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _severityLevels.map((level) {
              final isSelected = _severity == level['value'];
              return ChoiceChip(
                label: Text(level['label'] as String),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _severity = level['value'] as String);
                  }
                },
                selectedColor: (level['color'] as Color).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? level['color'] as Color : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? level['color'] as Color : Colors.grey.shade300,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _providerController,
            decoration: InputDecoration(
              labelText: 'Healthcare Provider (Optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.local_hospital),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              setState(() => _showAdvancedDetails = !_showAdvancedDetails);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _showAdvancedDetails ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'More Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.settings,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_showAdvancedDetails) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location/Facility',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _medicationsController,
              decoration: InputDecoration(
                labelText: 'Medications (comma-separated)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.medication),
                hintText: 'e.g., Aspirin, Ibuprofen',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isConfidential,
              onChanged: (value) {
                setState(() => _isConfidential = value);
              },
              title: const Text('Mark as Confidential'),
              subtitle: const Text('Only you can view this record'),
              secondary: const Icon(Icons.lock_outline),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey.shade50,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep == 1)
            TextButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          if (_currentStep == 0)
            ElevatedButton.icon(
              onPressed: _nextStep,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Save Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
