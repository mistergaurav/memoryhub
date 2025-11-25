import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../features/health_records/models/health_record.dart';
import '../../services/family/family_service.dart';
import '../../design_system/design_tokens.dart';
import 'controllers/health_record_approval_controller.dart';

class HealthRecordApprovalDialog extends StatefulWidget {
  final HealthRecord? record;

  const HealthRecordApprovalDialog({
    Key? key,
    this.record,
  }) : super(key: key);

  @override
  State<HealthRecordApprovalDialog> createState() => _HealthRecordApprovalDialogState();
}

class _HealthRecordApprovalDialogState extends State<HealthRecordApprovalDialog> {
  final HealthRecordApprovalController _controller = HealthRecordApprovalController();
  final FamilyService _familyService = FamilyService();

  String _visibilityType = 'family_tree';
  List<String> _selectedUserIds = [];
  List<String> _selectedCircleTypes = [];

  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _friendCircles = [];
  bool _isLoadingOptions = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final members = await _familyService.getFamilyMembers();
      final circles = await _familyService.getFriendCircles();
      if (mounted) {
        setState(() {
          _familyMembers = members;
          _friendCircles = circles;
          _isLoadingOptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOptions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.record == null) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No record to review'),
        ),
      );
    }
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecordSummary(),
                    const SizedBox(height: 24),
                    _buildVisibilitySection(),
                    if (_controller.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _controller.errorMessage!,
                                style: GoogleFonts.inter(
                                  color: Colors.red[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFEDF7F8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_ind,
              color: MemoryHubColors.teal500,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review Health Record',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: MemoryHubColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and set visibility for this record',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: MemoryHubColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: MemoryHubColors.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MemoryHubColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MemoryHubColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.record!.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MemoryHubColors.gray900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MemoryHubColors.teal500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.record!.recordType.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MemoryHubColors.teal500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.record!.description ?? '',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: MemoryHubColors.gray700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: MemoryHubColors.gray500),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMM d, yyyy').format(widget.record!.recordDate),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: MemoryHubColors.gray500,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.person, size: 14, color: MemoryHubColors.gray500),
              const SizedBox(width: 6),
              Text(
                'From: ${widget.record!.createdByName ?? "Unknown"}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: MemoryHubColors.gray500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySection() {
    if (_isLoadingOptions) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visibility Settings',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: MemoryHubColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Who can see this record?',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: MemoryHubColors.gray500,
          ),
        ),
        const SizedBox(height: 16),
        _buildVisibilityOption(
          title: 'Family Tree',
          subtitle: 'Visible to everyone in your family tree',
          value: 'family_tree',
          icon: Icons.account_tree,
        ),
        const SizedBox(height: 12),
        _buildVisibilityOption(
          title: 'Select Users',
          subtitle: 'Visible only to specific family members',
          value: 'select_users',
          icon: Icons.people,
        ),
        if (_visibilityType == 'select_users') ...[
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(left: 32),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MemoryHubColors.gray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Family Members:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: MemoryHubColors.gray700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _familyMembers.map((member) {
                    final isSelected = _selectedUserIds.contains(member['id']);
                    return FilterChip(
                      label: Text(member['name']),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedUserIds.add(member['id']);
                          } else {
                            _selectedUserIds.remove(member['id']);
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: MemoryHubColors.teal100,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? MemoryHubColors.teal700 : MemoryHubColors.gray700,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? MemoryHubColors.teal500 : MemoryHubColors.gray300,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildVisibilityOption(
          title: 'Family Circle',
          subtitle: 'Visible to specific relationship types (e.g., Close Friends)',
          value: 'family_circle',
          icon: Icons.groups,
        ),
        if (_visibilityType == 'family_circle') ...[
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(left: 32),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MemoryHubColors.gray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Circles:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: MemoryHubColors.gray700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _friendCircles.map((circle) {
                    final isSelected = _selectedCircleTypes.contains(circle['circle_type']);
                    return FilterChip(
                      label: Text(circle['name']),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCircleTypes.add(circle['circle_type']);
                          } else {
                            _selectedCircleTypes.remove(circle['circle_type']);
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: MemoryHubColors.teal100,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? MemoryHubColors.teal700 : MemoryHubColors.gray700,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? MemoryHubColors.teal500 : MemoryHubColors.gray300,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildVisibilityOption(
          title: 'Private',
          subtitle: 'Visible only to you and the sender',
          value: 'private',
          icon: Icons.lock,
        ),
      ],
    );
  }

  Widget _buildVisibilityOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _visibilityType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _visibilityType = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? MemoryHubColors.teal50.withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? MemoryHubColors.teal500 : MemoryHubColors.gray200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? MemoryHubColors.teal500 : MemoryHubColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : MemoryHubColors.gray500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? MemoryHubColors.teal900 : MemoryHubColors.gray900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: MemoryHubColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: MemoryHubColors.teal500, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _controller.isSubmitting
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reject Record?'),
                            content: const Text(
                                'Are you sure you want to reject this health record? It will be removed from your pending list.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Reject', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          if (widget.record == null) return;
                          final success = await _controller.rejectRecord(widget.record!.id);
                          if (success && mounted) {
                            Navigator.of(context).pop(true); // Return true to indicate refresh needed
                          }
                        }
                      },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Reject'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _controller.isSubmitting
                    ? null
                    : () async {
                        if (widget.record == null) return;
                        final success = await _controller.approveRecord(
                          widget.record!.id,
                          visibilityType: _visibilityType,
                          visibilityUserIds: _visibilityType == 'select_users' ? _selectedUserIds : null,
                          visibilityFamilyCircles: _visibilityType == 'family_circle' ? _selectedCircleTypes : null,
                        );
                        if (success && mounted) {
                          Navigator.of(context).pop(true); // Return true to indicate refresh needed
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MemoryHubColors.teal500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _controller.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Approve & Save',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
