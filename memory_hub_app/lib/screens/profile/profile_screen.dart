import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../config/api_config.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/gradient_container.dart';
import '../../design_system/design_tokens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _loadProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      _animationController.forward();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MemoryHubColors.red500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  String _getInitial() {
    if (_user?.fullName != null && _user!.fullName!.isNotEmpty) {
      return _user!.fullName!.substring(0, 1).toUpperCase();
    }
    if (_user?.email != null && _user!.email.isNotEmpty) {
      return _user!.email.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  String _getUsername() {
    if (_user?.username != null && _user!.username!.isNotEmpty) {
      return _user!.username!;
    }
    if (_user?.email != null && _user!.email.isNotEmpty && _user!.email.contains('@')) {
      return _user!.email.split('@')[0];
    }
    return 'user';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                MemoryHubColors.indigo500,
                MemoryHubColors.purple500,
                MemoryHubColors.pink500,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_error != null || _user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: MemoryHubColors.red500),
              const SizedBox(height: MemoryHubSpacing.lg),
              Text(_error ?? 'Failed to load profile'),
              const SizedBox(height: MemoryHubSpacing.lg),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pushNamed('/profile/settings'),
            tooltip: 'Settings',
          ),
          Padding(
            padding: const EdgeInsets.only(right: MemoryHubSpacing.sm),
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: MemoryHubBorderRadius.mdRadius,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildGlassmorphicHeader(isDark),
            _buildStatsRow(),
            _buildProfileSections(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassmorphicHeader(bool isDark) {
    final stats = _user!.stats ?? {};
    final followersCount = stats['followers'] ?? 0;
    final followingCount = stats['following'] ?? 0;

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Stack(
            children: [
              GradientContainer(
                height: 320,
                colors: [
                  MemoryHubColors.indigo600,
                  MemoryHubColors.purple600,
                  MemoryHubColors.pink500,
                ],
                child: Container(),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: Container(color: Colors.black.withOpacity(0.1)),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Hero(
                      tag: 'profile_avatar',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white,
                          backgroundImage: _user!.avatarUrl != null
                              ? NetworkImage(ApiConfig.getAssetUrl(_user!.avatarUrl!))
                              : null,
                          child: _user!.avatarUrl == null
                              ? Text(
                                  _getInitial(),
                                  style: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.bold,
                                    color: MemoryHubColors.indigo600,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: MemoryHubSpacing.lg),
                    Text(
                      _user!.fullName ?? 'User',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MemoryHubSpacing.xs),
                    Text(
                      '@${_getUsername()}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                      const SizedBox(height: MemoryHubSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.xxl),
                        child: Text(
                          _user!.bio!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.95),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: MemoryHubSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFollowStat('Following', followingCount),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withOpacity(0.3),
                          margin: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.xl),
                        ),
                        _buildFollowStat('Followers', followersCount),
                      ],
                    ),
                    const SizedBox(height: MemoryHubSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final stats = _user!.stats ?? {};
    final memories = stats['memories'] ?? 0;
    final files = stats['files'] ?? 0;
    final collections = stats['collections'] ?? 0;

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(MemoryHubSpacing.lg),
          child: Row(
            children: [
              Expanded(child: _buildStatCard('Posts', memories, Icons.auto_awesome, MemoryHubColors.indigo500)),
              const SizedBox(width: MemoryHubSpacing.md),
              Expanded(child: _buildStatCard('Files', files, Icons.folder_outlined, MemoryHubColors.purple500)),
              const SizedBox(width: MemoryHubSpacing.md),
              Expanded(child: _buildStatCard('Albums', collections, Icons.collections_outlined, MemoryHubColors.pink500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return GlassmorphicCard(
      blur: 20,
      opacity: 0.15,
      borderRadius: MemoryHubBorderRadius.lgRadius,
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: MemoryHubSpacing.sm),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSections() {
    return SliverPadding(
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildEditProfileCard(),
          const SizedBox(height: MemoryHubSpacing.lg),
          _buildQuickActionsSection(),
          const SizedBox(height: MemoryHubSpacing.lg),
          _buildAccountInfoSection(),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  Widget _buildEditProfileCard() {
    return GlassmorphicCard(
      blur: 15,
      opacity: 0.1,
      borderRadius: MemoryHubBorderRadius.lgRadius,
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      gradientColors: [
        MemoryHubColors.indigo500.withOpacity(0.1),
        MemoryHubColors.purple500.withOpacity(0.1),
      ],
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).pushNamed('/profile/edit');
          if (result == true) {
            _loadProfile();
          }
        },
        borderRadius: MemoryHubBorderRadius.lgRadius,
        child: Padding(
          padding: const EdgeInsets.all(MemoryHubSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(MemoryHubSpacing.md),
                decoration: BoxDecoration(
                  color: MemoryHubColors.indigo500.withOpacity(0.2),
                  borderRadius: MemoryHubBorderRadius.mdRadius,
                ),
                child: const Icon(Icons.edit_outlined, color: MemoryHubColors.indigo600, size: 24),
              ),
              const SizedBox(width: MemoryHubSpacing.lg),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Update your profile information',
                      style: TextStyle(fontSize: 13, color: MemoryHubColors.gray600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: MemoryHubColors.gray400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final actions = [
      {'title': 'My Memories', 'icon': Icons.auto_awesome, 'route': '/memories', 'color': MemoryHubColors.indigo500},
      {'title': 'Collections', 'icon': Icons.collections_outlined, 'route': '/collections', 'color': MemoryHubColors.purple500},
      {'title': 'Files', 'icon': Icons.folder_outlined, 'route': '/vault', 'color': MemoryHubColors.pink500},
      {'title': 'Analytics', 'icon': Icons.analytics_outlined, 'route': '/analytics', 'color': MemoryHubColors.cyan500},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: MemoryHubSpacing.sm, bottom: MemoryHubSpacing.md),
          child: Text(
            'Quick Access',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: MemoryHubSpacing.md,
            mainAxisSpacing: MemoryHubSpacing.md,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return GlassmorphicCard(
              blur: 15,
              opacity: 0.1,
              borderRadius: MemoryHubBorderRadius.lgRadius,
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, action['route'] as String),
                borderRadius: MemoryHubBorderRadius.lgRadius,
                child: Container(
                  padding: const EdgeInsets.all(MemoryHubSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(MemoryHubSpacing.sm),
                        decoration: BoxDecoration(
                          color: (action['color'] as Color).withOpacity(0.2),
                          borderRadius: MemoryHubBorderRadius.smRadius,
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          color: action['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: MemoryHubSpacing.sm),
                      Text(
                        action['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

  Widget _buildAccountInfoSection() {
    return GlassmorphicCard(
      blur: 15,
      opacity: 0.1,
      borderRadius: MemoryHubBorderRadius.lgRadius,
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: MemoryHubSpacing.lg),
          _buildInfoRow(Icons.email_outlined, 'Email', _user!.email),
          const Divider(height: MemoryHubSpacing.xl),
          _buildInfoRow(Icons.calendar_today_outlined, 'Member Since', 
            '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}'),
          const Divider(height: MemoryHubSpacing.xl),
          _buildInfoRow(Icons.verified_user_outlined, 'Account Status', 
            _user!.isActive ? 'Active' : 'Inactive',
            statusColor: _user!.isActive ? MemoryHubColors.green500 : MemoryHubColors.red500),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: MemoryHubColors.gray500),
        const SizedBox(width: MemoryHubSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: MemoryHubColors.gray600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
