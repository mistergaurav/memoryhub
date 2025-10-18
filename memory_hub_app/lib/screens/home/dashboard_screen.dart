import 'package:flutter/material.dart';
import '../memories/memory_create_screen.dart';
import '../vault/vault_upload_screen.dart';
import '../collections/collections_screen.dart';
import '../analytics/analytics_screen.dart';
import '../notifications/notifications_screen.dart';
import '../activity/activity_feed_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Load from API endpoint /api/v1/hub/dashboard
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _stats = {
          'memories': 42,
          'files': 156,
          'collections': 8,
          'followers': 23,
        };
        _recentActivity = [
          {
            'type': 'memory',
            'title': 'Added new memory',
            'description': 'Summer Vacation 2024',
            'time': '2 hours ago',
            'icon': Icons.photo_library,
            'color': Colors.blue,
          },
          {
            'type': 'follow',
            'title': 'New follower',
            'description': 'John Doe started following you',
            'time': '5 hours ago',
            'icon': Icons.person_add,
            'color': Colors.green,
          },
          {
            'type': 'collection',
            'title': 'Collection updated',
            'description': 'Added 3 memories to Family Photos',
            'time': '1 day ago',
            'icon': Icons.collections,
            'color': Colors.purple,
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Memory Hub'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.indigo.shade400,
                      Colors.purple.shade400,
                      Colors.pink.shade300,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 60,
                      right: 20,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 80,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildQuickActionCard(
                        title: 'New Memory',
                        icon: Icons.add_photo_alternate,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        onTap: () => Navigator.pushNamed(context, '/memories/create'),
                      ),
                      _buildQuickActionCard(
                        title: 'Upload File',
                        icon: Icons.cloud_upload,
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600],
                        ),
                        onTap: () => Navigator.pushNamed(context, '/vault/upload'),
                      ),
                      _buildQuickActionCard(
                        title: 'Search',
                        icon: Icons.search,
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.purple.shade600],
                        ),
                        onTap: () => Navigator.pushNamed(context, '/search'),
                      ),
                      _buildQuickActionCard(
                        title: 'Analytics',
                        icon: Icons.analytics,
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.orange.shade600],
                        ),
                        onTap: () => Navigator.pushNamed(context, '/analytics'),
                      ),
                      _buildQuickActionCard(
                        title: 'Stories',
                        icon: Icons.auto_stories,
                        gradient: LinearGradient(
                          colors: [Colors.pink.shade400, Colors.pink.shade600],
                        ),
                        onTap: () => Navigator.pushNamed(context, '/stories'),
                      ),
                      _buildQuickActionCard(
                        title: 'Family Hub',
                        icon: Icons.family_restroom,
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.teal.shade600],
                        ),
                        onTap: () => Navigator.pushNamed(context, '/family'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'More Features',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeaturesList(),
                  const SizedBox(height: 32),
                  const Text(
                    'Your Stats',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Memories',
                                _stats['memories'] ?? 0,
                                Icons.photo_library,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Files',
                                _stats['files'] ?? 0,
                                Icons.insert_drive_file,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Collections',
                          _stats['collections'] ?? 0,
                          Icons.collections,
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Followers',
                          _stats['followers'] ?? 0,
                          Icons.people,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Activity',
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
                              builder: (context) => const ActivityFeedScreen(),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _recentActivity.isEmpty
                          ? Card(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No recent activity',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentActivity.length,
                              itemBuilder: (context, index) {
                                final activity = _recentActivity[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (activity['color'] as Color).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        activity['icon'],
                                        color: activity['color'],
                                      ),
                                    ),
                                    title: Text(
                                      activity['title'],
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(activity['description']),
                                    trailing: Text(
                                      activity['time'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ),
        ],
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
        icon: const Icon(Icons.add),
        label: const Text('Create Memory'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {'title': 'Social Hubs', 'icon': Icons.groups, 'route': '/social/hubs', 'subtitle': 'Connect with communities'},
      {'title': 'User Search', 'icon': Icons.search, 'route': '/social/search', 'subtitle': 'Find people'},
      {'title': 'Collections', 'icon': Icons.collections, 'route': '/collections', 'subtitle': 'Organize memories'},
      {'title': 'Activity Feed', 'icon': Icons.feed, 'route': '/activity', 'subtitle': 'See what\'s happening'},
      {'title': 'Tags', 'icon': Icons.label, 'route': '/tags', 'subtitle': 'Organize with tags'},
      {'title': 'Reminders', 'icon': Icons.notifications_active, 'route': '/reminders', 'subtitle': 'Set memory reminders'},
      {'title': 'Voice Notes', 'icon': Icons.mic, 'route': '/voice-notes', 'subtitle': 'Record voice memories'},
      {'title': 'Templates', 'icon': Icons.description, 'route': '/templates', 'subtitle': 'Memory templates'},
      {'title': 'Categories', 'icon': Icons.category, 'route': '/categories', 'subtitle': 'Organize by category'},
      {'title': 'Places', 'icon': Icons.place, 'route': '/places', 'subtitle': 'Location-based memories'},
      {'title': 'Comments', 'icon': Icons.comment, 'route': '/comments', 'subtitle': 'View all comments'},
      {'title': 'Sharing', 'icon': Icons.share, 'route': '/sharing/management', 'subtitle': 'Manage shared links'},
      {'title': 'Export Data', 'icon': Icons.download, 'route': '/export', 'subtitle': 'Backup your data'},
      {'title': 'Scheduled Posts', 'icon': Icons.schedule, 'route': '/scheduled-posts', 'subtitle': 'Schedule content'},
      {'title': 'Genealogy Tree', 'icon': Icons.account_tree, 'route': '/family/genealogy', 'subtitle': 'Family tree'},
      {'title': 'Health Records', 'icon': Icons.health_and_safety, 'route': '/family/health', 'subtitle': 'Family health'},
      {'title': 'Recipes', 'icon': Icons.restaurant, 'route': '/family/recipes', 'subtitle': 'Family recipes'},
      {'title': 'Traditions', 'icon': Icons.celebration, 'route': '/family/traditions', 'subtitle': 'Family customs'},
      {'title': 'Legacy Letters', 'icon': Icons.mail, 'route': '/family/letters', 'subtitle': 'Write to future'},
      {'title': 'Admin Panel', 'icon': Icons.admin_panel_settings, 'route': '/admin', 'subtitle': 'Administration'},
    ];

    return Card(
      child: Column(
        children: features.map((feature) => ListTile(
          leading: Icon(feature['icon'] as IconData, color: Theme.of(context).colorScheme.primary),
          title: Text(feature['title'] as String),
          subtitle: Text(feature['subtitle'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, feature['route'] as String),
        )).toList(),
      ),
    );
  }
}
