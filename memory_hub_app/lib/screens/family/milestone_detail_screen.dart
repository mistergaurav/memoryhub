import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../models/family/family_milestone.dart';
import '../../services/family/family_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../dialogs/family/add_milestone_dialog.dart';
import 'family_timeline_screen.dart';

class MilestoneDetailScreen extends StatefulWidget {
  final String milestoneId;

  const MilestoneDetailScreen({Key? key, required this.milestoneId}) : super(key: key);

  @override
  State<MilestoneDetailScreen> createState() => _MilestoneDetailScreenState();
}

class _MilestoneDetailScreenState extends State<MilestoneDetailScreen> with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  FamilyMilestone? _milestone;
  bool _isLoading = true;
  bool _isLiking = false;
  String _error = '';
  late AnimationController _animationController;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadMilestone();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMilestone() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final milestone = await _familyService.getMilestoneDetail(widget.milestoneId);
      
      if (!mounted) return;
      
      setState(() {
        _milestone = milestone;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLike() async {
    if (_milestone == null || _isLiking || !mounted) return;

    setState(() => _isLiking = true);
    try {
      await _familyService.likeMilestone(_milestone!.id);
      await _loadMilestone();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like milestone: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Milestone'),
        content: const Text('Are you sure you want to delete this milestone? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            label: 'Cancel',
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _familyService.deleteMilestone(widget.milestoneId);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Milestone deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete milestone: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleEdit() async {
    if (_milestone == null) return;

    await showDialog(
      context: context,
      builder: (context) => AddMilestoneDialog(
        milestone: _milestone,
        onSubmit: (data) async {
          await _familyService.updateMilestone(_milestone!.id, data);
          await _loadMilestone();
        },
      ),
    );
  }

  void _handleShare() {
    if (_milestone == null) return;
    final text = '${_milestone!.title}\n${_milestone!.description ?? ''}\n${DateFormat('MMM d, yyyy').format(_milestone!.milestoneDate)}';
    Share.share(text, subject: 'Family Milestone: ${_milestone!.title}');
  }

  void _viewFullScreenPhoto(List<String> photos, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenPhotoViewer(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'birth':
        return const Color(0xFFEC4899);
      case 'graduation':
        return const Color(0xFF8B5CF6);
      case 'wedding':
        return const Color(0xFFEF4444);
      case 'anniversary':
        return const Color(0xFFF59E0B);
      case 'achievement':
        return const Color(0xFFEAB308);
      case 'first_words':
      case 'first_word':
        return const Color(0xFF06B6D4);
      case 'first_steps':
      case 'first_step':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'birth':
        return Icons.child_care;
      case 'graduation':
        return Icons.school;
      case 'wedding':
        return Icons.favorite;
      case 'anniversary':
        return Icons.cake;
      case 'achievement':
        return Icons.emoji_events;
      case 'first_words':
      case 'first_word':
        return Icons.chat_bubble;
      case 'first_steps':
      case 'first_step':
        return Icons.directions_walk;
      default:
        return Icons.star;
    }
  }

  String _formatType(String type) {
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _getYearsAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final years = (difference.inDays / 365).floor();
    final months = ((difference.inDays % 365) / 30).floor();
    
    if (years > 0) {
      return years == 1 ? '1 year ago' : '$years years ago';
    } else if (months > 0) {
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final days = difference.inDays;
      if (days == 0) return 'Today';
      if (days == 1) return 'Yesterday';
      return '$days days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Milestone Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Milestone Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMilestone,
                label: 'Retry',
              ),
            ],
          ),
        ),
      );
    }

    if (_milestone == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Milestone Details')),
        body: const Center(label: 'Milestone not found'),
      );
    }

    final milestone = _milestone!;
    final photos = milestone.photoUrl != null && milestone.photoUrl!.isNotEmpty 
        ? [milestone.photoUrl!] 
        : <String>[];
    final yearsAgo = _getYearsAgo(milestone.milestoneDate);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                milestone.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (photos.isNotEmpty)
                    photos.length == 1
                        ? GestureDetector(
                            onTap: () => _viewFullScreenPhoto(photos, 0),
                            child: Image.network(
                              photos[0],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildGradientBackground(),
                            ),
                          )
                        : CarouselSlider(
                            options: CarouselOptions(
                              height: double.infinity,
                              viewportFraction: 1.0,
                              autoPlay: true,
                              onPageChanged: (index, reason) {
                                setState(() => _currentPhotoIndex = index);
                              },
                            ),
                            items: photos.asMap().entries.map((entry) {
                              return GestureDetector(
                                onTap: () => _viewFullScreenPhoto(photos, entry.key),
                                child: Image.network(
                                  entry.value,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) => _buildGradientBackground(),
                                ),
                              );
                            }).toList(),
                          )
                  else
                    _buildGradientBackground(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: photos.asMap().entries.map((entry) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPhotoIndex == entry.key
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _handleShare,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _handleEdit();
                  } else if (value == 'delete') {
                    _handleDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _animationController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    )),
                    child: _buildDetailsCard(milestone, yearsAgo),
                  ),
                ),
                const SizedBox(height: 16),
                if (milestone.celebrationDetails != null)
                  FadeTransition(
                    opacity: _animationController,
                    child: _buildCelebrationCard(milestone),
                  ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _animationController,
                  child: _buildInteractionCard(milestone),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _animationController,
                  child: _buildTimelineCard(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getTypeColor(_milestone!.category),
            _getTypeColor(_milestone!.category).withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Icon(
              _getTypeIcon(_milestone!.category),
              size: 200,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(FamilyMilestone milestone, String yearsAgo) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getTypeColor(milestone.category),
                        _getTypeColor(milestone.category).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(milestone.category),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatType(milestone.category),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM d, yyyy').format(milestone.milestoneDate),
                        style: TextStyle(
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
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    yearsAgo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            if (milestone.genealogyPersonName != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    'Person: ${milestone.genealogyPersonName}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo,
                    ),
                  ),
                  if (milestone.autoGenerated) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.auto_awesome, size: 16, color: Colors.amber.shade700),
                  ],
                ],
              ),
            ],
            if (milestone.description != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.description, size: 20, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                milestone.description!,
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Created by ${milestone.createdByName ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Created ${DateFormat('MMM d, yyyy').format(milestone.createdAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationCard(FamilyMilestone milestone) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.party_mode, color: Colors.purple.shade700, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Celebration Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'This milestone includes special celebration information and memories.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionCard(FamilyMilestone milestone) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: _isLiking ? null : _handleLike,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLiking)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.favorite,
                  color: _getTypeColor(milestone.category),
                  size: 32,
                ),
              const SizedBox(width: 12),
              Text(
                '${milestone.likesCount} ${milestone.likesCount == 1 ? 'Like' : 'Likes'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FamilyTimelineScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timeline, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View in Timeline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'See this milestone in the family timeline',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenPhotoViewer extends StatelessWidget {
  final List<String> photos;
  final int initialIndex;

  const _FullScreenPhotoViewer({
    required this.photos,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: photos.length == 1
          ? InteractiveViewer(
              child: Center(
                child: Image.network(
                  photos[0],
                  fit: BoxFit.contain,
                ),
              ),
            )
          : CarouselSlider(
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height,
                viewportFraction: 1.0,
                initialPage: initialIndex,
                enableInfiniteScroll: false,
              ),
              items: photos.map((photoUrl) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
