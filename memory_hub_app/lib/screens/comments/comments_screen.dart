import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class CommentsScreen extends StatefulWidget {
  final String targetId;
  final String targetType;

  const CommentsScreen({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await _apiService.getComments(widget.targetType, widget.targetId);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await _apiService.createComment({
        'target_type': widget.targetType,
        'target_id': widget.targetId,
        'content': _commentController.text,
      });
      _commentController.clear();
      _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? _buildEmptyState()
                    : _buildCommentsList(),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No Comments Yet',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _buildCommentCard(comment);
      },
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final createdAt = comment['created_at'] != null
        ? DateTime.parse(comment['created_at'])
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    comment['user']?['name']?[0]?.toUpperCase() ?? 'U',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['user']?['name'] ?? 'Unknown',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteComment(comment['id']);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment['content'] ?? '',
              style: GoogleFonts.inter(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    _likeComment(comment['id']);
                  },
                  icon: Icon(
                    comment['liked'] == true ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                  ),
                  label: Text('${comment['likes'] ?? 0}'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: GoogleFonts.inter(fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isPosting ? null : _postComment,
            icon: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _likeComment(String commentId) async {
    try {
      await _apiService.likeComment(commentId);
      _loadComments();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _apiService.deleteComment(commentId);
      _loadComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}
