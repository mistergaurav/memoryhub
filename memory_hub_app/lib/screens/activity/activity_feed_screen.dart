import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/activity_feed_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import 'package:intl/intl.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final ActivityFeedService _activityFeedService = ActivityFeedService();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _activities = [];
  String? _error;
  
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreActivities();
      }
    }
  }

  Future<void> _loadActivities({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _activities.clear();
      });
    }
    
    setState(() => _isLoading = true);
    try {
      final data = await _activityFeedService.getActivityFeed(
        page: _currentPage,
        limit: 20,
      );
      
      setState(() {
        final activities = data['activities'] as List<dynamic>;
        
        if (refresh) {
          _activities = activities.cast<Map<String, dynamic>>();
        } else {
          _activities.addAll(activities.cast<Map<String, dynamic>>());
        }
        
        _hasMore = data['has_more'] ?? false;
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreActivities() async {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadActivities();
    setState(() => _isLoadingMore = false);
  }

  Future<void> _refresh() async {
    await _loadActivities(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Activity Feed',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filters - Coming soon')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _activities.isEmpty) {
      return _buildShimmerLoading();
    }
    
    if (_error != null && _activities.isEmpty) {
      return EnhancedEmptyState(
        icon: Icons.error_outline,
        title: 'Oops! Something went wrong',
        message: _error ?? 'Unable to load activity feed',
        actionLabel: 'Retry',
        onAction: _refresh,
      );
    }
    
    if (_activities.isEmpty && !_isLoading) {
      return EnhancedEmptyState(
        icon: Icons.feed_outlined,
        title: 'No activities yet',
        message: 'Follow users to see their updates and activities',
        actionLabel: 'Find Users',
        onAction: () {
          Navigator.pushNamed(context, '/social/user-search');
        },
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _activities.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final activity = _activities[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final type = activity['type'] ?? 'unknown';
    final isMemory = type == 'memory';
    final isHubItem = type == 'hub_item';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('View ${activity['title'] ?? 'activity'}')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActivityHeader(activity),
              const SizedBox(height: 12),
              _buildActivityDescription(activity, isMemory, isHubItem),
              const SizedBox(height: 12),
              _buildActivityContent(activity),
              if (activity['media_urls'] != null && (activity['media_urls'] as List).isNotEmpty)
                _buildMediaPreview(activity['media_urls']),
              const SizedBox(height: 12),
              _buildEngagementRow(activity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityHeader(Map<String, dynamic> activity) {
    final userName = activity['user_name'] ?? 'Unknown User';
    final userAvatar = activity['user_avatar'];
    final createdAt = activity['created_at'];
    
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          backgroundImage: userAvatar != null ? NetworkImage(userAvatar) : null,
          child: userAvatar == null
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (createdAt != null)
                Text(
                  _formatTimestamp(createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, size: 20),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('More options - Coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityDescription(Map<String, dynamic> activity, bool isMemory, bool isHubItem) {
    String description;
    IconData icon;
    Color iconColor;
    
    if (isMemory) {
      description = 'shared a new memory';
      icon = Icons.photo_library;
      iconColor = const Color(0xFF6366F1);
    } else if (isHubItem) {
      final itemType = activity['item_type'] ?? 'item';
      description = 'created a new $itemType';
      final typeConfig = _getHubItemTypeConfig(itemType);
      icon = typeConfig['icon'];
      iconColor = typeConfig['color'];
    } else {
      description = 'posted an update';
      icon = Icons.article;
      iconColor = Colors.grey;
    }
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
        ),
      ],
    );
  }

  Widget _buildActivityContent(Map<String, dynamic> activity) {
    final title = activity['title'] ?? '';
    final content = activity['content'] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            content.length > 200 ? '${content.substring(0, 200)}...' : content,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildMediaPreview(List<dynamic> mediaUrls) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: mediaUrls.isNotEmpty
              ? Image.network(
                  mediaUrls[0],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      ),
                    );
                  },
                )
              : Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image, size: 48, color: Colors.grey),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEngagementRow(Map<String, dynamic> activity) {
    final likeCount = activity['like_count'] ?? 0;
    final commentCount = activity['comment_count'] ?? 0;
    
    return Row(
      children: [
        _buildEngagementButton(
          icon: Icons.favorite_border,
          label: likeCount.toString(),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Like - Coming soon')),
            );
          },
        ),
        const SizedBox(width: 16),
        _buildEngagementButton(
          icon: Icons.comment_outlined,
          label: commentCount.toString(),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Comments - Coming soon')),
            );
          },
        ),
        const Spacer(),
        _buildEngagementButton(
          icon: Icons.share_outlined,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share - Coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getHubItemTypeConfig(String type) {
    switch (type) {
      case 'note':
        return {'icon': Icons.note, 'color': const Color(0xFF6366F1)};
      case 'link':
        return {'icon': Icons.link, 'color': const Color(0xFF10B981)};
      case 'task':
        return {'icon': Icons.task_alt, 'color': const Color(0xFFF59E0B)};
      case 'file':
        return {'icon': Icons.file_copy, 'color': const Color(0xFFEC4899)};
      default:
        return {'icon': Icons.article, 'color': const Color(0xFF6366F1)};
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime dateTime;
    
    if (timestamp is String) {
      dateTime = DateTime.parse(timestamp);
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown time';
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(dateTime);
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

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShimmerLoading(
            isLoading: true,
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const ShimmerBox(
                          width: 40,
                          height: 40,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(
                                height: 14,
                                width: 120,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 6),
                              ShimmerBox(
                                height: 12,
                                width: 80,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ShimmerBox(
                      height: 16,
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox(
                      height: 16,
                      width: 200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 16),
                    ShimmerBox(
                      height: 100,
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
