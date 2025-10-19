import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddVaccinationDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const AddVaccinationDialog({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<AddVaccinationDialog> createState() => _AddVaccinationDialogState();
}

class _AddVaccinationDialogState extends State<AddVaccinationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vaccineNameController = TextEditingController();
  final _providerController = TextEditingController();
  final _lotNumberController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dateAdministered = DateTime.now();
  DateTime? _nextDoseDate;

  @override
  void dispose() {
    _vaccineNameController.dispose();
    _providerController.dispose();
    _lotNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateAdministered() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateAdministered,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateAdministered) {
      setState(() {
        _dateAdministered = picked;
      });
    }
  }

  Future<void> _selectNextDoseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextDoseDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _nextDoseDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'family_member_id': 'current_user',
        'vaccine_name': _vaccineNameController.text.trim(),
        'date_administered': DateFormat('yyyy-MM-dd').format(_dateAdministered),
        'provider': _providerController.text.trim(),
        'lot_number': _lotNumberController.text.trim(),
        'next_dose_date': _nextDoseDate != null 
            ? DateFormat('yyyy-MM-dd').format(_nextDoseDate!)
            : null,
        'notes': _notesController.text.trim(),
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vaccines, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add Vaccination',
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
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    TextFormField(
                      controller: _vaccineNameController,
                      decoration: const InputDecoration(
                        labelText: 'Vaccine Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.vaccines),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter vaccine name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDateAdministered,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date Administered *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('MMMM d, yyyy').format(_dateAdministered),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _providerController,
                      decoration: const InputDecoration(
                        labelText: 'Healthcare Provider',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_hospital),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lotNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Lot Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectNextDoseDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Next Dose Date (Optional)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.event),
                          suffixIcon: _nextDoseDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _nextDoseDate = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        child: Text(
                          _nextDoseDate != null
                              ? DateFormat('MMMM d, yyyy').format(_nextDoseDate!)
                              : 'Tap to select',
                          style: TextStyle(
                            color: _nextDoseDate != null
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 3,
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
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Add Vaccination'),
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
