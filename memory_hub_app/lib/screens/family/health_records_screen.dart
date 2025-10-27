import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/family/family_service.dart';
import '../../models/family/health_record.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/add_health_record_dialog.dart';
import '../../widgets/approval_status_badge.dart';
import 'package:intl/intl.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({Key? key}) : super(key: key);

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  List<HealthRecord> _healthRecords = [];
  bool _isLoading = true;
  String _error = '';
  late AnimationController _animationController;
  String _selectedFilter = 'all';
  String _selectedView = 'grid';

  static const Color primaryMedicalBlue = Color(0xFF2563EB);
  static const Color accentTealGreen = Color(0xFF14B8A6);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color softGray = Color(0xFFF3F4F6);
  static const Color darkGray = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadHealthRecords();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthRecords() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await _familyService.getHealthRecords();
      final List<HealthRecord> records = response.map((record) => HealthRecord.fromJson(record)).toList();
      setState(() {
        _healthRecords = records;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<HealthRecord> get _filteredRecords {
    if (_selectedFilter == 'all') return _healthRecords;
    return _healthRecords.where((record) => record.recordType == _selectedFilter).toList();
  }

  void _showAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddHealthRecordDialog(),
    );
    
    if (result == true) {
      _loadHealthRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGray,
      body: RefreshIndicator(
        onRefresh: _loadHealthRecords,
        color: primaryMedicalBlue,
        child: CustomScrollView(
          slivers: [
            _buildModernAppBar(),
            _buildQuickStats(),
            _buildFilterChips(),
            if (_isLoading)
              _buildLoadingState()
            else if (_error.isNotEmpty)
              _buildErrorState()
            else if (_filteredRecords.isEmpty)
              _buildEmptyState()
            else
              _selectedView == 'grid' ? _buildGridView() : _buildListView(),
          ],
        ),
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
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Health Records',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryMedicalBlue.withOpacity(0.05),
                accentTealGreen.withOpacity(0.05),
                Colors.white,
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
                  color: dangerRed.withOpacity(0.05),
                ),
              ),
              Positioned(
                left: -20,
                top: 100,
                child: Icon(
                  Icons.medical_services_rounded,
                  size: 80,
                  color: primaryMedicalBlue.withOpacity(0.06),
                ),
              ),
              Positioned(
                right: 80,
                top: 80,
                child: Icon(
                  Icons.health_and_safety_rounded,
                  size: 45,
                  color: accentTealGreen.withOpacity(0.08),
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
            color: darkGray,
          ),
          onPressed: () {
            setState(() {
              _selectedView = _selectedView == 'grid' ? 'list' : 'grid';
            });
          },
          tooltip: 'Toggle view',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.filter_list_rounded, color: darkGray),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          offset: const Offset(0, 50),
          onSelected: (value) {
            setState(() {
              _selectedFilter = value;
            });
          },
          itemBuilder: (context) => [
            _buildFilterMenuItem('all', 'All Records', Icons.list_alt_rounded, null),
            const PopupMenuDivider(),
            _buildFilterMenuItem('medical', 'Medical', Icons.medical_services_rounded, primaryMedicalBlue),
            _buildFilterMenuItem('dental', 'Dental', Icons.sentiment_satisfied_rounded, accentTealGreen),
            _buildFilterMenuItem('vaccination', 'Vaccination', Icons.vaccines_rounded, successGreen),
            _buildFilterMenuItem('lab_result', 'Lab Results', Icons.science_rounded, purpleAccent),
            _buildFilterMenuItem('prescription', 'Prescriptions', Icons.medication_rounded, warningAmber),
            _buildFilterMenuItem('allergy', 'Allergies', Icons.warning_amber_rounded, dangerRed),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String value, String label, IconData icon, Color? color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? darkGray).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color ?? darkGray),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: _selectedFilter == value ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_isLoading || _healthRecords.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final totalRecords = _healthRecords.length;
    final recentCount = _healthRecords.where((r) => 
      r.recordDate.isAfter(DateTime.now().subtract(const Duration(days: 30)))
    ).length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Records',
                totalRecords.toString(),
                Icons.description_rounded,
                primaryMedicalBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'This Month',
                recentCount.toString(),
                Icons.calendar_today_rounded,
                accentTealGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    if (_healthRecords.isEmpty && !_isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final filters = [
      {'value': 'all', 'label': 'All', 'icon': Icons.list_alt_rounded},
      {'value': 'medical', 'label': 'Medical', 'icon': Icons.medical_services_rounded},
      {'value': 'vaccination', 'label': 'Vaccination', 'icon': Icons.vaccines_rounded},
      {'value': 'lab_result', 'label': 'Labs', 'icon': Icons.science_rounded},
      {'value': 'prescription', 'label': 'Rx', 'icon': Icons.medication_rounded},
    ];

    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        margin: const EdgeInsets.only(top: 16),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = _selectedFilter == filter['value'];
            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : darkGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter['label'] as String,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              selectedColor: primaryMedicalBlue,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? primaryMedicalBlue : darkGray.withOpacity(0.2),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : darkGray,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter['value'] as String;
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildGridCard(_filteredRecords[index], index),
          childCount: _filteredRecords.length,
        ),
      ),
    );
  }

  Widget _buildListView() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildListCard(_filteredRecords[index], index),
          childCount: _filteredRecords.length,
        ),
      ),
    );
  }

  Widget _buildGridCard(HealthRecord record, int index) {
    final color = _getRecordTypeColor(record.recordType);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showRecordDetails(record),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -15,
                      top: -15,
                      child: Icon(
                        _getRecordTypeIcon(record.recordType),
                        size: 80,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatRecordType(record.recordType),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (record.isConfidential)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Private',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 11, color: darkGray),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(record.recordDate),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: darkGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_pin_rounded, size: 11, color: accentTealGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              record.getSubjectDisplay(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: accentTealGreen,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      buildApprovalStatusBadge(record.approvalStatus),
                      if (record.hasReminders) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: warningAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.notifications_active,
                                size: 10,
                                color: warningAmber,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${record.reminders.length} reminder${record.reminders.length > 1 ? 's' : ''}',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: warningAmber,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(HealthRecord record, int index) {
    final color = _getRecordTypeColor(record.recordType);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showRecordDetails(record),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getRecordTypeIcon(record.recordType),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                record.title,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (record.isConfidential) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: dangerRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_rounded, size: 11, color: dangerRed),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Private',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: dangerRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formatRecordType(record.recordType),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today_rounded, size: 12, color: darkGray),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, yyyy').format(record.recordDate),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: darkGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_pin_rounded, size: 12, color: accentTealGreen),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                record.getSubjectDisplay(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: accentTealGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            buildApprovalStatusBadge(record.approvalStatus),
                            if (record.hasReminders) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: warningAmber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.notifications_active,
                                      size: 11,
                                      color: warningAmber,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${record.reminders.length}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: warningAmber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (record.description != null && record.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            record.description!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: darkGray,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chevron_right_rounded, color: darkGray.withOpacity(0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ShimmerLoading(
            isLoading: true,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final errorMessage = _error.replaceAll('Exception: ', '').replaceAll('Exception:', '');
    return SliverFillRemaining(
      child: EnhancedEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Error Loading Records',
        message: errorMessage.isNotEmpty ? errorMessage : 'Failed to load health records. Pull down to retry.',
        actionLabel: 'Retry',
        onAction: _loadHealthRecords,
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: primaryMedicalBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medical_services_rounded,
                size: 80,
                color: primaryMedicalBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Health Records Yet',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your family\'s health\nby adding your first record',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: darkGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Health Record',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryMedicalBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      heroTag: 'health_records_fab',
      onPressed: _showAddDialog,
      icon: const Icon(Icons.add_rounded, size: 24),
      label: Text(
        'Add Record',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      backgroundColor: primaryMedicalBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  void _showRecordDetails(HealthRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: darkGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getRecordTypeColor(record.recordType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getRecordTypeIcon(record.recordType),
                            size: 32,
                            color: _getRecordTypeColor(record.recordType),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.title,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatRecordType(record.recordType),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: darkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      Icons.calendar_today_rounded,
                      'Date',
                      DateFormat('MMMM d, yyyy').format(record.recordDate),
                    ),
                    if (record.provider != null && record.provider!.isNotEmpty)
                      _buildDetailRow(Icons.person_outline_rounded, 'Provider', record.provider!),
                    if (record.facility != null && record.facility!.isNotEmpty)
                      _buildDetailRow(Icons.local_hospital_rounded, 'Facility', record.facility!),
                    if (record.diagnosis != null && record.diagnosis!.isNotEmpty)
                      _buildDetailRow(Icons.medical_information_rounded, 'Diagnosis', record.diagnosis!),
                    if (record.description != null && record.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        record.description!,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF111827),
                          height: 1.6,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Edit feature coming soon')),
                              );
                            },
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: Text(
                              'Edit',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: primaryMedicalBlue, width: 1.5),
                              foregroundColor: primaryMedicalBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteConfirmation(record);
                            },
                            icon: const Icon(Icons.delete_rounded, size: 18),
                            label: Text(
                              'Delete',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: dangerRed, width: 1.5),
                              foregroundColor: dangerRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMedicalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: softGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: darkGray),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(HealthRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_rounded, color: dangerRed, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Record',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${record.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete feature coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRecordTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return primaryMedicalBlue;
      case 'dental':
        return accentTealGreen;
      case 'vaccination':
        return successGreen;
      case 'lab_result':
        return purpleAccent;
      case 'prescription':
        return warningAmber;
      case 'allergy':
        return dangerRed;
      case 'chronic_condition':
        return const Color(0xFF6366F1);
      default:
        return darkGray;
    }
  }

  IconData _getRecordTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return Icons.medical_services_rounded;
      case 'dental':
        return Icons.sentiment_satisfied_rounded;
      case 'vaccination':
        return Icons.vaccines_rounded;
      case 'lab_result':
        return Icons.science_rounded;
      case 'prescription':
        return Icons.medication_rounded;
      case 'allergy':
        return Icons.warning_amber_rounded;
      case 'chronic_condition':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.note_alt_rounded;
    }
  }

  String _formatRecordType(String type) {
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}
