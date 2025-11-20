import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_milestone.dart';
import '../../models/family/paginated_response.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/add_milestone_dialog.dart';
import 'milestone_detail_screen.dart';
import 'family_timeline_screen.dart';
import 'package:intl/intl.dart';
import '../../design_system/design_tokens.dart';

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
    {'value': null, 'label': 'All', 'icon': Icons.apps, 'color': MemoryHubColors.indigo500},
    {'value': 'birth', 'label': 'Birth', 'icon': Icons.child_care, 'color': MemoryHubColors.pink500},
    {'value': 'graduation', 'label': 'Graduation', 'icon': Icons.school, 'color': MemoryHubColors.purple500},
    {'value': 'wedding', 'label': 'Wedding', 'icon': Icons.favorite, 'color': MemoryHubColors.red500},
    {'value': 'anniversary', 'label': 'Anniversary', 'icon': Icons.cake, 'color': MemoryHubColors.amber500},
    {'value': 'achievement', 'label': 'Achievement', 'icon': Icons.emoji_events, 'color': MemoryHubColors.yellow500},
    {'value': 'first_words', 'label': 'First Words', 'icon': Icons.chat_bubble, 'color': MemoryHubColors.cyan500},
    {'value': 'first_steps', 'label': 'First Steps', 'icon': Icons.directions_walk, 'color': MemoryHubColors.green500},
    {'value': 'other', 'label': 'Other', 'icon': Icons.star, 'color': MemoryHubColors.gray600},
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
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 1;
      _milestones = [];
    });
    
    try {
      final response = await _familyService.getMilestones(
        page: _currentPage,
        pageSize: 20,
        milestoneType: _selectedType,
      );
      
      if (!mounted) return;
      
      setState(() {
        _milestones = response.items;
        _hasMore = response.hasMore;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMilestones() async {
    if (_isLoadingMore || !_hasMore || !mounted) return;

    setState(() => _isLoadingMore = true);
    
    try {
      final nextPage = _currentPage + 1;
      final response = await _familyService.getMilestones(
        page: nextPage,
        pageSize: 20,
        milestoneType: _selectedType,
      );
      
      if (!mounted) return;
      
      setState(() {
        _currentPage = nextPage;
        _milestones.addAll(response.items);
        _hasMore = response.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more: $e')),
      );
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

  void _clearFilters() {
    if (_selectedType != null) {
      setState(() => _selectedType = null);
      _loadMilestones();
    }
  }

  String _getYearsAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final years = (difference.inDays / 365).floor();
    final months = ((difference.inDays % 365) / 30).floor();
    
    if (years > 0) {
      return years == 1 ? '1 year ago' : '$years years ago';
    } else if (months > 0) {
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final days = difference.inDays;
      if (days == 0) return 'Today';
      if (days == 1) return 'Yesterday';
      return '$days days ago';
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
                        Colors.orange,
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
                          color: context.colors.surface.withValues(alpha: 0.1),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 80,
                        child: Icon(
                          Icons.star,
                          size: 40,
                          color: context.colors.surface.withValues(alpha: 0.3),
                        ),
                      ),
                      Positioned(
                        right: 60,
                        top: 100,
                        child: Icon(
                          Icons.star,
                          size: 25,
                          color: context.colors.surface.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (_selectedType != null)
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Clear Filters',
                    onPressed: _clearFilters,
                  ),
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
                          const HGap.xs(),
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
                          const HGap.xs(),
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
                                color: isSelected ? context.colors.surface : filter['color'] as Color,
                              ),
                              const HGap.xxs(),
                              Text(filter['label'] as String),
                            ],
                          ),
                          backgroundColor: Colors.grey[100],
                          selectedColor: filter['color'] as Color,
                          labelStyle: TextStyle(
                            color: isSelected ? context.colors.surface : Colors.grey[800],
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
                    Colors.orange,
                    Color(0xFFFBBF24),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < _milestones.length) {
                        return _buildEnhancedMilestoneCard(_milestones[index], index);
                      } else if (_isLoadingMore) {
                        return Padding(
                          padding: const EdgeInsets.all(MemoryHubSpacing.md),
                          child: Center(
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                const VGap.xs(),
                                Text(
                                  'Loading more milestones...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildEnhancedMilestoneCard(FamilyMilestone milestone, int index) {
    final isFirst = index == 0;
    final isLast = index == _milestones.length - 1;
    final yearsAgo = _getYearsAgo(milestone.milestoneDate);
    
    // Get photo list (handle both photoUrl and photos array)
    final List<String> photos = [];
    if (milestone.photoUrl != null && milestone.photoUrl!.isNotEmpty) {
      photos.add(milestone.photoUrl!);
    }

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
                              _getCategoryColor(milestone.category).withValues(alpha: 0.3),
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
                          _getCategoryColor(milestone.category).withValues(alpha: 0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryColor(milestone.category).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(milestone.category),
                      color: context.colors.surface,
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
                                  ? _getCategoryColor(_milestones[index + 1].category).withValues(alpha: 0.3)
                                  : _getCategoryColor(milestone.category).withValues(alpha: 0.3),
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
                  onTap: () => _navigateToDetail(milestone.id),
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
                            _getCategoryColor(milestone.category).withValues(alpha: 0.05),
                            context.colors.surface,
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
                                    color: _getCategoryColor(milestone.category).withValues(alpha: 0.15),
                                    borderRadius: Radii.mdRadius,
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
                            const VGap.xs(),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const HGap.xxs(),
                                Text(
                                  DateFormat('MMMM d, yyyy').format(milestone.milestoneDate),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const HGap.xs(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    yearsAgo,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (milestone.genealogyPersonName != null) ...[
                              const VGap.xs(),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 14, color: Colors.indigo),
                                  const HGap.xxs(),
                                  Text(
                                    milestone.genealogyPersonName!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  if (milestone.autoGenerated) ...[
                                    const HGap.xxs(),
                                    Icon(Icons.auto_awesome, size: 12, color: Colors.amber.shade700),
                                  ],
                                ],
                              ),
                            ],
                            if (milestone.description != null) ...[
                              const VGap.sm(),
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
                            if (photos.isNotEmpty) ...[
                              const VGap.sm(),
                              if (photos.length == 1)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    photos[0],
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
                                )
                              else
                                CarouselSlider(
                                  options: CarouselOptions(
                                    height: 150,
                                    viewportFraction: 0.9,
                                    enableInfiniteScroll: false,
                                    enlargeCenterPage: true,
                                  ),
                                  items: photos.map((photoUrl) {
                                    return Builder(
                                      builder: (BuildContext context) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            photoUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.broken_image, size: 40),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                            ],
                            if (milestone.celebrationDetails != null) ...[
                              const VGap.xs(),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.purple.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.party_mode, size: 16, color: Colors.purple.shade700),
                                    const HGap.xs(),
                                    Expanded(
                                      child: Text(
                                        'Celebration Details Available',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.purple.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const VGap.sm(),
                            Row(
                              children: [
                                _buildInteractionChip(
                                  Icons.favorite,
                                  milestone.likesCount.toString(),
                                  Theme.of(context).colorScheme.secondary,
                                ),
                                const HGap.xs(),
                                _buildInteractionChip(
                                  Icons.comment,
                                  milestone.commentsCount.toString(),
                                  Colors.blue,
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
                            const VGap.xs(),
                            Divider(color: Colors.grey[300]),
                            const VGap.xxs(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _navigateToTimeline(milestone),
                                  icon: const Icon(Icons.timeline, size: 16),
                                  label: const Text(
                                    'View in Timeline',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.amber.shade700,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: Radii.mdRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const HGap.xxs(),
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
        return Theme.of(context).colorScheme.secondary;
      case 'graduation':
        return context.colors.primary;
      case 'wedding':
        return context.colors.error;
      case 'anniversary':
        return Colors.orange;
      case 'achievement':
        return const Color(0xFFEAB308);
      case 'first_words':
      case 'first_word':
        return Colors.blue;
      case 'first_steps':
      case 'first_step':
        return Colors.green;
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
      case 'first_words':
      case 'first_word':
        return Icons.chat_bubble;
      case 'first_steps':
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
                  const HGap.sm(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 200, height: 18, borderRadius: BorderRadius.circular(4)),
                        const VGap.xs(),
                        ShimmerBox(width: 120, height: 13, borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
                  ),
                ],
              ),
              const VGap.sm(),
              ShimmerBox(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(4)),
              const VGap.xxs(),
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

  void _navigateToDetail(String milestoneId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MilestoneDetailScreen(milestoneId: milestoneId),
      ),
    ).then((updated) {
      if (updated == true && mounted) {
        _loadMilestones();
      }
    });
  }

  void _navigateToTimeline(FamilyMilestone milestone) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FamilyTimelineScreen(),
      ),
    );
  }
}
