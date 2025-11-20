import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/layout/gap.dart';
import '../../design_system/components/inputs/text_field_x.dart';

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
        title: Text('Categories', style: GoogleFonts.inter(fontWeight: MemoryHubTypography.bold)),
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
          Icon(Icons.category_outlined, size: 80, color: MemoryHubColors.gray400.withOpacity(0.5)),
          VGap.lg(),
          Text(
            'No Categories',
            style: GoogleFonts.inter(
              fontSize: MemoryHubTypography.h2,
              fontWeight: MemoryHubTypography.bold,
            ),
          ),
          VGap.xs(),
          Text(
            'Create your first category',
            style: GoogleFonts.inter(
              fontSize: MemoryHubTypography.bodyLarge,
              color: MemoryHubColors.gray500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(MemoryHubSpacing.xl),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: MemoryHubSpacing.lg,
        mainAxisSpacing: MemoryHubSpacing.lg,
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
      MemoryHubColors.purple500,
      MemoryHubColors.blue500,
      MemoryHubColors.green500,
      MemoryHubColors.amber500,
      MemoryHubColors.pink500,
      MemoryHubColors.teal500,
      MemoryHubColors.indigo500,
      MemoryHubColors.cyan500,
    ];
    final color = colors[category['name'].hashCode % colors.length];

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/categories/detail', arguments: category['id']);
      },
      borderRadius: MemoryHubBorderRadius.xlRadius,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: MemoryHubBorderRadius.xlRadius,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: MemoryHubSpacing.md,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(MemoryHubSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(MemoryHubSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: MemoryHubBorderRadius.mdRadius,
                ),
                child: const Icon(
                  Icons.category,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                category['name'],
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: MemoryHubTypography.h4,
                  fontWeight: MemoryHubTypography.bold,
                ),
              ),
              VGap(4),
              Text(
                '${category['memory_count'] ?? 0} memories',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: MemoryHubTypography.bodySmall + 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateCategoryDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Category', style: GoogleFonts.inter(fontWeight: MemoryHubTypography.bold)),
        content: TextFieldX(
          controller: nameController,
          hint: 'Category name',
          prefix: const Icon(Icons.category),
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
