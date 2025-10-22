import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/quick_add_health_record_dialog.dart';
import '../../dialogs/family/add_vaccination_dialog.dart';
import 'package:intl/intl.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({Key? key}) : super(key: key);

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _healthRecords = [];
  List<Map<String, dynamic>> _vaccinations = [];
  bool _isLoadingRecords = true;
  bool _isLoadingVaccinations = true;
  String _error = '';
  String? _selectedRecordType;
  String? _lastAddedRecordId;

  final List<Map<String, dynamic>> _recordTypes = [
    {'label': 'All', 'value': null, 'icon': Icons.all_inclusive, 'color': Colors.grey},
    {'label': 'Medical', 'value': 'medical', 'icon': Icons.medical_services, 'color': Color(0xFF3B82F6)},
    {'label': 'Allergies', 'value': 'allergy', 'icon': Icons.coronavirus, 'color': Color(0xFFEF4444)},
    {'label': 'Conditions', 'value': 'condition', 'icon': Icons.sick, 'color': Color(0xFFF59E0B)},
    {'label': 'Surgery', 'value': 'surgery', 'icon': Icons.local_hospital, 'color': Color(0xFF8B5CF6)},
    {'label': 'Emergency', 'value': 'emergency', 'icon': Icons.emergency, 'color': Color(0xFFDC2626)},
    {'label': 'Vaccination', 'value': 'vaccination', 'icon': Icons.vaccines, 'color': Color(0xFF10B981)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHealthRecords();
    _loadVaccinations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthRecords() async {
    setState(() {
      _isLoadingRecords = true;
      _error = '';
    });
    try {
      final records = await _familyService.getHealthRecords(
        recordType: _selectedRecordType,
      );
      setState(() {
        _healthRecords = records;
        _isLoadingRecords = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingRecords = false;
      });
    }
  }

  Future<void> _loadVaccinations() async {
    setState(() => _isLoadingVaccinations = true);
    try {
      final vaccinations = await _familyService.getVaccinations();
      setState(() {
        _vaccinations = vaccinations;
        _isLoadingVaccinations = false;
      });
    } catch (e) {
      setState(() => _isLoadingVaccinations = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadHealthRecords(),
      _loadVaccinations(),
    ]);
  }

  void _showQuickAddHealthRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => QuickAddHealthRecordDialog(
        onSubmit: _handleAddHealthRecord,
      ),
    );
  }

  void _showAddVaccinationDialog() {
    showDialog(
      context: context,
      builder: (context) => AddVaccinationDialog(
        onSubmit: _handleAddVaccination,
      ),
    );
  }

  Future<void> _handleAddHealthRecord(Map<String, dynamic> data) async {
    try {
      final result = await _familyService.createHealthRecord(data);
      
      setState(() {
        _lastAddedRecordId = result['id'] ?? result['_id'];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Health record added successfully'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              _loadHealthRecords().then((_) {
                final record = _healthRecords.firstWhere(
                  (r) => (r['id'] ?? r['_id']) == _lastAddedRecordId,
                  orElse: () => {},
                );
                if (record.isNotEmpty) {
                  _showRecordDetails(record);
                }
              });
            },
          ),
        ),
      );
      _loadHealthRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add health record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAddVaccination(Map<String, dynamic> data) async {
    try {
      await _familyService.createVaccination(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vaccination added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadVaccinations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add vaccination: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteHealthRecord(String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this health record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _familyService.deleteHealthRecord(recordId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadHealthRecords();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Health Records',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEF4444),
                      Color(0xFFF87171),
                      Color(0xFFFCA5A5),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      bottom: -30,
                      child: Icon(
                        Icons.health_and_safety,
                        size: 150,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search feature coming soon')),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Health Records'),
                Tab(text: 'Vaccinations'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildHealthRecordsTab(),
            _buildVaccinationsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'health_records_fab',
        onPressed: () {
          if (_tabController.index == 0) {
            _showQuickAddHealthRecordDialog();
          } else {
            _showAddVaccinationDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Quick Add' : 'Add Vaccination'),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  Widget _buildHealthRecordsTab() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildFilterChips(),
            ),
          ),
          if (_isLoadingRecords)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildShimmerCard(),
                  ),
                  childCount: 5,
                ),
              ),
            )
          else if (_error.isNotEmpty)
            SliverFillRemaining(
              child: EnhancedEmptyState(
                icon: Icons.error_outline,
                title: 'Error Loading Records',
                message: 'Failed to load health records. Pull to retry.',
                actionLabel: 'Retry',
                onAction: _loadHealthRecords,
              ),
            )
          else if (_healthRecords.isEmpty)
            SliverFillRemaining(
              child: EnhancedEmptyState(
                icon: Icons.health_and_safety,
                title: 'Start Your Health Journey',
                message: 'Keep your family\'s health records organized and accessible. Tap the button below to add your first record in just 30 seconds!',
                actionLabel: 'Add First Record',
                onAction: _showQuickAddHealthRecordDialog,
                gradientColors: const [
                  Color(0xFFEF4444),
                  Color(0xFFF87171),
                ],
              ),
            )
          else
            ..._buildGroupedRecords(),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildVaccinationsTab() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _isLoadingVaccinations
          ? ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildShimmerCard(),
              ),
            )
          : _vaccinations.isEmpty
              ? EnhancedEmptyState(
                  icon: Icons.vaccines,
                  title: 'No Vaccinations Yet',
                  message: 'Keep track of family vaccinations and immunization schedules to stay healthy and protected.',
                  actionLabel: 'Add Vaccination',
                  onAction: _showAddVaccinationDialog,
                  gradientColors: const [
                    Color(0xFFEF4444),
                    Color(0xFFF87171),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _vaccinations.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildVaccinationCard(_vaccinations[index]),
                  ),
                ),
    );
  }

  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.filter_list, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              'Filter by Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recordTypes.length,
            itemBuilder: (context, index) {
              final filter = _recordTypes[index];
              final isSelected = _selectedRecordType == filter['value'];
              final color = filter['color'] as Color;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 6),
                      Text(filter['label'] as String),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedRecordType = filter['value'] as String?;
                    });
                    _loadHealthRecords();
                  },
                  selectedColor: color,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  elevation: isSelected ? 2 : 0,
                  pressElevation: 4,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedRecords() {
    final groupedByMember = <String, List<Map<String, dynamic>>>{};
    
    for (var record in _healthRecords) {
      final memberName = record['genealogy_person_name'] ?? 
                        record['family_member_name'] ?? 
                        record['person_name'] ?? 
                        'Unknown Member';
      
      if (!groupedByMember.containsKey(memberName)) {
        groupedByMember[memberName] = [];
      }
      groupedByMember[memberName]!.add(record);
    }
    
    final widgets = <Widget>[];
    
    groupedByMember.forEach((memberName, records) {
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  memberName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${records.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildHealthRecordCard(records[index]),
              ),
              childCount: records.length,
            ),
          ),
        ),
      );
    });
    
    return widgets;
  }

  Widget _buildHealthRecordCard(Map<String, dynamic> record) {
    final title = record['title'] ?? 'Untitled';
    final recordType = record['record_type'] ?? 'unknown';
    final date = record['date'] ?? record['record_date'];
    final memberName = record['genealogy_person_name'] ?? record['family_member_name'] ?? record['person_name'] ?? 'Unknown Member';
    final severity = record['severity'];
    final provider = record['provider'];
    final description = record['description'];
    final isHereditary = record['is_hereditary'] ?? false;
    final inheritancePattern = record['inheritance_pattern'];
    final affectedRelatives = record['affected_relatives'] as List<dynamic>?;
    final ageOfOnset = record['age_of_onset'];
    final recordId = record['id'] ?? record['_id'] ?? '';

    Color getSeverityColor() {
      switch (severity) {
        case 'critical':
          return Colors.red;
        case 'high':
          return Colors.orange;
        case 'moderate':
          return Colors.yellow.shade700;
        default:
          return Colors.green;
      }
    }

    IconData getRecordTypeIcon() {
      switch (recordType) {
        case 'medical':
          return Icons.medical_services;
        case 'allergy':
          return Icons.coronavirus;
        case 'condition':
          return Icons.sick;
        case 'surgery':
          return Icons.local_hospital;
        case 'emergency':
          return Icons.emergency;
        case 'vaccination':
          return Icons.vaccines;
        default:
          return Icons.medical_services;
      }
    }

    Color getRecordTypeColor() {
      final type = _recordTypes.firstWhere(
        (t) => t['value'] == recordType,
        orElse: () => _recordTypes[1],
      );
      return type['color'] as Color;
    }

    return Dismissible(
      key: Key(recordId),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Record'),
              content: const Text('Are you sure you want to delete this health record?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        } else if (direction == DismissDirection.startToEnd) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Edit feature coming soon')),
          );
          return false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _familyService.deleteHealthRecord(recordId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Health record deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showRecordDetails(record),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(
                  color: getRecordTypeColor(),
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: getRecordTypeColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          getRecordTypeIcon(),
                          color: getRecordTypeColor(),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: getRecordTypeColor().withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    recordType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: getRecordTypeColor(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (severity != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getSeverityColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: getSeverityColor(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (date != null) ...[
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (provider != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.local_hospital,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            provider,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isHereditary) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.family_restroom, size: 16, color: Colors.purple.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'Hereditary Condition',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                          if (inheritancePattern != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Pattern: ${_formatInheritancePattern(inheritancePattern)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                          if (ageOfOnset != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Age of onset: $ageOfOnset years',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                          if (affectedRelatives != null && affectedRelatives.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Affected relatives: ${affectedRelatives.length}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVaccinationCard(Map<String, dynamic> vaccination) {
    final vaccineName = vaccination['vaccine_name'] ?? 'Unknown Vaccine';
    final dateAdministered = vaccination['date_administered'];
    final memberName = vaccination['family_member_name'] ?? 'Unknown Member';
    final provider = vaccination['provider'];
    final nextDoseDate = vaccination['next_dose_date'];
    final lotNumber = vaccination['lot_number'];

    final bool needsNextDose = nextDoseDate != null && 
        DateTime.parse(nextDoseDate).isAfter(DateTime.now());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showVaccinationDetails(vaccination),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.vaccines,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vaccineName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                memberName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (needsNextDose)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Next Dose',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Administered: ${_formatDate(dateAdministered)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (nextDoseDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Next Dose: ${_formatDate(nextDoseDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
              if (provider != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.local_hospital,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        provider,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (lotNumber != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.qr_code,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lot: $lotNumber',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 48, height: 48, borderRadius: BorderRadius.circular(12)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 150, height: 16, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 8),
                      ShimmerBox(width: 100, height: 12, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ShimmerBox(width: double.infinity, height: 12, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 4),
            ShimmerBox(width: 200, height: 12, borderRadius: BorderRadius.circular(4)),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        return DateFormat('MMM d, yyyy').format(parsedDate);
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  String _formatInheritancePattern(String pattern) {
    switch (pattern) {
      case 'autosomal_dominant':
        return 'Autosomal Dominant';
      case 'autosomal_recessive':
        return 'Autosomal Recessive';
      case 'x_linked_dominant':
        return 'X-Linked Dominant';
      case 'x_linked_recessive':
        return 'X-Linked Recessive';
      case 'mitochondrial':
        return 'Mitochondrial';
      case 'multifactorial':
        return 'Multifactorial';
      default:
        return pattern;
    }
  }

  void _showRecordDetails(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                record['title'] ?? 'Health Record',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (record['description'] != null) ...[
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit feature coming soon')),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteHealthRecord(record['id'] ?? record['_id'] ?? '');
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  void _showVaccinationDetails(Map<String, dynamic> vaccination) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                vaccination['vaccine_name'] ?? 'Vaccination',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit feature coming soon')),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
