import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_milestone.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/add_milestone_dialog.dart';
import 'milestone_detail_screen.dart';
import 'package:intl/intl.dart';

class FamilyMilestonesScreen extends StatefulWidget {
  const FamilyMilestonesScreen({Key? key}) : super(key: key);

  @override
  State<FamilyMilestonesScreen> createState() => _FamilyMilestonesScreenState();
}

class _FamilyMilestonesScreenState extends State<FamilyMilestonesScreen> with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  final ScrollController _scrollController = ScrollController();
  List<FamilyMilestone> _milestones = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  late AnimationController _animationController;
  
  int _currentPage = 1;
  bool _hasMore = true;
  String? _selectedType;
  String _sortOrder = 'newest';

  final List<Map<String, dynamic>> _filterTypes = [
    {'value': null, 'label': 'All', 'icon': Icons.apps, 'color': Color(0xFF6366F1)},
    {'value': 'birth', 'label': 'Birth', 'icon': Icons.child_care, 'color': Color(0xFFEC4899)},
    {'value': 'graduation', 'label': 'Graduation', 'icon': Icons.school, 'color': Color(0xFF8B5CF6)},
    {'value': 'wedding', 'label': 'Wedding', 'icon': Icons.favorite, 'color': Color(0xFFEF4444)},
    {'value': 'anniversary', 'label': 'Anniversary', 'icon': Icons.cake, 'color': Color(0xFFF59E0B)},
    {'value': 'achievement', 'label': 'Achievement', 'icon': Icons.emoji_events, 'color': Color(0xFFEAB308)},
    {'value': 'first_word', 'label': 'First Word', 'icon': Icons.chat_bubble, 'color': Color(0xFF06B6D4)},
    {'value': 'first_step', 'label': 'First Step', 'icon': Icons.directions_walk, 'color': Color(0xFF10B981)},
    {'value': 'other', 'label': 'Other', 'icon': Icons.star, 'color': Color(0xFF64748B)},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scrollController.addListener(_onScroll);
    _loadMilestones();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreMilestones();
      }
    }
  }

  Future<void> _loadMilestones() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 1;
      _milestones = [];
    });
    try {
      final milestones = await _familyService.getMilestones(
        page: _currentPage,
        pageSize: 20,
        milestoneType: _selectedType,
      );
      
      if (mounted) {
        setState(() {
          _milestones = milestones;
          _hasMore = milestones.length >= 20;
          _isLoading = false;
        });
        _animationController.forward();
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

  Future<void> _loadMoreMilestones() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final moreMilestones = await _familyService.getMilestones(
        page: nextPage,
        pageSize: 20,
        milestoneType: _selectedType,
      );
      
      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _milestones.addAll(moreMilestones);
          _hasMore = moreMilestones.length >= 20;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more: $e')),
        );
      }
    }
  }

  void _applySort(String sortOrder) {
    setState(() {
      _sortOrder = sortOrder;
      if (sortOrder == 'newest') {
        _milestones.sort((a, b) => b.milestoneDate.compareTo(a.milestoneDate));
      } else {
        _milestones.sort((a, b) => a.milestoneDate.compareTo(b.milestoneDate));
      }
    });
  }

  void _selectFilter(String? type) {
    if (_selectedType != type) {
      setState(() => _selectedType = type);
      _loadMilestones();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadMilestones,
        child: CustomScrollView(
          controller: _scrollController,
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  onSelected: _applySort,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'newest',
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 20,
                            color: _sortOrder == 'newest' ? Theme.of(context).primaryColor : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Newest First',
                            style: TextStyle(
                              fontWeight: _sortOrder == 'newest' ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'oldest',
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 20,
                            color: _sortOrder == 'oldest' ? Theme.of(context).primaryColor : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Oldest First',
                            style: TextStyle(
                              fontWeight: _sortOrder == 'oldest' ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterTypes.map((filter) {
                      final isSelected = _selectedType == filter['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                filter['icon'] as IconData,
                                size: 18,
                                color: isSelected ? Colors.white : filter['color'] as Color,
                              ),
                              const SizedBox(width: 6),
                              Text(filter['label'] as String),
                            ],
                          ),
                          backgroundColor: Colors.grey[100],
                          selectedColor: filter['color'] as Color,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => _selectFilter(filter['value'] as String?),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
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
                  message: _selectedType != null
                      ? 'No milestones found for this filter. Try a different one!'
                      : 'Start celebrating family achievements by adding your first milestone!',
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < _milestones.length) {
                        return _buildTimelineMilestoneCard(_milestones[index], index);
                      } else if (_isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                    childCount: _milestones.length + (_isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'family_milestones_fab',
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Milestone'),
        backgroundColor: const Color(0xFFF59E0B),
      ),
    );
  }

  Widget _buildTimelineMilestoneCard(FamilyMilestone milestone, int index) {
    final isFirst = index == 0;
    final isLast = index == _milestones.length - 1;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  if (!isFirst)
                    Expanded(
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getCategoryColor(milestone.category).withOpacity(0.3),
                              _getCategoryColor(milestone.category),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(milestone.category),
                          _getCategoryColor(milestone.category).withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryColor(milestone.category).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(milestone.category),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getCategoryColor(milestone.category),
                              index + 1 < _milestones.length
                                  ? _getCategoryColor(_milestones[index + 1].category).withOpacity(0.3)
                                  : _getCategoryColor(milestone.category).withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MilestoneDetailScreen(milestoneId: milestone.id),
                      ),
                    ).then((updated) {
                      if (updated == true) {
                        _loadMilestones();
                      }
                    });
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getCategoryColor(milestone.category).withOpacity(0.05),
                            Colors.white,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    milestone.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(milestone.category).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatType(milestone.category),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getCategoryColor(milestone.category),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('MMMM d, yyyy').format(milestone.milestoneDate),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            if (milestone.description != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                milestone.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (milestone.photoUrl != null) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  milestone.photoUrl!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 150,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, size: 40),
                                    );
                                  },
                                ),
                              ),
                            ],
                            if (milestone.genealogyPersonName != null || milestone.autoGenerated) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.indigo.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.account_tree, size: 14, color: Colors.indigo.shade700),
                                    const SizedBox(width: 6),
                                    if (milestone.genealogyPersonName != null)
                                      Text(
                                        milestone.genealogyPersonName!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo.shade800,
                                        ),
                                      ),
                                    if (milestone.autoGenerated) ...[
                                      if (milestone.genealogyPersonName != null) const SizedBox(width: 6),
                                      Icon(Icons.auto_awesome, size: 10, color: Colors.blue.shade700),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildInteractionChip(
                                  Icons.favorite,
                                  milestone.likesCount.toString(),
                                  const Color(0xFFEC4899),
                                ),
                                const SizedBox(width: 10),
                                _buildInteractionChip(
                                  Icons.comment,
                                  milestone.commentsCount.toString(),
                                  const Color(0xFF06B6D4),
                                ),
                                const Spacer(),
                                if (milestone.createdByName != null)
                                  Text(
                                    'by ${milestone.createdByName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionChip(IconData icon, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 12,
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
      case 'other':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
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
      case 'other':
        return Icons.star;
      default:
        return Icons.celebration;
    }
  }

  String _formatType(String type) {
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerBox(
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 200, height: 18, borderRadius: BorderRadius.circular(4)),
                        const SizedBox(height: 8),
                        ShimmerBox(width: 120, height: 13, borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ShimmerBox(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 4),
              ShimmerBox(width: 250, height: 14, borderRadius: BorderRadius.circular(4)),
            ],
          ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Milestone created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMilestones();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create milestone: $e')),
        );
      }
      rethrow;
    }
  }
}
