import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../config/api_config.dart';
import '../../widgets/gradient_container.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/share_bottom_sheet.dart';
import '../../widgets/animated_stat_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await _apiService.getCurrentUser();
      setState(() {
        _user = user;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _shareProfile() {
    if (_user == null) return;
    
    final profileUrl = '${ApiConfig.baseUrl}/profile/${_user!.id}';
    final userName = _user!.fullName ?? _user!.email;
    
    ShareBottomSheet.show(
      context,
      shareUrl: profileUrl,
      title: userName,
      description: _user!.bio ?? 'Check out my profile on Memory Hub',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Failed to load profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: CustomScrollView(
          slivers: [
            _buildProfileHeader(),
            _buildProfileContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          GradientContainer(
            height: 240,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.tertiary,
            ],
            child: Container(),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareProfile,
                  tooltip: 'Share Profile',
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/profile/settings');
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: _user!.avatarUrl != null
                        ? NetworkImage(ApiConfig.getAssetUrl(_user!.avatarUrl!))
                        : null,
                    child: _user!.avatarUrl == null
                        ? Text(
                            _user!.email.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 48, color: Colors.white),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _user!.fullName ?? _user!.email,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user!.email,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (_user!.bio != null) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _user!.bio!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).pushNamed('/profile/edit');
                    if (result == true) {
                      _loadProfile();
                    }
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_user!.stats != null) _buildEnhancedStatsSection(),
            const SizedBox(height: 24),
            _buildQuickLinks(),
            const SizedBox(height: 24),
            _buildAchievementsSection(),
            const SizedBox(height: 24),
            _buildAccountSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatsSection() {
    final stats = _user!.stats!;
    final statItems = [
      {'label': 'Memories', 'value': stats['memories'] ?? 0, 'icon': Icons.auto_awesome, 'color': const Color(0xFF6366F1)},
      {'label': 'Files', 'value': stats['files'] ?? 0, 'icon': Icons.folder_outlined, 'color': const Color(0xFFEC4899)},
      {'label': 'Collections', 'value': stats['collections'] ?? 0, 'icon': Icons.collections_outlined, 'color': const Color(0xFF8B5CF6)},
      {'label': 'Followers', 'value': stats['followers'] ?? 0, 'icon': Icons.people_outline, 'color': const Color(0xFF10B981)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Statistics',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: statItems.length,
          itemBuilder: (context, index) {
            final item = statItems[index];
            return AnimatedListItem(
              index: index,
              delay: 80,
              child: AnimatedStatCard(
                label: item['label'] as String,
                value: item['value'] as int,
                icon: item['icon'] as IconData,
                color: item['color'] as Color,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickLinks() {
    final links = [
      {'title': 'My Memories', 'icon': Icons.auto_awesome, 'route': '/memories', 'color': const Color(0xFF6366F1)},
      {'title': 'My Collections', 'icon': Icons.collections_outlined, 'route': '/collections', 'color': const Color(0xFFEC4899)},
      {'title': 'My Files', 'icon': Icons.folder_outlined, 'route': '/vault', 'color': const Color(0xFF8B5CF6)},
      {'title': 'Analytics', 'icon': Icons.analytics_outlined, 'route': '/analytics', 'color': const Color(0xFF10B981)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: links.length,
          itemBuilder: (context, index) {
            final link = links[index];
            return AnimatedListItem(
              index: index,
              delay: 100,
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, link['route'] as String),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (link['color'] as Color).withOpacity(0.8),
                        (link['color'] as Color),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (link['color'] as Color).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        link['icon'] as IconData,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          link['title'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _buildAchievementsSection() {
    final achievements = [
      {'title': 'Early Adopter', 'icon': Icons.stars, 'color': const Color(0xFFFCD34D)},
      {'title': 'Memory Keeper', 'icon': Icons.workspace_premium, 'color': const Color(0xFF8B5CF6)},
      {'title': 'Social Butterfly', 'icon': Icons.people, 'color': const Color(0xFFEC4899)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: achievements.asMap().entries.map((entry) {
              final index = entry.key;
              final achievement = entry.value;
              return AnimatedListItem(
                index: index,
                delay: 120,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  width: 140,
                  decoration: BoxDecoration(
                    color: (achievement['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (achievement['color'] as Color).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: achievement['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          achievement['icon'] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        achievement['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed('/profile/settings'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings & Privacy',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your account and preferences',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
