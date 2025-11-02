import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddEventDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;

  const AddEventDialog({
    Key? key,
    required this.onSubmit,
    this.initialData,
  }) : super(key: key);

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _eventType = 'other';
  String _recurrence = 'none';
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime? _endDate;
  TimeOfDay? _endTime;
  int? _reminderMinutes;
  bool _isAllDay = false;
  bool _isEditMode = false;

  final List<Map<String, String>> _eventTypes = [
    {'value': 'birthday', 'label': 'Birthday'},
    {'value': 'anniversary', 'label': 'Anniversary'},
    {'value': 'death_anniversary', 'label': 'Death Anniversary'},
    {'value': 'gathering', 'label': 'Family Gathering'},
    {'value': 'holiday', 'label': 'Holiday'},
    {'value': 'reminder', 'label': 'Reminder'},
    {'value': 'meeting', 'label': 'Meeting'},
    {'value': 'historical_event', 'label': 'Historical Event'},
    {'value': 'other', 'label': 'Other'},
  ];

  final List<Map<String, String>> _recurrenceOptions = [
    {'value': 'none', 'label': 'Does not repeat'},
    {'value': 'daily', 'label': 'Daily'},
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'yearly', 'label': 'Yearly'},
  ];

  final List<Map<String, dynamic>> _reminderOptions = [
    {'label': 'None', 'value': null},
    {'label': '15 minutes before', 'value': 15},
    {'label': '30 minutes before', 'value': 30},
    {'label': '1 hour before', 'value': 60},
    {'label': '1 day before', 'value': 1440},
    {'label': '1 week before', 'value': 10080},
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.initialData != null;
    if (_isEditMode) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    _titleController.text = data['title'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _locationController.text = data['location'] ?? '';
    _eventType = data['event_type'] ?? 'other';
    _recurrence = data['recurrence'] ?? 'none';
    
    if (data['event_date'] != null) {
      try {
        _startDate = DateTime.parse(data['event_date']);
        _startTime = TimeOfDay.fromDateTime(_startDate);
      } catch (e) {
        _startDate = DateTime.now();
        _startTime = TimeOfDay.now();
      }
    }
    
    if (data['end_date'] != null) {
      try {
        _endDate = DateTime.parse(data['end_date']);
        _endTime = TimeOfDay.fromDateTime(_endDate!);
      } catch (e) {
        _endDate = null;
        _endTime = null;
      }
    }
    
    if (data['reminder_minutes'] != null) {
      _reminderMinutes = int.tryParse(data['reminder_minutes'].toString());
    }
    
    _isAllDay = data['is_all_day'] ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final startDateTime = _isAllDay
          ? DateTime(_startDate.year, _startDate.month, _startDate.day)
          : _combineDateTime(_startDate, _startTime);

      final endDateTime = _endDate != null
          ? (_isAllDay
              ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59)
              : _combineDateTime(_endDate!, _endTime ?? _startTime))
          : null;

      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'event_type': _eventType,
        'event_date': startDateTime.toIso8601String(),
        'end_date': endDateTime?.toIso8601String(),
        'location': _locationController.text.trim(),
        'recurrence': _recurrence,
        'family_circle_ids': [],
        'attendee_ids': [],
        'reminder_minutes': _reminderMinutes,
      };
      widget.onSubmit(data);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditMode ? 'Edit Event' : 'Add Event',
                      style: const TextStyle(
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
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _eventType,
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _eventTypes.map((type) {
                        return DropdownMenuItem(
                          value: type['value'],
                          child: Text(type['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _eventType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('All-day event'),
                      value: _isAllDay,
                      onChanged: (value) {
                        setState(() {
                          _isAllDay = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('MMM d, yyyy').format(_startDate),
                              ),
                            ),
                          ),
                        ),
                        if (!_isAllDay) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _selectStartTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Time',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  _startTime.format(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Date (Optional)',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.calendar_today),
                                suffixIcon: _endDate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _endDate = null;
                                            _endTime = null;
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              child: Text(
                                _endDate != null
                                    ? DateFormat('MMM d, yyyy').format(_endDate!)
                                    : 'Tap to select',
                                style: TextStyle(
                                  color: _endDate != null
                                      ? Colors.black
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!_isAllDay && _endDate != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _selectEndTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Time',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  (_endTime ?? _startTime).format(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _recurrence,
                      decoration: const InputDecoration(
                        labelText: 'Repeat',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      items: _recurrenceOptions.map((option) {
                        return DropdownMenuItem(
                          value: option['value'],
                          child: Text(option['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _recurrence = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      value: _reminderMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Reminder',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notifications),
                      ),
                      items: _reminderOptions.map((option) {
                        return DropdownMenuItem(
                          value: option['value'] as int?,
                          child: Text(option['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _reminderMinutes = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(_isEditMode ? 'Save Changes' : 'Add Event'),
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
