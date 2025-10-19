import 'package:flutter/material.dart';
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

class _LegacyLettersScreenState extends State<LegacyLettersScreen> {
  final FamilyService _familyService = FamilyService();
  List<LegacyLetter> _letters = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final letters = await _familyService.getLegacyLetters();
      setState(() {
        _letters = letters;
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
        onRefresh: _loadLetters,
        child: CustomScrollView(
          slivers: [
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFFA78BFA),
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
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        left: 30,
                        top: 90,
                        child: Icon(
                          Icons.favorite,
                          size: 30,
                          color: Colors.white.withOpacity(0.3),
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
                  title: 'Error Loading Letters',
                  message: 'Failed to load legacy letters. Pull to retry.',
                  actionLabel: 'Retry',
                  onAction: _loadLetters,
                ),
              )
            else if (_letters.isEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.mail,
                  title: 'No Legacy Letters',
                  message: 'Create heartfelt messages for your loved ones to cherish forever.',
                  actionLabel: 'Write Letter',
                  onAction: _showAddDialog,
                  gradientColors: const [
                    Color(0xFF8B5CF6),
                    Color(0xFFA78BFA),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildLetterCard(_letters[index]),
                    childCount: _letters.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.edit),
        label: const Text('Write Letter'),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
    );
  }

  Widget _buildLetterCard(LegacyLetter letter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.05),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      letter.isSealed ? Icons.lock : Icons.lock_open,
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
                          letter.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          letter.isSealed ? 'Sealed' : 'Draft',
                          style: TextStyle(
                            fontSize: 14,
                            color: letter.isSealed
                                ? const Color(0xFF8B5CF6)
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
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
                    const SizedBox(width: 8),
                    Text(
                      'To: ${letter.recipientType}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (letter.scheduledDelivery != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withOpacity(0.1),
                        const Color(0xFFA78BFA).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 18,
                        color: Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery: ${DateFormat('MMM d, y').format(letter.scheduledDelivery!)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (letter.deliveredAt != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delivered on ${DateFormat('MMM d, y').format(letter.deliveredAt!)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created ${DateFormat('MMM d, y').format(letter.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 180, height: 18, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 8),
                      ShimmerBox(width: 100, height: 14, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ShimmerBox(width: double.infinity, height: 40, borderRadius: BorderRadius.circular(12)),
          ],
        ),
      ),
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
      _loadLetters();
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
