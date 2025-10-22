import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_timeline.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
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
      duration: const Duration(milliseconds: 300),
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
                _buildAppBar(),
                if (_isLoading)
                  SliverFillRemaining(
                    child: _buildLoadingState(),
                  )
                else if (_hasError)
                  SliverFillRemaining(
                    child: _buildErrorState(),
                  )
                else ...[
                  SliverToBoxAdapter(child: _buildQuickActionPills()),
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

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Family Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF7C3AED),
                Color(0xFFEC4899),
                Color(0xFF06B6D4),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Icon(
                  Icons.family_restroom,
                  size: 200,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Positioned(
                bottom: 60,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Life Canvas',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionPills() {
    final quickActions = [
      {'label': 'Albums', 'icon': Icons.photo_library, 'color': const Color(0xFF7C3AED), 'screen': const FamilyAlbumsScreen()},
      {'label': 'Timeline', 'icon': Icons.timeline, 'color': const Color(0xFFEC4899), 'screen': const FamilyTimelineScreen()},
      {'label': 'Calendar', 'icon': Icons.calendar_today, 'color': const Color(0xFF06B6D4), 'screen': const FamilyCalendarScreen()},
      {'label': 'Milestones', 'icon': Icons.celebration, 'color': const Color(0xFFF59E0B), 'screen': const FamilyMilestonesScreen()},
      {'label': 'Recipes', 'icon': Icons.restaurant_menu, 'color': const Color(0xFFEF4444), 'screen': const FamilyRecipesScreen()},
      {'label': 'Health', 'icon': Icons.health_and_safety, 'color': const Color(0xFF10B981), 'screen': const HealthRecordsScreen()},
      {'label': 'Letters', 'icon': Icons.mail, 'color': const Color(0xFF8B5CF6), 'screen': const LegacyLettersScreen()},
      {'label': 'Traditions', 'icon': Icons.local_florist, 'color': const Color(0xFF14B8A6), 'screen': const FamilyTraditionsScreen()},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: quickActions.length,
              itemBuilder: (context, index) {
                final action = quickActions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _buildQuickActionPill(
                    label: action['label'] as String,
                    icon: action['icon'] as IconData,
                    color: action['color'] as Color,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => action['screen'] as Widget,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionPill({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 85,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = [
      {
        'label': 'Albums',
        'value': _dashboardData['albums_count']?.toString() ?? '0',
        'icon': Icons.photo_library,
        'gradient': const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9333EA)]),
        'screen': const FamilyAlbumsScreen(),
      },
      {
        'label': 'Events',
        'value': _dashboardData['events_count']?.toString() ?? '0',
        'icon': Icons.event,
        'gradient': const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF472B6)]),
        'screen': const FamilyCalendarScreen(),
      },
      {
        'label': 'Milestones',
        'value': _dashboardData['milestones_count']?.toString() ?? '0',
        'icon': Icons.celebration,
        'gradient': const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
        'screen': const FamilyMilestonesScreen(),
      },
      {
        'label': 'Recipes',
        'value': _dashboardData['recipes_count']?.toString() ?? '0',
        'icon': Icons.restaurant_menu,
        'gradient': const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF87171)]),
        'screen': const FamilyRecipesScreen(),
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'At a Glance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return _buildStatCard(
                label: stat['label'] as String,
                value: stat['value'] as String,
                icon: stat['icon'] as IconData,
                gradient: stat['gradient'] as LinearGradient,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => stat['screen'] as Widget,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsNewSection() {
    if (_recentActivities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "What's New",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivities.length,
            itemBuilder: (context, index) {
              return _buildActivityCard(_recentActivities[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(TimelineEvent event) {
    final color = _getEventColor(event.eventType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getEventIcon(event.eventType),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, y').format(event.eventDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'title': 'Document Vault',
        'subtitle': 'Secure family documents',
        'icon': Icons.folder_special,
        'gradient': const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)]),
        'screen': const FamilyDocumentVaultScreen(),
      },
      {
        'title': 'Genealogy Tree',
        'subtitle': 'Build your family tree',
        'icon': Icons.account_tree,
        'gradient': const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
        'screen': const GenealogyTreeScreen(),
      },
      {
        'title': 'Parental Controls',
        'subtitle': 'Manage family settings',
        'icon': Icons.shield,
        'gradient': const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]),
        'screen': const ParentalControlsScreen(),
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'More Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => feature['screen'] as Widget,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: feature['gradient'] as LinearGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            feature['icon'] as IconData,
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
                                feature['title'] as String,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                feature['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialFAB() {
    final speedDialItems = [
      {
        'label': 'Album',
        'icon': Icons.photo_library,
        'color': const Color(0xFF7C3AED),
        'onTap': () => _showCreateDialog('album'),
      },
      {
        'label': 'Event',
        'icon': Icons.event,
        'color': const Color(0xFF06B6D4),
        'onTap': () => _showCreateDialog('event'),
      },
      {
        'label': 'Milestone',
        'icon': Icons.celebration,
        'color': const Color(0xFFF59E0B),
        'onTap': () => _showCreateDialog('milestone'),
      },
      {
        'label': 'Recipe',
        'icon': Icons.restaurant_menu,
        'color': const Color(0xFFEF4444),
        'onTap': () => _showCreateDialog('recipe'),
      },
      {
        'label': 'Health Record',
        'icon': Icons.health_and_safety,
        'color': const Color(0xFF10B981),
        'onTap': () => _showCreateDialog('health'),
      },
      {
        'label': 'Letter',
        'icon': Icons.mail,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => _showCreateDialog('letter'),
      },
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isFabExpanded)
          ...speedDialItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.white,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        item['label'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    heroTag: item['label'],
                    mini: true,
                    backgroundColor: item['color'] as Color,
                    onPressed: item['onTap'] as VoidCallback,
                    child: Icon(item['icon'] as IconData),
                  ),
                ],
              ),
            );
          }).toList(),
        FloatingActionButton(
          onPressed: _toggleFab,
          backgroundColor: const Color(0xFFEC4899),
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _fabController,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showCreateDialog(String type) {
    _toggleFab();
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
      case 'health':
        dialog = AddHealthRecordDialog(onSubmit: _createHealthRecord);
        break;
      case 'letter':
        dialog = AddLegacyLetterDialog(onSubmit: _createLetter);
        break;
      default:
        return;
    }

    showDialog(context: context, builder: (context) => dialog);
  }

  Future<void> _createAlbum(Map<String, dynamic> data) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album created successfully!')),
      );
      _loadDashboard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _createEvent(Map<String, dynamic> data) async {
    try {
      await _familyService.createCalendarEvent(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully!')),
      );
      _loadDashboard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _createMilestone(Map<String, dynamic> data) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Milestone created successfully!')),
      );
      _loadDashboard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _createRecipe(Map<String, dynamic> data) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe created successfully!')),
      );
      _loadDashboard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _createHealthRecord(Map<String, dynamic> data) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health record created successfully!')),
      );
      _loadDashboard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _createLetter(Map<String, dynamic> data) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Letter created successfully!')),
      );
      _loadDashboard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          ShimmerLoading(
            isLoading: true,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: ShimmerBox(height: 120, borderRadius: BorderRadius.circular(16))),
                    const SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 120, borderRadius: BorderRadius.circular(16))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: ShimmerBox(height: 120, borderRadius: BorderRadius.circular(16))),
                    const SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 120, borderRadius: BorderRadius.circular(16))),
                  ],
                ),
                const SizedBox(height: 20),
                ShimmerBox(height: 80, borderRadius: BorderRadius.circular(12)),
                const SizedBox(height: 12),
                ShimmerBox(height: 80, borderRadius: BorderRadius.circular(12)),
                const SizedBox(height: 12),
                ShimmerBox(height: 80, borderRadius: BorderRadius.circular(12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return EnhancedEmptyState(
      icon: Icons.error_outline,
      title: 'Oops! Something went wrong',
      message: 'We couldn\'t load your family dashboard. Please try again.',
      actionLabel: 'Retry',
      onAction: _loadDashboard,
      gradientColors: const [Color(0xFFEF4444), Color(0xFFF87171)],
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'birthday':
        return Icons.cake;
      case 'achievement':
        return Icons.emoji_events;
      case 'trip':
        return Icons.flight;
      case 'anniversary':
        return Icons.favorite;
      case 'gathering':
        return Icons.groups;
      default:
        return Icons.event;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'birthday':
        return const Color(0xFFEC4899);
      case 'achievement':
        return const Color(0xFFF59E0B);
      case 'trip':
        return const Color(0xFF06B6D4);
      case 'anniversary':
        return const Color(0xFFEF4444);
      case 'gathering':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF7C3AED);
    }
  }
}
