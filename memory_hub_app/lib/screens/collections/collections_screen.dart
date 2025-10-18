import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/collections_service.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/gradient_container.dart';
import '../../widgets/shimmer_loading.dart';
import 'collection_detail_screen.dart';

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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _viewToggleAnimation = CurvedAnimation(
      parent: _viewToggleController,
      curve: Curves.easeInOut,
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
            backgroundColor: Colors.red,
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
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collections',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Organize your memories',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
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
        padding: const EdgeInsets.all(20),
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
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Sort by:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSortChip('Recent', 'recent'),
                        const SizedBox(width: 8),
                        _buildSortChip('Name', 'name'),
                        const SizedBox(width: 8),
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
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _isGridView ? 2 : 1,
          childAspectRatio: _isGridView ? 0.85 : 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ShimmerLoading(
            isLoading: true,
            child: ShimmerBox(
              borderRadius: BorderRadius.circular(20),
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildGridCollectionCard(index),
            childCount: _filteredCollections.length,
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
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
                    padding: const EdgeInsets.all(16),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.photo_library,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${collection['memory_count'] ?? 0} memories',
                              style: GoogleFonts.inter(
                                fontSize: 12,
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
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(12),
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
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${collection['memory_count'] ?? 0} memories${collection['privacy'] == 'private' ? ' • Private' : ''}',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
          onTap: () => _navigateToDetail(collection),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(int index) {
    final gradients = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFFEC4899), const Color(0xFFF472B6)],
      [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
      [const Color(0xFF10B981), const Color(0xFF34D399)],
      [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
      [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Collection',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Collection Name',
                  hintText: 'Enter collection name',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe your collection',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Collection created successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadCollections();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
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
