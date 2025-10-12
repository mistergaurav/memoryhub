import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';

class UserProfileViewScreen extends StatefulWidget {
  final String userId;

  const UserProfileViewScreen({super.key, required this.userId});

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/${widget.userId}/profile'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _profile = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _toggleFollow() async {
    if (_profile == null) return;

    final wasFollowing = _profile!['is_following'] == true;
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
      _loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasFollowing ? 'Unfollowed' : 'Following'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Profile not found')),
      );
    }

    final stats = _profile!['stats'] ?? {};
    final recentMemories = _profile!['recent_memories'] ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: _profile!['avatar_url'] != null
                          ? NetworkImage(ApiConfig.getAssetUrl(_profile!['avatar_url']))
                          : null,
                      child: _profile!['avatar_url'] == null
                          ? Text(
                              (_profile!['full_name'] ??
                                      _profile!['email'])[0]
                                  .toUpperCase(),
                              style: const TextStyle(fontSize: 32, color: Colors.black87),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile!['full_name'] ?? _profile!['email'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_profile!['bio'] != null)
                        Text(
                          _profile!['bio'],
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_profile!['city'] != null) ...[
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              [_profile!['city'], _profile!['country']]
                                  .where((e) => e != null)
                                  .join(', '),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Memories',
                            stats['memories']?.toString() ?? '0',
                          ),
                          _buildStatItem(
                            'Files',
                            stats['files']?.toString() ?? '0',
                          ),
                          _buildStatItem(
                            'Followers',
                            stats['followers']?.toString() ?? '0',
                          ),
                          _buildStatItem(
                            'Following',
                            stats['following']?.toString() ?? '0',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_profile!['is_own_profile'] != true)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _toggleFollow,
                            child: Text(
                              _profile!['is_following'] == true
                                  ? 'Unfollow'
                                  : 'Follow',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                if (recentMemories.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Recent Memories',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentMemories.length,
                    itemBuilder: (context, index) {
                      final memory = recentMemories[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(memory['title']),
                          subtitle: Text(
                            memory['content'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            _formatDate(memory['created_at']),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM d, y').format(dt);
    } catch (e) {
      return '';
    }
  }
}
