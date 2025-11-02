import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_tradition.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/add_tradition_dialog.dart';
import 'package:intl/intl.dart';

class FamilyTraditionsScreen extends StatefulWidget {
  const FamilyTraditionsScreen({Key? key}) : super(key: key);

  @override
  State<FamilyTraditionsScreen> createState() => _FamilyTraditionsScreenState();
}

class _FamilyTraditionsScreenState extends State<FamilyTraditionsScreen> {
  final FamilyService _familyService = FamilyService();
  List<FamilyTradition> _traditions = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTraditions();
  }

  Future<void> _loadTraditions() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await _familyService.getTraditions();
      setState(() {
        _traditions = response.items;
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
        onRefresh: _loadTraditions,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Family Traditions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF10B981),
                        Color(0xFF34D399),
                        Color(0xFF6EE7B7),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        bottom: -50,
                        child: Icon(
                          Icons.local_florist,
                          size: 200,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        left: 30,
                        top: 100,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 30,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
            else if (_error.isNotEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Traditions',
                  message: 'Failed to load family traditions. Pull to retry.',
                  actionLabel: 'Retry',
                  onAction: _loadTraditions,
                ),
              )
            else if (_traditions.isEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.local_florist,
                  title: 'No Traditions Yet',
                  message: 'Preserve your family heritage by documenting cherished traditions.',
                  actionLabel: 'Add Tradition',
                  onAction: _showAddDialog,
                  gradientColors: const [
                    Color(0xFF10B981),
                    Color(0xFF34D399),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTraditionCard(_traditions[index]),
                    childCount: _traditions.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'family_traditions_fab',
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Tradition'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Widget _buildTraditionCard(FamilyTradition tradition) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCategoryColor(tradition.category).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(tradition.category),
                          _getCategoryColor(tradition.category).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryColor(tradition.category).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(tradition.category),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tradition.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(tradition.category).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tradition.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(tradition.category),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (tradition.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  tradition.description!,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
              if (tradition.photoUrl != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    tradition.photoUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getCategoryColor(tradition.category),
                              _getCategoryColor(tradition.category).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getCategoryIcon(tradition.category),
                          size: 64,
                          color: Colors.white54,
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (tradition.originAncestorName != null || tradition.countryOfOrigin != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_tree, size: 18, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Text(
                            'Family Lineage',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (tradition.originAncestorName != null) ...[
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Started by: ${tradition.originAncestorName}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (tradition.generationsPassed != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.timeline, size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Passed down ${tradition.generationsPassed} generation${tradition.generationsPassed! > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (tradition.countryOfOrigin != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.public, size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Origin: ${tradition.countryOfOrigin}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ] else if (tradition.culturalOrigin != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.public,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Origin: ${tradition.culturalOrigin}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (tradition.nextOccurrence != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor(tradition.category).withOpacity(0.1),
                        _getCategoryColor(tradition.category).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 18,
                        color: _getCategoryColor(tradition.category),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Next: ${DateFormat('MMM d, y').format(tradition.nextOccurrence!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _getCategoryColor(tradition.category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        tradition.frequency.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getCategoryColor(tradition.category),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'holiday':
        return const Color(0xFFEF4444);
      case 'cultural':
        return const Color(0xFF7C3AED);
      case 'religious':
        return const Color(0xFFF59E0B);
      case 'seasonal':
        return const Color(0xFF10B981);
      case 'family':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF06B6D4);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'holiday':
        return Icons.celebration;
      case 'cultural':
        return Icons.language;
      case 'religious':
        return Icons.mosque;
      case 'seasonal':
        return Icons.wb_sunny;
      case 'family':
        return Icons.family_restroom;
      default:
        return Icons.local_florist;
    }
  }

  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(
                  width: 60,
                  height: 60,
                  borderRadius: BorderRadius.circular(18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 180, height: 20, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 8),
                      ShimmerBox(width: 100, height: 16, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ShimmerBox(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 4),
            ShimmerBox(width: 200, height: 14, borderRadius: BorderRadius.circular(4)),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTraditionDialog(onSubmit: _handleAdd),
    );
  }

  Future<void> _handleAdd(Map<String, dynamic> data) async {
    try {
      await _familyService.createTradition(data);
      _loadTraditions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tradition added successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add tradition: $e'), backgroundColor: Colors.red),
        );
      }
      rethrow;
    }
  }
}
