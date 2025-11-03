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
              case 'clear_filters':
                _controller.clearFilters();
                break;
              case 'refresh':
                _handleRefresh();
                break;
            }
          },
          itemBuilder: (context) => [
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
