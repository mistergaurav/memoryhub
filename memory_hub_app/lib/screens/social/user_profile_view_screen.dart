import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/activity_feed_service.dart';
import '../../config/api_config.dart';
import '../../widgets/share_bottom_sheet.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/gradient_container.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../design_system/design_tokens.dart';

class UserProfileViewScreen extends StatefulWidget {
  final String userId;

  const UserProfileViewScreen({super.key, required this.userId});

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ActivityFeedService _activityService = ActivityFeedService();
  
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _userActivity = [];
  
  bool _isLoading = true;
  bool _isFollowLoading = false;
  bool _isLoadingPosts = false;
  bool _isLoadingActivity = false;
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: MemoryHubAnimations.slow,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _loadProfile();
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 0 && _userPosts.isEmpty && !_isLoadingPosts) {
      _loadUserPosts();
    } else if (_tabController.index == 2 && _userActivity.isEmpty && !_isLoadingActivity) {
      _loadUserActivity();
    }
  }

  Future<void> _loadProfile() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/${widget.userId}'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _profile = jsonDecode(response.body);
          _isLoading = false;
        });
        _animationController.forward();
        
        if (_tabController.index == 0) {
          _loadUserPosts();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Failed to load profile');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading profile: ${e.toString()}');
    }
  }

  Future<void> _loadUserPosts() async {
    if (_isLoadingPosts) return;
    setState(() => _isLoadingPosts = true);
    
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/memories/search/?privacy=public&page=1&limit=20'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> memories = jsonDecode(response.body);
        setState(() {
          _userPosts = memories.where((m) => m['owner_id'] == widget.userId).map((e) => e as Map<String, dynamic>).toList();
          _isLoadingPosts = false;
        });
      } else {
        setState(() => _isLoadingPosts = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  Future<void> _loadUserActivity() async {
    if (_isLoadingActivity) return;
    setState(() => _isLoadingActivity = true);
    
    try {
      final data = await _activityService.getUserActivity(
        userId: widget.userId,
        page: 1,
        limit: 20,
      );

      if (!mounted) return;

      setState(() {
        _userActivity = (data['activities'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ?? [];
        _isLoadingActivity = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingActivity = false);
      }
    }
  }

  void _shareProfile() {
    if (_profile == null) return;

    final profileUrl = '${ApiConfig.baseUrl}/profile/${widget.userId}';
    final userName = _profile!['full_name'] ?? _profile!['email'];

    ShareBottomSheet.show(
      context,
      shareUrl: profileUrl,
      title: userName,
      description: _profile!['bio'] ?? 'Check out this profile on Memory Hub',
    );
  }

  Future<void> _toggleFollow() async {
    if (_profile == null || _isFollowLoading) return;

    setState(() => _isFollowLoading = true);
    final wasFollowing = _profile!['is_following'] == true;

    setState(() {
      _profile!['is_following'] = !wasFollowing;
      final stats = _profile!['stats'] as Map<String, dynamic>?;
      if (stats != null) {
        stats['followers'] = (stats['followers'] ?? 0) + (wasFollowing ? -1 : 1);
      }
    });

    try {
      final headers = await _authService.getAuthHeaders();
      if (wasFollowing) {
        await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/social/users/${widget.userId}/follow'),
          headers: headers,
        );
      } else {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/social/users/${widget.userId}/follow'),
          headers: headers,
        );
      }
      if (!mounted) return;
      setState(() => _isFollowLoading = false);
      _showSuccessSnackBar(wasFollowing ? 'Unfollowed' : 'Now following');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profile!['is_following'] = wasFollowing;
        final stats = _profile!['stats'] as Map<String, dynamic>?;
        if (stats != null) {
          stats['followers'] = (stats['followers'] ?? 0) + (wasFollowing ? 1 : -1);
        }
        _isFollowLoading = false;
      });
      _showErrorSnackBar('Failed to ${wasFollowing ? 'unfollow' : 'follow'} user');
    }
  }

  void _showFollowersList() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/social/users/${widget.userId}/followers'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> followers = jsonDecode(response.body);
        _showUserListDialog('Followers', followers);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load followers');
    }
  }

  void _showFollowingList() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/social/users/${widget.userId}/following'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> following = jsonDecode(response.body);
        _showUserListDialog('Following', following);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load following');
    }
  }

  void _showUserListDialog(String title, List<dynamic> users) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: MemoryHubSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MemoryHubColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(MemoryHubSpacing.lg),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: MemoryHubTypography.h3,
                    fontWeight: MemoryHubTypography.bold,
                  ),
                ),
              ),
              const Divider(),
              Expanded(child: users.isEmpty
                    ? Center(
                        child: Text('No $title yet'),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['user_avatar'] != null
                                  ? NetworkImage(ApiConfig.getAssetUrl(user['user_avatar']))
                                  : null,
                              child: user['user_avatar'] == null
                                  ? Text(user['user_name']?[0]?.toUpperCase() ?? '?')
                                  : null,
                            ),
                            title: Text(user['user_name'] ?? 'Unknown'),
                            subtitle: user['user_bio'] != null
                                ? Text(
                                    user['user_bio'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              if (user['user_id'] != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfileViewScreen(
                                      userId: user['user_id'],
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: MemoryHubSpacing.md, bottom: MemoryHubSpacing.lg),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MemoryHubColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined, color: MemoryHubColors.red500),
                title: const Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  _showErrorSnackBar('Report feature coming soon');
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined, color: MemoryHubColors.red500),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _showErrorSnackBar('Block feature coming soon');
                },
              ),
              const SizedBox(height: MemoryHubSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MemoryHubColors.green500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MemoryHubColors.red500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: _buildLoadingShimmer(),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: MemoryHubColors.indigo600,
          foregroundColor: Colors.white,
        ),
        body: EnhancedEmptyState(
          icon: Icons.person_off_outlined,
          title: 'Profile Not Found',
          message: 'This user profile could not be loaded.',
          actionLabel: 'Retry',
          onAction: _loadProfile,
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareProfile,
            tooltip: 'Share Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
          if (_tabController.index == 0) {
            await _loadUserPosts();
          } else if (_tabController.index == 2) {
            await _loadUserActivity();
          }
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeroHeader(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: MemoryHubSpacing.xl),
                      _buildStatsRow(),
                      const SizedBox(height: MemoryHubSpacing.xl),
                      _buildActionButtons(),
                      const SizedBox(height: MemoryHubSpacing.xl),
                      _buildTabbedContent(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          GradientContainer(
            height: 380,
            colors: [
              MemoryHubColors.indigo600,
              MemoryHubColors.purple600,
              MemoryHubColors.pink500,
            ],
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const ShimmerBox(
                      width: 140,
                      height: 140,
                      borderRadius: BorderRadius.all(Radius.circular(70)),
                    ),
                    const SizedBox(height: MemoryHubSpacing.lg),
                    ShimmerBox(
                      width: 150,
                      height: 20,
                      borderRadius: MemoryHubBorderRadius.smRadius,
                    ),
                    const SizedBox(height: MemoryHubSpacing.sm),
                    ShimmerBox(
                      width: 200,
                      height: 16,
                      borderRadius: MemoryHubBorderRadius.smRadius,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(MemoryHubSpacing.lg),
            child: Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : MemoryHubSpacing.sm,
                      right: index == 2 ? 0 : MemoryHubSpacing.sm,
                    ),
                    child: ShimmerBox(
                      height: 120,
                      borderRadius: MemoryHubBorderRadius.lgRadius,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    final username = _profile!['username'];
    final fullName = _profile!['full_name'] ?? _profile!['email'];
    final bio = _profile!['bio'];
    final avatarUrl = _profile!['avatar_url'];
    final createdAt = _profile!['created_at'];
    final isOwnProfile = false; // Will be checked asynchronously

    String memberSince = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        memberSince = 'Member since ${DateFormat('MMM yyyy').format(date)}';
      } catch (e) {
        memberSince = '';
      }
    }

    return SliverToBoxAdapter(
      child: GradientContainer(
        height: 380,
        colors: [
          MemoryHubColors.indigo600,
          MemoryHubColors.purple600,
          MemoryHubColors.pink500,
        ],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MemoryHubSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'profile_avatar_${widget.userId}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(ApiConfig.getAssetUrl(avatarUrl))
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              fullName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: MemoryHubColors.indigo600,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: MemoryHubSpacing.lg),
                if (username != null)
                  Text(
                    '@$username',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                const SizedBox(height: MemoryHubSpacing.xs),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: MemoryHubSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg),
                    child: Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: MemoryHubSpacing.md),
                if (memberSince.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        memberSince,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: MemoryHubSpacing.lg),
                if (!isOwnProfile)
                  AnimatedScale(
                    scale: _isFollowLoading ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: ElevatedButton.icon(
                      onPressed: _isFollowLoading ? null : _toggleFollow,
                      icon: _isFollowLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(MemoryHubColors.indigo600),
                              ),
                            )
                          : Icon(
                              _profile!['is_following'] == true
                                  ? Icons.person_remove_outlined
                                  : Icons.person_add_outlined,
                              size: 20,
                            ),
                      label: Text(
                        _profile!['is_following'] == true ? 'Unfollow' : 'Follow',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: MemoryHubColors.indigo600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = _profile!['stats'] as Map<String, dynamic>? ?? {};
    final postsCount = stats['memories'] ?? 0;
    final followersCount = stats['followers'] ?? 0;
    final followingCount = stats['following'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg),
      child: Row(children: [
          Expanded(
            child: _buildStatCard(
              label: 'Posts',
              value: postsCount.toString(),
              icon: Icons.auto_awesome,
              color: MemoryHubColors.indigo500,
              onTap: () {
                _tabController.animateTo(0);
              },
            ),
          ),
          const SizedBox(width: MemoryHubSpacing.md),
          Expanded(child: _buildStatCard(
              label: 'Followers',
              value: followersCount.toString(),
              icon: Icons.people,
              color: MemoryHubColors.purple500,
              onTap: _showFollowersList,
            ),
          ),
          const SizedBox(width: MemoryHubSpacing.md),
          Expanded(child: _buildStatCard(
              label: 'Following',
              value: followingCount.toString(),
              icon: Icons.person_add,
              color: MemoryHubColors.pink500,
              onTap: _showFollowingList,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GlassmorphicCard(
      blur: 20,
      opacity: 0.15,
      borderRadius: MemoryHubBorderRadius.lgRadius,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: MemoryHubBorderRadius.lgRadius,
        child: Padding(
          padding: const EdgeInsets.all(MemoryHubSpacing.lg),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: MemoryHubSpacing.sm),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
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
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: GlassmorphicCard(
              blur: 15,
              opacity: 0.1,
              borderRadius: MemoryHubBorderRadius.lgRadius,
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () {
                  _showErrorSnackBar('Messaging feature coming soon');
                },
                borderRadius: MemoryHubBorderRadius.lgRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: MemoryHubSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.message_outlined, size: 20),
                      const SizedBox(width: MemoryHubSpacing.sm),
                      const Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: MemoryHubSpacing.md),
          Expanded(
            child: GlassmorphicCard(
              blur: 15,
              opacity: 0.1,
              borderRadius: MemoryHubBorderRadius.lgRadius,
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: _shareProfile,
                borderRadius: MemoryHubBorderRadius.lgRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: MemoryHubSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.share_outlined, size: 20),
                      const SizedBox(width: MemoryHubSpacing.sm),
                      const Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: MemoryHubSpacing.md),
          GlassmorphicCard(
            blur: 15,
            opacity: 0.1,
            borderRadius: MemoryHubBorderRadius.lgRadius,
            padding: const EdgeInsets.all(MemoryHubSpacing.md),
            child: InkWell(
              onTap: _showMoreOptions,
              borderRadius: MemoryHubBorderRadius.lgRadius,
              child: const Icon(Icons.more_horiz, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabbedContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg),
          child: GlassmorphicCard(
            blur: 15,
            opacity: 0.1,
            borderRadius: MemoryHubBorderRadius.lgRadius,
            padding: const EdgeInsets.all(MemoryHubSpacing.xs),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MemoryHubColors.indigo500,
                    MemoryHubColors.purple500,
                  ],
                ),
                borderRadius: MemoryHubBorderRadius.mdRadius,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'About'),
                Tab(text: 'Activity'),
              ],
            ),
          ),
        ),
        const SizedBox(height: MemoryHubSpacing.lg),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsTab(),
              _buildAboutTab(),
              _buildActivityTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_userPosts.isEmpty) {
      return EnhancedEmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'No Posts Yet',
        message: 'This user hasn\'t shared any public posts yet.',
        gradientColors: [
          MemoryHubColors.indigo500.withOpacity(0.1),
          MemoryHubColors.purple500.withOpacity(0.1),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return GlassmorphicCard(
      blur: 15,
      opacity: 0.1,
      borderRadius: MemoryHubBorderRadius.lgRadius,
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      margin: const EdgeInsets.only(bottom: MemoryHubSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post['title'] ?? 'Untitled',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.sm),
          Text(
            post['content'] ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          Row(
            children: [
              Icon(
                Icons.favorite_border,
                size: 18,
                color: MemoryHubColors.gray500,
              ),
              const SizedBox(width: 4),
              Text(
                '${post['like_count'] ?? 0}',
                style: const TextStyle(
                  fontSize: 12,
                  color: MemoryHubColors.gray600,
                ),
              ),
              const SizedBox(width: MemoryHubSpacing.lg),
              Icon(
                Icons.comment_outlined,
                size: 18,
                color: MemoryHubColors.gray500,
              ),
              const SizedBox(width: 4),
              Text(
                '${post['comment_count'] ?? 0}',
                style: const TextStyle(
                  fontSize: 12,
                  color: MemoryHubColors.gray600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    final bio = _profile!['bio'];
    final city = _profile!['city'];
    final country = _profile!['country'];
    final website = _profile!['website'];
    final email = _profile!['email'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg),
      child: GlassmorphicCard(
        blur: 15,
        opacity: 0.1,
        borderRadius: MemoryHubBorderRadius.lgRadius,
        padding: const EdgeInsets.all(MemoryHubSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: MemoryHubColors.indigo500),
                SizedBox(width: MemoryHubSpacing.sm),
                Text(
                  'About',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: MemoryHubSpacing.lg),
              Text(
                bio,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
            if (city != null || country != null) ...[
              const SizedBox(height: MemoryHubSpacing.lg),
              const Divider(),
              const SizedBox(height: MemoryHubSpacing.lg),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: MemoryHubColors.gray500),
                  const SizedBox(width: MemoryHubSpacing.sm),
                  Expanded(
                    child: Text(
                      [city, country].where((e) => e != null && e.isNotEmpty).join(', '),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ],
            if (website != null && website.isNotEmpty) ...[
              const SizedBox(height: MemoryHubSpacing.lg),
              const Divider(),
              const SizedBox(height: MemoryHubSpacing.lg),
              Row(
                children: [
                  const Icon(Icons.link, size: 20, color: MemoryHubColors.gray500),
                  const SizedBox(width: MemoryHubSpacing.sm),
                  Expanded(
                    child: Text(
                      website.replaceAll(RegExp(r'https?://'), ''),
                      style: const TextStyle(
                        fontSize: 15,
                        color: MemoryHubColors.indigo500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (email != null && email.isNotEmpty) ...[
              const SizedBox(height: MemoryHubSpacing.lg),
              const Divider(),
              const SizedBox(height: MemoryHubSpacing.lg),
              Row(
                children: [
                  const Icon(Icons.email, size: 20, color: MemoryHubColors.gray500),
                  const SizedBox(width: MemoryHubSpacing.sm),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ],
            if (bio == null && city == null && website == null && email == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: MemoryHubSpacing.xl),
                child: Center(
                  child: Text(
                    'No additional information available',
                    style: TextStyle(
                      color: MemoryHubColors.gray500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    if (_isLoadingActivity) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_userActivity.isEmpty) {
      return EnhancedEmptyState(
        icon: Icons.timeline_outlined,
        title: 'No Activity Yet',
        message: 'This user doesn\'t have any recent activity to display.',
        gradientColors: [
          MemoryHubColors.purple500.withOpacity(0.1),
          MemoryHubColors.pink500.withOpacity(0.1),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg),
      itemCount: _userActivity.length,
      itemBuilder: (context, index) {
        final activity = _userActivity[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final activityType = activity['activity_type'] ?? 'unknown';
    IconData icon;
    Color iconColor;

    switch (activityType) {
      case 'post_created':
        icon = Icons.add_circle_outline;
        iconColor = MemoryHubColors.green500;
        break;
      case 'post_liked':
        icon = Icons.favorite_outline;
        iconColor = MemoryHubColors.red500;
        break;
      case 'post_commented':
        icon = Icons.comment_outlined;
        iconColor = MemoryHubColors.indigo500;
        break;
      case 'user_followed':
        icon = Icons.person_add_outlined;
        iconColor = MemoryHubColors.purple500;
        break;
      default:
        icon = Icons.circle_outlined;
        iconColor = MemoryHubColors.gray500;
    }

    return GlassmorphicCard(
      blur: 15,
      opacity: 0.1,
      borderRadius: MemoryHubBorderRadius.lgRadius,
      padding: const EdgeInsets.all(MemoryHubSpacing.lg),
      margin: const EdgeInsets.only(bottom: MemoryHubSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(MemoryHubSpacing.sm),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: MemoryHubBorderRadius.smRadius,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: MemoryHubSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'Activity',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: MemoryHubSpacing.xs),
                if (activity['description'] != null)
                  Text(
                    activity['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (activity['timestamp'] != null) ...[
                  const SizedBox(height: MemoryHubSpacing.xs),
                  Text(
                    _formatTimestamp(activity['timestamp']),
                    style: const TextStyle(
                      fontSize: 11,
                      color: MemoryHubColors.gray500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return DateFormat('MMM d, y').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}
