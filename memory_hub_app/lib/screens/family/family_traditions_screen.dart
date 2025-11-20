import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_tradition.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/add_tradition_dialog.dart';
import 'package:intl/intl.dart';
import '../../design_system/design_system.dart';

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
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      Positioned(
                        left: 30,
                        top: 100,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 30,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.all(16),
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
                  gradientColors: [
                    const Color(0xFF10B981),
                    const Color(0xFF34D399),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
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
      margin: EdgeInsets.only(bottom: 16),
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
              _getCategoryColor(tradition.category).withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: Padded(padding: const EdgeInsets.all(20), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padded(padding: const EdgeInsets.all(14), 
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(tradition.category),
                          _getCategoryColor(tradition.category).withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryColor(tradition.category).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(tradition.category),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const HGap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tradition.title,
                          style: context.text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const VGap(4),
                        Padded.symmetric(
                          horizontal: 10,
                          vertical: 4,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(tradition.category).withOpacity(0.2),
                            borderRadius: Radii.mdRadius,
                          ),
                          child: Text(
                            tradition.category.toUpperCase(),
                            style: context.text.labelSmall?.copyWith(
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
                const VGap(16),
                Text(
                  tradition.description!,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurface.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
              ],
              if (tradition.photoUrl != null) ...[
                const VGap(16),
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
                              _getCategoryColor(tradition.category).withValues(alpha: 0.7),
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
              const VGap(16),
              if (tradition.originAncestorName != null || tradition.countryOfOrigin != null) ...[
                Padded(padding: const EdgeInsets.all(14), 
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
                          const HGap(8),
                          Text(
                            'Family Lineage',
                            style: context.text.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      const VGap(10),
                      if (tradition.originAncestorName != null) ...[
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                            const HGap(6),
                            Expanded(
                              child: Text(
                                'Started by: ${tradition.originAncestorName}',
                                style: context.text.bodySmall?.copyWith(
                                  color: context.colors.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (tradition.generationsPassed != null) ...[
                        const VGap(6),
                        Row(
                          children: [
                            Icon(Icons.timeline, size: 16, color: Colors.grey.shade700),
                            const HGap(6),
                            Text(
                              'Passed down ${tradition.generationsPassed} generation${tradition.generationsPassed! > 1 ? 's' : ''}',
                              style: context.text.bodySmall?.copyWith(
                                color: context.colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (tradition.countryOfOrigin != null) ...[
                        const VGap(6),
                        Row(
                          children: [
                            Icon(Icons.public, size: 16, color: Colors.grey.shade700),
                            const HGap(6),
                            Text(
                              'Origin: ${tradition.countryOfOrigin}',
                              style: context.text.bodySmall?.copyWith(
                                color: context.colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ] else if (tradition.culturalOrigin != null)
                Padded(padding: const EdgeInsets.all(12), 
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
                      const HGap(8),
                      Text(
                        'Origin: ${tradition.culturalOrigin}',
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (tradition.nextOccurrence != null) ...[
                const VGap(12),
                Padded(padding: const EdgeInsets.all(12), 
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor(tradition.category).withValues(alpha: 0.1),
                        _getCategoryColor(tradition.category).withValues(alpha: 0.05),
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
                      const HGap(8),
                      Text(
                        'Next: ${DateFormat('MMM d, y').format(tradition.nextOccurrence!)}',
                        style: context.text.bodyMedium?.copyWith(
                          color: _getCategoryColor(tradition.category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        tradition.frequency.toUpperCase(),
                        style: context.text.labelSmall?.copyWith(
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
        return MemoryHubColors.red500;
      case 'cultural':
        return MemoryHubColors.violet600;
      case 'religious':
        return MemoryHubColors.amber500;
      case 'seasonal':
        return const Color(0xFF10B981);
      case 'family':
        return MemoryHubColors.pink500;
      default:
        return MemoryHubColors.cyan500;
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
      margin: EdgeInsets.only(bottom: 16),
      child: Padded(padding: const EdgeInsets.all(20), 
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
                const HGap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 180, height: 20, borderRadius: BorderRadius.circular(4)),
                      const VGap(8),
                      ShimmerBox(width: 100, height: 16, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ),
              ],
            ),
            const VGap(16),
            ShimmerBox(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(4)),
            const VGap(4),
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
