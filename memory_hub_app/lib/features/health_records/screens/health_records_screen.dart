import 'package:flutter/material.dart';
import '../design_system.dart';
import '../state/health_records_controller.dart';
import '../widgets/health_record_card.dart';
import '../widgets/record_filter_chips.dart';
import '../widgets/health_stats_card.dart';
import '../widgets/empty_state_widget.dart';
import '../../../dialogs/family/add_health_record_dialog.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/enhanced_empty_state.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({Key? key}) : super(key: key);

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen>
    with SingleTickerProviderStateMixin {
  late HealthRecordsController _controller;
  late AnimationController _fabAnimationController;
  String _selectedView = 'grid';

  @override
  void initState() {
    super.initState();
    _controller = HealthRecordsController();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: HealthRecordsDesignSystem.animationNormal,
    );
    _loadData();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _controller.loadRecords(),
      _controller.loadDashboard(),
    ]);
  }

  Future<void> _handleRefresh() async {
    await _controller.loadRecords(forceRefresh: true);
  }

  void _showAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddHealthRecordDialog(),
    );

    if (result == true && mounted) {
      await _controller.loadRecords(forceRefresh: true);
    }
  }

  void _showRecordDetails(String recordId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening details for record: $recordId'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
        ),
      ),
    );
  }

  void _showStatistics() {
    final stats = _controller.getRecordTypeStats();
    final recentCount = _controller.getRecentRecordsCount(days: 30);
    final recentWeekCount = _controller.getRecentRecordsCount(days: 7);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusLarge),
        ),
        title: Row(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              color: HealthRecordsDesignSystem.deepCobalt,
            ),
            const SizedBox(width: HealthRecordsDesignSystem.spacing12),
            const Text('Health Records Statistics'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Total Records', _controller.totalRecords.toString()),
              _buildStatRow('This Week', recentWeekCount.toString()),
              _buildStatRow('This Month', recentCount.toString()),
              const Divider(height: 24),
              const Text(
                'By Record Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...stats.entries.map((entry) => _buildStatRow(
                entry.key.replaceAll('_', ' ').toUpperCase(),
                entry.value.toString(),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: HealthRecordsDesignSystem.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: HealthRecordsDesignSystem.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: HealthRecordsDesignSystem.deepCobalt,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealthRecordsDesignSystem.backgroundColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: HealthRecordsDesignSystem.tealAccent,
            child: CustomScrollView(
              slivers: [
                _buildModernAppBar(),
                if (_controller.isLoaded) ...[
                  _buildQuickStats(),
                  _buildFilterChips(),
                ],
                _buildContent(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: HealthRecordsDesignSystem.surfaceColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
          left: HealthRecordsDesignSystem.spacing20,
          bottom: HealthRecordsDesignSystem.spacing16,
        ),
        title: Text(
          'Health Records',
          style: HealthRecordsDesignSystem.textTheme.displayMedium,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HealthRecordsDesignSystem.deepCobalt.withOpacity(0.05),
                HealthRecordsDesignSystem.tealAccent.withOpacity(0.05),
                HealthRecordsDesignSystem.surfaceColor,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: 40,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 140,
                  color: HealthRecordsDesignSystem.errorRed.withOpacity(0.05),
                ),
              ),
              Positioned(
                left: -20,
                top: 100,
                child: Icon(
                  Icons.medical_services_rounded,
                  size: 80,
                  color: HealthRecordsDesignSystem.deepCobalt.withOpacity(0.06),
                ),
              ),
              Positioned(
                right: 80,
                top: 80,
                child: Icon(
                  Icons.health_and_safety_rounded,
                  size: 45,
                  color: HealthRecordsDesignSystem.tealAccent.withOpacity(0.08),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _selectedView == 'grid' ? Icons.view_list_rounded : Icons.grid_view_rounded,
            color: HealthRecordsDesignSystem.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _selectedView = _selectedView == 'grid' ? 'list' : 'grid';
            });
          },
          tooltip: 'Toggle view',
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: HealthRecordsDesignSystem.textSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
          ),
          offset: const Offset(0, 50),
          onSelected: (value) {
            switch (value) {
              case 'sort_date_desc':
                _controller.setSortBy('date_desc');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sorted by: Newest First'), duration: Duration(seconds: 1)),
                );
                break;
              case 'sort_date_asc':
                _controller.setSortBy('date_asc');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sorted by: Oldest First'), duration: Duration(seconds: 1)),
                );
                break;
              case 'sort_title_asc':
                _controller.setSortBy('title_asc');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sorted by: Title (A-Z)'), duration: Duration(seconds: 1)),
                );
                break;
              case 'sort_title_desc':
                _controller.setSortBy('title_desc');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sorted by: Title (Z-A)'), duration: Duration(seconds: 1)),
                );
                break;
              case 'clear_filters':
                _controller.clearFilters();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filters cleared'), duration: Duration(seconds: 1)),
                );
                break;
              case 'refresh':
                _handleRefresh();
                break;
              case 'export':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon'), duration: Duration(seconds: 2)),
                );
                break;
              case 'statistics':
                _showStatistics();
                break;
              case 'clear_cache':
                _controller.clearCache();
                _handleRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared and refreshed'), duration: Duration(seconds: 1)),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              enabled: false,
              child: Text(
                'Sort By',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            PopupMenuItem(
              value: 'sort_date_desc',
              child: Row(
                children: [
                  Icon(
                    _controller.selectedSortBy == 'date_desc' ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 18,
                    color: _controller.selectedSortBy == 'date_desc' 
                        ? HealthRecordsDesignSystem.deepCobalt
                        : HealthRecordsDesignSystem.textSecondary,
                  ),
                  const SizedBox(width: HealthRecordsDesignSystem.spacing12),
                  Text(
                    'Newest First',
                    style: HealthRecordsDesignSystem.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'sort_date_asc',
              child: Row(
                children: [
                  Icon(
                    _controller.selectedSortBy == 'date_asc' ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 18,
                    color: _controller.selectedSortBy == 'date_asc' 
                        ? HealthRecordsDesignSystem.deepCobalt
                        : HealthRecordsDesignSystem.textSecondary,
                  ),
                  const SizedBox(width: HealthRecordsDesignSystem.spacing12),
                  Text(
                    'Oldest First',
                    style: HealthRecordsDesignSystem.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'sort_title_asc',
              child: Row(
                children: [
                  Icon(
                    _controller.selectedSortBy == 'title_asc' ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 18,
                    color: _controller.selectedSortBy == 'title_asc' 
                        ? HealthRecordsDesignSystem.deepCobalt
                        : HealthRecordsDesignSystem.textSecondary,
                  ),
                  const SizedBox(width: HealthRecordsDesignSystem.spacing12),
                  Text(
                    'Title (A-Z)',
                    style: HealthRecordsDesignSystem.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'sort_title_desc',
              child: Row(
                children: [
                  Icon(
                    _controller.selectedSortBy == 'title_desc' ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 18,
                    color: _controller.selectedSortBy == 'title_desc' 
                        ? HealthRecordsDesignSystem.deepCobalt
                        : HealthRecordsDesignSystem.textSecondary,
                  ),
                  const SizedBox(width: HealthRecordsDesignSystem.spacing12),
                  Text(
                    'Title (Z-A)',
                    style: HealthRecordsDesignSystem.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'statistics',
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: HealthRecordsDesignSystem.textSecondary,
                  ),
                  const SizedBox(width: HealthRecordsDesignSystem.spacing12),
                  Text(
                    'View Statistics',
                    style: HealthRecordsDesignSystem.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(
                    Icons.download_rounded,
                    size: 18,
                    color: HealthRecordsDesignSystem.textSecondary,
                  ),
                  const SizedBox(width: HealthRecordsDesignSystem.spacing12),
                  Text(
                    'Export Records',
                    style: HealthRecordsDesignSystem.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'clear_filters',
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_off_rounded,
                    size: 18,
                    color: HealthRecordsDesignSystem.textSecondary,
                  ),
                  const SizedBox(width: HealthRecordsDesignSystem.spacing12),
                  Text(
                    'Clear Filters',
                    style: HealthRecordsDesignSystem.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear_cache',
              child: Row(
                children: [
                  Icon(
                    Icons.cleaning_services_rounded,
                    size: 18,
                    color: HealthRecordsDesignSystem.textSecondary,
                  ),
                  const SizedBox(width: HealthRecordsDesignSystem.spacing12),
                  Text(
                    'Clear Cache',
                    style: HealthRecordsDesignSystem.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: HealthRecordsDesignSystem.textSecondary,
                  ),
                  const SizedBox(width: HealthRecordsDesignSystem.spacing12),
                  Text(
                    'Refresh',
                    style: HealthRecordsDesignSystem.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: HealthRecordsDesignSystem.spacing8),
      ],
    );
  }

  Widget _buildQuickStats() {
    final recentCount = _controller.getRecentRecordsCount(days: 30);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          HealthRecordsDesignSystem.spacing16,
          HealthRecordsDesignSystem.spacing16,
          HealthRecordsDesignSystem.spacing16,
          0,
        ),
        child: Row(
          children: [
            Expanded(
              child: HealthStatsCard(
                label: 'Total Records',
                value: _controller.totalRecords.toString(),
                icon: Icons.description_rounded,
                color: HealthRecordsDesignSystem.deepCobalt,
              ),
            ),
            const SizedBox(width: HealthRecordsDesignSystem.spacing12),
            Expanded(
              child: HealthStatsCard(
                label: 'This Month',
                value: recentCount.toString(),
                icon: Icons.calendar_today_rounded,
                color: HealthRecordsDesignSystem.tealAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {
        'value': 'all',
        'label': 'All',
        'icon': Icons.list_alt_rounded,
        'color': HealthRecordsDesignSystem.deepCobalt,
      },
      {
        'value': 'medical',
        'label': 'Medical',
        'icon': Icons.medical_services_rounded,
        'color': HealthRecordsDesignSystem.deepCobalt,
      },
      {
        'value': 'vaccination',
        'label': 'Vaccination',
        'icon': Icons.vaccines_rounded,
        'color': HealthRecordsDesignSystem.successGreen,
      },
      {
        'value': 'lab_result',
        'label': 'Labs',
        'icon': Icons.science_rounded,
        'color': HealthRecordsDesignSystem.purpleAccent,
      },
      {
        'value': 'prescription',
        'label': 'Rx',
        'icon': Icons.medication_rounded,
        'color': HealthRecordsDesignSystem.warningOrange,
      },
      {
        'value': 'allergy',
        'label': 'Allergy',
        'icon': Icons.warning_amber_rounded,
        'color': HealthRecordsDesignSystem.errorRed,
      },
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: HealthRecordsDesignSystem.spacing16),
        child: RecordFilterChips(
          selectedFilter: _controller.selectedFilter,
          onFilterSelected: (filter) => _controller.setFilter(filter),
          filters: filters,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading) {
      return _buildLoadingState();
    }

    if (_controller.hasError) {
      return _buildErrorState();
    }

    if (_controller.isEmpty) {
      return _buildEmptyState();
    }

    return _selectedView == 'grid' ? _buildGridView() : _buildListView();
  }

  Widget _buildGridView() {
    return SliverPadding(
      padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: HealthRecordsDesignSystem.spacing12,
          mainAxisSpacing: HealthRecordsDesignSystem.spacing12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final record = _controller.records[index];
            return HealthRecordCard(
              record: record,
              onTap: () => _showRecordDetails(record.id),
              animationDelay: index * 50,
              isGridView: true,
            );
          },
          childCount: _controller.records.length,
        ),
      ),
    );
  }

  Widget _buildListView() {
    return SliverPadding(
      padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final record = _controller.records[index];
            return HealthRecordCard(
              record: record,
              onTap: () => _showRecordDetails(record.id),
              animationDelay: index * 50,
              isGridView: false,
            );
          },
          childCount: _controller.records.length,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: HealthRecordsDesignSystem.spacing12,
          mainAxisSpacing: HealthRecordsDesignSystem.spacing12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ShimmerLoading(
            isLoading: true,
            child: Container(
              decoration: BoxDecoration(
                color: HealthRecordsDesignSystem.surfaceColor,
                borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusXLarge),
              ),
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final errorMessage = _controller.errorMessage ?? 'An unexpected error occurred';
    
    return SliverFillRemaining(
      child: EnhancedEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Error Loading Records',
        message: errorMessage,
        actionLabel: 'Retry',
        onAction: () => _controller.loadRecords(forceRefresh: true),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_controller.selectedFilter != 'all') {
      return SliverFillRemaining(
        child: HealthRecordsEmptyState(
          title: 'No Records Found',
          message: 'No records match your current filter.\nTry selecting a different filter or add a new record.',
          icon: Icons.filter_alt_off_rounded,
          iconColor: HealthRecordsDesignSystem.textSecondary,
          actionLabel: 'Clear Filters',
          onAction: () => _controller.clearFilters(),
        ),
      );
    }

    return SliverFillRemaining(
      child: HealthRecordsEmptyState(
        title: 'No Health Records Yet',
        message: 'Start tracking your family\'s health\nby adding your first record',
        icon: Icons.medical_services_rounded,
        iconColor: HealthRecordsDesignSystem.deepCobalt,
        actionLabel: 'Add Health Record',
        onAction: _showAddDialog,
      ),
    );
  }

  Widget _buildFAB() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
      child: FloatingActionButton.extended(
        heroTag: 'health_records_fab',
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(
          'Add Record',
          style: HealthRecordsDesignSystem.textTheme.labelLarge?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: HealthRecordsDesignSystem.deepCobalt,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
        ),
      ),
    );
  }
}
