import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_milestone.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/add_milestone_dialog.dart';
import 'package:intl/intl.dart';

class FamilyMilestonesScreen extends StatefulWidget {
  const FamilyMilestonesScreen({Key? key}) : super(key: key);

  @override
  State<FamilyMilestonesScreen> createState() => _FamilyMilestonesScreenState();
}

class _FamilyMilestonesScreenState extends State<FamilyMilestonesScreen> with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  List<FamilyMilestone> _milestones = [];
  bool _isLoading = true;
  String _error = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadMilestones();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMilestones() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final milestones = await _familyService.getMilestones();
      setState(() {
        _milestones = milestones;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadMilestones,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Family Milestones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF59E0B),
                        Color(0xFFFBBF24),
                        Color(0xFFFCD34D),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40,
                        bottom: -40,
                        child: Icon(
                          Icons.celebration,
                          size: 180,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 80,
                        child: Icon(
                          Icons.star,
                          size: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      Positioned(
                        right: 60,
                        top: 100,
                        child: Icon(
                          Icons.star,
                          size: 25,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sort feature coming soon')),
                    );
                  },
                ),
              ],
            ),
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerCard(),
                    childCount: 4,
                  ),
                ),
              )
            else if (_error.isNotEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Milestones',
                  message: 'Failed to load family milestones. Pull to retry.',
                  actionLabel: 'Retry',
                  onAction: _loadMilestones,
                ),
              )
            else if (_milestones.isEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.celebration,
                  title: 'No Milestones Yet',
                  message: 'Start celebrating family achievements by adding your first milestone!',
                  actionLabel: 'Add Milestone',
                  onAction: _showAddDialog,
                  gradientColors: const [
                    Color(0xFFF59E0B),
                    Color(0xFFFBBF24),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildMilestoneCard(_milestones[index], index),
                    childCount: _milestones.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Milestone'),
        backgroundColor: const Color(0xFFF59E0B),
      ),
    );
  }

  Widget _buildMilestoneCard(FamilyMilestone milestone, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getCategoryColor(milestone.category).withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
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
                            _getCategoryColor(milestone.category),
                            _getCategoryColor(milestone.category).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _getCategoryColor(milestone.category).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(milestone.category),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMMM d, y').format(milestone.milestoneDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (milestone.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    milestone.description!,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
                if (milestone.genealogyPersonName != null || milestone.autoGenerated || milestone.generation != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_tree, size: 18, color: Colors.indigo.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (milestone.genealogyPersonName != null) ...[
                                Text(
                                  milestone.genealogyPersonName!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                              ],
                              if (milestone.generation != null) ...[
                                if (milestone.genealogyPersonName != null) const SizedBox(height: 4),
                                Text(
                                  'Generation ${milestone.generation}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (milestone.autoGenerated) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: 10, color: Colors.blue.shade700),
                                const SizedBox(width: 3),
                                Text(
                                  'Auto',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (milestone.photoUrl != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      milestone.photoUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 48),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildInteractionChip(
                          Icons.favorite,
                          milestone.likesCount.toString(),
                          const Color(0xFFEC4899),
                        ),
                        const SizedBox(width: 12),
                        _buildInteractionChip(
                          Icons.comment,
                          milestone.commentsCount.toString(),
                          const Color(0xFF06B6D4),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(milestone.category).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        milestone.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(milestone.category),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionChip(IconData icon, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'birthday':
        return const Color(0xFFEC4899);
      case 'achievement':
        return const Color(0xFF10B981);
      case 'graduation':
        return const Color(0xFF7C3AED);
      case 'wedding':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF06B6D4);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'birthday':
        return Icons.cake;
      case 'achievement':
        return Icons.emoji_events;
      case 'graduation':
        return Icons.school;
      case 'wedding':
        return Icons.favorite;
      default:
        return Icons.celebration;
    }
  }

  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 200, height: 20, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 8),
                      ShimmerBox(width: 120, height: 14, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ShimmerBox(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 4),
            ShimmerBox(width: 250, height: 14, borderRadius: BorderRadius.circular(4)),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMilestoneDialog(onSubmit: _handleAdd),
    );
  }

  Future<void> _handleAdd(Map<String, dynamic> data) async {
    try {
      await _familyService.createMilestone(data);
      _loadMilestones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milestone added successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add milestone: $e'), backgroundColor: Colors.red),
        );
      }
      rethrow;
    }
  }
}
