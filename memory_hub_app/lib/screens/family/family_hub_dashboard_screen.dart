import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_timeline.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../widgets/hero_header.dart';
import '../../widgets/quick_action_tile.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/timeline_card.dart';
import '../../widgets/recent_section.dart';
import '../../design_system/design_tokens.dart';
import '../../dialogs/family/add_album_dialog.dart';
import '../../dialogs/family/add_event_dialog.dart';
import '../../dialogs/family/add_milestone_dialog.dart';
import '../../dialogs/family/add_recipe_dialog.dart';
import '../../dialogs/family/add_health_record_dialog.dart';
import '../../dialogs/family/add_legacy_letter_dialog.dart';
import 'family_albums_screen.dart';
import 'family_timeline_screen.dart';
import 'family_calendar_screen.dart';
import 'family_milestones_screen.dart';
import 'family_recipes_screen.dart';
import 'legacy_letters_screen.dart';
import 'family_traditions_screen.dart';
import 'parental_controls_screen.dart';
import 'family_document_vault_screen.dart';
import 'genealogy_tree_screen.dart';
import 'health_records_screen.dart';

class FamilyHubDashboardScreen extends StatefulWidget {
  const FamilyHubDashboardScreen({Key? key}) : super(key: key);

  @override
  State<FamilyHubDashboardScreen> createState() => _FamilyHubDashboardScreenState();
}

class _FamilyHubDashboardScreenState extends State<FamilyHubDashboardScreen> with TickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _dashboardData = {};
  List<TimelineEvent> _recentActivities = [];
  bool _isFabExpanded = false;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: MemoryHubAnimations.normal,
      vsync: this,
    );
    _loadDashboard();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final dashboardFuture = _familyService.getFamilyDashboard();
      final activitiesFuture = _familyService.getTimelineEvents();

      final results = await Future.wait([
        dashboardFuture,
        activitiesFuture,
      ]);

      setState(() {
        _dashboardData = results[0] as Map<String, dynamic>;
        _recentActivities = (results[1] as List<TimelineEvent>).take(8).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });
    if (_isFabExpanded) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  int _getStat(String category, {String? subKey}) {
    try {
      if (_dashboardData.isEmpty) return 0;
      
      final stats = _dashboardData['stats'] as Map<String, dynamic>?;
      if (stats == null) return 0;
      
      if (subKey != null) {
        final categoryData = stats[category];
        if (categoryData is Map<String, dynamic>) {
          return (categoryData[subKey] as num?)?.toInt() ?? 0;
        }
        return 0;
      }
      
      return (stats[category] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('Error getting stat $category: $e');
      return 0;
    }
  }

  List<dynamic> _getRecentItems(String key) {
    try {
      if (_dashboardData.isEmpty) return [];
      final items = _dashboardData[key];
      if (items is List) return items;
      return [];
    } catch (e) {
      debugPrint('Error getting recent items $key: $e');
      return [];
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? MemoryHubColors.red500 : null,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _handleAction(Future<void> Function() action, String successMessage, String errorPrefix) async {
    try {
      await action();
      await _loadDashboard();
      _showSnackBar(successMessage);
    } catch (e) {
      _showSnackBar('$errorPrefix: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadDashboard,
            child: CustomScrollView(
              slivers: [
                HeroHeaderWithDate(
                  title: 'Family Hub',
                  subtitle: 'Your Life Canvas',
                  date: DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                  icon: Icons.family_restroom,
                  gradientColors: const [
                    MemoryHubColors.purple700,
                    MemoryHubColors.pink500,
                    MemoryHubColors.cyan500,
                  ],
                ),
                if (_isLoading)
                  SliverFillRemaining(
                    child: _buildLoadingState(),
                  )
                else if (_hasError)
                  SliverFillRemaining(
                    child: _buildErrorState(),
                  )
                else ...[
                  SliverToBoxAdapter(child: _buildQuickActionSection()),
                  SliverToBoxAdapter(child: _buildStatsSection()),
                  SliverToBoxAdapter(child: _buildRecentItemsSection()),
                  SliverToBoxAdapter(child: _buildWhatsNewSection()),
                  SliverToBoxAdapter(child: _buildFeaturesSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ],
            ),
          ),
          if (_isFabExpanded)
            GestureDetector(
              onTap: _toggleFab,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildSpeedDialFAB(),
    );
  }

  Widget _buildQuickActionSection() {
    final quickActions = [
      QuickActionTileData(
        label: 'Albums',
        icon: Icons.photo_library,
        color: MemoryHubColors.purple600,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FamilyAlbumsScreen()),
        ),
      ),
      QuickActionTileData(
        label: 'Timeline',
        icon: Icons.timeline,
        color: MemoryHubColors.pink500,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FamilyTimelineScreen()),
        ),
      ),
      QuickActionTileData(
        label: 'Calendar',
        icon: Icons.calendar_today,
        color: MemoryHubColors.cyan500,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FamilyCalendarScreen()),
        ),
      ),
      QuickActionTileData(
        label: 'Milestones',
        icon: Icons.celebration,
        color: MemoryHubColors.amber500,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FamilyMilestonesScreen()),
        ),
      ),
      QuickActionTileData(
        label: 'Recipes',
        icon: Icons.restaurant_menu,
        color: MemoryHubColors.red500,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FamilyRecipesScreen()),
        ),
      ),
      QuickActionTileData(
        label: 'Health',
        icon: Icons.health_and_safety,
        color: MemoryHubColors.green500,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HealthRecordsScreen()),
        ),
      ),
      QuickActionTileData(
        label: 'Letters',
        icon: Icons.mail,
        color: MemoryHubColors.purple500,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LegacyLettersScreen()),
        ),
      ),
      QuickActionTileData(
        label: 'Traditions',
        icon: Icons.local_florist,
        color: MemoryHubColors.teal500,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FamilyTraditionsScreen()),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MemoryHubSpacing.lg),
      child: QuickActionHorizontalList(
        title: 'Quick Actions',
        actions: quickActions,
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'At a Glance',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: MemoryHubSpacing.md,
            mainAxisSpacing: MemoryHubSpacing.md,
            childAspectRatio: 1.4,
            children: [
              Semantics(
                label: 'Albums count: ${_getStat('albums')}',
                button: true,
                child: StatCard(
                  label: 'Albums',
                  value: _getStat('albums').toString(),
                  icon: Icons.photo_library,
                  gradientColors: MemoryHubGradients.albums.colors,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FamilyAlbumsScreen()),
                  ),
                ),
              ),
              Semantics(
                label: 'Upcoming events count: ${_getStat('upcoming_events')}',
                button: true,
                child: StatCard(
                  label: 'Events',
                  value: _getStat('upcoming_events').toString(),
                  icon: Icons.event,
                  gradientColors: MemoryHubGradients.secondary.colors,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FamilyCalendarScreen()),
                  ),
                ),
              ),
              Semantics(
                label: 'Family circles count: ${_getStat('family_circles')}',
                button: true,
                child: StatCard(
                  label: 'Circles',
                  value: _getStat('family_circles').toString(),
                  icon: Icons.groups,
                  gradientColors: MemoryHubGradients.milestones.colors,
                  onTap: () {
                    _showSnackBar('Family Circles feature coming soon!');
                  },
                ),
              ),
              Semantics(
                label: 'Relationships count: ${_getStat('relationships')}',
                button: true,
                child: StatCard(
                  label: 'Relations',
                  value: _getStat('relationships').toString(),
                  icon: Icons.account_tree,
                  gradientColors: MemoryHubGradients.recipes.colors,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GenealogyTreeScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItemsSection() {
    final recentAlbums = _getRecentItems('recent_albums');
    final upcomingEvents = _getRecentItems('upcoming_events');
    final recentMilestones = _getRecentItems('recent_milestones');

    if (recentAlbums.isEmpty && upcomingEvents.isEmpty && recentMilestones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          if (recentAlbums.isNotEmpty) ...[
            RecentSection(
              title: 'Recent Albums',
              items: recentAlbums,
              icon: Icons.photo_library,
              color: MemoryHubColors.purple600,
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FamilyAlbumsScreen()),
              ),
            ),
            const SizedBox(height: MemoryHubSpacing.md),
          ],
          if (upcomingEvents.isNotEmpty) ...[
            RecentSection(
              title: 'Upcoming Events',
              items: upcomingEvents,
              icon: Icons.event,
              color: MemoryHubColors.cyan500,
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FamilyCalendarScreen()),
              ),
            ),
            const SizedBox(height: MemoryHubSpacing.md),
          ],
          if (recentMilestones.isNotEmpty) ...[
            RecentSection(
              title: 'Recent Milestones',
              items: recentMilestones,
              icon: Icons.celebration,
              color: MemoryHubColors.amber500,
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FamilyMilestonesScreen()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWhatsNewSection() {
    if (_recentActivities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(MemoryHubSpacing.lg),
        child: EnhancedEmptyState(
          icon: Icons.event_note,
          title: 'No Recent Activity',
          message: 'Start creating albums, events, and milestones to see them here.',
          actionLabel: 'Create Something',
          onAction: _toggleFab,
          gradientColors: const [
            MemoryHubColors.purple500,
            MemoryHubColors.pink500,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "What's New",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Semantics(
                label: 'View all timeline events',
                button: true,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FamilyTimelineScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivities.length,
            itemBuilder: (context, index) {
              final event = _recentActivities[index];
              return Semantics(
                label: '${event.title}, ${event.description ?? ''}, ${DateFormat.yMMMd().format(event.eventDate)}',
                button: true,
                child: TimelineCard(
                  title: event.title,
                  subtitle: event.description,
                  date: event.eventDate,
                  icon: _getEventIcon(event.eventType),
                  gradientColors: _getEventGradient(event.eventType),
                  onTap: () => _navigateToEventDetail(event),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More Features',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          Semantics(
            label: 'Document Vault - Secure family documents',
            button: true,
            child: _buildFeatureCard(
              title: 'Document Vault',
              subtitle: 'Secure family documents',
              icon: Icons.folder_special,
              gradientColors: const [MemoryHubColors.teal500, MemoryHubColors.teal400],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FamilyDocumentVaultScreen()),
              ),
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          Semantics(
            label: 'Genealogy Tree - Build your family tree',
            button: true,
            child: _buildFeatureCard(
              title: 'Genealogy Tree',
              subtitle: 'Build your family tree',
              icon: Icons.account_tree,
              gradientColors: const [MemoryHubColors.amber500, MemoryHubColors.amber400],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GenealogyTreeScreen()),
              ),
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          Semantics(
            label: 'Parental Controls - Manage family settings',
            button: true,
            child: _buildFeatureCard(
              title: 'Parental Controls',
              subtitle: 'Manage family settings',
              icon: Icons.shield,
              gradientColors: const [MemoryHubColors.indigo500, MemoryHubColors.indigo400],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ParentalControlsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: MemoryHubElevation.md,
      shape: RoundedRectangleBorder(
        borderRadius: MemoryHubBorderRadius.xlRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: MemoryHubBorderRadius.xlRadius,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: MemoryHubBorderRadius.xlRadius,
          ),
          padding: const EdgeInsets.all(MemoryHubSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(MemoryHubSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: MemoryHubBorderRadius.mdRadius,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: MemoryHubSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: MemoryHubSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Navigate to $title',
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: MemoryHubSpacing.lg),
          Text(
            'Loading your family hub...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MemoryHubSpacing.xl),
        child: EnhancedEmptyState(
          icon: Icons.error_outline,
          title: 'Unable to Load Dashboard',
          message: _errorMessage.contains('401') || _errorMessage.contains('Unauthorized')
              ? 'Your session has expired. Please log in again.'
              : 'We encountered an issue loading your family hub. Please check your connection and try again.',
          actionLabel: 'Retry',
          onAction: _loadDashboard,
          gradientColors: const [
            MemoryHubColors.red500,
            MemoryHubColors.red400,
          ],
        ),
      ),
    );
  }

  void _navigateToEventDetail(TimelineEvent event) {
    Widget? targetScreen;

    switch (event.eventType.toLowerCase()) {
      case 'album':
        targetScreen = const FamilyAlbumsScreen();
        break;
      case 'event':
      case 'birthday':
      case 'anniversary':
      case 'meeting':
      case 'gathering':
      case 'holiday':
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
      case 'health':
        targetScreen = const HealthRecordsScreen();
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FamilyTimelineScreen()),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen!),
    );
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
      case 'death_anniversary':
        return Icons.favorite;
      case 'meeting':
      case 'gathering':
        return Icons.people;
      case 'holiday':
        return Icons.celebration;
      case 'trip':
      case 'travel':
        return Icons.flight;
      case 'health':
        return Icons.health_and_safety;
      default:
        return Icons.event_note;
    }
  }

  List<Color> _getEventGradient(String eventType) {
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
      case 'death_anniversary':
        return [MemoryHubColors.purple500, MemoryHubColors.pink500];
      case 'meeting':
      case 'gathering':
        return [MemoryHubColors.purple600, MemoryHubColors.purple400];
      case 'holiday':
        return [MemoryHubColors.amber500, MemoryHubColors.amber400];
      case 'trip':
      case 'travel':
        return [MemoryHubColors.cyan500, MemoryHubColors.teal500];
      case 'health':
        return [MemoryHubColors.green500, MemoryHubColors.green400];
      default:
        return [MemoryHubColors.purple500, MemoryHubColors.purple400];
    }
  }

  Widget _buildSpeedDialFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isFabExpanded) ...[
          Semantics(
            label: 'Create new album',
            button: true,
            child: _buildFABOption(
              label: 'Album',
              icon: Icons.photo_library,
              onTap: () => _showDialog('album'),
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.sm),
          Semantics(
            label: 'Create new event',
            button: true,
            child: _buildFABOption(
              label: 'Event',
              icon: Icons.event,
              onTap: () => _showDialog('event'),
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.sm),
          Semantics(
            label: 'Create new milestone',
            button: true,
            child: _buildFABOption(
              label: 'Milestone',
              icon: Icons.celebration,
              onTap: () => _showDialog('milestone'),
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.sm),
          Semantics(
            label: 'Create new recipe',
            button: true,
            child: _buildFABOption(
              label: 'Recipe',
              icon: Icons.restaurant_menu,
              onTap: () => _showDialog('recipe'),
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.sm),
          Semantics(
            label: 'Add health record',
            button: true,
            child: _buildFABOption(
              label: 'Health',
              icon: Icons.health_and_safety,
              onTap: () => _showDialog('health'),
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.sm),
          Semantics(
            label: 'Create legacy letter',
            button: true,
            child: _buildFABOption(
              label: 'Letter',
              icon: Icons.mail,
              onTap: () => _showDialog('letter'),
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
        ],
        Semantics(
          label: _isFabExpanded ? 'Close create menu' : 'Open create menu',
          button: true,
          child: FloatingActionButton(
            heroTag: 'family_hub_main_fab',
            onPressed: _toggleFab,
            tooltip: 'Create new item',
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _fabController,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFABOption({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            _toggleFab();
            onTap();
          },
          borderRadius: MemoryHubBorderRadius.smRadius,
          child: Material(
            color: Theme.of(context).cardColor,
            elevation: MemoryHubElevation.md,
            borderRadius: MemoryHubBorderRadius.smRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MemoryHubSpacing.md,
                vertical: MemoryHubSpacing.sm,
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(width: MemoryHubSpacing.sm),
        FloatingActionButton.small(
          heroTag: 'family_hub_fab_$label',
          onPressed: () {
            _toggleFab();
            onTap();
          },
          tooltip: 'Create $label',
          child: Icon(icon),
        ),
      ],
    );
  }

  Future<void> _showDialog(String type) async {
    Widget? dialog;
    
    switch (type) {
      case 'album':
        dialog = AddAlbumDialog(onSubmit: _createAlbum);
        break;
      case 'event':
        dialog = AddEventDialog(onSubmit: _createEvent);
        break;
      case 'milestone':
        dialog = AddMilestoneDialog(onSubmit: _createMilestone);
        break;
      case 'recipe':
        dialog = AddRecipeDialog(onSubmit: _createRecipe);
        break;
      case 'health':
        dialog = const AddHealthRecordDialog();
        break;
      case 'letter':
        dialog = AddLegacyLetterDialog(onSubmit: _createLegacyLetter);
        break;
      default:
        return;
    }

    if (dialog != null) {
      await showDialog(
        context: context,
        builder: (context) => dialog!,
      );
    }
  }

  Future<void> _createAlbum(Map<String, dynamic> data) async {
    await _handleAction(
      () => _familyService.createAlbum(data),
      'Album created successfully',
      'Failed to create album',
    );
  }

  Future<void> _createEvent(Map<String, dynamic> data) async {
    try {
      final result = await _familyService.createCalendarEvent(data);
      final conflicts = result['conflicts'] ?? 0;
      final warning = result['conflict_warning'];
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              conflicts > 0 && warning != null
                  ? warning
                  : 'Event created successfully',
            ),
            backgroundColor: conflicts > 0 ? Colors.orange : Colors.green,
            duration: Duration(seconds: conflicts > 0 ? 4 : 2),
          ),
        );
      }
      _refreshData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create event: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createMilestone(Map<String, dynamic> data) async {
    await _handleAction(
      () => _familyService.createMilestone(data),
      'Milestone created successfully',
      'Failed to create milestone',
    );
  }

  Future<void> _createRecipe(Map<String, dynamic> data) async {
    await _handleAction(
      () => _familyService.createRecipe(data),
      'Recipe created successfully',
      'Failed to create recipe',
    );
  }

  Future<void> _createLegacyLetter(Map<String, dynamic> data) async {
    await _handleAction(
      () => _familyService.createLegacyLetter(data),
      'Legacy letter created successfully',
      'Failed to create legacy letter',
    );
  }
}
