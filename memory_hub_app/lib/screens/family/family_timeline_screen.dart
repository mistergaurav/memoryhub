import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_timeline.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/add_event_dialog.dart';
import 'package:intl/intl.dart';

class FamilyTimelineScreen extends StatefulWidget {
  const FamilyTimelineScreen({Key? key}) : super(key: key);

  @override
  State<FamilyTimelineScreen> createState() => _FamilyTimelineScreenState();
}

class _FamilyTimelineScreenState extends State<FamilyTimelineScreen> {
  final FamilyService _familyService = FamilyService();
  List<TimelineEvent> _events = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final events = await _familyService.getTimelineEvents(
        filter: _selectedFilter != 'all' ? _selectedFilter : null,
      );
      setState(() {
        _events = events;
        _isLoading = false;
      });
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
        onRefresh: _loadEvents,
        child: CustomScrollView(
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
                        Color(0xFFEC4899),
                        Color(0xFFF472B6),
                        Color(0xFFFBBF24),
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
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                    Color(0xFFEC4899),
                    Color(0xFFF472B6),
                  ],
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTimelineItem(_events[index], index),
                  childCount: _events.length,
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
        backgroundColor: const Color(0xFFEC4899),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'value': 'all', 'icon': Icons.all_inclusive},
      {'label': 'Birthday', 'value': 'birthday', 'icon': Icons.cake},
      {'label': 'Achievement', 'value': 'achievement', 'icon': Icons.emoji_events},
      {'label': 'Trip', 'value': 'trip', 'icon': Icons.flight},
      {'label': 'Other', 'value': 'other', 'icon': Icons.event},
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
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(filter['label'] as String),
                ],
              ),
              selectedColor: const Color(0xFFEC4899),
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                        Colors.grey.shade300,
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                            event.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, y').format(event.eventDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (event.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if (event.photoUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          event.photoUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildInteractionButton(
                          Icons.favorite_border,
                          event.likesCount.toString(),
                          const Color(0xFFEC4899),
                        ),
                        const SizedBox(width: 16),
                        _buildInteractionButton(
                          Icons.comment_outlined,
                          event.commentsCount.toString(),
                          const Color(0xFF06B6D4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
    switch (eventType) {
      case 'birthday':
        return [const Color(0xFFEC4899), const Color(0xFFF472B6)];
      case 'achievement':
        return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case 'trip':
        return [const Color(0xFF06B6D4), const Color(0xFF22D3EE)];
      default:
        return [const Color(0xFF7C3AED), const Color(0xFF9333EA)];
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'birthday':
        return Icons.cake;
      case 'achievement':
        return Icons.emoji_events;
      case 'trip':
        return Icons.flight;
      default:
        return Icons.event;
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
