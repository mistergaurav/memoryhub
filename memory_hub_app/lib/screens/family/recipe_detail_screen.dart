import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_recipe.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({Key? key, required this.recipeId}) : super(key: key);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  final PageController _pageController = PageController();

  FamilyRecipe? _recipe;
  bool _isLoading = true;
  String _error = '';
  int _currentPhotoIndex = 0;
  int _servings = 0;
  bool _isFavorite = false;
  Set<int> _checkedIngredients = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecipe();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipe() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final recipe = await _familyService.getRecipeDetail(widget.recipeId);
      if (!mounted) return;

      setState(() {
        _recipe = recipe;
        _servings = recipe.servings ?? 4;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _rateRecipe(int rating) async {
    if (_recipe == null) return;

    try {
      await _familyService.rateRecipe(widget.recipeId, rating);
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe rated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRecipe();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rate recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_recipe == null) return;

    try {
      if (_isFavorite) {
        await _familyService.unfavoriteRecipe(widget.recipeId);
      } else {
        await _familyService.favoriteRecipe(widget.recipeId);
      }

      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() => _isFavorite = !_isFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'Added to favorites' : 'Removed from favorites',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsMade() async {
    if (_recipe == null) return;

    try {
      await _familyService.markRecipeMade(widget.recipeId);
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as made!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRecipe();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as made: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty || _recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recipe')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load recipe'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRecipe,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Photo Carousel
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _recipe!.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              background: _buildPhotoCarousel(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon')),
                  );
                },
              ),
            ],
          ),

          // Recipe Info Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating and Stats
                  _buildStatsRow(),
                  const SizedBox(height: 20),

                  // Time and Difficulty Badges
                  _buildInfoBadges(),
                  const SizedBox(height: 20),

                  // Servings Adjuster
                  _buildServingsAdjuster(),
                  const SizedBox(height: 24),

                  // Tabs
                  _buildTabs(),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIngredientsTab(),
                _buildInstructionsTab(),
                _buildDetailsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPhotoCarousel() {
    final photos = _recipe!.photos.isNotEmpty
        ? _recipe!.photos
        : ['placeholder'];

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: photos.length,
          onPageChanged: (index) {
            setState(() => _currentPhotoIndex = index);
          },
          itemBuilder: (context, index) {
            if (photos[index] == 'placeholder') {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.restaurant, size: 120, color: Colors.white54),
                ),
              );
            }
            return Image.network(
              photos[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image, size: 64),
              ),
            );
          },
        ),
        if (photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPhotoIndex == index
                        ? Colors.white
                        : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        // Rating
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            value: _recipe!.averageRating.toStringAsFixed(1),
            label: 'Rating',
            color: Colors.amber,
            onTap: _showRatingDialog,
          ),
        ),
        const SizedBox(width: 12),
        // Times Made
        Expanded(
          child: _buildStatCard(
            icon: Icons.restaurant,
            value: '${_recipe!.timesMade}',
            label: 'Times Made',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        // Favorites
        Expanded(
          child: _buildStatCard(
            icon: Icons.favorite,
            value: '${_recipe!.favoritesCount}',
            label: 'Favorites',
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadges() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildBadge(
          icon: Icons.timer_outlined,
          label: 'Prep',
          value: '${_recipe!.prepTimeMinutes ?? 0} min',
          color: const Color(0xFF06B6D4),
        ),
        _buildBadge(
          icon: Icons.timer,
          label: 'Cook',
          value: '${_recipe!.cookTimeMinutes ?? 0} min',
          color: const Color(0xFF7C3AED),
        ),
        _buildBadge(
          icon: Icons.bar_chart,
          label: 'Difficulty',
          value: _recipe!.difficulty.toUpperCase(),
          color: _getDifficultyColor(_recipe!.difficulty),
        ),
        _buildBadge(
          icon: Icons.category,
          label: 'Category',
          value: _recipe!.categoryDisplay,
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServingsAdjuster() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Color(0xFFEF4444)),
              const SizedBox(width: 12),
              const Text(
                'Servings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFFEF4444),
                onPressed: () {
                  if (_servings > 1) {
                    setState(() => _servings--);
                    HapticFeedback.lightImpact();
                  }
                },
              ),
              Container(
                width: 50,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$_servings',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFFEF4444),
                onPressed: () {
                  setState(() => _servings++);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      labelColor: const Color(0xFFEF4444),
      unselectedLabelColor: Colors.grey,
      indicatorColor: const Color(0xFFEF4444),
      tabs: const [
        Tab(text: 'Ingredients'),
        Tab(text: 'Instructions'),
        Tab(text: 'Details'),
      ],
    );
  }

  Widget _buildIngredientsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...List.generate(_recipe!.ingredients.length, (index) {
          final ingredient = _recipe!.ingredients[index];
          return CheckboxListTile(
            value: _checkedIngredients.contains(index),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _checkedIngredients.add(index);
                } else {
                  _checkedIngredients.remove(index);
                }
              });
              HapticFeedback.selectionClick();
            },
            activeColor: const Color(0xFFEF4444),
            title: Text(
              ingredient.name,
              style: TextStyle(
                decoration: _checkedIngredients.contains(index)
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(
              '${ingredient.amount}${ingredient.unit != null ? ' ${ingredient.unit}' : ''}',
              style: TextStyle(
                color: Colors.grey.shade600,
                decoration: _checkedIngredients.contains(index)
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInstructionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...List.generate(_recipe!.steps.length, (index) {
          final step = _recipe!.steps[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${step.stepNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.instruction,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      if (step.photo != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            step.photo!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_recipe!.description != null) ...[
          _buildDetailSection('Description', _recipe!.description!),
          const SizedBox(height: 20),
        ],
        if (_recipe!.originStory != null) ...[
          _buildDetailSection('Origin Story', _recipe!.originStory!,
              icon: Icons.history_edu),
          const SizedBox(height: 20),
        ],
        if (_recipe!.familyNotes != null) ...[
          _buildDetailSection('Family Notes', _recipe!.familyNotes!,
              icon: Icons.family_restroom),
          const SizedBox(height: 20),
        ],
        if (_recipe!.createdByName != null) ...[
          _buildDetailSection(
            'Created By',
            _recipe!.createdByName!,
            icon: Icons.person,
          ),
          const SizedBox(height: 20),
        ],
        _buildDetailSection(
          'Created On',
          _formatDate(_recipe!.createdAt),
          icon: Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, String content, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: const Color(0xFFEF4444)),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _markAsMade,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'I Made This!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate this Recipe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < (_recipe?.averageRating ?? 0).round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _rateRecipe(index + 1);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'hard':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
