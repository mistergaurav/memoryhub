import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_timeline.dart';
import '../../models/family/paginated_response.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/add_event_dialog.dart';
import '../../design_system/design_tokens.dart';
import 'package:intl/intl.dart';
import 'timeline_event_detail_screen.dart';
import 'family_albums_screen.dart';
import 'family_calendar_screen.dart';
import 'family_milestones_screen.dart';
import 'family_recipes_screen.dart';
import 'family_traditions_screen.dart';

class FamilyTimelineScreen extends StatefulWidget {
  const FamilyTimelineScreen({Key? key}) : super(key: key);

  @override
  State<FamilyTimelineScreen> createState() => _FamilyTimelineScreenState();
}

class _FamilyTimelineScreenState extends State<FamilyTimelineScreen> with TickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  final ScrollController _scrollController = ScrollController();
  List<TimelineEvent> _events = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  String _selectedFilter = 'all';
  int _currentPage = 1;
  bool _hasMoreData = true;
  int _totalCount = 0;

  final Map<String, List<TimelineEvent>> _groupedEvents = {};
  final List<String> _sectionOrder = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreEvents();
      }
    }
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 1;
      _hasMoreData = true;
    });
    
    try {
      final response = await _familyService.getTimelineEvents(
        filter: _selectedFilter != 'all' ? _selectedFilter : null,
        page: 1,
        pageSize: 20,
      );
      
      if (!mounted) return;
      
      setState(() {
        _events = response.items;
        _totalCount = response.total;
        _hasMoreData = response.hasMore;
        _isLoading = false;
        _groupEventsByDate();
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreEvents() async {
    if (_isLoadingMore || !_hasMoreData || !mounted) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final response = await _familyService.getTimelineEvents(
        filter: _selectedFilter != 'all' ? _selectedFilter : null,
        page: _currentPage,
        pageSize: 20,
      );
      
      if (!mounted) return;
      
      setState(() {
        _events.addAll(response.items);
        _totalCount = response.total;
        _hasMoreData = response.hasMore;
        _isLoadingMore = false;
        _groupEventsByDate();
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });
    }
  }

  void _groupEventsByDate() {
    _groupedEvents.clear();
    _sectionOrder.clear();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: now.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    
    for (final event in _events) {
      final eventDate = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );
      
      String section;
      if (eventDate == today) {
        section = 'Today';
      } else if (eventDate == yesterday) {
        section = 'Yesterday';
      } else if (eventDate.isAfter(thisWeekStart) && eventDate.isBefore(today)) {
        section = 'This Week';
      } else if (eventDate.isAfter(thisMonthStart) && eventDate.isBefore(today)) {
        section = 'This Month';
      } else {
        section = 'Older';
      }
      
      if (!_groupedEvents.containsKey(section)) {
        _groupedEvents[section] = [];
        _sectionOrder.add(section);
      }
      _groupedEvents[section]!.add(event);
    }
    
    final preferredOrder = ['Today', 'Yesterday', 'This Week', 'This Month', 'Older'];
    _sectionOrder.sort((a, b) {
      final aIndex = preferredOrder.indexOf(a);
      final bIndex = preferredOrder.indexOf(b);
      return aIndex.compareTo(bIndex);
    });
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Family Timeline',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                        Color(0xFFA855F7),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          Icons.auto_stories,
                          size: 140,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      if (_totalCount > 0)
                        Positioned(
                          left: 16,
                          bottom: 60,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: Radii.xlRadius,
                            ),
                            child: Text(
                              '$_totalCount ${_totalCount == 1 ? 'Event' : 'Events'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter timeline events',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: MemoryHubSpacing.md),
                child: _buildFilterChips(),
              ),
            ),
            if (_isLoading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: _buildShimmerItem(),
                  ),
                  childCount: 5,
                ),
              )
            else if (_error.isNotEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Timeline',
                  message: 'Failed to load timeline events. Pull to retry.',
                  actionLabel: 'Retry',
                  onAction: _loadEvents,
                  gradientColors: const [
                    MemoryHubColors.red500,
                    MemoryHubColors.red400,
                  ],
                ),
              )
            else if (_events.isEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.auto_stories,
                  title: 'No Events Yet',
                  message: 'Start documenting your family journey by adding timeline events.',
                  actionLabel: 'Add Event',
                  onAction: _showAddEventDialog,
                  gradientColors: const [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                  ],
                ),
              )
            else
              ..._buildGroupedTimelineSections(),
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(MemoryHubSpacing.xl),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(height: MemoryHubSpacing.md),
                        Text(
                          'Loading more events...',
                          style: TextStyle(
                            fontSize: MemoryHubTypography.bodySmall,
                            color: MemoryHubColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_hasMoreData && _events.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(MemoryHubSpacing.xl),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: MemoryHubColors.gray400,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All events loaded',
                          style: TextStyle(
                            fontSize: MemoryHubTypography.bodySmall,
                            color: MemoryHubColors.gray500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'family_timeline_fab',
        onPressed: _showAddEventDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
    );
  }

  List<Widget> _buildGroupedTimelineSections() {
    final List<Widget> sections = [];
    
    for (int sectionIndex = 0; sectionIndex < _sectionOrder.length; sectionIndex++) {
      final sectionName = _sectionOrder[sectionIndex];
      final sectionEvents = _groupedEvents[sectionName]!;
      
      sections.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    sectionName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: Radii.mdRadius,
                  ),
                  child: Text(
                    '${sectionEvents.length}',
                    style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      sections.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final event = sectionEvents[index];
              final isLast = index == sectionEvents.length - 1 && sectionIndex == _sectionOrder.length - 1;
              return _buildTimelineItem(event, isLast);
            },
            childCount: sectionEvents.length,
          ),
        ),
      );
    }
    
    return sections;
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'value': 'all', 'icon': Icons.all_inclusive},
      {'label': 'Albums', 'value': 'album', 'icon': Icons.photo_library},
      {'label': 'Events', 'value': 'event', 'icon': Icons.event},
      {'label': 'Milestones', 'value': 'milestone', 'icon': Icons.celebration},
      {'label': 'Recipes', 'value': 'recipe', 'icon': Icons.restaurant_menu},
      {'label': 'Traditions', 'value': 'tradition', 'icon': Icons.local_florist},
      {'label': 'Memories', 'value': 'memory', 'icon': Icons.photo_album},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['value'];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? MemoryHubSpacing.lg : 0,
              right: MemoryHubSpacing.sm,
            ),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 4),
                  Text(filter['label'] as String),
                ],
              ),
              selectedColor: const Color(0xFF8B5CF6),
              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF8B5CF6),
                fontWeight: isSelected ? MemoryHubTypography.semiBold : MemoryHubTypography.regular,
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['value'] as String;
                });
                _loadEvents();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(TimelineEvent event, bool isLast) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _getGradientColors(event.eventType),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getGradientColors(event.eventType)[0].withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getEventIcon(event.eventType),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 3,
                    height: 80,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getGradientColors(event.eventType)[0],
                          const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                elevation: MemoryHubElevation.md,
                shape: RoundedRectangleBorder(
                  borderRadius: MemoryHubBorderRadius.xlRadius,
                  side: BorderSide(
                    color: _getGradientColors(event.eventType)[0].withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => _navigateToDetail(event),
                  borderRadius: MemoryHubBorderRadius.xlRadius,
                  child: Padding(
                    padding: const EdgeInsets.all(MemoryHubSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: MemoryHubTypography.h4,
                                      fontWeight: MemoryHubTypography.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getRelativeTime(event.createdAt),
                                    style: TextStyle(
                                      fontSize: MemoryHubTypography.caption,
                                      color: MemoryHubColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: MemoryHubSpacing.sm,
                                vertical: MemoryHubSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _getGradientColors(event.eventType),
                                ),
                                borderRadius: MemoryHubBorderRadius.mdRadius,
                              ),
                              child: Text(
                                DateFormat('MMM d').format(event.eventDate),
                                style: const TextStyle(
                                  fontSize: MemoryHubTypography.caption,
                                  color: Colors.white,
                                  fontWeight: MemoryHubTypography.semiBold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (event.description != null && event.description!.isNotEmpty) ...[
                          const SizedBox(height: MemoryHubSpacing.sm),
                          Text(
                            event.description!,
                            style: TextStyle(
                              fontSize: MemoryHubTypography.bodyMedium,
                              color: MemoryHubColors.gray700,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (event.photoUrl != null) ...[
                          const SizedBox(height: MemoryHubSpacing.md),
                          ClipRRect(
                            borderRadius: MemoryHubBorderRadius.mdRadius,
                            child: Image.network(
                              event.photoUrl!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: MemoryHubColors.gray200,
                                    borderRadius: MemoryHubBorderRadius.mdRadius,
                                  ),
                                  child: Icon(
                                    Icons.broken_image,
                                    color: MemoryHubColors.gray400,
                                    size: 48,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        _buildRelatedContentTags(event),
                        const SizedBox(height: MemoryHubSpacing.md),
                        Row(
                          children: [
                            _buildReactionButton(event),
                            const SizedBox(width: MemoryHubSpacing.md),
                            _buildCommentButton(event),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: MemoryHubColors.gray400,
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildRelatedContentTags(TimelineEvent event) {
    final tags = <Map<String, dynamic>>[];
    
    final type = event.eventType.toLowerCase();
    if (type.contains('milestone') || type.contains('achievement')) {
      tags.add({'icon': Icons.celebration, 'label': 'Milestone', 'color': const Color(0xFFF59E0B)});
    }
    if (type.contains('album') || type.contains('photo')) {
      tags.add({'icon': Icons.photo_library, 'label': 'Album', 'color': const Color(0xFF8B5CF6)});
    }
    if (type.contains('recipe') || type.contains('food')) {
      tags.add({'icon': Icons.restaurant_menu, 'label': 'Recipe', 'color': const Color(0xFFEF4444)});
    }
    if (type.contains('event') || type.contains('calendar')) {
      tags.add({'icon': Icons.event, 'label': 'Event', 'color': const Color(0xFF06B6D4)});
    }
    if (type.contains('tradition')) {
      tags.add({'icon': Icons.local_florist, 'label': 'Tradition', 'color': const Color(0xFF14B8A6)});
    }
    
    if (tags.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: MemoryHubSpacing.md),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: (tag['color'] as Color).withValues(alpha: 0.1),
              borderRadius: Radii.mdRadius,
              border: Border.all(
                color: (tag['color'] as Color).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tag['icon'] as IconData,
                  size: 14,
                  color: tag['color'] as Color,
                ),
                const SizedBox(width: 4),
                Text(
                  tag['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: tag['color'] as Color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReactionButton(TimelineEvent event) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❤️ Reacted to "${event.title}"'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEC4899),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEC4899).withValues(alpha: 0.1),
          borderRadius: Radii.xlRadius,
          border: Border.all(
            color: const Color(0xFFEC4899).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite,
              size: 16,
              color: Color(0xFFEC4899),
            ),
            const SizedBox(width: 4),
            Text(
              event.likesCount > 0 ? '${event.likesCount}' : 'Like',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFEC4899),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentButton(TimelineEvent event) {
    return InkWell(
      onTap: () => _navigateToDetail(event),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
          borderRadius: Radii.xlRadius,
          border: Border.all(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: Color(0xFF06B6D4),
            ),
            const SizedBox(width: 4),
            Text(
              event.commentsCount > 0 ? '${event.commentsCount}' : 'Comment',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF06B6D4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(TimelineEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimelineEventDetailScreen(
          event: event,
          onEventUpdated: _loadEvents,
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String eventType) {
    final type = eventType.toLowerCase();
    switch (type) {
      case 'album':
      case 'photo':
        return [const Color(0xFF8B5CF6), const Color(0xFFA855F7)];
      case 'event':
      case 'calendar':
        return [const Color(0xFF06B6D4), const Color(0xFF22D3EE)];
      case 'milestone':
      case 'achievement':
        return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case 'recipe':
      case 'food':
        return [const Color(0xFFEF4444), const Color(0xFFF87171)];
      case 'tradition':
        return [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)];
      case 'memory':
        return [const Color(0xFFEC4899), const Color(0xFFF472B6)];
      case 'birthday':
        return [const Color(0xFFEC4899), const Color(0xFFF472B6)];
      case 'anniversary':
        return [const Color(0xFF8B5CF6), const Color(0xFFEC4899)];
      case 'trip':
      case 'travel':
        return [const Color(0xFF06B6D4), const Color(0xFF14B8A6)];
      default:
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
    }
  }

  IconData _getEventIcon(String eventType) {
    final type = eventType.toLowerCase();
    switch (type) {
      case 'album':
      case 'photo':
        return Icons.photo_library;
      case 'event':
      case 'calendar':
        return Icons.event;
      case 'milestone':
        return Icons.celebration;
      case 'achievement':
        return Icons.emoji_events;
      case 'recipe':
      case 'food':
        return Icons.restaurant_menu;
      case 'tradition':
        return Icons.local_florist;
      case 'memory':
        return Icons.photo_album;
      case 'birthday':
        return Icons.cake;
      case 'anniversary':
        return Icons.favorite;
      case 'trip':
      case 'travel':
        return Icons.flight;
      case 'health':
        return Icons.health_and_safety;
      default:
        return Icons.auto_stories;
    }
  }

  Widget _buildShimmerItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(
          width: 56,
          height: 56,
          borderRadius: BorderRadius.circular(28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(width: 150, height: 20, borderRadius: BorderRadius.circular(4)),
                      ShimmerBox(width: 60, height: 24, borderRadius: BorderRadius.circular(12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ShimmerBox(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 6),
                  ShimmerBox(width: 200, height: 14, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 12),
                  ShimmerBox(width: double.infinity, height: 120, borderRadius: BorderRadius.circular(8)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.filter_list, color: Color(0xFF8B5CF6)),
            SizedBox(width: 12),
            Text('Filter Events'),
          ],
        ),
        content: const Text('Use the filter chips above to filter events by type.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        onSubmit: _handleAddEvent,
      ),
    );
  }

  Future<void> _handleAddEvent(Map<String, dynamic> data) async {
    try {
      await _familyService.createCalendarEvent(data);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event added to timeline successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadEvents();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add event: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
