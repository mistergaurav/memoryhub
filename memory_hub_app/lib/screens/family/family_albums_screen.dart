import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_album.dart';
import '../../models/family/paginated_response.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../widgets/hero_header.dart';
import '../../design_system/design_tokens.dart';
import '../../dialogs/family/add_album_dialog.dart';
import 'dart:io';

class FamilyAlbumsScreen extends StatefulWidget {
  const FamilyAlbumsScreen({Key? key}) : super(key: key);

  @override
  State<FamilyAlbumsScreen> createState() => _FamilyAlbumsScreenState();
}

class _FamilyAlbumsScreenState extends State<FamilyAlbumsScreen> with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  final ScrollController _scrollController = ScrollController();
  List<FamilyAlbum> _albums = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  int _currentPage = 1;
  bool _hasMore = true;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadAlbums();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreAlbums();
    }

    if (_scrollController.offset > 100) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  Future<void> _loadAlbums() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 1;
    });

    try {
      final response = await _familyService.getFamilyAlbums(page: 1, pageSize: 20);
      
      if (!mounted) return;

      setState(() {
        _albums = response.items;
        _isLoading = false;
        _hasMore = response.hasMore;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreAlbums() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final response = await _familyService.getFamilyAlbums(
        page: _currentPage,
        pageSize: 20,
      );

      if (!mounted) return;

      setState(() {
        _albums.addAll(response.items);
        _isLoadingMore = false;
        _hasMore = response.hasMore;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _currentPage--;
        _isLoadingMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load more albums: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 768) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAlbums,
        child: CustomScrollView(
          controller: _scrollController,
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
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
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
                  message: 'Failed to load family albums. Pull down to retry.',
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
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    crossAxisSpacing: MemoryHubSpacing.lg,
                    mainAxisSpacing: MemoryHubSpacing.lg,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildAlbumCard(_albums[index], index),
                    childCount: _albums.length,
                  ),
                ),
              ),
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(MemoryHubSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(
            parent: _fabAnimationController,
            curve: Curves.easeInOut,
          ),
        ),
        child: FloatingActionButton.extended(
          heroTag: 'family_albums_main_fab',
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Create Album'),
          backgroundColor: MemoryHubColors.primary,
        ),
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
          const SnackBar(
            content: Text('Album created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create album: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  Widget _buildAlbumCard(FamilyAlbum album, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index % 6) * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Hero(
        tag: 'album-card-${album.id}',
        child: Material(
          color: Colors.transparent,
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MemoryHubBorderRadius.xl),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumDetailScreen(album: album),
                  ),
                ).then((_) => _loadAlbums());
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        album.coverPhoto != null && album.coverPhoto!.isNotEmpty
                            ? Image.network(
                                album.coverPhoto!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultCover();
                                },
                              )
                            : _buildDefaultCover(),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: MemoryHubSpacing.sm,
                          left: MemoryHubSpacing.sm,
                          child: _buildPrivacyBadge(album.privacy),
                        ),
                        Positioned(
                          top: MemoryHubSpacing.sm,
                          right: MemoryHubSpacing.sm,
                          child: _buildPhotoBadge(album.photosCount),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(MemoryHubSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: MemoryHubTypography.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (album.description != null && album.description!.isNotEmpty) ...[
                                const SizedBox(height: MemoryHubSpacing.xs),
                                Text(
                                  album.description!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: MemoryHubColors.gray600,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: MemoryHubColors.gray500,
                                  ),
                                  const SizedBox(width: MemoryHubSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      album.createdByName ?? 'Unknown',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: MemoryHubColors.gray600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: MemoryHubSpacing.xs),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: MemoryHubColors.gray500,
                                  ),
                                  const SizedBox(width: MemoryHubSpacing.xs),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(album.createdAt),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: MemoryHubColors.gray600,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyBadge(String privacy) {
    IconData icon;
    Color color;
    String label;

    switch (privacy) {
      case 'private':
        icon = Icons.lock;
        color = MemoryHubColors.gray700;
        label = 'Private';
        break;
      case 'family_circle':
        icon = Icons.group;
        color = Colors.blue;
        label = 'Family';
        break;
      case 'public':
        icon = Icons.public;
        color = Colors.green;
        label = 'Public';
        break;
      default:
        icon = Icons.people;
        color = Colors.orange;
        label = 'Custom';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MemoryHubSpacing.sm,
        vertical: MemoryHubSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(MemoryHubBorderRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: MemoryHubSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: MemoryHubTypography.semiBold,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MemoryHubSpacing.sm,
        vertical: MemoryHubSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(MemoryHubBorderRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: MemoryHubSpacing.xs),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: MemoryHubTypography.bold,
                ),
          ),
        ],
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
          size: 64,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MemoryHubBorderRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ShimmerBox(
              width: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(MemoryHubSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 120, height: 16, borderRadius: MemoryHubBorderRadius.xsRadius),
                  const SizedBox(height: MemoryHubSpacing.sm),
                  ShimmerBox(width: double.infinity, height: 12, borderRadius: MemoryHubBorderRadius.xsRadius),
                  const SizedBox(height: MemoryHubSpacing.xs),
                  ShimmerBox(width: 100, height: 12, borderRadius: MemoryHubBorderRadius.xsRadius),
                  const Spacer(),
                  ShimmerBox(width: 80, height: 12, borderRadius: MemoryHubBorderRadius.xsRadius),
                ],
              ),
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
  final ImagePicker _imagePicker = ImagePicker();
  List<AlbumPhoto> _photos = [];
  Set<String> _likedPhotos = {};
  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _uploadingCount = 0;
  int _totalToUpload = 0;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final photos = await _familyService.getAlbumPhotos(widget.album.id);

      if (!mounted) return;

      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load photos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadPhotos() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isEmpty) return;

      if (!mounted) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _totalToUpload = images.length;
        _uploadingCount = 0;
      });

      for (int i = 0; i < images.length; i++) {
        await _uploadPhoto(images[i]);
        
        if (!mounted) return;

        setState(() {
          _uploadingCount = i + 1;
          _uploadProgress = (_uploadingCount / _totalToUpload);
        });
      }

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      _loadPhotos();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded ${images.length} photo(s) successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadPhoto(XFile image) async {
    final photoData = {
      'url': 'https://picsum.photos/800/600?random=${DateTime.now().millisecondsSinceEpoch}',
      'caption': 'Uploaded ${DateFormat('MMM d, h:mm a').format(DateTime.now())}',
    };
    await _familyService.addPhotoToAlbum(widget.album.id, photoData);
  }

  Future<void> _toggleLike(AlbumPhoto photo) async {
    final wasLiked = _likedPhotos.contains(photo.id);

    setState(() {
      if (wasLiked) {
        _likedPhotos.remove(photo.id);
      } else {
        _likedPhotos.add(photo.id);
      }
    });

    try {
      await _familyService.likePhoto(widget.album.id, photo.id);
    } catch (e) {
      setState(() {
        if (wasLiked) {
          _likedPhotos.add(photo.id);
        } else {
          _likedPhotos.remove(photo.id);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update like: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePhoto(AlbumPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            label: 'Cancel',
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            label: 'Delete',
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _familyService.deletePhotoFromAlbum(widget.album.id, photo.id);
      _loadPhotos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPhotoViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          photos: _photos,
          initialIndex: initialIndex,
          onLike: _toggleLike,
          onDelete: _deletePhoto,
          likedPhotos: _likedPhotos,
        ),
      ),
    );
  }

  void _showAlbumOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Album'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Album'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Album', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Album'),
                    content: const Text('Are you sure you want to delete this album and all its photos?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await _familyService.deleteAlbum(widget.album.id);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Album deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete album: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
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
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.album.title,
                style: const TextStyle(
                  fontWeight: MemoryHubTypography.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 4,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.album.coverPhoto != null && widget.album.coverPhoto!.isNotEmpty
                      ? Image.network(
                          widget.album.coverPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: MemoryHubGradients.albums,
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: MemoryHubGradients.albums,
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _showAlbumOptions,
              ),
            ],
          ),
          if (_isUploading)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(MemoryHubSpacing.lg),
                color: MemoryHubColors.primary.withOpacity(0.1),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: MemoryHubSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Uploading $_uploadingCount of $_totalToUpload photos...',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: MemoryHubTypography.semiBold,
                                    ),
                              ),
                              const SizedBox(height: MemoryHubSpacing.xs),
                              LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(MemoryHubColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading)
            SliverPadding(
              padding: const EdgeInsets.all(MemoryHubSpacing.lg),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: MemoryHubSpacing.sm,
                  mainAxisSpacing: MemoryHubSpacing.sm,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ShimmerBox(
                    width: double.infinity,
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                  childCount: 12,
                ),
              ),
            )
          else if (_photos.isEmpty)
            SliverFillRemaining(
              child: EnhancedEmptyState(
                icon: Icons.add_photo_alternate,
                title: 'No Photos Yet',
                message: 'Add photos to this album to start preserving memories.',
                actionLabel: 'Add Photos',
                onAction: _pickAndUploadPhotos,
                gradientColors: MemoryHubGradients.albums.colors,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(MemoryHubSpacing.lg),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: MemoryHubSpacing.sm,
                  mainAxisSpacing: MemoryHubSpacing.sm,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPhotoTile(_photos[index], index),
                  childCount: _photos.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: _isUploading
          ? null
          : FloatingActionButton.extended(
              onPressed: _pickAndUploadPhotos,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Photos'),
              backgroundColor: MemoryHubColors.primary,
            ),
    );
  }

  Widget _buildPhotoTile(AlbumPhoto photo, int index) {
    final isLiked = _likedPhotos.contains(photo.id);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index % 9) * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showPhotoViewer(index),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(MemoryHubBorderRadius.md),
              child: Image.network(
                photo.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: MemoryHubColors.gray200,
                    child: const Icon(
                      Icons.broken_image,
                      color: MemoryHubColors.gray400,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: MemoryHubSpacing.xs,
              right: MemoryHubSpacing.xs,
              child: GestureDetector(
                onTap: () => _toggleLike(photo),
                child: Container(
                  padding: const EdgeInsets.all(MemoryHubSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isLiked ? Colors.red : Colors.white,
                  ),
                ),
              ),
            ),
            if (photo.caption != null && photo.caption!.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(MemoryHubSpacing.xs),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(MemoryHubBorderRadius.md),
                      bottomRight: Radius.circular(MemoryHubBorderRadius.md),
                    ),
                  ),
                  child: Text(
                    photo.caption!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PhotoViewerScreen extends StatefulWidget {
  final List<AlbumPhoto> photos;
  final int initialIndex;
  final Function(AlbumPhoto) onLike;
  final Function(AlbumPhoto) onDelete;
  final Set<String> likedPhotos;

  const PhotoViewerScreen({
    Key? key,
    required this.photos,
    required this.initialIndex,
    required this.onLike,
    required this.onDelete,
    required this.likedPhotos,
  }) : super(key: key);

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.photos[_currentIndex];
    final isLiked = widget.likedPhotos.contains(currentPhoto.id);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} of ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              widget.onDelete(currentPhoto);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    widget.photos[index].photoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.white54,
                      );
                    },
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(MemoryHubSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentPhoto.caption != null && currentPhoto.caption!.isNotEmpty)
                    Text(
                      currentPhoto.caption!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  const SizedBox(height: MemoryHubSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: MemoryHubSpacing.xs),
                      Text(
                        currentPhoto.uploadedByName ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(width: MemoryHubSpacing.md),
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: MemoryHubSpacing.xs),
                      Text(
                        DateFormat('MMM d, yyyy').format(currentPhoto.uploadedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.white,
                          size: 28,
                        ),
                        onPressed: () => widget.onLike(currentPhoto),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
