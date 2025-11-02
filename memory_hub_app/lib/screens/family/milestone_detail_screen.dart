import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/family/family_milestone.dart';
import '../../services/family/family_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../dialogs/family/add_milestone_dialog.dart';

class MilestoneDetailScreen extends StatefulWidget {
  final String milestoneId;

  const MilestoneDetailScreen({Key? key, required this.milestoneId}) : super(key: key);

  @override
  State<MilestoneDetailScreen> createState() => _MilestoneDetailScreenState();
}

class _MilestoneDetailScreenState extends State<MilestoneDetailScreen> {
  final FamilyService _familyService = FamilyService();
  FamilyMilestone? _milestone;
  bool _isLoading = true;
  bool _isLiking = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadMilestone();
  }

  Future<void> _loadMilestone() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final milestone = await _familyService.getMilestoneDetail(widget.milestoneId);
      setState(() {
        _milestone = milestone;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLike() async {
    if (_milestone == null || _isLiking) return;

    setState(() => _isLiking = true);
    try {
      await _familyService.likeMilestone(_milestone!.id);
      await _loadMilestone();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like milestone: $e')),
      );
    } finally {
      setState(() => _isLiking = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Milestone'),
        content: const Text('Are you sure you want to delete this milestone? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _familyService.deleteMilestone(widget.milestoneId);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Milestone deleted successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete milestone: $e')),
        );
      }
    }
  }

  Future<void> _handleEdit() async {
    if (_milestone == null) return;

    await showDialog(
      context: context,
      builder: (context) => AddMilestoneDialog(
        onSubmit: (data) async {
          await _familyService.updateMilestone(_milestone!.id, data);
          await _loadMilestone();
        },
      ),
    );
  }

  void _handleShare() {
    if (_milestone == null) return;
    final text = '${_milestone!.title}\n${_milestone!.description ?? ''}\n${DateFormat('MMM d, yyyy').format(_milestone!.milestoneDate)}';
    Share.share(text, subject: 'Family Milestone: ${_milestone!.title}');
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'birth':
        return const Color(0xFFEC4899);
      case 'graduation':
        return const Color(0xFF8B5CF6);
      case 'wedding':
        return const Color(0xFFEF4444);
      case 'anniversary':
        return const Color(0xFFF59E0B);
      case 'achievement':
        return const Color(0xFFEAB308);
      case 'first_word':
        return const Color(0xFF06B6D4);
      case 'first_step':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'birth':
        return Icons.child_care;
      case 'graduation':
        return Icons.school;
      case 'wedding':
        return Icons.favorite;
      case 'anniversary':
        return Icons.cake;
      case 'achievement':
        return Icons.emoji_events;
      case 'first_word':
        return Icons.chat_bubble;
      case 'first_step':
        return Icons.directions_walk;
      default:
        return Icons.star;
    }
  }

  String _formatType(String type) {
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMilestone,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _milestone == null
                  ? const Center(child: Text('Milestone not found'))
                  : CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 250,
                          pinned: true,
                          flexibleSpace: FlexibleSpaceBar(
                            title: Text(
                              _milestone!.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                              ),
                            ),
                            background: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _getTypeColor(_milestone!.category),
                                    _getTypeColor(_milestone!.category).withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -40,
                                    bottom: -40,
                                    child: Icon(
                                      _getTypeIcon(_milestone!.category),
                                      size: 180,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  if (_milestone!.photoUrl != null)
                                    Positioned.fill(
                                      child: Image.network(
                                        _milestone!.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: _handleShare,
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _handleEdit();
                                } else if (value == 'delete') {
                                  _handleDelete();
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  _getTypeColor(_milestone!.category),
                                                  _getTypeColor(_milestone!.category).withOpacity(0.7),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getTypeIcon(_milestone!.category),
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _formatType(_milestone!.category),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                DateFormat('MMMM d, yyyy').format(_milestone!.milestoneDate),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (_milestone!.description != null) ...[
                                        const SizedBox(height: 20),
                                        const Divider(),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Description',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _milestone!.description!,
                                          style: const TextStyle(fontSize: 15, height: 1.6),
                                        ),
                                      ],
                                      const SizedBox(height: 20),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 20, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Created by ${_milestone!.createdByName ?? 'Unknown'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 20, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Created ${DateFormat('MMM d, yyyy').format(_milestone!.createdAt)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  onTap: _isLiking ? null : _handleLike,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (_isLiking)
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        else
                                          Icon(
                                            Icons.favorite,
                                            color: _getTypeColor(_milestone!.category),
                                            size: 28,
                                          ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${_milestone!.likesCount} ${_milestone!.likesCount == 1 ? 'Like' : 'Likes'}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
