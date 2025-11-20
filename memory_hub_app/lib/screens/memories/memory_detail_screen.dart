import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/memory.dart';
import 'package:intl/intl.dart';
import '../../widgets/share_bottom_sheet.dart';
import '../../config/api_config.dart';
import '../../design_system/layout/gap.dart';
import '../../design_system/layout/padded.dart';
import '../../design_system/components/buttons/secondary_button.dart';
import '../../design_system/utils/context_ext.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';

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
        context.showSnackbar('Error: $e', isError: true);
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
        context.showSnackbar('Error: $e', isError: true);
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
        body: Center(
          child: CircularProgressIndicator(
            color: context.colors.primary,
          ),
        ),
      );
    }

    if (_error != null || _memory == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                size: 64,
                color: context.colors.error,
              ),
              VGap.lg(),
              Padded.symmetric(
                horizontal: Spacing.xl,
                child: Text(
                  _error ?? 'Memory not found',
                  style: context.text.bodyLarge?.copyWith(
                    color: context.colors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              VGap.lg(),
              SecondaryButton(
                onPressed: _loadMemory,
                label: 'Retry',
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Details', style: context.text.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareMemory,
            tooltip: 'Share Memory',
          ),
          IconButton(
            icon: Icon(
              _memory!.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _memory!.isBookmarked ? MemoryHubColors.amber500 : null,
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
                          color: context.colors.surfaceContainerHighest,
                          child: Icon(
                            Icons.image,
                            size: 64,
                            color: context.colors.outline,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            Padded.lg(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _memory!.title,
                    style: context.text.headlineMedium?.copyWith(
                      fontWeight: MemoryHubTypography.bold,
                    ),
                  ),
                  VGap.xs(),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: context.colors.outline,
                      ),
                      HGap.xxs(),
                      Text(
                        DateFormat('MMMM d, yyyy').format(_memory!.createdAt),
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      if (_memory!.mood != null) ...[
                        HGap.lg(),
                        Icon(
                          Icons.mood,
                          size: 16,
                          color: context.colors.outline,
                        ),
                        HGap.xxs(),
                        Text(
                          _memory!.mood!,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  VGap.xl(),
                  Text(
                    _memory!.content,
                    style: context.text.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                  ),
                  if (_memory!.tags.isNotEmpty) ...[
                    VGap.xl(),
                    Wrap(
                      spacing: Spacing.xs,
                      runSpacing: Spacing.xs,
                      children: _memory!.tags.map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: context.text.labelMedium,
                          ),
                          backgroundColor: MemoryHubColors.indigo100,
                        );
                      }).toList(),
                    ),
                  ],
                  VGap.xl(),
                  Divider(color: context.colors.outlineVariant),
                  VGap.lg(),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _memory!.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _memory!.isLiked
                              ? MemoryHubColors.red500
                              : context.colors.outline,
                        ),
                        onPressed: _handleLike,
                      ),
                      Text(
                        '${_memory!.likeCount}',
                        style: context.text.bodyMedium,
                      ),
                      HGap.xl(),
                      Icon(
                        Icons.visibility,
                        color: context.colors.outline,
                      ),
                      HGap.xs(),
                      Text(
                        '${_memory!.viewCount}',
                        style: context.text.bodyMedium,
                      ),
                      HGap.xl(),
                      Icon(
                        Icons.comment,
                        color: context.colors.outline,
                      ),
                      HGap.xs(),
                      Text(
                        '${_memory!.commentCount}',
                        style: context.text.bodyMedium,
                      ),
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
