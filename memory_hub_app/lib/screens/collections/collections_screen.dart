import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/collections_service.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/gradient_container.dart';
import '../../widgets/shimmer_loading.dart';
import 'collection_detail_screen.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/layout/gap.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> with TickerProviderStateMixin {
  final CollectionsService _service = CollectionsService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _collections = [];
  List<dynamic> _filteredCollections = [];
  bool _isGridView = true;
  String _sortBy = 'recent';
  
  late AnimationController _viewToggleController;
  late Animation<double> _viewToggleAnimation;

  @override
  void initState() {
    super.initState();
    _viewToggleController = AnimationController(
      duration: MemoryHubAnimations.normal,
      vsync: this,
    );
    _viewToggleAnimation = CurvedAnimation(
      parent: _viewToggleController,
      curve: MemoryHubAnimations.easeInOut,
    );
    _loadCollections();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewToggleController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    setState(() => _isLoading = true);
    try {
      final collections = await _service.getCollections();
      setState(() {
        _collections = collections;
        _filteredCollections = collections;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading collections: $e'),
            backgroundColor: MemoryHubColors.red500,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterCollections(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCollections = _collections;
      } else {
        _filteredCollections = _collections.where((collection) {
          final name = (collection['name'] ?? '').toString().toLowerCase();
          final description = (collection['description'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || description.contains(searchLower);
        }).toList();
      }
      _applySorting();
    });
  }

  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredCollections.sort((a, b) => 
            (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
          break;
        case 'size':
          _filteredCollections.sort((a, b) => 
            (b['memory_count'] ?? 0).compareTo(a['memory_count'] ?? 0));
          break;
        case 'recent':
        default:
          _filteredCollections.sort((a, b) {
            final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
            final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildSearchAndFilters(),
          if (_isLoading)
            _buildLoadingState()
          else if (_filteredCollections.isEmpty)
            _buildEmptyState()
          else
            _buildCollectionsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCollectionDialog(),
        label: const Text('New Collection'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: GradientContainer(
        padding: EdgeInsets.fromLTRB(
          MemoryHubSpacing.xl,
          MemoryHubSpacing.xxxxl - 4,
          MemoryHubSpacing.xl,
          MemoryHubSpacing.xl,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(MemoryHubBorderRadius.xxl),
          bottomRight: Radius.circular(MemoryHubBorderRadius.xxl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                ),
                HGap.xs(),
                Expanded(
                  child: Text(
                    'Collections',
                    style: GoogleFonts.inter(
                      fontSize: MemoryHubTypography.h1,
                      fontWeight: MemoryHubTypography.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            VGap.xs(),
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Text(
                'Organize your memories',
                style: GoogleFonts.inter(
                  fontSize: MemoryHubTypography.h6,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(MemoryHubSpacing.xl),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search collections...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterCollections('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _filterCollections,
                  ),
                ),
                HGap.md(),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: MemoryHubBorderRadius.lgRadius,
                  ),
                  child: IconButton(
                    icon: AnimatedIcon(
                      icon: AnimatedIcons.view_list,
                      progress: _viewToggleAnimation,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                        if (_isGridView) {
                          _viewToggleController.reverse();
                        } else {
                          _viewToggleController.forward();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            VGap.lg(),
            Row(
              children: [
                Text(
                  'Sort by:',
                  style: GoogleFonts.inter(
                    fontSize: MemoryHubTypography.h6,
                    fontWeight: MemoryHubTypography.medium,
                  ),
                ),
                HGap.md(),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSortChip('Recent', 'recent'),
                        HGap.xs(),
                        _buildSortChip('Name', 'name'),
                        HGap.xs(),
                        _buildSortChip('Size', 'size'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _sortBy = value;
          _applySorting();
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: GoogleFonts.inter(
        fontSize: MemoryHubTypography.bodySmall + 1,
        fontWeight: isSelected ? MemoryHubTypography.semiBold : MemoryHubTypography.regular,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.xl),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _isGridView ? 2 : 1,
          childAspectRatio: _isGridView ? 0.85 : 3,
          crossAxisSpacing: MemoryHubSpacing.lg,
          mainAxisSpacing: MemoryHubSpacing.lg,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ShimmerLoading(
            isLoading: true,
            child: ShimmerBox(
              borderRadius: MemoryHubBorderRadius.xlRadius,
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: EnhancedEmptyState(
        icon: Icons.collections_outlined,
        title: _searchController.text.isNotEmpty 
            ? 'No Collections Found' 
            : 'No Collections Yet',
        message: _searchController.text.isNotEmpty
            ? 'Try a different search term'
            : 'Create your first collection to organize your memories',
        actionLabel: _searchController.text.isEmpty ? 'Create Collection' : null,
        onAction: _searchController.text.isEmpty ? _showCreateCollectionDialog : null,
      ),
    );
  }

  Widget _buildCollectionsList() {
    if (_isGridView) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
          MemoryHubSpacing.xl,
          0,
          MemoryHubSpacing.xl,
          100,
        ),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: MemoryHubSpacing.lg,
            mainAxisSpacing: MemoryHubSpacing.lg,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildGridCollectionCard(index),
            childCount: _filteredCollections.length,
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
          MemoryHubSpacing.xl,
          0,
          MemoryHubSpacing.xl,
          100,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildListCollectionCard(index),
            childCount: _filteredCollections.length,
          ),
        ),
      );
    }
  }

  Widget _buildGridCollectionCard(int index) {
    final collection = _filteredCollections[index];
    final colors = _getGradientColors(index);
    
    return AnimatedListItem(
      index: index,
      delay: 50,
      child: GestureDetector(
        onTap: () => _navigateToDetail(collection),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: MemoryHubBorderRadius.xlRadius,
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: MemoryHubBorderRadius.xlRadius,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.collections,
                    size: 120,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(MemoryHubSpacing.lg),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection['name'] ?? 'Collection',
                          style: GoogleFonts.inter(
                            fontSize: MemoryHubTypography.bodyLarge,
                            fontWeight: MemoryHubTypography.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        VGap(4),
                        Row(
                          children: [
                            const Icon(
                              Icons.photo_library,
                              size: 14,
                              color: Colors.white,
                            ),
                            HGap(4),
                            Text(
                              '${collection['memory_count'] ?? 0} memories',
                              style: GoogleFonts.inter(
                                fontSize: MemoryHubTypography.bodySmall,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (collection['privacy'] == 'private')
                  Positioned(
                    top: MemoryHubSpacing.md,
                    right: MemoryHubSpacing.md,
                    child: Container(
                      padding: EdgeInsets.all(MemoryHubSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: MemoryHubBorderRadius.smRadius,
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.white,
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

  Widget _buildListCollectionCard(int index) {
    final collection = _filteredCollections[index];
    final colors = _getGradientColors(index);
    
    return AnimatedListItem(
      index: index,
      delay: 50,
      child: Container(
        margin: EdgeInsets.only(bottom: MemoryHubSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: MemoryHubBorderRadius.lgRadius,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: MemoryHubSpacing.lg,
            vertical: MemoryHubSpacing.sm,
          ),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: MemoryHubBorderRadius.mdRadius,
            ),
            child: const Icon(
              Icons.collections,
              color: Colors.white,
              size: 28,
            ),
          ),
          title: Text(
            collection['name'] ?? 'Collection',
            style: GoogleFonts.inter(
              fontWeight: MemoryHubTypography.semiBold,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${collection['memory_count'] ?? 0} memories${collection['privacy'] == 'private' ? ' • Private' : ''}',
            style: GoogleFonts.inter(fontSize: MemoryHubTypography.bodySmall + 1),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: MemoryHubColors.gray400,
          ),
          onTap: () => _navigateToDetail(collection),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(int index) {
    final gradients = [
      [MemoryHubColors.indigo500, MemoryHubColors.purple500],
      [MemoryHubColors.pink500, MemoryHubColors.pink400],
      [MemoryHubColors.purple500, MemoryHubColors.purple400],
      [MemoryHubColors.green500, MemoryHubColors.green400],
      [MemoryHubColors.blue500, MemoryHubColors.blue400],
      [MemoryHubColors.amber500, MemoryHubColors.amber400],
    ];
    return gradients[index % gradients.length];
  }

  void _navigateToDetail(dynamic collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionDetailScreen(
          collectionId: collection['id'],
          collectionName: collection['name'],
        ),
      ),
    ).then((_) => _loadCollections());
  }

  void _showCreateCollectionDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String privacy = 'private';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MemoryHubBorderRadius.xxl)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.all(MemoryHubSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Collection',
                style: GoogleFonts.inter(
                  fontSize: MemoryHubTypography.h2,
                  fontWeight: MemoryHubTypography.bold,
                ),
              ),
              VGap.xl(),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Collection Name',
                  hintText: 'Enter collection name',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              VGap.lg(),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe your collection',
                ),
                maxLines: 3,
              ),
              VGap.lg(),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy',
                      style: GoogleFonts.inter(
                        fontSize: MemoryHubTypography.h6,
                        fontWeight: MemoryHubTypography.medium,
                      ),
                    ),
                    VGap.xs(),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Private'),
                            value: 'private',
                            groupValue: privacy,
                            onChanged: (value) {
                              setState(() => privacy = value!);
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Public'),
                            value: 'public',
                            groupValue: privacy,
                            onChanged: (value) {
                              setState(() => privacy = value!);
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              VGap.xl(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  HGap.lg(),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a name')),
                          );
                          return;
                        }
                        try {
                          await _service.createCollection(
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            privacy: privacy,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            _loadCollections();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Collection created'),
                                backgroundColor: MemoryHubColors.green500,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: MemoryHubColors.red500,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
