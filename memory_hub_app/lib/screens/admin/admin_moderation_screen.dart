import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../widgets/gradient_container.dart';
import '../../widgets/animated_list_item.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _flaggedContent = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFlaggedContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFlaggedContent() async {
    setState(() => _isLoading = true);
    try {
      _flaggedContent = [
        {
          'id': '1',
          'type': 'memory',
          'content': 'This is an inappropriate memory...',
          'author': 'user123',
          'reports': 5,
          'reason': 'Inappropriate content',
          'date': DateTime.now().subtract(const Duration(hours: 2)),
        },
        {
          'id': '2',
          'type': 'comment',
          'content': 'This is spam comment',
          'author': 'spammer456',
          'reports': 12,
          'reason': 'Spam',
          'date': DateTime.now().subtract(const Duration(hours: 5)),
        },
        {
          'id': '3',
          'type': 'profile',
          'content': 'Fake profile with misleading information',
          'author': 'fake789',
          'reports': 3,
          'reason': 'Impersonation',
          'date': DateTime.now().subtract(const Duration(days: 1)),
        },
      ];
      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(String itemId, String action) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action action applied to item $itemId'),
          backgroundColor: action == 'approve' ? Colors.green : Colors.red,
        ),
      );
      setState(() {
        _flaggedContent.removeWhere((item) => item['id'] == itemId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: GradientContainer(
                height: 200,
                colors: [
                  Colors.red,
                  Colors.orange,
                  Colors.amber,
                ],
                child: Center(
                  child: Icon(
                    Icons.report_problem,
                    size: 80,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              title: Text(
                'Content Moderation',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'All', icon: Icon(Icons.list)),
                Tab(text: 'Memories', icon: Icon(Icons.photo)),
                Tab(text: 'Comments', icon: Icon(Icons.comment)),
                Tab(text: 'Users', icon: Icon(Icons.person)),
              ],
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadFlaggedContent,
                      label: 'Retry',
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContentList(_flaggedContent),
                  _buildContentList(_flaggedContent.where((item) => item['type'] == 'memory').toList()),
                  _buildContentList(_flaggedContent.where((item) => item['type'] == 'comment').toList()),
                  _buildContentList(_flaggedContent.where((item) => item['type'] == 'profile').toList()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              'No flagged content',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return AnimatedListItem(
          index: index,
          child: _buildModerationCard(item),
        );
      },
    );
  }

  Widget _buildModerationCard(Map<String, dynamic> item) {
    final IconData typeIcon;
    final Color typeColor;
    
    switch (item['type']) {
      case 'memory':
        typeIcon = Icons.photo;
        typeColor = Colors.purple;
        break;
      case 'comment':
        typeIcon = Icons.comment;
        typeColor = Colors.blue;
        break;
      case 'profile':
        typeIcon = Icons.person;
        typeColor = Colors.teal;
        break;
      default:
        typeIcon = Icons.help;
        typeColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['type'].toString().toUpperCase()} - Flagged',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'By ${item['author']}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: 16, color: Colors.red[900]),
                      const SizedBox(width: 4),
                      Text(
                        '${item['reports']} reports',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item['content'],
                style: GoogleFonts.inter(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 6),
                Text(
                  'Reason: ${item['reason']}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleAction(item['id'], 'approve'),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text(
                      'Approve',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _handleAction(item['id'], 'remove'),
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text(
                      'Remove',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
