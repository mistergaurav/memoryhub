import 'package:flutter/material.dart';
import 'dart:ui';
import '../../design_system/design_tokens.dart';
import '../../design_system/layout/gap.dart';
import '../../design_system/layout/padded.dart';
import '../../design_system/components/buttons/primary_button.dart';
import '../../design_system/components/surfaces/app_card.dart';
import '../../design_system/components/feedback/app_dialog.dart';
import '../../design_system/utils/context_ext.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../config/api_config.dart';
import '../../widgets/gradient_container.dart';

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
    final confirm = await AppDialog.confirm(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      isDangerous: true,
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
          decoration: const BoxDecoration(
            gradient: MemoryHubGradients.primary,
          ),
          child: Center(
            child: CircularProgressIndicator(color: context.colors.onPrimary),
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
              const VGap.lg(),
              Text(_error ?? 'Failed to load profile'),
              const VGap.lg(),
              PrimaryButton(
                onPressed: _loadProfile,
                label: 'Retry',
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: context.colors.surface.withValues(alpha: 0),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.colors.onPrimary),
            onPressed: () => Navigator.of(context).pushNamed('/profile/settings'),
            tooltip: 'Settings',
          ),
          Padded.only(
            right: MemoryHubSpacing.sm,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.onPrimary.withValues(alpha: 0.2),
                foregroundColor: context.colors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: MemoryHubBorderRadius.mdRadius,
                  side: BorderSide(color: context.colors.onPrimary.withValues(alpha: 0.3)),
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
                  child: Container(color: context.colors.onSurface.withValues(alpha: 0.1)),
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
                          border: Border.all(color: context.colors.onPrimary, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.onSurface.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: context.colors.surface,
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
                    const VGap.lg(),
                    Text(
                      _user!.fullName ?? 'User',
                      style: context.text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onPrimary,
                        shadows: [
                          Shadow(
                            color: context.colors.onSurface.withValues(alpha: 0.26),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const VGap.xs(),
                    Text(
                      '@${_getUsername()}',
                      style: context.text.bodyLarge?.copyWith(
                        color: context.colors.onPrimary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                      const VGap.md(),
                      Padded.symmetric(
                        horizontal: MemoryHubSpacing.xxl,
                        child: Text(
                          _user!.bio!,
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.onPrimary.withValues(alpha: 0.95),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const VGap.lg(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFollowStat('Following', followingCount),
                        Padded.symmetric(
                          horizontal: MemoryHubSpacing.xl,
                          child: Container(
                            width: 1,
                            height: 30,
                            color: context.colors.onPrimary.withValues(alpha: 0.3),
                          ),
                        ),
                        _buildFollowStat('Followers', followersCount),
                      ],
                    ),
                    const VGap.xl(),
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
          style: context.text.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.onPrimary,
          ),
        ),
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onPrimary.withValues(alpha: 0.8),
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
        child: Padded.all(
          MemoryHubSpacing.lg,
          child: Row(
            children: [
              Expanded(child: _buildStatCard('Posts', memories, Icons.auto_awesome, MemoryHubColors.indigo500)),
              const HGap.md(),
              Expanded(child: _buildStatCard('Files', files, Icons.folder_outlined, MemoryHubColors.purple500)),
              const HGap.md(),
              Expanded(child: _buildStatCard('Albums', collections, Icons.collections_outlined, MemoryHubColors.pink500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const VGap.sm(),
          Text(
            value.toString(),
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const VGap.xs(),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: context.text.bodyMedium?.color?.withValues(alpha: 0.7),
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
          const VGap.lg(),
          _buildQuickActionsSection(),
          const VGap.lg(),
          _buildAccountInfoSection(),
          const VGap(100),
        ]),
      ),
    );
  }

  Widget _buildEditProfileCard() {
    return AppCard(
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      onTap: () async {
        final result = await Navigator.of(context).pushNamed('/profile/edit');
        if (result == true) {
          _loadProfile();
        }
      },
      child: Padded.all(
        MemoryHubSpacing.sm,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(MemoryHubSpacing.md),
              decoration: BoxDecoration(
                color: MemoryHubColors.indigo500.withValues(alpha: 0.2),
                borderRadius: MemoryHubBorderRadius.mdRadius,
              ),
              child: const Icon(Icons.edit_outlined, color: MemoryHubColors.indigo600, size: 24),
            ),
            const HGap.lg(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Profile',
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const VGap.xxs(),
                  Text(
                    'Update your profile information',
                    style: context.text.bodySmall?.copyWith(
                      color: MemoryHubColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: MemoryHubColors.gray400),
          ],
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
        Padded.only(
          left: MemoryHubSpacing.sm,
          bottom: MemoryHubSpacing.md,
          child: Text(
            'Quick Access',
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
            return AppCard(
              padding: EdgeInsets.zero,
              onTap: () => Navigator.pushNamed(context, action['route'] as String),
              child: Padded.all(
                MemoryHubSpacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(MemoryHubSpacing.sm),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withValues(alpha: 0.2),
                        borderRadius: MemoryHubBorderRadius.smRadius,
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const VGap.sm(),
                    Text(
                      action['title'] as String,
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildAccountInfoSection() {
    return AppCard(
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const VGap.lg(),
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
        const HGap.md(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.text.bodySmall?.copyWith(
                  color: MemoryHubColors.gray600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const VGap.xxs(),
              Text(
                value,
                style: context.text.bodyMedium?.copyWith(
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
