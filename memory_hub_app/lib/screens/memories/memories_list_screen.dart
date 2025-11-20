import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/memory.dart';
import '../../config/api_config.dart';
import 'package:intl/intl.dart';
import '../../design_system/layout/gap.dart';
import '../../design_system/layout/padded.dart';
import '../../design_system/components/surfaces/app_card.dart';
import '../../design_system/components/buttons/primary_button.dart';
import '../../design_system/components/buttons/secondary_button.dart';
import '../../design_system/components/inputs/text_field_x.dart';
import '../../design_system/utils/context_ext.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';

class MemoriesListScreen extends StatefulWidget {
  const MemoriesListScreen({super.key});

  @override
  State<MemoriesListScreen> createState() => _MemoriesListScreenState();
}

class _MemoriesListScreenState extends State<MemoriesListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Memory> _memories = [];
  bool _isLoading = true;
  String? _error;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);
    try {
      final memories = await _apiService.searchMemories(
        query: _searchQuery,
      );
      setState(() {
        _memories = memories;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleSearch(String query) {
    setState(() => _searchQuery = query.isEmpty ? null : query);
    _loadMemories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memories', style: context.text.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed('/memories/create');
              if (result == true) {
                _loadMemories();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padded.xs(
            child: TextFieldX(
              controller: _searchController,
              hint: 'Search memories...',
              prefix: const Icon(Icons.search),
              suffix: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _handleSearch('');
                      },
                    )
                  : null,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: context.colors.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 64,
              color: context.colors.error,
            ),
            const VGap.lg(),
            Padded.symmetric(
              horizontal: Spacing.xl,
              child: Text(
                _error!,
                style: context.text.bodyLarge?.copyWith(
                  color: context.colors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const VGap.lg(),
            SecondaryButton(
              onPressed: _loadMemories,
              label: 'Retry',
            ),
          ],
        ),
      );
    }

    if (_memories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.memory,
              size: 64,
              color: context.colors.outline,
            ),
            const VGap.lg(),
            Text(
              _searchQuery != null ? 'No memories found' : 'No memories yet',
              style: context.text.titleMedium?.copyWith(
                color: context.colors.outline,
              ),
            ),
            const VGap.lg(),
            PrimaryButton(
              onPressed: () async {
                final result = await Navigator.of(context).pushNamed('/memories/create');
                if (result == true) {
                  _loadMemories();
                }
              },
              label: 'Create Memory',
              leading: const Icon(Icons.add, size: 20),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMemories,
      color: context.colors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _memories.length,
        itemBuilder: (context, index) {
          final memory = _memories[index];
          return Padded.only(
            bottom: Spacing.lg,
            child: _buildMemoryCard(memory),
          );
        },
      ),
    );
  }

  Widget _buildMemoryCard(Memory memory) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () async {
        final result = await Navigator.of(context).pushNamed(
          '/memories/detail',
          arguments: memory.id,
        );
        if (result == true) {
          _loadMemories();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memory.mediaUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(MemoryHubBorderRadius.lg),
              ),
              child: Image.network(
                ApiConfig.getAssetUrl(memory.mediaUrls.first),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: context.colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.image,
                      size: 64,
                      color: context.colors.outline,
                    ),
                  );
                },
              ),
            ),
          Padded.lg(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: MemoryHubTypography.bold,
                  ),
                ),
                const VGap.xs(),
                Text(
                  memory.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                if (memory.tags.isNotEmpty) ...[
                  const VGap.sm(),
                  Wrap(
                    spacing: Spacing.xs,
                    runSpacing: Spacing.xs,
                    children: memory.tags.map((tag) {
                      return Chip(
                        label: Text(
                          tag,
                          style: context.text.labelSmall,
                        ),
                        backgroundColor: MemoryHubColors.indigo100,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
                const VGap.sm(),
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 16,
                      color: memory.isLiked
                          ? MemoryHubColors.red500
                          : context.colors.outline,
                    ),
                    const HGap.xxs(),
                    Text(
                      '${memory.likeCount}',
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const HGap.md(),
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: context.colors.outline,
                    ),
                    const HGap.xxs(),
                    Text(
                      '${memory.viewCount}',
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: context.colors.outline,
                    ),
                    const HGap.xxs(),
                    Text(
                      DateFormat('MMM d, yyyy').format(memory.createdAt),
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
