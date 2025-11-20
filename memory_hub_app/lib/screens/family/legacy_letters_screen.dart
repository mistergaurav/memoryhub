import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import '../../services/family/family_service.dart';
import '../../models/family/legacy_letter.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/add_legacy_letter_dialog.dart';
import 'package:intl/intl.dart';

class LegacyLettersScreen extends StatefulWidget {
  const LegacyLettersScreen({Key? key}) : super(key: key);

  @override
  State<LegacyLettersScreen> createState() => _LegacyLettersScreenState();
}

class _LegacyLettersScreenState extends State<LegacyLettersScreen> with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  late TabController _tabController;
  
  List<LegacyLetter> _sentLetters = [];
  List<ReceivedLetter> _receivedLetters = [];
  bool _isLoadingSent = true;
  bool _isLoadingReceived = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSentLetters();
    _loadReceivedLetters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSentLetters() async {
    setState(() {
      _isLoadingSent = true;
      _error = '';
    });
    try {
      final letters = await _familyService.getSentLetters();
      setState(() {
        _sentLetters = letters;
        _isLoadingSent = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingSent = false;
      });
    }
  }

  Future<void> _loadReceivedLetters() async {
    setState(() => _isLoadingReceived = true);
    try {
      final letters = await _familyService.getReceivedLetters();
      setState(() {
        _receivedLetters = letters;
        _isLoadingReceived = false;
      });
    } catch (e) {
      setState(() => _isLoadingReceived = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadSentLetters(),
      _loadReceivedLetters(),
    ]);
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
                'Legacy Letters',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.colors.primary,
                      context.colors.primaryLight,
                      Color(0xFFC4B5FD),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      bottom: -40,
                      child: Icon(
                        Icons.mail,
                        size: 180,
                        color: context.colors.surface.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      top: 90,
                      child: Icon(
                        Icons.favorite,
                        size: 30,
                        color: context.colors.surface.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: context.colors.surface,
              tabs: const [
                Tab(
                  icon: Icon(Icons.send),
                  text: 'Sent Letters',
                ),
                Tab(
                  icon: Icon(Icons.inbox),
                  text: 'Received Letters',
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSentLettersTab(),
            _buildReceivedLettersTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'legacy_letters_fab',
        onPressed: _showAddDialog,
        icon: const Icon(Icons.edit),
        label: const Text('Write Letter'),
        backgroundColor: context.colors.primary,
      ),
    );
  }

  Widget _buildSentLettersTab() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _isLoadingSent
          ? ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: 4,
              itemBuilder: (context, index) => _buildShimmerCard(),
            )
          : _error.isNotEmpty
              ? EnhancedEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Letters',
                  message: 'Failed to load sent letters. Pull to retry.',
                  actionLabel: 'Retry',
                  onAction: _loadSentLetters,
                )
              : _sentLetters.isEmpty
                  ? EnhancedEmptyState(
                      icon: Icons.mail,
                      title: 'No Sent Letters',
                      message: 'Create heartfelt messages for your loved ones to cherish forever.',
                      actionLabel: 'Write Letter',
                      onAction: _showAddDialog,
                      gradientColors: [
                        context.colors.primary,
                        context.colors.primaryLight,
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _sentLetters.length,
                      itemBuilder: (context, index) => _buildSentLetterCard(_sentLetters[index]),
                    ),
    );
  }

  Widget _buildReceivedLettersTab() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _isLoadingReceived
          ? ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: 4,
              itemBuilder: (context, index) => _buildShimmerCard(),
            )
          : _receivedLetters.isEmpty
              ? EnhancedEmptyState(
                  icon: Icons.inbox,
                  title: 'No Received Letters',
                  message: 'You haven\'t received any legacy letters yet.',
                  gradientColors: [
                    context.colors.primary,
                    context.colors.primaryLight,
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _receivedLetters.length,
                  itemBuilder: (context, index) => _buildReceivedLetterCard(_receivedLetters[index]),
                ),
    );
  }

  Widget _buildSentLetterCard(LegacyLetter letter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => _showLetterDetails(letter),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colors.primary.withOpacity(0.05),
                context.colors.surface,
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
                      padding: const EdgeInsets.all(MemoryHubSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.colors.primary, context.colors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        letter.encrypt ? Icons.lock : Icons.mail,
                        color: context.colors.surface,
                        size: 32,
                      ),
                    ),
                    const HGap.md(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            letter.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const VGap.xxs(),
                          _buildStatusBadge(letter.status),
                        ],
                      ),
                    ),
                  ],
                ),
                const VGap.md(),
                Container(
                  padding: EdgeInsets.all(MemoryHubSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                      const HGap.xs(),
                      Expanded(
                        child: Text(
                          'To: ${letter.recipientNames.isNotEmpty ? letter.recipientNames.join(", ") : "${letter.recipientIds.length} recipient(s)"}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const VGap.sm(),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const HGap.xxs(),
                    Text(
                      'Delivery: ${DateFormat('MMM d, y').format(letter.deliveryDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (letter.deliveredAt != null) ...[
                      const HGap.md(),
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const HGap.xxs(),
                      Text(
                        'Delivered ${DateFormat('MMM d').format(letter.deliveredAt!)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (letter.readCount > 0) ...[
                  const VGap.xs(),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      const HGap.xxs(),
                      Text(
                        'Read by ${letter.readCount} recipient${letter.readCount > 1 ? "s" : ""}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedLetterCard(ReceivedLetter letter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: letter.isRead ? 2 : 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: letter.isRead
            ? BorderSide.none
            : BorderSide(color: context.colors.primary.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _showReceivedLetterDetails(letter),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: letter.isRead
                  ? [context.colors.surface, context.colors.surface]
                  : [
                      context.colors.primary.withOpacity(0.1),
                      context.colors.surface,
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
                      padding: const EdgeInsets.all(MemoryHubSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: letter.isRead
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : [context.colors.primary, context.colors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: letter.isRead
                            ? []
                            : [
                                BoxShadow(
                                  color: context.colors.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Icon(
                        letter.isRead ? Icons.drafts : Icons.mail,
                        color: context.colors.surface,
                        size: 32,
                      ),
                    ),
                    const HGap.md(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  letter.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: letter.isRead ? Colors.grey.shade700 : Colors.black,
                                  ),
                                ),
                              ),
                              if (!letter.isRead)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: context.colors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.surface,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const VGap.xxs(),
                          Text(
                            'From: ${letter.authorName ?? "Unknown"}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const VGap.md(),
                Container(
                  padding: EdgeInsets.all(MemoryHubSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.colors.primary.withOpacity(0.1),
                        context.colors.primaryLight.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 18,
                        color: context.colors.primary,
                      ),
                      const HGap.xs(),
                      Text(
                        'Delivered on ${DateFormat('MMMM d, y').format(letter.deliveredAt)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: context.colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'draft':
        badgeColor = Colors.grey;
        label = 'Draft';
        icon = Icons.edit;
        break;
      case 'scheduled':
        badgeColor = Colors.orange;
        label = 'Scheduled';
        icon = Icons.schedule;
        break;
      case 'delivered':
        badgeColor = Colors.green;
        label = 'Delivered';
        icon = Icons.check_circle;
        break;
      case 'read':
        badgeColor = Colors.blue;
        label = 'Read';
        icon = Icons.visibility;
        break;
      default:
        badgeColor = Colors.grey;
        label = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const HGap.xxs(),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
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
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.circular(16),
                ),
                const HGap.md(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 180, height: 18, borderRadius: BorderRadius.circular(4)),
                      const VGap.xs(),
                      ShimmerBox(width: 100, height: 14, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ),
              ],
            ),
            const VGap.md(),
            ShimmerBox(width: double.infinity, height: 40, borderRadius: BorderRadius.circular(12)),
          ],
        ),
      ),
    );
  }

  void _showLetterDetails(LegacyLetter letter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(MemoryHubSpacing.lg),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(MemoryHubSpacing.sm),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [context.colors.primary, context.colors.primaryLight],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.mail, color: context.colors.surface, size: 24),
                        ),
                        const HGap.sm(),
                        Expanded(
                          child: Text(
                            letter.title,
                            style: const context.text.headlineMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const VGap.md(),
                    _buildStatusBadge(letter.status),
                    const VGap.lg(),
                    _buildInfoRow(Icons.people, 'Recipients', letter.recipientNames.isNotEmpty ? letter.recipientNames.join(", ") : "${letter.recipientIds.length} recipient(s)"),
                    const VGap.sm(),
                    _buildInfoRow(Icons.calendar_today, 'Delivery Date', DateFormat('MMMM d, y').format(letter.deliveryDate)),
                    if (letter.deliveredAt != null) ...[
                      const VGap.sm(),
                      _buildInfoRow(Icons.check_circle, 'Delivered At', DateFormat('MMMM d, y h:mm a').format(letter.deliveredAt!)),
                    ],
                    const VGap.sm(),
                    _buildInfoRow(Icons.visibility, 'Read Count', '${letter.readCount} recipient${letter.readCount != 1 ? "s" : ""}'),
                    if (letter.encrypt) ...[
                      const VGap.sm(),
                      _buildInfoRow(Icons.lock, 'Encryption', 'Enabled'),
                    ],
                    if (letter.content != null) ...[
                      const VGap.lg(),
                      const Divider(),
                      const VGap.md(),
                      const Text(
                        'Letter Content',
                        style: context.text.titleLarge,
                      ),
                      const VGap.sm(),
                      Container(
                        padding: const EdgeInsets.all(MemoryHubSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          letter.content!,
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceivedLetterDetails(ReceivedLetter letter) async {
    if (!letter.isRead) {
      try {
        await _familyService.markLetterAsRead(letter.id);
        _loadReceivedLetters();
      } catch (e) {
        // Silent fail, letter will still be shown
      }
    }

    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(MemoryHubSpacing.lg),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(MemoryHubSpacing.sm),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [context.colors.primary, context.colors.primaryLight],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.mail, color: context.colors.surface, size: 24),
                        ),
                        const HGap.sm(),
                        Expanded(
                          child: Text(
                            letter.title,
                            style: const context.text.headlineMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const VGap.md(),
                    Container(
                      padding: const EdgeInsets.all(MemoryHubSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.colors.primary.withOpacity(0.1),
                            context.colors.primaryLight.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.favorite, size: 20, color: context.colors.primary),
                              const HGap.xs(),
                              Text(
                                'From: ${letter.authorName ?? "Unknown"}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.primary,
                                ),
                              ),
                            ],
                          ),
                          const VGap.xs(),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: context.colors.primary),
                              const HGap.xs(),
                              Text(
                                'Delivered on ${DateFormat('MMMM d, y').format(letter.deliveredAt)}',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const VGap.lg(),
                    const Divider(),
                    const VGap.md(),
                    const Text(
                      'Letter Content',
                      style: context.text.titleLarge,
                    ),
                    const VGap.sm(),
                    Container(
                      padding: const EdgeInsets.all(MemoryHubSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        letter.content,
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.6),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const HGap.sm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const VGap.xxs(),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddLegacyLetterDialog(onSubmit: _handleAdd),
    );
  }

  Future<void> _handleAdd(Map<String, dynamic> data) async {
    try {
      await _familyService.createLegacyLetter(data);
      _loadSentLetters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Letter saved successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save letter: $e'), backgroundColor: Colors.red),
        );
      }
      rethrow;
    }
  }
}
