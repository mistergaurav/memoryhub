import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_album.dart';
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

class _FamilyAlbumsScreenState extends State<FamilyAlbumsScreen> {
  final FamilyService _familyService = FamilyService();
  final ScrollController _scrollController = ScrollController();
  List<FamilyAlbum> _albums = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreAlbums();
    }
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 1;
    });
    try {
      final albums = await _familyService.getFamilyAlbums();
      setState(() {
        _albums = albums;
        _isLoading = false;
        _hasMore = albums.length >= 20;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreAlbums() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      _currentPage++;
      final newAlbums = await _familyService.getFamilyAlbums();
      setState(() {
        _albums.addAll(newAlbums);
        _isLoadingMore = false;
        _hasMore = newAlbums.length >= 20;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
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
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(MemoryHubSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
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
      elevation: 2,
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  album.coverPhoto != null
                      ? Hero(
                          tag: 'album-cover-${album.id}',
                          child: Image.network(
                            album.coverPhoto!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultCover();
                            },
                          ),
                        )
                      : _buildDefaultCover(),
                  Positioned(
                    top: MemoryHubSpacing.sm,
                    left: MemoryHubSpacing.sm,
                    child: _buildPrivacyBadge(album.privacy),
                  ),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: MemoryHubTypography.semiBold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (album.description != null) ...[
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
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: MemoryHubColors.gray600,
                              ),
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
        borderRadius: MemoryHubBorderRadius.mdRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: MemoryHubSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: MemoryHubTypography.semiBold,
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
  final ImagePicker _imagePicker = ImagePicker();
  List<AlbumPhoto> _photos = [];
  Set<String> _likedPhotos = {};
  bool _isLoading = true;
  bool _isUploading = false;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load photos: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadPhotos() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isEmpty) return;

      setState(() => _isUploading = true);

      for (final image in images) {
        await _uploadPhoto(image);
      }

      setState(() => _isUploading = false);
      _loadPhotos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${images.length} photo(s) successfully')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photos: $e')),
        );
      }
    }
  }

  Future<void> _uploadPhoto(XFile image) async {
    final photoData = {
      'url': 'https://via.placeholder.com/800',
      'caption': 'Uploaded ${DateTime.now().toString().substring(0, 16)}',
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
          SnackBar(content: Text('Failed to update like: $e')),
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
          likedPhotos: _likedPhotos,
        ),
      ),
    );
  }

  void _showAlbumOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MemoryHubBorderRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Album'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Album', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AddAlbumDialog(
        onSubmit: _handleEdit,
        initialData: {
          'title': widget.album.title,
          'description': widget.album.description,
          'privacy': widget.album.privacy,
        },
      ),
    );
  }

  Future<void> _handleEdit(Map<String, dynamic> data) async {
    try {
      await _familyService.updateAlbum(widget.album.id, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Album updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update album: $e')),
        );
      }
      rethrow;
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Album'),
        content: const Text('Are you sure you want to delete this album? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAlbum();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAlbum() async {
    try {
      await _familyService.deleteAlbum(widget.album.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Album deleted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete album: $e')),
        );
      }
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
            onPressed: _showAlbumOptions,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: MemoryHubSpacing.md),
                  Text('Loading photos...', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            )
          : _photos.isEmpty
              ? EnhancedEmptyState(
                  icon: Icons.photo,
                  title: 'No Photos Yet',
                  message: 'Add photos to this album to start building memories.',
                  actionLabel: 'Add Photos',
                  onAction: _pickAndUploadPhotos,
                  gradientColors: MemoryHubGradients.albums.colors,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(MemoryHubSpacing.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: MemoryHubSpacing.sm,
                    mainAxisSpacing: MemoryHubSpacing.sm,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    final isLiked = _likedPhotos.contains(photo.id);
                    return GestureDetector(
                      onTap: () => _showPhotoViewer(index),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'photo-${photo.id}',
                            child: ClipRRect(
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
                            ),
                          ),
                          Positioned(
                            bottom: MemoryHubSpacing.xs,
                            right: MemoryHubSpacing.xs,
                            child: Container(
                              padding: const EdgeInsets.all(MemoryHubSpacing.xs),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: MemoryHubBorderRadius.smRadius,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 16,
                                    color: isLiked ? Colors.red : Colors.white,
                                  ),
                                  const SizedBox(width: MemoryHubSpacing.xs),
                                  Text(
                                    photo.likesCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'family_albums_detail_fab',
        onPressed: _isUploading ? null : _pickAndUploadPhotos,
        child: _isUploading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class PhotoViewerScreen extends StatefulWidget {
  final List<AlbumPhoto> photos;
  final int initialIndex;
  final Function(AlbumPhoto) onLike;
  final Set<String> likedPhotos;

  const PhotoViewerScreen({
    Key? key,
    required this.photos,
    required this.initialIndex,
    required this.onLike,
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
    final photo = widget.photos[_currentIndex];
    final isLiked = widget.likedPhotos.contains(photo.id);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          final currentPhoto = widget.photos[index];
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: 'photo-${currentPhoto.id}',
                child: Image.network(
                  currentPhoto.photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, color: Colors.white, size: 64);
                  },
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(MemoryHubSpacing.md),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      widget.onLike(photo);
                      setState(() {});
                    },
                  ),
                  Text(
                    '${photo.likesCount} likes',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.comment, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comments coming soon')),
                      );
                    },
                  ),
                  Text(
                    '${photo.commentsCount}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              if (photo.caption != null) ...[
                const SizedBox(height: MemoryHubSpacing.sm),
                Text(
                  photo.caption!,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
              const SizedBox(height: MemoryHubSpacing.xs),
              Text(
                'Uploaded by ${photo.uploadedByName ?? "Unknown"}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
