import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../memories/memory_detail_screen.dart';
import 'hub_info_screen.dart';
import '../../widgets/share_bottom_sheet.dart';
import '../../design_system/design_system.dart';

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
        AppSnackbar.error(context, 'Error loading hub: $e');
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

  Future<void> _showShareMemoryDialog() async {
    List<dynamic> myMemories = [];
    bool isLoading = true;
    String? error;

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/memories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        myMemories = jsonDecode(response.body);
      } else {
        error = 'Failed to load memories';
      }
    } catch (e) {
      error = 'Error: $e';
    } finally {
      isLoading = false;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.share, color: context.colors.primary),
              const HGap.sm(),
              const Text('Share Memory to Hub'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: context.colors.error.withOpacity(0.7)),
                            const VGap.md(),
                            Text(error, style: TextStyle(color: context.colors.error)),
                          ],
                        ),
                      )
                    : myMemories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_library_outlined, size: 64, color: context.colors.onSurface.withOpacity(0.3)),
                                const VGap.md(),
                                Text(
                                  'No memories to share',
                                  style: context.text.titleMedium?.copyWith(
                                    color: context.colors.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const VGap.sm(),
                                Text(
                                  'Create a memory first',
                                  style: context.text.bodySmall?.copyWith(
                                    color: context.colors.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: myMemories.length,
                            itemBuilder: (context, index) {
                              final memory = myMemories[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: Spacing.sm),
                                child: AppCard(
                                  child: ListTile(
                                    leading: memory['image_url'] != null
                                        ? ClipRRect(
                                            borderRadius: MemoryHubBorderRadius.smRadius,
                                          child: Image.network(
                                            ApiConfig.getAssetUrl(memory['image_url']),
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                color: context.colors.surfaceVariant,
                                                child: const Icon(Icons.broken_image, size: 24),
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: context.colors.primaryContainer,
                                            borderRadius: MemoryHubBorderRadius.smRadius,
                                          ),
                                          child: Icon(
                                            Icons.photo,
                                            color: context.colors.primary,
                                          ),
                                        ),
                                  title: Text(
                                    memory['title'] ?? 'Untitled',
                                    style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    _formatDate(memory['created_at']),
                                    style: context.text.bodySmall?.copyWith(
                                      color: context.colors.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.send),
                                    color: context.colors.primary,
                                    onPressed: () async {
                                      try {
                                        final headers = await _authService.getAuthHeaders();
                                        final response = await http.post(
                                          Uri.parse(
                                              '${ApiConfig.baseUrl}/social/hubs/${widget.hubId}/memories'),
                                          headers: headers,
                                          body: jsonEncode({
                                            'memory_id': memory['id'],
                                          }),
                                        );

                                        Navigator.pop(context);

                                        if (response.statusCode == 200 ||
                                            response.statusCode == 201) {
                                          AppSnackbar.success(
                                            context,
                                            '${memory['title'] ?? 'Memory'} shared to hub!',
                                          );
                                          _loadHubData();
                                        } else {
                                          final error = jsonDecode(response.body);
                                          AppSnackbar.error(
                                            context,
                                            error['detail'] ?? 'Failed to share memory',
                                          );
                                        }
                                      } catch (e) {
                                        Navigator.pop(context);
                                        AppSnackbar.error(context, 'Error: $e');
                                      }
                                    },
                                  ),
                                ),
                              ),
                              );
                            },
                          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
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
                      context.colors.primary,
                      context.colors.secondary,
                      context.colors.tertiary,
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
                      color: context.colors.onSurface.withOpacity(0.3),
                    ),
                    const VGap.md(),
                    Text(
                      'No memories in this hub yet',
                      style: context.text.titleMedium?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const VGap.sm(),
                    Text(
                      'Memories shared to this hub will appear here',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(Spacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final memory = _memories[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AppCard(
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
                                      color: context.colors.surfaceVariant,
                                      child: const Icon(Icons.broken_image, size: 48),
                                    );
                                  },
                                ),
                              ),
                            Padded.md(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    memory['title'] ?? 'Untitled',
                                    style: context.text.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const VGap.sm(),
                                  Text(
                                    memory['content'] ?? '',
                                    style: context.text.bodyMedium,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const VGap.sm(),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: context.colors.primary,
                                        child: Text(
                                          (memory['owner_name'] ?? 'U')[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      ),
                                      const HGap.sm(),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              memory['owner_name'] ?? 'Unknown',
                                              style: context.text.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              _formatDate(memory['created_at']),
                                              style: context.text.bodySmall?.copyWith(
                                                color: context.colors.onSurface.withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.favorite_border, size: 20, color: context.colors.onSurface.withOpacity(0.6)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${memory['like_count'] ?? 0}',
                                            style: TextStyle(color: context.colors.onSurface.withOpacity(0.6)),
                                          ),
                                          const HGap.sm(),
                                          Icon(Icons.comment_outlined, size: 20, color: context.colors.onSurface.withOpacity(0.6)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${memory['comment_count'] ?? 0}',
                                            style: TextStyle(color: context.colors.onSurface.withOpacity(0.6)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (memory['tags'] != null && (memory['tags'] as List).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: Spacing.sm),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: (memory['tags'] as List)
                                            .take(3)
                                            .map((tag) => Chip(
                                                  label: Text(tag.toString()),
                                                  visualDensity: VisualDensity.compact,
                                                  backgroundColor: context.colors.primaryContainer,
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
        onPressed: _showShareMemoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Share Memory'),
      ),
    );
  }
}
