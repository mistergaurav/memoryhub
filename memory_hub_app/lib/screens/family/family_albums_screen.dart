import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_album.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../widgets/hero_header.dart';
import '../../design_system/design_tokens.dart';
import '../../dialogs/family/add_album_dialog.dart';

class FamilyAlbumsScreen extends StatefulWidget {
  const FamilyAlbumsScreen({Key? key}) : super(key: key);

  @override
  State<FamilyAlbumsScreen> createState() => _FamilyAlbumsScreenState();
}

class _FamilyAlbumsScreenState extends State<FamilyAlbumsScreen> {
  final FamilyService _familyService = FamilyService();
  List<FamilyAlbum> _albums = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final albums = await _familyService.getFamilyAlbums();
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAlbums,
        child: CustomScrollView(
          slivers: [
            HeroHeader(
              title: 'Family Albums',
              subtitle: 'Preserve precious memories together',
              icon: Icons.photo_library,
              gradientColors: MemoryHubGradients.albums.colors,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search feature coming soon')),
                    );
                  },
                ),
              ],
            ),
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.all(MemoryHubSpacing.lg),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: MemoryHubSpacing.lg,
                    mainAxisSpacing: MemoryHubSpacing.lg,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerCard(),
                    childCount: 6,
                  ),
                ),
              )
            else if (_error.isNotEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Albums',
                  message: 'Failed to load family albums. Pull to retry.',
                  actionLabel: 'Retry',
                  onAction: _loadAlbums,
                  gradientColors: MemoryHubGradients.error.colors,
                ),
              )
            else if (_albums.isEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.photo_library,
                  title: 'No Albums Yet',
                  message: 'Create your first family album to start preserving memories together.',
                  actionLabel: 'Create Album',
                  onAction: _showAddDialog,
                  gradientColors: MemoryHubGradients.albums.colors,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(MemoryHubSpacing.lg),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: MemoryHubSpacing.lg,
                    mainAxisSpacing: MemoryHubSpacing.lg,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildAlbumCard(_albums[index]),
                    childCount: _albums.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'family_albums_main_fab',
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Album'),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddAlbumDialog(onSubmit: _handleAdd),
    );
  }

  Future<void> _handleAdd(Map<String, dynamic> data) async {
    try {
      await _familyService.createAlbum(data);
      _loadAlbums();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Album created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create album: $e')),
        );
      }
      rethrow;
    }
  }

  Widget _buildAlbumCard(FamilyAlbum album) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlbumDetailScreen(album: album),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  album.coverPhoto != null
                      ? Image.network(
                          album.coverPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultCover();
                          },
                        )
                      : _buildDefaultCover(),
                  Positioned(
                    top: MemoryHubSpacing.sm,
                    right: MemoryHubSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MemoryHubSpacing.sm,
                        vertical: MemoryHubSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: MemoryHubBorderRadius.mdRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: MemoryHubSpacing.xs),
                          Text(
                            album.photosCount.toString(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: MemoryHubTypography.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(MemoryHubSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (album.description != null) ...[
                    const SizedBox(height: MemoryHubSpacing.xs),
                    Text(
                      album.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: MemoryHubSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 14,
                        color: MemoryHubColors.gray500,
                      ),
                      const SizedBox(width: MemoryHubSpacing.xs),
                      Expanded(
                        child: Text(
                          album.createdByName ?? 'Unknown',
                          style: Theme.of(context).textTheme.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: MemoryHubGradients.albums,
      ),
      child: const Center(
        child: Icon(
          Icons.photo_library,
          size: 60,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ShimmerBox(
              width: double.infinity,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(MemoryHubBorderRadius.xl),
                topRight: Radius.circular(MemoryHubBorderRadius.xl),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(MemoryHubSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 120, height: 16, borderRadius: MemoryHubBorderRadius.xsRadius),
                const SizedBox(height: MemoryHubSpacing.sm),
                ShimmerBox(width: double.infinity, height: 12, borderRadius: MemoryHubBorderRadius.xsRadius),
                const SizedBox(height: MemoryHubSpacing.xs),
                ShimmerBox(width: 100, height: 12, borderRadius: MemoryHubBorderRadius.xsRadius),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AlbumDetailScreen extends StatefulWidget {
  final FamilyAlbum album;

  const AlbumDetailScreen({Key? key, required this.album}) : super(key: key);

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final FamilyService _familyService = FamilyService();
  List<AlbumPhoto> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final photos = await _familyService.getAlbumPhotos(widget.album.id);
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? EnhancedEmptyState(
                  icon: Icons.photo,
                  title: 'No Photos Yet',
                  message: 'Add photos to this album to start building memories.',
                  actionLabel: 'Add Photo',
                  onAction: () {},
                  gradientColors: MemoryHubGradients.albums.colors,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(MemoryHubSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: MemoryHubSpacing.sm,
                    mainAxisSpacing: MemoryHubSpacing.sm,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return ClipRRect(
                      borderRadius: MemoryHubBorderRadius.mdRadius,
                      child: Image.network(
                        photo.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: MemoryHubColors.gray200,
                            child: const Icon(Icons.broken_image),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'family_albums_fab',
        onPressed: () {},
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
