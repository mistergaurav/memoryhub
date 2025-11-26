import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design_system/design_system.dart';
import '../../design_system/layout/padded.dart';
import '../../models/family/genealogy_person.dart';
import '../../services/family/genealogy/persons_service.dart';
import '../../services/family/genealogy/relationships_service.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/gradient_container.dart';

class GenealogyRequestDetailScreen extends StatefulWidget {
  final String notificationId;
  final String personId;
  final String actorName;

  const GenealogyRequestDetailScreen({
    super.key,
    required this.notificationId,
    required this.personId,
    required this.actorName,
  });

  @override
  State<GenealogyRequestDetailScreen> createState() => _GenealogyRequestDetailScreenState();
}

class _GenealogyRequestDetailScreenState extends State<GenealogyRequestDetailScreen> {
  bool _isLoading = true;
  GenealogyPerson? _person;
  String? _error;
  String? _relationshipLabel;
  final _personsService = GenealogyPersonsService();
  final _relationshipsService = GenealogyRelationshipsService();

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final person = await _personsService.getPerson(widget.personId);
      
      // Fetch relationships to determine how they are related
      String? label;
      try {
        final relationships = await _relationshipsService.getPersonRelationships(widget.personId);
        if (relationships.isNotEmpty) {
          // Find relationship created by the actor (inviter)
          // Since we don't have actor ID easily available here, we'll just take the first one 
          // or try to infer. For now, taking the first one is a reasonable approximation 
          // as a new person usually has one relationship initially.
          final rel = relationships.first;
          
          // Determine label based on relationship type
          // If person is person1 (child/parent/spouse of person2)
          // We need to know who person2 is to be sure, but assuming person2 is the inviter or close relative
          
          final type = rel.relationshipType;
          final gender = person.gender.toLowerCase();
          
          if (type == 'parent') {
            // If this person is the 'parent' in the relationship
            if (rel.person1Id == widget.personId) {
               label = gender == 'male' ? 'Father' : (gender == 'female' ? 'Mother' : 'Parent');
            } else {
               label = gender == 'male' ? 'Son' : (gender == 'female' ? 'Daughter' : 'Child');
            }
          } else if (type == 'child') {
             if (rel.person1Id == widget.personId) {
               label = gender == 'male' ? 'Son' : (gender == 'female' ? 'Daughter' : 'Child');
            } else {
               label = gender == 'male' ? 'Father' : (gender == 'female' ? 'Mother' : 'Parent');
            }
          } else if (type == 'spouse') {
            label = gender == 'male' ? 'Husband' : (gender == 'female' ? 'Wife' : 'Spouse');
          } else if (type == 'sibling') {
            label = gender == 'male' ? 'Brother' : (gender == 'female' ? 'Sister' : 'Sibling');
          }
        }
      } catch (e) {
        print('Error fetching relationships: $e');
      }

      if (mounted) {
        setState(() {
          _person = person;
          _relationshipLabel = label;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleApprove() async {
    try {
      setState(() => _isLoading = true);
      await _personsService.approvePerson(widget.personId);
      
      if (mounted) {
        final provider = Provider.of<NotificationsProvider>(context, listen: false);
        await provider.markAsRead(widget.notificationId);
        await provider.refresh();
        
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request approved', style: GoogleFonts.inter()),
            backgroundColor: MemoryHubColors.green600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e', style: GoogleFonts.inter()),
            backgroundColor: MemoryHubColors.red600,
          ),
        );
      }
    }
  }

  Future<void> _handleReject() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Request', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejecting this request:',
              style: GoogleFonts.inter(color: MemoryHubColors.gray700),
            ),
            VGap(MemoryHubSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (e.g., "I don\'t know this person")',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: MemoryHubColors.gray600)),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MemoryHubColors.red600),
            child: Text('Reject', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason == null) return;

    try {
      setState(() => _isLoading = true);
      await _personsService.rejectPerson(widget.personId, reason: reason);
      
      if (mounted) {
        final provider = Provider.of<NotificationsProvider>(context, listen: false);
        await provider.markAsRead(widget.notificationId);
        await provider.refresh();
        
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request rejected', style: GoogleFonts.inter()),
            backgroundColor: MemoryHubColors.gray600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e', style: GoogleFonts.inter()),
            backgroundColor: MemoryHubColors.red600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invitation Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: MemoryHubColors.white,
        foregroundColor: MemoryHubColors.gray900,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      Padded(
                        padding: Spacing.edgeInsetsAll(Spacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoSection(),
                            VGap(MemoryHubSpacing.xl),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return GradientContainer(
      height: 200,
      colors: [MemoryHubColors.orange500, MemoryHubColors.red500],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(MemoryHubSpacing.lg),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_alt_1,
                size: 48,
                color: MemoryHubColors.orange500,
              ),
            ),
            VGap(MemoryHubSpacing.md),
            Text(
              'Family Tree Invitation',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.lgRadius),
      child: Padding(
        padding: EdgeInsets.all(MemoryHubSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invitation from ${widget.actorName}',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MemoryHubColors.gray900,
              ),
            ),
            VGap(MemoryHubSpacing.md),
            Text(
              '${widget.actorName} has added you to their family tree as:',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: MemoryHubColors.gray700,
              ),
            ),
            if (_relationshipLabel != null) ...[
              VGap(MemoryHubSpacing.sm),
              Container(
                padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.md, vertical: MemoryHubSpacing.xs),
                decoration: BoxDecoration(
                  color: MemoryHubColors.blue50,
                  borderRadius: MemoryHubBorderRadius.mdRadius,
                  border: Border.all(color: MemoryHubColors.blue200),
                ),
                child: Text(
                  _relationshipLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: MemoryHubColors.blue700,
                  ),
                ),
              ),
            ],
            VGap(MemoryHubSpacing.lg),
            Container(
              padding: EdgeInsets.all(MemoryHubSpacing.md),
              decoration: BoxDecoration(
                color: MemoryHubColors.gray50,
                borderRadius: MemoryHubBorderRadius.mdRadius,
                border: Border.all(color: MemoryHubColors.gray200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: MemoryHubColors.blue100,
                    backgroundImage: _person?.photoUrl != null ? NetworkImage(_person!.photoUrl!) : null,
                    child: _person?.photoUrl == null
                        ? Text(
                            _person?.firstName[0] ?? '?',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: MemoryHubColors.blue600,
                            ),
                          )
                        : null,
                  ),
                  HGap(MemoryHubSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_person?.firstName} ${_person?.lastName}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: MemoryHubColors.gray900,
                          ),
                        ),
                        if (_person?.biography != null) ...[
                          VGap(MemoryHubSpacing.xs),
                          Text(
                            _person!.biography!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: MemoryHubColors.gray600,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            VGap(MemoryHubSpacing.lg),
            Text(
              'By approving this request, you will be linked to this profile in their tree. This will also allow you to see their family tree and merge it with yours.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: MemoryHubColors.gray600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_person?.approvalStatus == 'approved') {
      return Container(
        padding: EdgeInsets.all(MemoryHubSpacing.md),
        decoration: BoxDecoration(
          color: MemoryHubColors.green50,
          borderRadius: MemoryHubBorderRadius.mdRadius,
          border: Border.all(color: MemoryHubColors.green200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: MemoryHubColors.green600),
            HGap(MemoryHubSpacing.sm),
            Text(
              'You have approved this request',
              style: GoogleFonts.inter(
                color: MemoryHubColors.green700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_person?.approvalStatus == 'rejected') {
      return Container(
        padding: EdgeInsets.all(MemoryHubSpacing.md),
        decoration: BoxDecoration(
          color: MemoryHubColors.red50,
          borderRadius: MemoryHubBorderRadius.mdRadius,
          border: Border.all(color: MemoryHubColors.red200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: MemoryHubColors.red600),
            HGap(MemoryHubSpacing.sm),
            Text(
              'You have rejected this request',
              style: GoogleFonts.inter(
                color: MemoryHubColors.red700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _handleReject,
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: MemoryHubColors.red600,
              padding: EdgeInsets.symmetric(vertical: MemoryHubSpacing.md),
              side: const BorderSide(color: MemoryHubColors.red600),
            ),
          ),
        ),
        HGap(MemoryHubSpacing.md),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleApprove,
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MemoryHubColors.green600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: MemoryHubSpacing.md),
            ),
          ),
        ),
      ],
    );
  }
}
