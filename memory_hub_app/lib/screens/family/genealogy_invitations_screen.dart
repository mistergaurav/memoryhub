import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/family/family_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import 'package:intl/intl.dart';

class GenealogyInvitationsScreen extends StatefulWidget {
  const GenealogyInvitationsScreen({Key? key}) : super(key: key);

  @override
  State<GenealogyInvitationsScreen> createState() => _GenealogyInvitationsScreenState();
}

class _GenealogyInvitationsScreenState extends State<GenealogyInvitationsScreen> with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _allInvites = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInvitations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvitations() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final invites = await _familyService.getInviteLinks();
      setState(() {
        _allInvites = invites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _pendingInvites =>
      _allInvites.where((i) => i['status'] == 'pending').toList();

  List<Map<String, dynamic>> get _acceptedInvites =>
      _allInvites.where((i) => i['status'] == 'accepted').toList();

  List<Map<String, dynamic>> get _expiredInvites =>
      _allInvites.where((i) => i['status'] == 'expired').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Family Invitations', style: TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA), Color(0xFFC4B5FD)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(Icons.mail_outline, size: 120, color: Colors.white.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: [
                Tab(
                  icon: const Icon(Icons.pending_outlined),
                  text: 'Pending (${_pendingInvites.length})',
                ),
                Tab(
                  icon: const Icon(Icons.check_circle_outline),
                  text: 'Accepted (${_acceptedInvites.length})',
                ),
                Tab(
                  icon: const Icon(Icons.cancel_outlined),
                  text: 'Expired (${_expiredInvites.length})',
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInvitesList(_pendingInvites, 'pending'),
            _buildInvitesList(_acceptedInvites, 'accepted'),
            _buildInvitesList(_expiredInvites, 'expired'),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitesList(List<Map<String, dynamic>> invites, String type) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => _buildShimmerCard(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: EnhancedEmptyState(
          icon: Icons.error_outline,
          title: 'Error Loading Invitations',
          message: 'Failed to load invitations. Pull to retry.',
          actionLabel: 'Retry',
          onAction: _loadInvitations,
        ),
      );
    }

    if (invites.isEmpty) {
      String message = '';
      String actionLabel = '';
      if (type == 'pending') {
        message = 'No pending invitations. Create one to invite family members to join your tree.';
        actionLabel = 'Go to Tree';
      } else if (type == 'accepted') {
        message = 'No accepted invitations yet. When family members accept your invitations, they will appear here.';
        actionLabel = '';
      } else {
        message = 'No expired invitations.';
        actionLabel = '';
      }
      
      return Center(
        child: EnhancedEmptyState(
          icon: type == 'pending' ? Icons.mail_outline : type == 'accepted' ? Icons.check_circle_outline : Icons.cancel_outlined,
          title: 'No ${type.substring(0, 1).toUpperCase()}${type.substring(1)} Invitations',
          message: message,
          actionLabel: actionLabel,
          onAction: actionLabel.isNotEmpty ? () => Navigator.pop(context) : null,
          gradientColors: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInvitations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invites.length,
        itemBuilder: (context, index) => _buildInviteCard(invites[index], type),
      ),
    );
  }

  Widget _buildInviteCard(Map<String, dynamic> invite, String type) {
    final personName = invite['person_name'] ?? 'Unknown';
    final email = invite['email'] ?? '';
    final createdAt = invite['created_at'];
    final expiresAt = invite['expires_at'];
    final acceptedAt = invite['accepted_at'];
    final token = invite['token'] ?? '';
    final inviteUrl = invite['invite_url'] ?? '';

    Color statusColor = type == 'pending' 
        ? Colors.orange 
        : type == 'accepted' 
            ? Colors.green 
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_outline, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Created: ${_formatDate(createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (type == 'pending') ...[
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: Colors.orange.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Expires: ${_formatDate(expiresAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
                  ),
                ],
              ),
            ],
            if (type == 'accepted' && acceptedAt != null) ...[
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Accepted: ${_formatDate(acceptedAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                  ),
                ],
              ),
            ],
            if (type == 'expired') ...[
              Row(
                children: [
                  Icon(Icons.cancel, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Expired: ${_formatDate(expiresAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
            if (type == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyInviteLink(inviteUrl),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareInvite(personName, email, inviteUrl),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      ShimmerBox(width: 200, height: 12, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ),
              ],
            ),
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

  void _copyInviteLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation link copied to clipboard'),
        backgroundColor: Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareInvite(String personName, String email, String url) {
    final message = 'Join my family tree on Memory Hub!\n\n'
        'I\'ve added you as $personName in our family genealogy.\n\n'
        'Click this link to accept and link your account:\n$url\n\n'
        'Looking forward to building our family history together!';
    
    Share.share(message, subject: 'Family Tree Invitation');
  }
}
