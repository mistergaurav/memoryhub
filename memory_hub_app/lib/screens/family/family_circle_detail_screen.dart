import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/family/core/family_circles_service.dart';
import '../../services/auth_service.dart';
import '../../models/family/family_circle.dart';
import '../../models/user_search_result.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../design_system/design_tokens.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import '../../dialogs/family/create_family_circle_dialog.dart';
import '../../widgets/user_search_autocomplete.dart';

class FamilyCircleDetailScreen extends StatefulWidget {
  final FamilyCircle circle;

  const FamilyCircleDetailScreen({Key? key, required this.circle}) : super(key: key);

  @override
  State<FamilyCircleDetailScreen> createState() => _FamilyCircleDetailScreenState();
}

class _FamilyCircleDetailScreenState extends State<FamilyCircleDetailScreen> {
  final FamilyCirclesService _circlesService = FamilyCirclesService();
  final AuthService _authService = AuthService();
  late FamilyCircle _circle;
  bool _isLoading = true;
  String _error = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _circle = widget.circle;
    _loadCircleDetails();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await _authService.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  Future<void> _loadCircleDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final circle = await _circlesService.getFamilyCircleById(_circle.id);
      if (!mounted) return;

      setState(() {
        _circle = circle;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool get _isOwner => _currentUserId != null && _currentUserId == _circle.ownerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const VGap.lg(),
                    Text(
                      'Loading circle details...',
                      style: context.text.bodyLarge?.copyWith(
                            color: MemoryHubColors.gray600,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else if (_error.isNotEmpty)
            SliverFillRemaining(
              child: EnhancedEmptyState(
                icon: Icons.error_outline,
                title: 'Error Loading Circle',
                message: 'Failed to load circle details. Pull down to retry.',
                actionLabel: 'Retry',
                onAction: _loadCircleDetails,
                gradientColors: MemoryHubGradients.error.colors,
              ),
            )
          else ...[
            _buildCircleInfo(),
            _buildMembersSection(),
          ],
          const SliverToBoxAdapter(child: VGap.xxxl()),
        ],
      ),
      floatingActionButton: _isOwner
          ? FloatingActionButton.extended(
              heroTag: 'circle_detail_fab',
              onPressed: _showAddMemberDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Member'),
              backgroundColor: MemoryHubColors.primary,
            )
          : null,
    );
  }

  Widget _buildAppBar() {
    final color = _getCircleColor(_circle.color);
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _circle.name,
          style: const TextStyle(
            fontWeight: MemoryHubTypography.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Center(
            child: _circle.avatarUrl != null && _circle.avatarUrl!.isNotEmpty
                ? Image.network(
                    _circle.avatarUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar();
                    },
                  )
                : _buildDefaultAvatar(),
          ),
        ),
      ),
      actions: [
        if (_isOwner) ...[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
            tooltip: 'Edit Circle',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
            tooltip: 'Delete Circle',
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.groups,
      color: Colors.white,
      size: 80,
    );
  }

  Widget _buildCircleInfo() {
    return SliverToBoxAdapter(child: Padded.all(
        Spacing.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.category,
                    label: 'Type',
                    value: _circle.displayCircleType,
                  ),
                ),
                const HGap.md(),
                Expanded(child: _buildInfoCard(
                    icon: Icons.people,
                    label: 'Members',
                    value: '${_circle.memberCount}',
                  ),
                ),
              ],
            ),
            if (_circle.description != null && _circle.description!.isNotEmpty) ...[
              const VGap.lg(),
              Card(
                elevation: MemoryHubElevation.sm,
                shape: RoundedRectangleBorder(
                  borderRadius: MemoryHubBorderRadius.xlRadius,
                ),
                child: Padded.all(
                  Spacing.lg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.description,
                            color: MemoryHubColors.gray600,
                            size: 20,
                          ),
                          const HGap.sm(),
                          Text(
                            'Description',
                            style: context.text.titleMedium?.copyWith(
                                  fontWeight: MemoryHubTypography.semiBold,
                                ),
                          ),
                        ],
                      ),
                      const VGap.md(),
                      Text(
                        _circle.description!,
                        style: context.text.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const VGap.md(),
            Text(
              'Created ${DateFormat.yMMMMd().format(_circle.createdAt)}',
              style: context.text.bodySmall?.copyWith(
                    color: MemoryHubColors.gray500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: MemoryHubElevation.sm,
      shape: RoundedRectangleBorder(
        borderRadius: MemoryHubBorderRadius.xlRadius,
      ),
      child: Padded.all(
        Spacing.lg,
        child: Column(
          children: [
            Icon(icon, color: _getCircleColor(_circle.color), size: 32),
            const VGap.sm(),
            Text(
              value,
              style: context.text.headlineSmall?.copyWith(
                    fontWeight: MemoryHubTypography.bold,
                  ),
            ),
            const VGap.xs(),
            Text(
              label,
              style: context.text.bodySmall?.copyWith(
                    color: MemoryHubColors.gray600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return SliverToBoxAdapter(
      child: Padded.all(
        Spacing.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Members (${_circle.members.length})',
              style: context.text.headlineSmall?.copyWith(
                    fontWeight: MemoryHubTypography.bold,
                  ),
            ),
            const VGap.md(),
            if (_circle.members.isEmpty)
              Card(
                elevation: MemoryHubElevation.sm,
                shape: RoundedRectangleBorder(
                  borderRadius: MemoryHubBorderRadius.xlRadius,
                ),
                child: Padded.all(
                  Spacing.xl,
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 48,
                          color: MemoryHubColors.gray400,
                        ),
                        const VGap.md(),
                        Text(
                          'No members yet',
                          style: context.text.titleMedium?.copyWith(
                                color: MemoryHubColors.gray600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _circle.members.length,
                itemBuilder: (context, index) {
                  final member = _circle.members[index];
                  final isCurrentUser = member.id == _currentUserId;
                  final canRemove = _isOwner && member.id != _circle.ownerId;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: MemoryHubSpacing.md),
                    elevation: MemoryHubElevation.sm,
                    shape: RoundedRectangleBorder(
                      borderRadius: MemoryHubBorderRadius.lgRadius,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getCircleColor(_circle.color),
                        backgroundImage: member.avatar != null && member.avatar!.isNotEmpty
                            ? NetworkImage(member.avatar!)
                            : null,
                        child: member.avatar == null || member.avatar!.isEmpty
                            ? Text(
                                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: MemoryHubTypography.semiBold,
                                ),
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: MemoryHubTypography.semiBold,
                              ),
                            ),
                          ),
                          if (member.id == _circle.ownerId)
                            Container(
                              padding: Spacing.edgeInsetsSymmetric(
                                horizontal: Spacing.sm,
                                vertical: Spacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: MemoryHubColors.amber500.withValues(alpha: 0.2),
                                borderRadius: MemoryHubBorderRadius.fullRadius,
                              ),
                              child: const Text(
                                'Owner',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: MemoryHubTypography.semiBold,
                                  color: MemoryHubColors.amber600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: isCurrentUser ? const Text('You') : null,
                      trailing: canRemove
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: MemoryHubColors.red500,
                              onPressed: () => _confirmRemoveMember(member),
                            )
                          : null,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getCircleColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return MemoryHubColors.purple500;
    }
    try {
      final hexColor = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return MemoryHubColors.purple500;
    }
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: const Text('Use the user search feature to add members to this circle.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateFamilyCircleDialog(
        onSubmit: _handleUpdate,
        initialCircle: _circle,
      ),
    );
  }

  Future<void> _handleUpdate(FamilyCircleCreate circleData) async {
    try {
      final update = FamilyCircleUpdate(
        name: circleData.name,
        description: circleData.description,
        circleType: circleData.circleType,
        avatarUrl: circleData.avatarUrl,
        color: circleData.color,
      );
      await _circlesService.updateFamilyCircle(_circle.id, update);
      await _loadCircleDetails();
      if (mounted) {
        AppSnackbar.success(context, 'Circle updated successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update circle: $e');
      }
      rethrow;
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Circle'),
        content: Text('Are you sure you want to delete "${_circle.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleDelete();
            },
            style: TextButton.styleFrom(foregroundColor: MemoryHubColors.red500),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    try {
      await _circlesService.deleteFamilyCircle(_circle.id);
      if (mounted) {
        Navigator.pop(context, true);
        AppSnackbar.success(context, 'Circle deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to delete circle: $e');
      }
    }
  }

  void _confirmRemoveMember(CircleMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.name} from this circle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleRemoveMember(member);
            },
            style: TextButton.styleFrom(foregroundColor: MemoryHubColors.red500),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRemoveMember(CircleMember member) async {
    try {
      await _circlesService.removeCircleMember(_circle.id, member.id);
      await _loadCircleDetails();
      if (mounted) {
        AppSnackbar.success(context, 'Member removed successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to remove member: $e');
      }
    }
  }
}
