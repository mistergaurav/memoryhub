import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/hub_service.dart';
import '../../models/hub_item.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import 'package:intl/intl.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  final HubService _hubService = HubService();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoadingDashboard = true;
  bool _isLoadingItems = false;
  bool _isLoadingMore = false;
  bool _isDashboardExpanded = true;
  
  Map<String, dynamic>? _dashboardData;
  List<HubItem> _hubItems = [];
  String? _error;
  
  int _currentPage = 1;
  int _totalPages = 1;
  String _selectedFilter = 'all';
  
  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'value': 'all', 'icon': Icons.grid_view},
    {'label': 'Notes', 'value': 'note', 'icon': Icons.note},
    {'label': 'Links', 'value': 'link', 'icon': Icons.link},
    {'label': 'Tasks', 'value': 'task', 'icon': Icons.task_alt},
    {'label': 'Files', 'value': 'file', 'icon': Icons.file_copy},
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadHubItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _currentPage < _totalPages) {
        _loadMoreItems();
      }
    }
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoadingDashboard = true);
    try {
      final data = await _hubService.getDashboard();
      setState(() {
        _dashboardData = data;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoadingDashboard = false);
    }
  }

  Future<void> _loadHubItems({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hubItems.clear();
      });
    }
    
    setState(() => _isLoadingItems = true);
    try {
      final data = await _hubService.getHubItems(
        page: _currentPage,
        pageSize: 20,
        itemType: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      
      setState(() {
        final items = (data['items'] as List<dynamic>)
            .map((json) => HubItem.fromJson(json))
            .toList();
        
        if (refresh) {
          _hubItems = items;
        } else {
          _hubItems.addAll(items);
        }
        
        _totalPages = data['total_pages'] ?? 1;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final nextPage = _currentPage + 1;
      final data = await _hubService.getHubItems(
        page: nextPage,
        pageSize: 20,
        itemType: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      
      setState(() {
        final items = (data['items'] as List<dynamic>)
            .map((json) => HubItem.fromJson(json))
            .toList();
        _hubItems.addAll(items);
        _currentPage = nextPage;
        _totalPages = data['total_pages'] ?? 1;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more items: $e')),
        );
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadDashboard(),
      _loadHubItems(refresh: true),
    ]);
  }

  Future<void> _toggleLike(HubItem item) async {
    final originalLikeStatus = item.isLiked;
    final originalLikeCount = item.likeCount;
    
    setState(() {
      final index = _hubItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _hubItems[index] = HubItem(
          id: item.id,
          title: item.title,
          description: item.description,
          itemType: item.itemType,
          content: item.content,
          tags: item.tags,
          privacy: item.privacy,
          isPinned: item.isPinned,
          ownerId: item.ownerId,
          ownerName: item.ownerName,
          ownerAvatar: item.ownerAvatar,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          viewCount: item.viewCount,
          likeCount: originalLikeStatus ? originalLikeCount - 1 : originalLikeCount + 1,
          commentCount: item.commentCount,
          isLiked: !originalLikeStatus,
          isBookmarked: item.isBookmarked,
        );
      }
    });

    try {
      await _hubService.toggleLike(item.id, originalLikeStatus);
    } catch (e) {
      setState(() {
        final index = _hubItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _hubItems[index] = HubItem(
            id: item.id,
            title: item.title,
            description: item.description,
            itemType: item.itemType,
            content: item.content,
            tags: item.tags,
            privacy: item.privacy,
            isPinned: item.isPinned,
            ownerId: item.ownerId,
            ownerName: item.ownerName,
            ownerAvatar: item.ownerAvatar,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            viewCount: item.viewCount,
            likeCount: originalLikeCount,
            commentCount: item.commentCount,
            isLiked: originalLikeStatus,
            isBookmarked: item.isBookmarked,
          );
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${originalLikeStatus ? 'unlike' : 'like'} item')),
        );
      }
    }
  }

  Future<void> _toggleBookmark(HubItem item) async {
    final originalBookmarkStatus = item.isBookmarked;
    
    setState(() {
      final index = _hubItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _hubItems[index] = HubItem(
          id: item.id,
          title: item.title,
          description: item.description,
          itemType: item.itemType,
          content: item.content,
          tags: item.tags,
          privacy: item.privacy,
          isPinned: item.isPinned,
          ownerId: item.ownerId,
          ownerName: item.ownerName,
          ownerAvatar: item.ownerAvatar,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          viewCount: item.viewCount,
          likeCount: item.likeCount,
          commentCount: item.commentCount,
          isLiked: item.isLiked,
          isBookmarked: !originalBookmarkStatus,
        );
      }
    });

    try {
      await _hubService.toggleBookmark(item.id, originalBookmarkStatus);
    } catch (e) {
      setState(() {
        final index = _hubItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _hubItems[index] = HubItem(
            id: item.id,
            title: item.title,
            description: item.description,
            itemType: item.itemType,
            content: item.content,
            tags: item.tags,
            privacy: item.privacy,
            isPinned: item.isPinned,
            ownerId: item.ownerId,
            ownerName: item.ownerName,
            ownerAvatar: item.ownerAvatar,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            viewCount: item.viewCount,
            likeCount: item.likeCount,
            commentCount: item.commentCount,
            isLiked: item.isLiked,
            isBookmarked: originalBookmarkStatus,
          );
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${originalBookmarkStatus ? 'unbookmark' : 'bookmark'} item')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hub',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // TODO: Navigate to create hub item screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create hub item - Coming soon')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (_isLoadingDashboard)
              _buildDashboardShimmer()
            else if (_dashboardData != null)
              _buildDashboard(),
            
            _buildQuickActions(),
            _buildFilterChips(),
            
            if (_isLoadingItems && _hubItems.isEmpty)
              _buildItemsShimmer()
            else if (_hubItems.isEmpty && !_isLoadingItems)
              _buildEmptyState()
            else
              _buildHubItemsList(),
            
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final stats = _dashboardData?['stats'] ?? {};
    final totalItems = stats['total_items'] ?? 0;
    final totalLikes = stats['total_likes'] ?? 0;
    final totalViews = stats['total_views'] ?? 0;
    
    final itemsByType = stats['items_by_type'] as Map<String, dynamic>? ?? {};
    final bookmarkCount = itemsByType.values.fold<int>(0, (sum, val) => sum + (val as int? ?? 0)) ~/ 4;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(_isDashboardExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() => _isDashboardExpanded = !_isDashboardExpanded);
                  },
                ),
              ],
            ),
          ),
          if (_isDashboardExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Total Items',
                    totalItems.toString(),
                    Icons.widgets,
                    const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  _buildStatCard(
                    'Likes',
                    totalLikes.toString(),
                    Icons.favorite,
                    const [Color(0xFF10B981), Color(0xFF14B8A6)],
                  ),
                  _buildStatCard(
                    'Bookmarks',
                    bookmarkCount.toString(),
                    Icons.bookmark,
                    const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  _buildStatCard(
                    'Views',
                    totalViews.toString(),
                    Icons.visibility,
                    const [Color(0xFF6366F1), Color(0xFFEC4899)],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'label': 'Create Note', 'icon': Icons.note_add, 'colors': [Color(0xFF6366F1), Color(0xFF8B5CF6)]},
      {'label': 'Create Link', 'icon': Icons.link, 'colors': [Color(0xFF10B981), Color(0xFF14B8A6)]},
      {'label': 'Create Task', 'icon': Icons.add_task, 'colors': [Color(0xFFF59E0B), Color(0xFFEF4444)]},
      {'label': 'Upload File', 'icon': Icons.upload_file, 'colors': [Color(0xFFEC4899), Color(0xFF8B5CF6)]},
    ];

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final action = actions[index];
                final colors = action['colors'] as List<Color>;
                return _buildQuickActionChip(
                  action['label'] as String,
                  action['icon'] as IconData,
                  colors,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon, List<Color> colors) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label - Coming soon')),
        );
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Filter',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter['value'];
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(filter['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter['value'] as String;
                      _currentPage = 1;
                      _hubItems.clear();
                    });
                    _loadHubItems();
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHubItemsList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _hubItems[index];
            return _buildHubItemCard(item);
          },
          childCount: _hubItems.length,
        ),
      ),
    );
  }

  Widget _buildHubItemCard(HubItem item) {
    final typeConfig = _getTypeConfig(item.itemType);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('View ${item.title}')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeConfig['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      typeConfig['icon'],
                      color: typeConfig['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (item.description != null && item.description!.isNotEmpty)
                          Text(
                            item.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(item.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const Spacer(),
                  _buildActionButton(
                    icon: item.isLiked ? Icons.favorite : Icons.favorite_border,
                    label: item.likeCount.toString(),
                    color: item.isLiked ? Colors.red : Colors.grey[600],
                    onTap: () => _toggleLike(item),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: item.isBookmarked ? Colors.blue : Colors.grey[600],
                    onTap: () => _toggleBookmark(item),
                  ),
                ],
              ),
              if (item.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    String? label,
    required Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeConfig(String type) {
    switch (type) {
      case 'note':
        return {'icon': Icons.note, 'color': Color(0xFF6366F1)};
      case 'link':
        return {'icon': Icons.link, 'color': Color(0xFF10B981)};
      case 'task':
        return {'icon': Icons.task_alt, 'color': Color(0xFFF59E0B)};
      case 'file':
        return {'icon': Icons.file_copy, 'color': Color(0xFFEC4899)};
      default:
        return {'icon': Icons.article, 'color': Color(0xFF6366F1)};
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildDashboardShimmer() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: List.generate(
            4,
            (index) => ShimmerLoading(
              isLoading: true,
              child: ShimmerBox(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerLoading(
              isLoading: true,
              child: ShimmerBox(
                height: 120,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          childCount: 5,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: EnhancedEmptyState(
        icon: Icons.inbox,
        title: 'No hub items yet',
        message: 'Create your first hub item to get started',
        actionLabel: 'Create Item',
        onAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create hub item - Coming soon')),
          );
        },
      ),
    );
  }
}
