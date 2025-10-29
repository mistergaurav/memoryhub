import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/gradient_container.dart';
import '../../widgets/shimmer_loading.dart';
import 'package:intl/intl.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String? _error;
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerController.forward();
    _loadDashboard();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getHubDashboard();
      setState(() {
        _dashboardData = data;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            if (_error != null)
              SliverFillRemaining(child: _buildErrorState())
            else if (_isLoading)
              SliverFillRemaining(child: _buildLoadingState())
            else
              _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    String greetingIcon = '☀️';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
      greetingIcon = '🌤️';
    } else if (hour >= 17) {
      greeting = 'Good evening';
      greetingIcon = '🌙';
    }

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _headerAnimation,
        child: Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF6B9D),
                Color(0xFFC44569),
                Color(0xFFFFA07A),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          greetingIcon,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          greeting,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.95),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your Family\nMemory Hub',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Where every moment matters',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
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

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: List.generate(
              4,
              (index) => ShimmerLoading(
                isLoading: true,
                child: ShimmerBox(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
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
      message: _error ?? 'Unable to load dashboard. Please try again.',
      actionLabel: 'Retry',
      onAction: _loadDashboard,
    );
  }

  Widget _buildContent() {
    final stats = _dashboardData?['stats'] ?? {};
    // final quickLinks = _dashboardData?['quick_links'] ?? []; // Reserved for future use
    final recentActivity = _dashboardData?['recent_activity'] ?? [];

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildStatsSection(stats),
          const SizedBox(height: 32),
          _buildFamilyInspirationSection(context),
          const SizedBox(height: 32),
          _buildQuickActionsSection(context),
          const SizedBox(height: 32),
          _buildMyHubsSection(context),
          const SizedBox(height: 32),
          _buildFeaturesGrid(context),
          const SizedBox(height: 32),
          _buildRecentActivitySection(recentActivity),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your Memory Journey',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.explore, color: Color(0xFFFF6B9D), size: 24),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            StatCard(
              label: 'Memories',
              value: stats['memories_count']?.toString() ?? '0',
              icon: Icons.auto_awesome,
              gradientColors: const [Color(0xFFFF6B9D), Color(0xFFFFA07A)],
              trend: '+12%',
              onTap: () => Navigator.pushNamed(context, '/memories'),
            ),
            StatCard(
              label: 'Family Photos',
              value: stats['files_count']?.toString() ?? '0',
              icon: Icons.photo_library,
              gradientColors: const [Color(0xFFC44569), Color(0xFFFF6B9D)],
              trend: '+5',
              onTap: () => Navigator.pushNamed(context, '/family/albums'),
            ),
            StatCard(
              label: 'Collections',
              value: stats['collections_count']?.toString() ?? '0',
              icon: Icons.collections_bookmark,
              gradientColors: const [Color(0xFFFFA07A), Color(0xFFFFD700)],
              onTap: () => Navigator.pushNamed(context, '/collections'),
            ),
            StatCard(
              label: 'Family Love',
              value: stats['total_likes']?.toString() ?? '0',
              icon: Icons.favorite,
              gradientColors: const [Color(0xFFFF6B9D), Color(0xFFC44569)],
              trend: '+8',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFamilyInspirationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Family Moments',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.camera_alt, color: Color(0xFFFF6B9D), size: 24),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Create lasting memories with your loved ones',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildInspirationCard(
                'attached_assets/stock_images/happy_family_memorie_f3176cf4.jpg',
                'Cherish Every Moment',
                'Create beautiful memories together',
                const [Color(0xFFFF6B9D), Color(0xFFFFA07A)],
              ),
              const SizedBox(width: 12),
              _buildInspirationCard(
                'attached_assets/stock_images/happy_family_memorie_59cd59a7.jpg',
                'Build Your Legacy',
                'Preserve stories for generations',
                const [Color(0xFFC44569), Color(0xFFFF6B9D)],
              ),
              const SizedBox(width: 12),
              _buildInspirationCard(
                'attached_assets/stock_images/happy_family_memorie_3d532408.jpg',
                'Share the Love',
                'Connect with family and friends',
                const [Color(0xFFFFA07A), Color(0xFFFFD700)],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInspirationCard(String imagePath, String title, String subtitle, List<Color> overlayColors) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: overlayColors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.asset(
              imagePath,
              width: 300,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 300,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: overlayColors,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.family_restroom, size: 80, color: Colors.white),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.flash_on, color: Color(0xFFFFA07A), size: 24),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActionCard(
                'Create Memory',
                Icons.auto_awesome,
                const [Color(0xFFFF6B9D), Color(0xFFFFA07A)],
                () => Navigator.pushNamed(context, '/memories/create'),
              ),
              const SizedBox(width: 12),
              _buildActionCard(
                'Family Album',
                Icons.photo_library,
                const [Color(0xFFC44569), Color(0xFFFF6B9D)],
                () => Navigator.pushNamed(context, '/family/albums'),
              ),
              const SizedBox(width: 12),
              _buildActionCard(
                'New Collection',
                Icons.collections_bookmark,
                const [Color(0xFFFFA07A), Color(0xFFFFD700)],
                () => Navigator.pushNamed(context, '/collections'),
              ),
              const SizedBox(width: 12),
              _buildActionCard(
                'Create Story',
                Icons.auto_stories,
                const [Color(0xFFFF6B9D), Color(0xFFC44569)],
                () => Navigator.pushNamed(context, '/stories/create'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, List<Color> colors, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyHubsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Hubs',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '2 Active',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildHubCard(
                context,
                title: 'Collections',
                subtitle: 'Organize memories',
                icon: Icons.collections_bookmark,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                count: '8',
                countLabel: 'Collections',
                onTap: () => Navigator.pushNamed(context, '/collections'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHubCard(
                context,
                title: 'Family Hub',
                subtitle: '12 features',
                icon: Icons.family_restroom,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                ),
                count: '12',
                countLabel: 'Features',
                onTap: () => Navigator.pushNamed(context, '/family'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHubCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required String count,
    required String countLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
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
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                icon,
                size: 120,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          count,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          countLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final features = [
      {'title': 'Notifications', 'icon': Icons.notifications_outlined, 'route': '/notifications', 'color': const Color(0xFFF59E0B)},
      {'title': 'Activity Feed', 'icon': Icons.timeline, 'route': '/activity', 'color': const Color(0xFF3B82F6)},
      {'title': 'Analytics', 'icon': Icons.analytics_outlined, 'route': '/analytics', 'color': const Color(0xFF10B981)},
      {'title': 'Social Hub', 'icon': Icons.people_outline, 'route': '/social/hubs', 'color': const Color(0xFFEC4899)},
      {'title': 'Search', 'icon': Icons.search, 'route': '/search', 'color': const Color(0xFF8B5CF6)},
      {'title': 'Settings', 'icon': Icons.settings_outlined, 'route': '/profile/settings', 'color': const Color(0xFF6366F1)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return AnimatedListItem(
              index: index,
              delay: 50,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, feature['route'] as String),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (feature['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          feature['icon'] as IconData,
                          color: feature['color'] as Color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feature['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(List<dynamic> recentActivity) {
    if (recentActivity.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          EnhancedEmptyState(
            icon: Icons.history,
            title: 'No Activity Yet',
            message: 'Your recent activities will appear here',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/activity'),
              child: Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...recentActivity.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          return AnimatedListItem(
            index: index,
            delay: 80,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getColorForActivityType(activity['type'] ?? '').withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForActivityType(activity['type'] ?? ''),
                    color: _getColorForActivityType(activity['type'] ?? ''),
                    size: 20,
                  ),
                ),
                title: Text(
                  activity['title'] ?? '',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  activity['description'] ?? '',
                  style: GoogleFonts.inter(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatDate(activity['timestamp']),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  IconData _getIconForActivityType(String type) {
    switch (type) {
      case 'memory':
        return Icons.auto_awesome;
      case 'file':
        return Icons.file_copy_outlined;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment_outlined;
      case 'collection':
        return Icons.collections_outlined;
      default:
        return Icons.circle;
    }
  }

  Color _getColorForActivityType(String type) {
    switch (type) {
      case 'memory':
        return const Color(0xFF6366F1);
      case 'file':
        return const Color(0xFFEC4899);
      case 'like':
        return const Color(0xFFF43F5E);
      case 'comment':
        return const Color(0xFF8B5CF6);
      case 'collection':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      return '';
    }
  }
}
