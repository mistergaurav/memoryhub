import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design_system/design_tokens.dart';
import '../../widgets/memories/user_selection_sheet.dart';
import '../../widgets/media_attachment_picker.dart';
import '../../services/family/core/relationships_service.dart';

class AddLegacyLetterDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const AddLegacyLetterDialog({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<AddLegacyLetterDialog> createState() => _AddLegacyLetterDialogState();
}

class _AddLegacyLetterDialogState extends State<AddLegacyLetterDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final RelationshipsService _relationshipsService = RelationshipsService();
  
  List<String> _selectedRecipientIds = [];
  Map<String, String> _recipientNames = {}; // user_id -> name mapping
  List<MediaAttachment> _attachments = [];
  DateTime? _deliveryDate;
  bool _encrypt = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _showRecipientSelector() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UserSelectionSheet(
        initialSelectedIds: _selectedRecipientIds,
        onSelectionChanged: (selectedIds) async {
          // Fetch names for selected users
          final names = <String, String>{};
          try {
            final friendsData = await _relationshipsService.getRelationships(
              statusFilter: 'accepted',
              relationshipTypeFilter: 'friend',
            );
            final familyData = await _relationshipsService.getRelationships(
              statusFilter: 'accepted',
              relationshipTypeFilter: 'family',
            );
            
            final allUsers = <Map<String, dynamic>>[];
            if (friendsData['data'] != null) {
              for (var item in friendsData['data']) {
                if (item['related_user'] != null) {
                  allUsers.add(item['related_user']);
                }
              }
            }
            if (familyData['data'] != null) {
              for (var item in familyData['data']) {
                if (item['related_user'] != null && !allUsers.any((u) => u['id'] == item['related_user']['id'])) {
                  allUsers.add(item['related_user']);
                }
              }
            }
            
            for (var user in allUsers) {
              if (selectedIds.contains(user['id'])) {
                names[user['id']] = user['full_name'] ?? 'Unknown';
              }
            }
          } catch (e) {
            // Fallback to showing IDs if names can't be fetched
            for (var id in selectedIds) {
              names[id] = id;
            }
          }
          
          setState(() {
            _selectedRecipientIds = selectedIds;
            _recipientNames = names;
          });
        },
      ),
    );
  }

  void _removeRecipient(String userId) {
    setState(() {
      _selectedRecipientIds.remove(userId);
      _recipientNames.remove(userId);
    });
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 50)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MemoryHubColors.purple600,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _deliveryDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRecipientIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipient')),
      );
      return;
    }

    if (_deliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery date')),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'recipient_ids': _selectedRecipientIds,
      'delivery_date': _deliveryDate!.toIso8601String(),
      'encrypt': _encrypt,
      'attachments': _attachments.map((a) => a.path).toList(),
    };

    try {
      await widget.onSubmit(data);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getRecipientNamesText() {
    if (_selectedRecipientIds.isEmpty) return '[Select Recipients]';
    final names = _selectedRecipientIds.map((id) => _recipientNames[id] ?? 'Unknown').toList();
    if (names.length <= 2) {
      return names.join(' and ');
    } else {
      return '${names.take(2).join(', ')} and ${names.length - 2} others';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.xlRadius),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF7), // Cream/parchment background
          borderRadius: MemoryHubBorderRadius.xlRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(MemoryHubSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MemoryHubColors.purple600.withOpacity(0.1),
                    MemoryHubColors.purple400.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(MemoryHubSpacing.md),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [MemoryHubColors.purple600, MemoryHubColors.purple400],
                      ),
                      borderRadius: MemoryHubBorderRadius.mdRadius,
                    ),
                    child: const Icon(Icons.mail, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: MemoryHubSpacing.lg),
                  Expanded(
                    child: Text(
                      '✉️ Legacy Letter',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: MemoryHubColors.purple700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Letter Content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(MemoryHubSpacing.xxl),
                  children: [
                    // "Dear" salutation
                    Row(
                      children: [
                        Text(
                          'Dear ',
                          style: GoogleFonts.dancingScript(
                            fontSize: 20,
                            color: MemoryHubColors.gray700,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showRecipientSelector,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: MemoryHubColors.purple400,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                              ),
                              child: Text(
                                _getRecipientNamesText(),
                                style: GoogleFonts.dancingScript(
                                  fontSize: 20,
                                  color: _selectedRecipientIds.isEmpty 
                                      ? MemoryHubColors.gray400 
                                      : MemoryHubColors.purple700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          ',',
                          style: GoogleFonts.dancingScript(
                            fontSize: 20,
                            color: MemoryHubColors.gray700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: MemoryHubSpacing.xxl),

                    // Subject
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        labelStyle: GoogleFonts.merriweather(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: MemoryHubBorderRadius.mdRadius,
                          borderSide: BorderSide(color: MemoryHubColors.purple200),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.subject, color: MemoryHubColors.purple400),
                      ),
                      style: GoogleFonts.merriweather(fontSize: 16, fontWeight: FontWeight.w600),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Subject is required' : null,
                    ),

                    const SizedBox(height: MemoryHubSpacing.xxl),

                    // Letter Content
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: 'Your Message',
                        labelStyle: GoogleFonts.merriweather(fontSize: 14),
                        hintText: 'Write your heartfelt message here...',
                        hintStyle: GoogleFonts.merriweather(
                          fontSize: 14,
                          color: MemoryHubColors.gray400,
                          fontStyle: FontStyle.italic,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: MemoryHubBorderRadius.mdRadius,
                          borderSide: BorderSide(color: MemoryHubColors.purple200),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        alignLabelWithHint: true,
                      ),
                      style: GoogleFonts.merriweather(fontSize: 15, height: 1.8),
                      maxLines: 10,
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Message is required' : null,
                    ),

                    const SizedBox(height: MemoryHubSpacing.xxl),

                    // Media Attachments
                    MediaAttachmentPicker(
                      initialAttachments: _attachments,
                      onAttachmentsChanged: (attachments) {
                        setState(() {
                          _attachments = attachments;
                        });
                      },
                    ),

                    const SizedBox(height: MemoryHubSpacing.xxl),

                    // Delivery Date
                    InkWell(
                      onTap: _selectDeliveryDate,
                      child: Container(
                        padding: EdgeInsets.all(MemoryHubSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: MemoryHubColors.purple200),
                          borderRadius: MemoryHubBorderRadius.mdRadius,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: MemoryHubColors.purple600),
                            const SizedBox(width: MemoryHubSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery Date',
                                    style: GoogleFonts.merriweather(
                                      fontSize: 12,
                                      color: MemoryHubColors.gray600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _deliveryDate != null
                                        ? '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}'
                                        : 'Select when this letter should be delivered',
                                    style: GoogleFonts.merriweather(
                                      fontSize: 14,
                                      color: _deliveryDate != null
                                          ? MemoryHubColors.gray800
                                          : MemoryHubColors.gray400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: MemoryHubColors.gray400),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: MemoryHubSpacing.lg),

                    // Encryption Toggle
                    Container(
                      padding: EdgeInsets.all(MemoryHubSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: MemoryHubColors.purple200),
                        borderRadius: MemoryHubBorderRadius.mdRadius,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock, color: MemoryHubColors.purple600),
                          const SizedBox(width: MemoryHubSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Encrypt Letter',
                                  style: GoogleFonts.merriweather(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Extra privacy for sensitive content',
                                  style: GoogleFonts.merriweather(
                                    fontSize: 12,
                                    color: MemoryHubColors.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _encrypt,
                            onChanged: (value) => setState(() => _encrypt = value),
                            activeColor: MemoryHubColors.purple600,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: MemoryHubSpacing.xxl + 8),

                    // Signature
                    Row(
                      children: [
                        Text(
                          'With love,',
                          style: GoogleFonts.dancingScript(
                            fontSize: 18,
                            color: MemoryHubColors.gray700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: MemoryHubSpacing.xl),
                        Text(
                          '[Your name]',
                          style: GoogleFonts.dancingScript(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: MemoryHubColors.purple700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(MemoryHubSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: MemoryHubColors.gray200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                  const SizedBox(width: MemoryHubSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: Text(
                      'Send Letter',
                      style: GoogleFonts.merriweather(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MemoryHubColors.purple600,
                      padding: EdgeInsets.symmetric(
                        horizontal: MemoryHubSpacing.xxl,
                        vertical: MemoryHubSpacing.lg,
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
