import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../design_system/design_tokens.dart';

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
    {'value': 'appointment', 'label': 'Appointment', 'icon': Icons.event, 'color': MemoryHubColors.blue500},
    {'value': 'medication', 'label': 'Medication', 'icon': Icons.medication, 'color': MemoryHubColors.green500},
    {'value': 'vaccination', 'label': 'Vaccination', 'icon': Icons.vaccines, 'color': MemoryHubColors.purple600},
    {'value': 'lab_test', 'label': 'Lab Test', 'icon': Icons.biotech, 'color': MemoryHubColors.yellow500},
    {'value': 'checkup', 'label': 'Checkup', 'icon': Icons.health_and_safety, 'color': MemoryHubColors.cyan600},
    {'value': 'refill', 'label': 'Refill', 'icon': Icons.refresh, 'color': MemoryHubColors.pink500},
    {'value': 'custom', 'label': 'Custom', 'icon': Icons.notifications, 'color': MemoryHubColors.indigo600},
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
      shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.xxlRadius),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(MemoryHubSpacing.xl),
                  children: [
                    _buildRecordInfo(),
                    const SizedBox(height: MemoryHubSpacing.xl),
                    _buildReminderTypeSelection(),
                    const SizedBox(height: MemoryHubSpacing.xl),
                    _buildTitleField(),
                    const SizedBox(height: MemoryHubSpacing.lg),
                    _buildDescriptionField(),
                    const SizedBox(height: MemoryHubSpacing.xl),
                    _buildDateTimeSelection(),
                    const SizedBox(height: MemoryHubSpacing.xl),
                    _buildRepeatFrequencySelection(),
                    if (_repeatFrequency != 'once') ...[
                      const SizedBox(height: MemoryHubSpacing.lg),
                      _buildRepeatCountField(),
                    ],
                    const SizedBox(height: MemoryHubSpacing.xl),
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
      padding: EdgeInsets.all(MemoryHubSpacing.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [MemoryHubColors.indigo600, MemoryHubColors.purple600],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(MemoryHubSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: MemoryHubBorderRadius.mdRadius,
            ),
            child: const Icon(Icons.alarm_add, color: Colors.white, size: 24),
          ),
          const SizedBox(width: MemoryHubSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingReminder != null ? 'Edit Reminder' : 'Add Reminder',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: MemoryHubTypography.h3,
                    fontWeight: MemoryHubTypography.bold,
                  ),
                ),
                const SizedBox(height: MemoryHubSpacing.xs),
                const Text(
                  'Set a reminder for this health record',
                  style: TextStyle(color: Colors.white70, fontSize: MemoryHubTypography.bodyMedium),
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
      padding: EdgeInsets.all(MemoryHubSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: MemoryHubBorderRadius.mdRadius,
      ),
      child: Row(
        children: [
          Icon(Icons.medical_information, color: Colors.grey[700]),
          const SizedBox(width: MemoryHubSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health Record',
                  style: TextStyle(fontSize: MemoryHubTypography.caption, color: Colors.grey),
                ),
                const SizedBox(height: MemoryHubSpacing.xs),
                Text(
                  widget.recordTitle,
                  style: const TextStyle(fontSize: MemoryHubTypography.bodyLarge, fontWeight: MemoryHubTypography.semiBold),
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
          style: TextStyle(fontSize: MemoryHubTypography.bodyLarge, fontWeight: MemoryHubTypography.semiBold),
        ),
        const SizedBox(height: MemoryHubSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _reminderTypes.map((type) {
            final isSelected = _selectedReminderType == type['value'];
            return InkWell(
              onTap: () => setState(() => _selectedReminderType = type['value'] as String),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg, vertical: MemoryHubSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? type['color'] as Color : Colors.grey[100],
                  borderRadius: MemoryHubBorderRadius.xlRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    const SizedBox(width: MemoryHubSpacing.sm),
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
        border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
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
        border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
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
          style: TextStyle(fontSize: MemoryHubTypography.bodyLarge, fontWeight: MemoryHubTypography.semiBold),
        ),
        const SizedBox(height: MemoryHubSpacing.md),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.all(MemoryHubSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: MemoryHubColors.indigo600),
                      const SizedBox(width: MemoryHubSpacing.md),
                      Text(
                        DateFormat('MMM dd, yyyy').format(_dueDate),
                        style: const TextStyle(fontSize: MemoryHubTypography.bodyLarge),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: MemoryHubSpacing.md),
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: EdgeInsets.all(MemoryHubSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: MemoryHubColors.indigo600),
                      const SizedBox(width: MemoryHubSpacing.md),
                      Text(
                        _dueTime.format(context),
                        style: const TextStyle(fontSize: MemoryHubTypography.bodyLarge),
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
          style: TextStyle(fontSize: MemoryHubTypography.bodyLarge, fontWeight: MemoryHubTypography.semiBold),
        ),
        const SizedBox(height: MemoryHubSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _repeatFrequencies.map((freq) {
            final isSelected = _repeatFrequency == freq['value'];
            return InkWell(
              onTap: () => setState(() => _repeatFrequency = freq['value'] as String),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg, vertical: MemoryHubSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? MemoryHubColors.indigo600 : Colors.grey[100],
                  borderRadius: MemoryHubBorderRadius.xlRadius,
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
        border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
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
          style: TextStyle(fontSize: MemoryHubTypography.bodyLarge, fontWeight: MemoryHubTypography.semiBold),
        ),
        const SizedBox(height: MemoryHubSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _deliveryChannelOptions.map((channel) {
            final isSelected = _deliveryChannels.contains(channel['value']);
            return InkWell(
              onTap: () => _toggleDeliveryChannel(channel['value'] as String),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg, vertical: MemoryHubSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? MemoryHubColors.green500 : Colors.grey[100],
                  borderRadius: MemoryHubBorderRadius.xlRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      channel['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    const SizedBox(width: MemoryHubSpacing.sm),
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
      padding: EdgeInsets.all(MemoryHubSpacing.xl),
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
          const SizedBox(width: MemoryHubSpacing.md),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: MemoryHubColors.indigo600,
              padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.xxl, vertical: MemoryHubSpacing.lg),
              shape: RoundedRectangleBorder(
                borderRadius: MemoryHubBorderRadius.mdRadius,
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
                    style: const TextStyle(color: Colors.white, fontSize: MemoryHubTypography.bodyLarge),
                  ),
          ),
        ],
      ),
    );
  }
}
