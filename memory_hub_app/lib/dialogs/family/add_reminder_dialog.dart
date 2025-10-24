import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';

class AddReminderDialog extends StatefulWidget {
  final String recordId;
  final String recordTitle;
  final Map<String, dynamic>? existingReminder;
  final Function(Map<String, dynamic>) onSubmit;

  const AddReminderDialog({
    Key? key,
    required this.recordId,
    required this.recordTitle,
    this.existingReminder,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedReminderType = 'custom';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _dueTime = TimeOfDay.now();
  String _repeatFrequency = 'once';
  int? _repeatCount;
  final List<String> _deliveryChannels = ['in_app'];
  
  String? _assignedUserId;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _reminderTypes = [
    {'value': 'appointment', 'label': 'Appointment', 'icon': Icons.event, 'color': Color(0xFF3B82F6)},
    {'value': 'medication', 'label': 'Medication', 'icon': Icons.medication, 'color': Color(0xFF10B981)},
    {'value': 'vaccination', 'label': 'Vaccination', 'icon': Icons.vaccines, 'color': Color(0xFF8B5CF6)},
    {'value': 'lab_test', 'label': 'Lab Test', 'icon': Icons.biotech, 'color': Color(0xFFF59E0B)},
    {'value': 'checkup', 'label': 'Checkup', 'icon': Icons.health_and_safety, 'color': Color(0xFF06B6D4)},
    {'value': 'refill', 'label': 'Refill', 'icon': Icons.refresh, 'color': Color(0xFFEC4899)},
    {'value': 'custom', 'label': 'Custom', 'icon': Icons.notifications, 'color': Color(0xFF6366F1)},
  ];

  final List<Map<String, dynamic>> _repeatFrequencies = [
    {'value': 'once', 'label': 'Once'},
    {'value': 'daily', 'label': 'Daily'},
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'yearly', 'label': 'Yearly'},
  ];

  final List<Map<String, dynamic>> _deliveryChannelOptions = [
    {'value': 'in_app', 'label': 'In-App', 'icon': Icons.notifications},
    {'value': 'email', 'label': 'Email', 'icon': Icons.email},
    {'value': 'push', 'label': 'Push', 'icon': Icons.phonelink},
    {'value': 'sms', 'label': 'SMS', 'icon': Icons.sms},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    if (widget.existingReminder != null) {
      _loadExistingReminder();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await _authService.getCurrentUserId();
    setState(() {
      _assignedUserId = userId;
    });
  }

  void _loadExistingReminder() {
    final reminder = widget.existingReminder!;
    _titleController.text = reminder['title'] ?? '';
    _descriptionController.text = reminder['description'] ?? '';
    _selectedReminderType = reminder['reminder_type'] ?? 'custom';
    _repeatFrequency = reminder['repeat_frequency'] ?? 'once';
    _repeatCount = reminder['repeat_count'];
    
    if (reminder['due_at'] != null) {
      final dueAt = DateTime.parse(reminder['due_at']);
      _dueDate = dueAt;
      _dueTime = TimeOfDay.fromDateTime(dueAt);
    }
    
    if (reminder['delivery_channels'] != null) {
      _deliveryChannels.clear();
      _deliveryChannels.addAll(List<String>.from(reminder['delivery_channels']));
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null && picked != _dueTime) {
      setState(() => _dueTime = picked);
    }
  }

  void _toggleDeliveryChannel(String channel) {
    setState(() {
      if (_deliveryChannels.contains(channel)) {
        if (_deliveryChannels.length > 1) {
          _deliveryChannels.remove(channel);
        }
      } else {
        _deliveryChannels.add(channel);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assignedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading user information...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final dueDateTime = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );

    final data = {
      'record_id': widget.recordId,
      'assigned_user_id': _assignedUserId,
      'reminder_type': _selectedReminderType,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'due_at': dueDateTime.toIso8601String(),
      'repeat_frequency': _repeatFrequency,
      if (_repeatCount != null) 'repeat_count': _repeatCount,
      'delivery_channels': _deliveryChannels,
      'metadata': {},
    };

    try {
      widget.onSubmit(data);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildRecordInfo(),
                    const SizedBox(height: 24),
                    _buildReminderTypeSelection(),
                    const SizedBox(height: 24),
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 24),
                    _buildDateTimeSelection(),
                    const SizedBox(height: 24),
                    _buildRepeatFrequencySelection(),
                    if (_repeatFrequency != 'once') ...[
                      const SizedBox(height: 16),
                      _buildRepeatCountField(),
                    ],
                    const SizedBox(height: 24),
                    _buildDeliveryChannels(),
                  ],
                ),
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
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
            child: const Icon(Icons.alarm_add, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingReminder != null ? 'Edit Reminder' : 'Add Reminder',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set a reminder for this health record',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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
    );
  }

  Widget _buildRecordInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.medical_information, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health Record',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.recordTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _reminderTypes.map((type) {
            final isSelected = _selectedReminderType == type['value'];
            return InkWell(
              onTap: () => setState(() => _selectedReminderType = type['value'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? type['color'] as Color : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Title *',
        hintText: 'e.g., Doctor Appointment',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Add details about this reminder',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      maxLines: 3,
    );
  }

  Widget _buildDateTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Due Date & Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM dd, yyyy').format(_dueDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF6366F1)),
                      const SizedBox(width: 12),
                      Text(
                        _dueTime.format(context),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRepeatFrequencySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repeat Frequency',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _repeatFrequencies.map((freq) {
            final isSelected = _repeatFrequency == freq['value'];
            return InkWell(
              onTap: () => setState(() => _repeatFrequency = freq['value'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  freq['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRepeatCountField() {
    return TextFormField(
      initialValue: _repeatCount?.toString() ?? '',
      decoration: InputDecoration(
        labelText: 'Number of Repeats',
        hintText: 'How many times to repeat?',
        prefixIcon: const Icon(Icons.repeat),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        setState(() {
          _repeatCount = int.tryParse(value);
        });
      },
    );
  }

  Widget _buildDeliveryChannels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Channels',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _deliveryChannelOptions.map((channel) {
            final isSelected = _deliveryChannels.contains(channel['value']);
            return InkWell(
              onTap: () => _toggleDeliveryChannel(channel['value'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      channel['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      channel['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.existingReminder != null ? 'Update' : 'Add Reminder',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}
