import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_timeline.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/add_event_dialog.dart';
import '../../design_system/design_tokens.dart';
import 'package:intl/intl.dart';
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

class _FamilyTimelineScreenState extends State<FamilyTimelineScreen> {
  final FamilyService _familyService = FamilyService();
  final ScrollController _scrollController = ScrollController();
  List<TimelineEvent> _events = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  String _selectedFilter = 'all';
  int _currentPage = 1;
  bool _hasMoreData = true;

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreEvents();
      }
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 1;
      _hasMoreData = true;
    });
    try {
      final events = await _familyService.getTimelineEvents(
        filter: _selectedFilter != 'all' ? _selectedFilter : null,
      );
      setState(() {
        _events = events;
        _isLoading = false;
        _hasMoreData = events.length >= 20;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreEvents() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final newEvents = await _familyService.getTimelineEvents(
        filter: _selectedFilter != 'all' ? _selectedFilter : null,
      );
      setState(() {
        if (newEvents.isEmpty) {
          _hasMoreData = false;
        } else {
          _events.addAll(newEvents);
          _hasMoreData = newEvents.length >= 20;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });
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
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MemoryHubColors.pink500,
                        MemoryHubColors.pink400,
                        MemoryHubColors.amber400,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          Icons.timeline,
                          size: 120,
                          color: Colors.white.withOpacity(0.1),
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
                  icon: Icons.timeline,
                  title: 'No Events Yet',
                  message: 'Start documenting your family journey by adding timeline events.',
                  actionLabel: 'Add Event',
                  onAction: _showAddEventDialog,
                  gradientColors: const [
                    MemoryHubColors.pink500,
                    MemoryHubColors.pink400,
                  ],
                ),
              )
            else ...[
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTimelineItem(_events[index], index),
                  childCount: _events.length,
                ),
              ),
              if (_isLoadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(MemoryHubSpacing.xl),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              MemoryHubColors.pink500,
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
                      child: Text(
                        'All events loaded',
                        style: TextStyle(
                          fontSize: MemoryHubTypography.bodySmall,
                          color: MemoryHubColors.gray500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'family_timeline_fab',
        onPressed: _showAddEventDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
        backgroundColor: MemoryHubColors.pink500,
      ),
    );
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
                    color: isSelected ? Colors.white : MemoryHubColors.gray700,
                  ),
                  const SizedBox(width: 4),
                  Text(filter['label'] as String),
                ],
              ),
              selectedColor: MemoryHubColors.pink500,
              backgroundColor: MemoryHubColors.gray200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : MemoryHubColors.gray700,
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

  Widget _buildTimelineItem(TimelineEvent event, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _getGradientColors(event.eventType),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getGradientColors(event.eventType)[0].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _getEventIcon(event.eventType),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              if (index < _events.length - 1)
                Container(
                  width: 2,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _getGradientColors(event.eventType)[0],
                        MemoryHubColors.gray300,
                      ],
                    ),
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
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: MemoryHubTypography.h4,
                                fontWeight: MemoryHubTypography.bold,
                              ),
                            ),
                          ),
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
                      if (event.description != null) ...[
                        const SizedBox(height: MemoryHubSpacing.sm),
                        Text(
                          event.description!,
                          style: TextStyle(
                            fontSize: MemoryHubTypography.bodyMedium,
                            color: MemoryHubColors.gray700,
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
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
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
                      const SizedBox(height: MemoryHubSpacing.md),
                      Row(
                        children: [
                          _buildInteractionButton(
                            Icons.favorite_border,
                            event.likesCount.toString(),
                            MemoryHubColors.pink500,
                          ),
                          const SizedBox(width: MemoryHubSpacing.lg),
                          _buildInteractionButton(
                            Icons.comment_outlined,
                            event.commentsCount.toString(),
                            MemoryHubColors.cyan500,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
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
    );
  }

  void _navigateToDetail(TimelineEvent event) {
    Widget? targetScreen;

    switch (event.eventType.toLowerCase()) {
      case 'album':
        targetScreen = const FamilyAlbumsScreen();
        break;
      case 'event':
      case 'birthday':
      case 'anniversary':
        targetScreen = const FamilyCalendarScreen();
        break;
      case 'milestone':
      case 'achievement':
        targetScreen = const FamilyMilestonesScreen();
        break;
      case 'recipe':
        targetScreen = const FamilyRecipesScreen();
        break;
      case 'tradition':
        targetScreen = const FamilyTraditionsScreen();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('View ${event.title}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen!),
    );
  }

  Widget _buildInteractionButton(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<Color> _getGradientColors(String eventType) {
    final type = eventType.toLowerCase();
    switch (type) {
      case 'album':
        return [MemoryHubColors.purple600, MemoryHubColors.purple400];
      case 'event':
      case 'calendar':
        return [MemoryHubColors.cyan500, MemoryHubColors.cyan400];
      case 'milestone':
      case 'achievement':
        return [MemoryHubColors.amber500, MemoryHubColors.amber400];
      case 'recipe':
        return [MemoryHubColors.red500, MemoryHubColors.red400];
      case 'tradition':
        return [MemoryHubColors.teal500, MemoryHubColors.teal400];
      case 'memory':
        return [MemoryHubColors.pink500, MemoryHubColors.pink400];
      case 'birthday':
        return [MemoryHubColors.pink500, MemoryHubColors.pink400];
      case 'anniversary':
        return [MemoryHubColors.purple500, MemoryHubColors.pink500];
      case 'trip':
      case 'travel':
        return [MemoryHubColors.cyan500, MemoryHubColors.teal500];
      default:
        return [MemoryHubColors.purple500, MemoryHubColors.purple400];
    }
  }

  IconData _getEventIcon(String eventType) {
    final type = eventType.toLowerCase();
    switch (type) {
      case 'album':
        return Icons.photo_library;
      case 'event':
      case 'calendar':
        return Icons.event;
      case 'milestone':
        return Icons.celebration;
      case 'achievement':
        return Icons.emoji_events;
      case 'recipe':
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
        return Icons.event_note;
    }
  }

  Widget _buildShimmerItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(
          width: 50,
          height: 50,
          borderRadius: BorderRadius.circular(25),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 200, height: 18, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 8),
                  ShimmerBox(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 4),
                  ShimmerBox(width: 150, height: 14, borderRadius: BorderRadius.circular(4)),
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
        title: const Text('Filter Events'),
        content: const Text('Select event type to filter'),
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
      _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }
}
