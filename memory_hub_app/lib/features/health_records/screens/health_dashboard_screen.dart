import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:memory_hub_app/design_system/design_tokens.dart';
import '../state/health_records_controller.dart';
import '../../../../dialogs/family/add_health_record_dialog.dart';
import '../../../../dialogs/family/health_record_approval_dialog.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthRecordsController>().loadDashboard();
    });
  }

  void _showAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddHealthRecordDialog(),
    );

    if (result == true && mounted) {
      context.read<HealthRecordsController>().loadDashboard();
    }
  }

  void _showApprovalDialog() {
    showDialog(
      context: context,
      builder: (context) => const HealthRecordApprovalDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MemoryHubColors.gray50,
      body: Consumer<HealthRecordsController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.dashboard.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final dashboard = controller.dashboard;
          final pendingCount = dashboard['pending_approvals_count'] ?? 0;
          final upcomingEvents = (dashboard['upcoming_events'] as List?) ?? [];
          final recentRecords = (dashboard['recent_records'] as List?) ?? [];

          return RefreshIndicator(
            onRefresh: () => controller.loadDashboard(),
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pendingCount > 0) ...[
                          _buildPendingApprovalsCard(pendingCount),
                          const SizedBox(height: 24),
                        ],
                        _buildSectionHeader('Upcoming Timeline'),
                        const SizedBox(height: 16),
                        _buildTimeline(upcomingEvents),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Quick Actions'),
                        const SizedBox(height: 16),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Recent Updates'),
                        const SizedBox(height: 16),
                        _buildRecentRecords(recentRecords),
                        const SizedBox(height: 80), // Bottom padding for FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: MemoryHubColors.teal600,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Record',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      backgroundColor: MemoryHubColors.teal600,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Health Dashboard',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [MemoryHubColors.teal600, MemoryHubColors.cyan500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: MemoryHubColors.gray900,
      ),
    );
  }

  Widget _buildPendingApprovalsCard(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MemoryHubColors.orange500.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MemoryHubColors.orange500.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: MemoryHubColors.orange500,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.approval, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Pending Approvals',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: MemoryHubColors.gray900,
                  ),
                ),
                Text(
                  'Review records waiting for your approval',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: MemoryHubColors.gray600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showApprovalDialog,
            child: Text(
              'Review',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: MemoryHubColors.orange600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List events) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MemoryHubColors.gray200),
        ),
        child: Center(
          child: Text(
            'No upcoming events',
            style: GoogleFonts.inter(color: MemoryHubColors.gray500),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final event = events[index];
          final date = DateTime.parse(event['date']);
          final isMedication = event['type'] == 'medication';
          
          return Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isMedication 
                            ? MemoryHubColors.red500.withOpacity(0.1) 
                            : MemoryHubColors.blue500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isMedication ? Icons.medication : Icons.calendar_today,
                        color: isMedication ? MemoryHubColors.red500 : MemoryHubColors.blue500,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d').format(date),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: MemoryHubColors.gray600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  event['title'] ?? 'Event',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: MemoryHubColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(date),
                  style: GoogleFonts.inter(
                    color: MemoryHubColors.gray500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.monitor_heart,
            label: 'Log Vitals',
            color: MemoryHubColors.purple500,
            onTap: () {
              // TODO: Implement Log Vitals
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.upload_file,
            label: 'Upload Doc',
            color: MemoryHubColors.blue500,
            onTap: () {
              // TODO: Implement Upload Doc
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.history,
            label: 'History',
            color: MemoryHubColors.teal600,
            onTap: () {
              Navigator.pushNamed(context, '/family/health/history');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MemoryHubColors.gray200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: MemoryHubColors.gray900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecords(List records) {
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: records.map((record) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MemoryHubColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForType(record['record_type']),
                  color: MemoryHubColors.gray700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record['title'] ?? 'Untitled',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: MemoryHubColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(DateTime.parse(record['date'])),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: MemoryHubColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: MemoryHubColors.gray400),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'medication': return Icons.medication;
      case 'vaccination': return Icons.vaccines;
      case 'lab_result': return Icons.science;
      case 'appointment': return Icons.calendar_today;
      default: return Icons.assignment;
    }
  }
}
