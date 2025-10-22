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
            style: Theme.of(context).textTheme.headlineMedium,
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
              StatCard(
                label: 'Albums',
                value: _dashboardData['albums_count']?.toString() ?? '0',
                icon: Icons.photo_library,
                gradientColors: MemoryHubGradients.albums.colors,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FamilyAlbumsScreen()),
                ),
              ),
              StatCard(
                label: 'Events',
                value: _dashboardData['events_count']?.toString() ?? '0',
                icon: Icons.event,
                gradientColors: MemoryHubGradients.secondary.colors,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FamilyCalendarScreen()),
                ),
              ),
              StatCard(
                label: 'Milestones',
                value: _dashboardData['milestones_count']?.toString() ?? '0',
                icon: Icons.celebration,
                gradientColors: MemoryHubGradients.milestones.colors,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FamilyMilestonesScreen()),
                ),
              ),
              StatCard(
                label: 'Recipes',
                value: _dashboardData['recipes_count']?.toString() ?? '0',
                icon: Icons.restaurant_menu,
                gradientColors: MemoryHubGradients.recipes.colors,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FamilyRecipesScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsNewSection() {
    if (_recentActivities.isEmpty) {
      return const SizedBox.shrink();
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
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              TextButton(
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
            ],
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivities.length,
            itemBuilder: (context, index) {
              final event = _recentActivities[index];
              return TimelineCard(
                title: event.title,
                subtitle: event.description,
                date: event.eventDate,
                icon: _getEventIcon(event.eventType),
                gradientColors: _getEventGradient(event.eventType),
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
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          _buildFeatureCard(
            title: 'Document Vault',
            subtitle: 'Secure family documents',
            icon: Icons.folder_special,
            gradientColors: const [MemoryHubColors.teal500, MemoryHubColors.teal400],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FamilyDocumentVaultScreen()),
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          _buildFeatureCard(
            title: 'Genealogy Tree',
            subtitle: 'Build your family tree',
            icon: Icons.account_tree,
            gradientColors: const [MemoryHubColors.amber500, MemoryHubColors.amber400],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GenealogyTreeScreen()),
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          _buildFeatureCard(
            title: 'Parental Controls',
            subtitle: 'Manage family settings',
            icon: Icons.shield,
            gradientColors: const [MemoryHubColors.indigo500, MemoryHubColors.indigo400],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ParentalControlsScreen()),
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
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return EnhancedEmptyState(
      icon: Icons.error_outline,
      title: 'Error Loading Dashboard',
      message: 'Failed to load family dashboard. Pull down to retry.',
      actionLabel: 'Retry',
      onAction: _loadDashboard,
      gradientColors: const [
        MemoryHubColors.red500,
        MemoryHubColors.red400,
      ],
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'birthday':
        return Icons.cake;
      case 'death_anniversary':
        return Icons.favorite;
      case 'anniversary':
        return Icons.favorite_border;
      case 'meeting':
      case 'gathering':
        return Icons.people;
      case 'holiday':
        return Icons.celebration;
      default:
        return Icons.event;
    }
  }

  List<Color> _getEventGradient(String eventType) {
    switch (eventType) {
      case 'birthday':
        return [MemoryHubColors.pink500, MemoryHubColors.pink400];
      case 'anniversary':
        return [MemoryHubColors.red600, MemoryHubColors.pink500];
      case 'meeting':
      case 'gathering':
        return [MemoryHubColors.purple600, MemoryHubColors.purple400];
      case 'holiday':
        return [MemoryHubColors.amber500, MemoryHubColors.amber400];
      default:
        return [MemoryHubColors.cyan500, MemoryHubColors.cyan400];
    }
  }

  Widget _buildSpeedDialFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isFabExpanded) ...[
          _buildFABOption(
            label: 'Album',
            icon: Icons.photo_library,
            onTap: () => _showDialog('album'),
          ),
          const SizedBox(height: MemoryHubSpacing.sm),
          _buildFABOption(
            label: 'Event',
            icon: Icons.event,
            onTap: () => _showDialog('event'),
          ),
          const SizedBox(height: MemoryHubSpacing.sm),
          _buildFABOption(
            label: 'Milestone',
            icon: Icons.celebration,
            onTap: () => _showDialog('milestone'),
          ),
          const SizedBox(height: MemoryHubSpacing.sm),
          _buildFABOption(
            label: 'Recipe',
            icon: Icons.restaurant_menu,
            onTap: () => _showDialog('recipe'),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
        ],
        FloatingActionButton(
          heroTag: 'family_hub_main_fab',
          onPressed: _toggleFab,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _fabController,
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
        Material(
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
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
          child: Icon(icon),
        ),
      ],
    );
  }

  Future<void> _showDialog(String type) async {
    Widget dialog;
    
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
      default:
        return;
    }

    await showDialog(
      context: context,
      builder: (context) => dialog,
    );
  }

  Future<void> _createAlbum(Map<String, dynamic> data) async {
    try {
      await _familyService.createAlbum(data);
      _loadDashboard();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Album created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create album: $e')),
        );
      }
    }
  }

  Future<void> _createEvent(Map<String, dynamic> data) async {
    try {
      await _familyService.createCalendarEvent(data);
      _loadDashboard();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: $e')),
        );
      }
    }
  }

  Future<void> _createMilestone(Map<String, dynamic> data) async {
    try {
      await _familyService.createMilestone(data);
      _loadDashboard();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milestone created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create milestone: $e')),
        );
      }
    }
  }

  Future<void> _createRecipe(Map<String, dynamic> data) async {
    try {
      await _familyService.createRecipe(data);
      _loadDashboard();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create recipe: $e')),
        );
      }
    }
  }
}
