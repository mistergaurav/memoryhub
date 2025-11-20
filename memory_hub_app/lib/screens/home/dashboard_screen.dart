import 'dart:ui';
import 'package:flutter/material.dart';
import '../memories/memory_create_screen.dart';
import '../notifications/notifications_screen.dart';
import '../activity/activity_feed_screen.dart';
import '../../services/dashboard_service.dart';
import '../../services/analytics_service.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/layout/gap.dart';
import '../../design_system/layout/padded.dart';
import '../../design_system/utils/context_ext.dart';
import '../../providers/user_provider.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentActivity = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final DashboardService _dashboardService = DashboardService();
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: MemoryHubAnimations.slow,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: MemoryHubAnimations.easeIn,
    );
    _fadeController.forward();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final statsData = await _analyticsService.getOverview();
      final activityData = await _dashboardService.getRecentActivity(limit: 10);
      
      setState(() {
        _stats = statsData;
        _recentActivity = activityData.map((activity) {
          return {
            'type': activity['type'] ?? 'activity',
            'title': activity['title'] ?? 'Activity',
            'description': activity['description'] ?? '',
            'time': _formatTime(activity['timestamp']),
            'icon': _getIconForType(activity['type']),
            'color': _getColorForType(activity['type']),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _stats = {
          'total_memories': 0,
          'total_files': 0,
          'total_collections': 0,
          'total_followers': 0,
        };
        _recentActivity = [];
      });
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final diff = DateTime.now().difference(dt);
      
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${(diff.inDays / 7).floor()} weeks ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'memory_created':
      case 'memory':
        return Icons.photo_library;
      case 'file_uploaded':
      case 'file':
        return Icons.upload_file;
      case 'collection_created':
      case 'collection':
        return Icons.collections;
      case 'user_followed':
      case 'follow':
        return Icons.person_add;
      case 'comment':
        return Icons.comment;
      case 'like':
        return Icons.favorite;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'memory_created':
      case 'memory':
        return MemoryHubColors.indigo500;
      case 'file_uploaded':
      case 'file':
        return MemoryHubColors.green500;
      case 'collection_created':
      case 'collection':
        return MemoryHubColors.purple500;
      case 'user_followed':
      case 'follow':
        return MemoryHubColors.pink500;
      case 'comment':
        return MemoryHubColors.amber500;
      case 'like':
        return MemoryHubColors.red500;
      default:
        return MemoryHubColors.gray500;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userName = userProvider.currentUser?.fullName ?? userProvider.currentUser?.username ?? 'there';
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(userName),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padded.all(
                  MemoryHubSpacing.xl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMyHubsSection(),
                      VGap.xxl(),
                      _buildStatsSection(),
                      VGap.xxl(),
                      _buildQuickActionsSection(),
                      VGap.xxl(),
                      _buildFeaturesSection(),
                      VGap.xxl(),
                      _buildRecentActivitySection(),
                      VGap.xl(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MemoryCreateScreen(),
            ),
          );
        },
        icon: Icon(Icons.add),
        label: Text(
          'Create Memory',
          style: context.text.labelLarge?.copyWith(
            fontWeight: MemoryHubTypography.semiBold,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(String userName) {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Dashboard',
          style: context.text.titleLarge?.copyWith(
            fontWeight: MemoryHubTypography.bold,
            color: context.colors.onPrimary,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: MemoryHubGradients.primary,
          ),
          child: Stack(
            children: [
              Positioned(
                top: 40,
                right: -30,
                child: Icon(
                  Icons.auto_awesome,
                  size: 140,
                  color: context.colors.onPrimary.withValues(alpha: 0.15),
                ),
              ),
              Positioned(
                bottom: 30,
                left: MemoryHubSpacing.xl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, $userName!',
                      style: context.text.titleMedium?.copyWith(
                        color: context.colors.onPrimary.withValues(alpha: 0.95),
                        fontWeight: MemoryHubTypography.semiBold,
                      ),
                    ),
                    VGap.xs(),
                    Text(
                      'Ready to create amazing memories?',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMyHubsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Hub',
              style: context.text.headlineSmall?.copyWith(
                fontWeight: MemoryHubTypography.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MemoryHubSpacing.md,
                vertical: MemoryHubSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.15),
                    context.colors.secondary.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: MemoryHubBorderRadius.mdRadius,
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: context.colors.primary,
                  ),
                  HGap.xs(),
                  Text(
                    'Active',
                    style: context.text.bodySmall?.copyWith(
                      fontWeight: MemoryHubTypography.semiBold,
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        VGap.lg(),
        _buildLargeHubCard(
          context,
          title: 'Collections',
          subtitle: 'Organize your memories into beautiful albums',
          icon: Icons.collections_bookmark,
          gradient: MemoryHubGradients.primary,
          count: '${_stats['total_collections'] ?? _stats['collections'] ?? 0}',
          countLabel: 'Collections',
          stats: [
            {'label': 'Total', 'value': '${_stats['total_collections'] ?? _stats['collections'] ?? 0}'},
            {'label': 'This Month', 'value': '${_stats['collections_this_month'] ?? 0}'},
          ],
          onTap: () => Navigator.pushNamed(context, '/collections'),
        ),
      ],
    );
  }

  Widget _buildLargeHubCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required String count,
    required String countLabel,
    required List<Map<String, String>> stats,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: MemoryHubBorderRadius.xxlRadius,
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: MemoryHubBorderRadius.xxlRadius,
              ),
            ),
            ClipRRect(
              borderRadius: MemoryHubBorderRadius.xxlRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colors.onPrimary.withValues(alpha: 0.2),
                        context.colors.onPrimary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: MemoryHubBorderRadius.xxlRadius,
                    border: Border.all(
                      color: context.colors.onPrimary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Icon(
                icon,
                size: 160,
                color: context.colors.onPrimary.withValues(alpha: 0.15),
              ),
            ),
            Padded.all(
              MemoryHubSpacing.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.colors.onPrimary.withValues(alpha: 0.3),
                          borderRadius: MemoryHubBorderRadius.lgRadius,
                          border: Border.all(
                            color: context.colors.onPrimary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(icon, color: context.colors.onPrimary, size: 32),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: MemoryHubSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.onPrimary.withValues(alpha: 0.25),
                          borderRadius: MemoryHubBorderRadius.mdRadius,
                          border: Border.all(
                            color: context.colors.onPrimary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              count,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: MemoryHubTypography.bold,
                                color: context.colors.onPrimary,
                              ),
                            ),
                            HGap.sm(),
                            Text(
                              countLabel,
                              style: context.text.bodySmall?.copyWith(
                                color: context.colors.onPrimary.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: context.text.headlineSmall?.copyWith(
                      fontWeight: MemoryHubTypography.bold,
                      color: context.colors.onPrimary,
                      shadows: [
                        Shadow(
                          color: context.colors.onSurface.withValues(alpha: 0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  VGap.sm(),
                  Text(
                    subtitle,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onPrimary.withValues(alpha: 0.95),
                    ),
                  ),
                  VGap.lg(),
                  Row(
                    children: stats.map((stat) {
                      return Padding(
                        padding: EdgeInsets.only(right: MemoryHubSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat['value']!,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: MemoryHubTypography.bold,
                                color: context.colors.onPrimary,
                              ),
                            ),
                            Text(
                              stat['label']!,
                              style: context.text.bodySmall?.copyWith(
                                color: context.colors.onPrimary.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: context.text.headlineSmall?.copyWith(
            fontWeight: MemoryHubTypography.bold,
          ),
        ),
        VGap.lg(),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Memories',
                (_stats['total_memories'] ?? _stats['memories'] ?? 0) is int 
                    ? (_stats['total_memories'] ?? _stats['memories'] ?? 0)
                    : int.tryParse((_stats['total_memories'] ?? _stats['memories'] ?? 0).toString()) ?? 0,
                Icons.auto_awesome,
                MemoryHubColors.indigo500,
                _stats['memories_growth'] ?? '+0%',
              ),
            ),
            HGap.md(),
            Expanded(
              child: _buildStatCard(
                'Files',
                (_stats['total_files'] ?? _stats['files'] ?? 0) is int 
                    ? (_stats['total_files'] ?? _stats['files'] ?? 0)
                    : int.tryParse((_stats['total_files'] ?? _stats['files'] ?? 0).toString()) ?? 0,
                Icons.folder_outlined,
                MemoryHubColors.green500,
                _stats['files_growth'] ?? '+0',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color, String trend) {
    return Container(
      padding: EdgeInsets.all(MemoryHubSpacing.xl),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: MemoryHubBorderRadius.xlRadius,
        border: Border.all(
          color: context.theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(MemoryHubSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: MemoryHubBorderRadius.mdRadius,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MemoryHubSpacing.sm,
                  vertical: MemoryHubSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: MemoryHubColors.green500.withValues(alpha: 0.1),
                  borderRadius: MemoryHubBorderRadius.smRadius,
                ),
                child: Text(
                  trend,
                  style: context.text.bodySmall?.copyWith(
                    fontWeight: MemoryHubTypography.semiBold,
                    color: MemoryHubColors.green500,
                  ),
                ),
              ),
            ],
          ),
          VGap.lg(),
          Text(
            value.toString(),
            style: context.text.headlineLarge?.copyWith(
              fontWeight: MemoryHubTypography.bold,
              color: color,
            ),
          ),
          VGap.xs(),
          Text(
            label,
            style: context.text.bodyMedium?.copyWith(
              color: MemoryHubColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final quickActions = [
      {
        'title': 'New Memory',
        'icon': Icons.add_photo_alternate,
        'gradient': MemoryHubGradients.primary,
        'route': '/memories/create',
      },
      {
        'title': 'Upload File',
        'icon': Icons.cloud_upload,
        'gradient': MemoryHubGradients.success,
        'route': '/vault/upload',
      },
      {
        'title': 'Create Story',
        'icon': Icons.auto_stories,
        'gradient': MemoryHubGradients.secondary,
        'route': '/stories/create',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: context.text.headlineSmall?.copyWith(
            fontWeight: MemoryHubTypography.bold,
          ),
        ),
        VGap.lg(),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: quickActions.map((action) {
              return Padding(
                padding: EdgeInsets.only(right: MemoryHubSpacing.md),
                child: _buildQuickActionCard(
                  title: action['title'] as String,
                  icon: action['icon'] as IconData,
                  gradient: action['gradient'] as Gradient,
                  onTap: () => Navigator.pushNamed(context, action['route'] as String),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: EdgeInsets.all(MemoryHubSpacing.xl),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: MemoryHubBorderRadius.xlRadius,
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(MemoryHubSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.onPrimary.withValues(alpha: 0.2),
                borderRadius: MemoryHubBorderRadius.mdRadius,
              ),
              child: Icon(icon, color: context.colors.onPrimary, size: 28),
            ),
            VGap.md(),
            Text(
              title,
              style: context.text.bodyMedium?.copyWith(
                fontWeight: MemoryHubTypography.semiBold,
                color: context.colors.onPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {'title': 'Social Hub', 'icon': Icons.people_outline, 'route': '/social/hubs', 'color': MemoryHubColors.pink500},
      {'title': 'Search', 'icon': Icons.search, 'route': '/search', 'color': MemoryHubColors.purple500},
      {'title': 'Tags', 'icon': Icons.label_outline, 'route': '/tags', 'color': MemoryHubColors.green500},
      {'title': 'Categories', 'icon': Icons.category_outlined, 'route': '/categories', 'color': MemoryHubColors.amber500},
      {'title': 'Places', 'icon': Icons.place_outlined, 'route': '/places', 'color': MemoryHubColors.blue500},
      {'title': 'Settings', 'icon': Icons.settings_outlined, 'route': '/profile/settings', 'color': MemoryHubColors.indigo500},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore Features',
          style: context.text.headlineSmall?.copyWith(
            fontWeight: MemoryHubTypography.bold,
          ),
        ),
        VGap.lg(),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: MemoryHubSpacing.md,
            mainAxisSpacing: MemoryHubSpacing.md,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, feature['route'] as String),
              child: Container(
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: MemoryHubBorderRadius.lgRadius,
                  border: Border.all(
                    color: context.theme.dividerColor,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(MemoryHubSpacing.md),
                      decoration: BoxDecoration(
                        color: (feature['color'] as Color).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: feature['color'] as Color,
                        size: 28,
                      ),
                    ),
                    VGap.sm(),
                    Text(
                      feature['title'] as String,
                      style: context.text.bodySmall?.copyWith(
                        fontWeight: MemoryHubTypography.semiBold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: context.text.headlineSmall?.copyWith(
                fontWeight: MemoryHubTypography.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivityFeedScreen(),
                  ),
                );
              },
              child: Text(
                'View All',
                style: context.text.labelLarge?.copyWith(
                  fontWeight: MemoryHubTypography.semiBold,
                ),
              ),
            ),
          ],
        ),
        VGap.lg(),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _recentActivity.isEmpty
                ? Container(
                    padding: EdgeInsets.all(MemoryHubSpacing.xxxxl),
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      borderRadius: MemoryHubBorderRadius.xlRadius,
                      border: Border.all(
                        color: context.theme.dividerColor,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: MemoryHubColors.gray400,
                          ),
                          VGap.md(),
                          Text(
                            'No recent activity',
                            style: context.text.bodyMedium?.copyWith(
                              color: MemoryHubColors.gray600,
                              fontWeight: MemoryHubTypography.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: _recentActivity.map((activity) {
                      return Container(
                        margin: EdgeInsets.only(bottom: MemoryHubSpacing.md),
                        decoration: BoxDecoration(
                          color: context.theme.cardColor,
                          borderRadius: MemoryHubBorderRadius.lgRadius,
                          border: Border.all(
                            color: context.theme.dividerColor,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: MemoryHubSpacing.lg,
                            vertical: MemoryHubSpacing.sm,
                          ),
                          leading: Container(
                            padding: EdgeInsets.all(MemoryHubSpacing.sm + 2),
                            decoration: BoxDecoration(
                              color: (activity['color'] as Color).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              activity['icon'],
                              color: activity['color'],
                              size: 20,
                            ),
                          ),
                          title: Text(
                            activity['title'],
                            style: context.text.bodyMedium?.copyWith(
                              fontWeight: MemoryHubTypography.semiBold,
                            ),
                          ),
                          subtitle: Text(
                            activity['description'],
                            style: context.text.bodySmall,
                          ),
                          trailing: Text(
                            activity['time'],
                            style: context.text.bodySmall?.copyWith(
                              color: MemoryHubColors.gray600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
      ],
    );
  }
}
