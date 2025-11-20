import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import 'dart:async';
import '../../services/family/family_service.dart';
import '../../models/family/family_recipe.dart';
import '../../models/family/paginated_response.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/add_recipe_dialog.dart';
import 'recipe_detail_screen.dart';

class FamilyRecipesScreen extends StatefulWidget {
  const FamilyRecipesScreen({Key? key}) : super(key: key);

  @override
  State<FamilyRecipesScreen> createState() => _FamilyRecipesScreenState();
}

class _FamilyRecipesScreenState extends State<FamilyRecipesScreen> {
  final FamilyService _familyService = FamilyService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<FamilyRecipe> _recipes = [];
  FamilyRecipe? _featuredRecipe;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  
  // Pagination
  int _currentPage = 1;
  int _totalItems = 0;
  bool _hasMore = true;

  // Filters
  String? _selectedCategory;
  String? _selectedDifficulty;
  String _sortBy = 'newest'; // newest, most_popular, highest_rated, most_made
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecipes(isInitial: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadRecipes({bool isInitial = false}) async {
    if (!mounted) return;

    setState(() {
      if (isInitial) {
        _isLoading = true;
        _currentPage = 1;
        _recipes.clear();
      }
      _error = '';
    });

    try {
      final response = await _familyService.getRecipes(
        page: _currentPage,
        pageSize: 20,
      );

      if (!mounted) return;

      setState(() {
        _recipes = response.items;
        _totalItems = response.total;
        _hasMore = response.hasMore;
        _isLoading = false;

        // Set featured recipe (highest rated or most made)
        if (_recipes.isNotEmpty) {
          _featuredRecipe = _recipes.reduce((a, b) {
            final scoreA = a.averageRating * 10 + a.timesMade;
            final scoreB = b.averageRating * 10 + b.timesMade;
            return scoreA > scoreB ? a : b;
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await _familyService.getRecipes(
        page: _currentPage + 1,
        pageSize: 20,
      );

      if (!mounted) return;

      setState(() {
        _currentPage++;
        _recipes.addAll(response.items);
        _hasMore = response.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = value);
      _loadRecipes(isInitial: true);
    });
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddRecipeDialog(onSubmit: _handleAdd),
    );
  }

  Future<void> _handleAdd(Map<String, dynamic> data) async {
    try {
      await _familyService.createRecipe(data);
      if (mounted) {
        _loadRecipes(isInitial: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  List<FamilyRecipe> get _filteredRecipes {
    var filtered = _recipes;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((recipe) {
        return recipe.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (recipe.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((r) => r.category == _selectedCategory).toList();
    }

    // Apply difficulty filter
    if (_selectedDifficulty != null) {
      filtered = filtered.where((r) => r.difficulty == _selectedDifficulty).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'most_popular':
        filtered.sort((a, b) => b.favoritesCount.compareTo(a.favoritesCount));
        break;
      case 'highest_rated':
        filtered.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'most_made':
        filtered.sort((a, b) => b.timesMade.compareTo(a.timesMade));
        break;
      case 'newest':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = _filteredRecipes;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadRecipes(isInitial: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Family Recipes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colors.error,
                        Color(0xFFF87171),
                        Color(0xFFFBBF24),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        bottom: -50,
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 200,
                          color: context.colors.surface.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search recipes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.md),
                child: Row(children: [
                    _buildFilterChip(
                      label: 'All',
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    _buildFilterChip(label: 'Main Course',
                      isSelected: _selectedCategory == 'main_course',
                      onTap: () => setState(() => _selectedCategory = 'main_course'),
                    ),
                    _buildFilterChip(label: 'Appetizer',
                      isSelected: _selectedCategory == 'appetizer',
                      onTap: () => setState(() => _selectedCategory = 'appetizer'),
                    ),
                    _buildFilterChip(label: 'Dessert',
                      isSelected: _selectedCategory == 'dessert',
                      onTap: () => setState(() => _selectedCategory = 'dessert'),
                    ),
                    _buildFilterChip(label: 'Breakfast',
                      isSelected: _selectedCategory == 'breakfast',
                      onTap: () => setState(() => _selectedCategory = 'breakfast'),
                    ),
                    _buildFilterChip(label: 'Soup',
                      isSelected: _selectedCategory == 'soup',
                      onTap: () => setState(() => _selectedCategory = 'soup'),
                    ),
                  ],
                ),
              ),
            ),

            // Sort Dropdown
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Sort by:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const HGap.sm(),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        underline: Container(),
                        items: const [
                          DropdownMenuItem(value: 'newest', child: const Text('Newest')),
                          DropdownMenuItem(value: 'most_popular', child: const Text('Most Popular')),
                          DropdownMenuItem(value: 'highest_rated', child: const Text('Highest Rated')),
                          DropdownMenuItem(value: 'most_made', child: const Text('Most Made')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _sortBy = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Featured Recipe
            if (!_isLoading && _featuredRecipe != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildFeaturedCard(_featuredRecipe!),
                ),
              ),

            // Loading State
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerCard(),
                    childCount: 4,
                  ),
                ),
              )
            // Error State
            else if (_error.isNotEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Recipes',
                  message: 'Failed to load family recipes. Pull to retry.',
                  actionLabel: 'Retry',
                  onAction: () => _loadRecipes(isInitial: true),
                ),
              )
            // Empty State
            else if (filteredRecipes.isEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.restaurant_menu,
                  title: _searchQuery.isNotEmpty
                      ? 'No Recipes Found'
                      : 'No Recipes Yet',
                  message: _searchQuery.isNotEmpty
                      ? 'Try adjusting your search or filters'
                      : 'Start preserving your family culinary heritage!',
                  actionLabel: _searchQuery.isEmpty ? 'Add Recipe' : null,
                  onAction: _searchQuery.isEmpty ? _showAddDialog : null,
                  gradientColors: [
                    context.colors.error,
                    Color(0xFFF87171),
                  ],
                ),
              )
            // Recipe Grid
            else
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return AnimatedOpacity(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        opacity: 1.0,
                        child: _buildRecipeCard(filteredRecipes[index]),
                      );
                    },
                    childCount: filteredRecipes.length,
                  ),
                ),
              ),

            // Loading More Indicator
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'family_recipes_fab',
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Recipe'),
        backgroundColor: context.colors.error,
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: context.colors.error,
        checkmarkColor: context.colors.surface,
        labelStyle: TextStyle(
          color: isSelected ? context.colors.surface : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(FamilyRecipe recipe) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [context.colors.error, Color(0xFFFBBF24)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Color(0xFFFBBF24)),
                      HGap.xxs(),
                      Text(
                        'Featured',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.colors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(MemoryHubSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: const TextStyle(
                          color: context.colors.surface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const VGap.xs(),
                      Row(
                        children: [
                          _buildInfoBadge(
                            Icons.star,
                            '${recipe.averageRating.toStringAsFixed(1)}',
                            Colors.amber,
                          ),
                          const HGap.sm(),
                          _buildInfoBadge(
                            Icons.restaurant,
                            '${recipe.timesMade} made',
                            Colors.green,
                          ),
                          const HGap.sm(),
                          _buildInfoBadge(
                            Icons.favorite,
                            '${recipe.favoritesCount}',
                            Colors.pink,
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
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: Radii.mdRadius,
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const HGap.xxs(),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(FamilyRecipe recipe) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: recipe.photos.isNotEmpty
                        ? Image.network(
                            recipe.photos.first,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultRecipeImage(),
                          )
                        : _buildDefaultRecipeImage(),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(recipe.difficulty),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recipe.difficulty.toUpperCase(),
                        style: const TextStyle(
                          color: context.colors.surface,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                        const HGap.xxs(),
                        Text(
                          recipe.averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                        const HGap.xxs(),
                        Text(
                          '${recipe.totalTime} min',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const VGap.xxs(),
                    Row(
                      children: [
                        Icon(Icons.restaurant, size: 14, color: Colors.grey.shade600),
                        const HGap.xxs(),
                        Text(
                          '${recipe.timesMade} made',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        const Spacer(),
                        Icon(Icons.favorite, size: 14, color: Colors.red.shade400),
                        const HGap.xxs(),
                        Text(
                          '${recipe.favoritesCount}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
    );
  }

  Widget _buildDefaultRecipeImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.error, Color(0xFFF87171)],
        ),
      ),
      child: Center(
        child: Icon(Icons.restaurant, size: 60, color: context.colors.surface.withValues(alpha: 0.54)),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return context.colors.error;
      default:
        return Colors.grey;
    }
  }

  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: double.infinity,
            height: 180,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 200,
                  height: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
                const VGap.xs(),
                ShimmerBox(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
