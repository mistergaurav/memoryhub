import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/memory.dart';
import 'package:intl/intl.dart';
import '../../widgets/share_bottom_sheet.dart';
import '../../config/api_config.dart';

class MemoryDetailScreen extends StatefulWidget {
  final String memoryId;

  const MemoryDetailScreen({super.key, required this.memoryId});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  final ApiService _apiService = ApiService();
  Memory? _memory;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMemory();
  }

  Future<void> _loadMemory() async {
    setState(() => _isLoading = true);
    try {
      final memory = await _apiService.getMemory(widget.memoryId);
      setState(() {
        _memory = memory;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLike() async {
    if (_memory == null) return;
    try {
      await _apiService.likeMemory(_memory!.id);
      _loadMemory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleBookmark() async {
    if (_memory == null) return;
    try {
      await _apiService.bookmarkMemory(_memory!.id);
      _loadMemory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _shareMemory() {
    if (_memory == null) return;
    
    final memoryUrl = '${ApiConfig.baseUrl}/memory/${widget.memoryId}';
    
    ShareBottomSheet.show(
      context,
      shareUrl: memoryUrl,
      title: _memory!.title,
      description: _memory!.content.length > 100 
          ? '${_memory!.content.substring(0, 100)}...' 
          : _memory!.content,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _memory == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Memory not found'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadMemory,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareMemory,
            tooltip: 'Share Memory',
          ),
          IconButton(
            icon: Icon(
              _memory!.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _memory!.isBookmarked ? Colors.amber : null,
            ),
            onPressed: _handleBookmark,
            tooltip: 'Bookmark',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_memory!.mediaUrls.isNotEmpty)
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: _memory!.mediaUrls.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      ApiConfig.getAssetUrl(_memory!.mediaUrls[index]),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 64),
                        );
                      },
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _memory!.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMMM d, yyyy').format(_memory!.createdAt),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (_memory!.mood != null) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.mood, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _memory!.mood!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _memory!.content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  if (_memory!.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _memory!.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Colors.deepPurple.shade50,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _memory!.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _memory!.isLiked ? Colors.red : null,
                        ),
                        onPressed: _handleLike,
                      ),
                      Text('${_memory!.likeCount}'),
                      const SizedBox(width: 24),
                      const Icon(Icons.visibility, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('${_memory!.viewCount}'),
                      const SizedBox(width: 24),
                      const Icon(Icons.comment, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('${_memory!.commentCount}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
