import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
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
        title: Text('Categories', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreateCategoryDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? _buildEmptyState()
              : _buildCategoriesGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No Categories',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first category',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];
    final color = colors[category['name'].hashCode % colors.length];

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/categories/detail', arguments: category['id']);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(category['name']),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                category['name'],
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${category['memory_count'] ?? 0} memories',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lowercaseName = name.toLowerCase();
    if (lowercaseName.contains('family')) return Icons.family_restroom;
    if (lowercaseName.contains('travel')) return Icons.flight;
    if (lowercaseName.contains('work')) return Icons.work;
    if (lowercaseName.contains('food')) return Icons.restaurant;
    if (lowercaseName.contains('birthday')) return Icons.cake;
    return Icons.category;
  }

  void _showCreateCategoryDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Category', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Category name',
            prefixIcon: Icon(Icons.category),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await _apiService.createCategory({'name': nameController.text});
                  if (mounted) {
                    Navigator.pop(context);
                    _loadCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category created')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
