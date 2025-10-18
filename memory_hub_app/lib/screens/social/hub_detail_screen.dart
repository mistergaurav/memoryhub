import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../memories/memory_detail_screen.dart';
import 'hub_info_screen.dart';
import '../../widgets/share_bottom_sheet.dart';

class HubDetailScreen extends StatefulWidget {
  final String hubId;
  final String hubName;

  const HubDetailScreen({
    super.key,
    required this.hubId,
    required this.hubName,
  });

  @override
  State<HubDetailScreen> createState() => _HubDetailScreenState();
}

class _HubDetailScreenState extends State<HubDetailScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _memories = [];
  // Map<String, dynamic>? _hubInfo; // Reserved for future use
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHubData();
  }

  Future<void> _loadHubData() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _authService.getAuthHeaders();
      
      final hubResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/social/hubs/${widget.hubId}'),
        headers: headers,
      );

      // if (hubResponse.statusCode == 200) {
      //   _hubInfo = jsonDecode(hubResponse.body);
      // }

      final memoriesResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/social/hubs/${widget.hubId}/memories'),
        headers: headers,
      );

      if (memoriesResponse.statusCode == 200) {
        setState(() {
          _memories = jsonDecode(memoriesResponse.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading hub: $e')),
        );
      }
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM d, y').format(dt);
    } catch (e) {
      return '';
    }
  }

  void _shareHub() {
    final hubUrl = '${ApiConfig.baseUrl}/hub/${widget.hubId}';
    
    ShareBottomSheet.show(
      context,
      shareUrl: hubUrl,
      title: widget.hubName,
      description: 'Join this community hub on Memory Hub',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.hubName),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.workspaces,
                    size: 80,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share Hub',
                onPressed: _shareHub,
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Hub Info',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HubInfoScreen(
                        hubId: widget.hubId,
                        hubName: widget.hubName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_memories.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No memories in this hub yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Memories shared to this hub will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final memory = _memories[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MemoryDetailScreen(
                                memoryId: memory['id'],
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (memory['image_url'] != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  ApiConfig.getAssetUrl(memory['image_url']),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image, size: 48),
                                    );
                                  },
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    memory['title'] ?? 'Untitled',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    memory['content'] ?? '',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        child: Text(
                                          (memory['owner_name'] ?? 'U')[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              memory['owner_name'] ?? 'Unknown',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            Text(
                                              _formatDate(memory['created_at']),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.favorite_border, size: 20, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${memory['like_count'] ?? 0}',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.comment_outlined, size: 20, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${memory['comment_count'] ?? 0}',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (memory['tags'] != null && (memory['tags'] as List).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: (memory['tags'] as List)
                                            .take(3)
                                            .map((tag) => Chip(
                                                  label: Text(tag.toString()),
                                                  visualDensity: VisualDensity.compact,
                                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _memories.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Share memory to hub feature coming soon!')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Share Memory'),
      ),
    );
  }
}
