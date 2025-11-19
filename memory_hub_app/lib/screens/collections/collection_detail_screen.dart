import 'package:flutter/material.dart';
import '../../services/collections_service.dart';
import '../../services/hubs_service.dart';
import '../../config/api_config.dart';
import '../memories/memory_detail_screen.dart';
import 'package:intl/intl.dart';
import '../../widgets/share_bottom_sheet.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/layout/gap.dart';

class CollectionDetailScreen extends StatefulWidget {
  final String collectionId;
  final String collectionName;

  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    required this.collectionName,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final CollectionsService _service = CollectionsService();
  final HubsService _hubsService = HubsService();
  Map<String, dynamic>? _collection;
  List<dynamic> _memories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollectionData();
  }

  Future<void> _loadCollectionData() async {
    setState(() => _isLoading = true);
    try {
      final collectionData = await _service.getCollection(widget.collectionId);
      final memories = await _service.getCollectionMemories(widget.collectionId);
      
      setState(() {
        _collection = collectionData;
        _memories = memories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading collection: $e')),
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

  void _shareCollection() {
    if (_collection == null) return;
    
    final collectionUrl = '${ApiConfig.baseUrl}/collection/${widget.collectionId}';
    final collectionName = _collection!['name'] ?? widget.collectionName;
    final description = _collection!['description'] ?? 'Check out this collection on Memory Hub';
    
    ShareBottomSheet.show(
      context,
      shareUrl: collectionUrl,
      title: collectionName,
      description: description,
      showShareToHub: true,
      onShareToHub: _shareToHub,
    );
  }

  Future<void> _shareToHub() async {
    final availableHubs = await _getAvailableHubs();
    
    if (availableHubs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hubs available. Join or create a hub first!')),
        );
      }
      return;
    }
    
    if (!mounted) return;
    
    final selectedHub = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share to Hub'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableHubs.length,
            itemBuilder: (context, index) {
              final hub = availableHubs[index];
              return ListTile(
                leading: const Icon(Icons.workspaces),
                title: Text(hub['name'] ?? 'Unnamed Hub'),
                subtitle: Text('${hub['member_count'] ?? 0} members'),
                onTap: () => Navigator.pop(context, hub),
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
    );
    
    if (selectedHub != null && mounted) {
      try {
        await _hubsService.shareToHub(
          selectedHub['id'],
          'collection',
          widget.collectionId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Collection shared to ${selectedHub['name']}'),
              backgroundColor: MemoryHubColors.green500,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share: $e'),
              backgroundColor: MemoryHubColors.red500,
            ),
          );
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getAvailableHubs() async {
    try {
      return await _hubsService.getMyHubs();
    } catch (e) {
      debugPrint('Error loading hubs: $e');
      return [];
    }
  }

  Future<void> _removeMemoryFromCollection(String memoryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Memory'),
        content: const Text('Remove this memory from the collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.removeMemoryFromCollection(widget.collectionId, memoryId);
        await _loadCollectionData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Memory removed from collection'),
              backgroundColor: MemoryHubColors.green500,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
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
              title: Text(widget.collectionName),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.primaries[widget.collectionName.hashCode % Colors.primaries.length],
                      Colors.primaries[(widget.collectionName.hashCode + 1) % Colors.primaries.length],
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.photo_library,
                    size: 80,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share Collection',
                onPressed: _shareCollection,
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit),
                        const HGap.md(),
                        const Text('Edit Collection'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: MemoryHubColors.red500),
                        const HGap.md(),
                        Text('Delete Collection', style: TextStyle(color: MemoryHubColors.red500)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Collection'),
                        content: const Text('Are you sure? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: MemoryHubColors.red500,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      try {
                        await _service.deleteCollection(widget.collectionId);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Collection deleted')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    }
                  }
                },
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(
              child: Card(
                margin: EdgeInsets.all(MemoryHubSpacing.lg),
                child: Padding(
                  padding: EdgeInsets.all(MemoryHubSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.photo_library,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const HGap.md(),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _collection?['name'] ?? widget.collectionName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: MemoryHubTypography.bold,
                                      ),
                                ),
                                if (_collection?['description'] != null)
                                  Padding(
                                    padding: EdgeInsets.only(top: MemoryHubSpacing.xs / 2),
                                    child: Text(
                                      _collection!['description'],
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: MemoryHubColors.gray600,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(height: MemoryHubSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.photo,
                            'Memories',
                            '${_memories.length}',
                          ),
                          _buildStatItem(
                            Icons.calendar_today,
                            'Created',
                            _formatDate(_collection?['created_at']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_memories.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: MemoryHubColors.gray400,
                      ),
                      const VGap.lg(),
                      Text(
                        'No memories in this collection',
                        style: TextStyle(
                          fontSize: MemoryHubTypography.h4,
                          color: MemoryHubColors.gray600,
                        ),
                      ),
                      const VGap.xs(),
                      Text(
                        'Add memories to this collection from the memory detail screen',
                        style: TextStyle(
                          fontSize: MemoryHubTypography.h6,
                          color: MemoryHubColors.gray500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  MemoryHubSpacing.lg,
                  0,
                  MemoryHubSpacing.lg,
                  MemoryHubSpacing.lg,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: MemoryHubSpacing.md,
                    mainAxisSpacing: MemoryHubSpacing.md,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final memory = _memories[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MemoryDetailScreen(
                                  memoryId: memory['id'],
                                ),
                              ),
                            ).then((_) => _loadCollectionData());
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: MemoryHubColors.gray300,
                                  ),
                                  child: memory['image_url'] != null
                                      ? Image.network(
                                          ApiConfig.getAssetUrl(memory['image_url']),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(Icons.broken_image, size: 48),
                                            );
                                          },
                                        )
                                      : const Icon(Icons.photo, size: 48),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(MemoryHubSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      memory['title'] ?? 'Untitled',
                                      style: TextStyle(
                                        fontWeight: MemoryHubTypography.bold,
                                        fontSize: MemoryHubTypography.h6,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const VGap(4),
                                    Text(
                                      _formatDate(memory['created_at']),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: MemoryHubColors.gray600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    color: MemoryHubColors.red500,
                                    onPressed: () => _removeMemoryFromCollection(memory['id']),
                                    tooltip: 'Remove from collection',
                                  ),
                                ],
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
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const VGap.xs(),
        Text(
          value,
          style: TextStyle(
            fontSize: MemoryHubTypography.h4,
            fontWeight: MemoryHubTypography.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: MemoryHubTypography.bodySmall,
            color: MemoryHubColors.gray600,
          ),
        ),
      ],
    );
  }
}
