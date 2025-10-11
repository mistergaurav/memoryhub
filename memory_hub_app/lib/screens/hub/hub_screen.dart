import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/hub_item.dart';
import 'package:intl/intl.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stats = _dashboardData?['stats'] ?? {};
    final quickLinks = _dashboardData?['quick_links'] ?? [];
    final recentActivity = _dashboardData?['recent_activity'] ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatsSection(stats),
            const SizedBox(height: 32),
            _buildQuickActionsSection(quickLinks),
            const SizedBox(height: 32),
            _buildRecentActivitySection(recentActivity),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Memories',
          stats['memories_count']?.toString() ?? '0',
          Icons.memory,
          Colors.purple,
        ),
        _buildStatCard(
          'Files',
          stats['files_count']?.toString() ?? '0',
          Icons.file_copy,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Views',
          stats['total_views']?.toString() ?? '0',
          Icons.visibility,
          Colors.green,
        ),
        _buildStatCard(
          'Total Likes',
          stats['total_likes']?.toString() ?? '0',
          Icons.favorite,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(List<dynamic> quickLinks) {
    return Column(
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
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: quickLinks.map((link) {
            return _buildQuickActionButton(
              link['title'] ?? '',
              _getIconForAction(link['icon'] ?? ''),
              link['url'] ?? '',
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, String route) {
    return ElevatedButton.icon(
      onPressed: () {
        if (route == '/memories/new') {
          Navigator.of(context).pushNamed('/memories/create');
        } else if (route == '/vault/upload') {
          Navigator.of(context).pushNamed('/vault/upload');
        }
      },
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildRecentActivitySection(List<dynamic> recentActivity) {
    if (recentActivity.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...recentActivity.take(5).map((activity) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                _getIconForActivityType(activity['type'] ?? ''),
                color: Colors.deepPurple,
              ),
              title: Text(activity['title'] ?? ''),
              subtitle: Text(activity['description'] ?? ''),
              trailing: Text(
                _formatDate(activity['timestamp']),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  IconData _getIconForAction(String action) {
    switch (action) {
      case 'memory':
        return Icons.memory;
      case 'upload':
        return Icons.upload_file;
      case 'note':
        return Icons.note_add;
      case 'task':
        return Icons.task_alt;
      default:
        return Icons.add;
    }
  }

  IconData _getIconForActivityType(String type) {
    switch (type) {
      case 'memory':
        return Icons.memory;
      case 'file':
        return Icons.file_copy;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.circle;
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
