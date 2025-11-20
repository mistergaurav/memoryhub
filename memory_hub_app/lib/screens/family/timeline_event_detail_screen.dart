import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/family/family_timeline.dart';
import '../../design_system/design_tokens.dart';
import 'family_albums_screen.dart';
import 'family_calendar_screen.dart';
import 'family_milestones_screen.dart';
import 'family_recipes_screen.dart';
import 'family_traditions_screen.dart';

class TimelineEventDetailScreen extends StatefulWidget {
  final TimelineEvent event;
  final VoidCallback? onEventUpdated;

  const TimelineEventDetailScreen({
    Key? key,
    required this.event,
    this.onEventUpdated,
  }) : super(key: key);

  @override
  State<TimelineEventDetailScreen> createState() => _TimelineEventDetailScreenState();
}

class _TimelineEventDetailScreenState extends State<TimelineEventDetailScreen> with SingleTickerProviderStateMixin {
  late TimelineEvent _event;
  bool _isLiked = false;
  int _likesCount = 0;
  int _commentsCount = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = [];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _likesCount = _event.likesCount;
    _commentsCount = _event.commentsCount;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadMockComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadMockComments() {
    if (_commentsCount > 0) {
      _comments.addAll([
        {
          'user': 'Sarah Johnson',
          'avatar': 'SJ',
          'comment': 'What a beautiful moment! 💕',
          'time': '2 hours ago',
        },
        {
          'user': 'Michael Chen',
          'avatar': 'MC',
          'comment': 'This brings back so many memories!',
          'time': '5 hours ago',
        },
      ]);
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    
    if (_isLiked) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLiked ? '❤️ You liked this event' : 'Removed like'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _isLiked ? context.colors.accent : Colors.grey,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() {
      _comments.insert(0, {
        'user': 'You',
        'avatar': 'Y',
        'comment': _commentController.text.trim(),
        'time': 'Just now',
      });
      _commentsCount++;
      _commentController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💬 Comment added!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.info,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareEvent() {
    final eventDetails = '''
${_event.title}
${_event.description ?? ''}

📅 ${DateFormat('EEEE, MMMM d, yyyy').format(_event.eventDate)}
🏷️ ${_formatEventType(_event.eventType)}
${_event.photoUrl != null ? '📸 Photo attached' : ''}
''';

    Clipboard.setData(ClipboardData(text: eventDetails));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Event details copied to clipboard'),
        backgroundColor: context.colors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Color> _getGradientColors() {
    final type = _event.eventType.toLowerCase();
    switch (type) {
      case 'album':
      case 'photo':
        return [context.colors.primary, const Color(0xFFA855F7)];
      case 'event':
      case 'calendar':
        return [context.colors.info, const Color(0xFF22D3EE)];
      case 'milestone':
      case 'achievement':
        return [context.colors.warning, const Color(0xFFFBBF24)];
      case 'recipe':
      case 'food':
        return [context.colors.error, const Color(0xFFF87171)];
      case 'tradition':
        return [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)];
      case 'memory':
        return [context.colors.accent, const Color(0xFFF472B6)];
      case 'birthday':
        return [context.colors.accent, const Color(0xFFF472B6)];
      case 'anniversary':
        return [context.colors.primary, context.colors.accent];
      default:
        return [const Color(0xFF6366F1), context.colors.primary];
    }
  }

  IconData _getEventIcon() {
    final type = _event.eventType.toLowerCase();
    switch (type) {
      case 'album':
      case 'photo':
        return Icons.photo_library;
      case 'event':
      case 'calendar':
        return Icons.event;
      case 'milestone':
        return Icons.celebration;
      case 'achievement':
        return Icons.emoji_events;
      case 'recipe':
      case 'food':
        return Icons.restaurant_menu;
      case 'tradition':
        return Icons.local_florist;
      case 'memory':
        return Icons.photo_album;
      case 'birthday':
        return Icons.cake;
      case 'anniversary':
        return Icons.favorite;
      default:
        return Icons.auto_stories;
    }
  }

  String _formatEventType(String eventType) {
    return eventType.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradientColors();
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: _event.photoUrl != null ? 300 : 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _event.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 8),
                  ],
                ),
              ),
              background: _event.photoUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _event.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: gradient,
                                ),
                              ),
                              child: Icon(
                                _getEventIcon(),
                                size: 80,
                                color: context.colors.surface.withOpacity(0.3),
                              ),
                            );
                          },
                        ),
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
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -30,
                            bottom: -30,
                            child: Icon(
                              _getEventIcon(),
                              size: 140,
                              color: context.colors.surface.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareEvent,
                tooltip: 'Share event',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInteractionButton(
                          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                          label: '$_likesCount ${_likesCount == 1 ? 'Like' : 'Likes'}',
                          color: context.colors.accent,
                          onTap: _toggleLike,
                          animation: _scaleAnimation,
                        ),
                      ),
                      const HGap.sm(),
                      Expanded(child: _buildInteractionButton(
                          icon: Icons.chat_bubble_outline,
                          label: '$_commentsCount ${_commentsCount == 1 ? 'Comment' : 'Comments'}',
                          color: context.colors.info,
                          onTap: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                          },
                        ),
                      ),
                    ],
                  ),
                  const VGap.lg(),
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    title: 'Event Date',
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_event.eventDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const VGap.xxs(),
                      Text(
                        'Created ${_formatRelativeTime(_event.createdAt)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const VGap.md(),
                  if (_event.description != null && _event.description!.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.description,
                      title: 'Description',
                      children: [
                        Text(
                          _event.description!,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                    const VGap.md(),
                  ],
                  _buildInfoCard(
                    icon: Icons.category,
                    title: 'Event Type',
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getEventIcon(),
                              color: context.colors.surface,
                              size: 20,
                            ),
                            const HGap.xs(),
                            Text(
                              _formatEventType(_event.eventType),
                              style: const TextStyle(
                                color: context.colors.surface,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const VGap.md(),
                  _buildRelatedContent(),
                  const VGap.md(),
                  if (_event.createdByName != null) ...[
                    _buildInfoCard(
                      icon: Icons.person,
                      title: 'Created By',
                      children: [
                        Text(
                          _event.createdByName!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const VGap.md(),
                  ],
                  if (_event.taggedMembers.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.people,
                      title: 'Tagged Members',
                      children: [
                        Text(
                          '${_event.taggedMembers.length} ${_event.taggedMembers.length == 1 ? 'member' : 'members'} tagged',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    const VGap.md(),
                  ],
                  _buildCommentsSection(),
                  const VGap(80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 12,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: context.colors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const HGap.sm(),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), context.colors.primary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: context.colors.surface),
                  onPressed: _addComment,
                  tooltip: 'Send comment',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    Animation<double>? animation,
  }) {
    Widget iconWidget = Icon(icon, color: color, size: 24);
    
    if (animation != null) {
      iconWidget = ScaleTransition(
        scale: animation,
        child: iconWidget,
      );
    }
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const HGap.xs(),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
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
                Container(
                  padding: const Spacing.xs,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getGradientColors(),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: context.colors.surface, size: 20),
                ),
                const HGap.sm(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const VGap.sm(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedContent() {
    final relatedItems = <Map<String, dynamic>>[];
    
    final type = _event.eventType.toLowerCase();
    if (type.contains('milestone') || type.contains('achievement')) {
      relatedItems.add({
        'icon': Icons.celebration,
        'title': 'View Milestones',
        'subtitle': 'See all family milestones',
        'color': context.colors.warning,
        'screen': const FamilyMilestonesScreen(),
      });
    }
    if (type.contains('album') || type.contains('photo')) {
      relatedItems.add({
        'icon': Icons.photo_library,
        'title': 'View Albums',
        'subtitle': 'Explore family photo albums',
        'color': context.colors.primary,
        'screen': const FamilyAlbumsScreen(),
      });
    }
    if (type.contains('recipe') || type.contains('food')) {
      relatedItems.add({
        'icon': Icons.restaurant_menu,
        'title': 'View Recipes',
        'subtitle': 'Browse family recipes',
        'color': context.colors.error,
        'screen': const FamilyRecipesScreen(),
      });
    }
    if (type.contains('event') || type.contains('calendar') || type.contains('birthday') || type.contains('anniversary')) {
      relatedItems.add({
        'icon': Icons.event,
        'title': 'View Calendar',
        'subtitle': 'See all upcoming events',
        'color': context.colors.info,
        'screen': const FamilyCalendarScreen(),
      });
    }
    if (type.contains('tradition')) {
      relatedItems.add({
        'icon': Icons.local_florist,
        'title': 'View Traditions',
        'subtitle': 'Discover family traditions',
        'color': const Color(0xFF14B8A6),
        'screen': const FamilyTraditionsScreen(),
      });
    }
    
    if (relatedItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
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
                Container(
                  padding: const Spacing.xs,
                  decoration: BoxDecoration(
                    color: context.colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.link,
                    color: context.colors.primary,
                    size: 20,
                  ),
                ),
                const HGap.sm(),
                const Text(
                  'Related Content',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const VGap.sm(),
            ...relatedItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => item['screen'] as Widget,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const Spacing.sm,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (item['color'] as Color).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const Spacing.xs,
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: item['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const HGap.sm(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: item['color'] as Color,
                              ),
                            ),
                            Text(
                              item['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
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
                Container(
                  padding: const Spacing.xs,
                  decoration: BoxDecoration(
                    color: context.colors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: context.colors.info,
                    size: 20,
                  ),
                ),
                const HGap.sm(),
                Text(
                  'Comments ($_commentsCount)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const VGap.md(),
            if (_comments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const VGap.sm(),
                      Text(
                        'No comments yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                      const VGap.xxs(),
                      Text(
                        'Be the first to comment!',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._comments.map((comment) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: context.colors.primary,
                      child: Text(
                        comment['avatar'],
                        style: const TextStyle(
                          color: context.colors.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const HGap.sm(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment['user'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const HGap.xs(),
                              Text(
                                comment['time'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const VGap.xxs(),
                          Text(
                            comment['comment'],
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }
}
