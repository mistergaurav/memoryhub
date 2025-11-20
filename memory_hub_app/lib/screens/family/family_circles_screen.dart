import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/family/core/family_circles_service.dart';
import '../../models/family/family_circle.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../widgets/hero_header.dart';
import '../../widgets/shimmer_loading.dart';
import '../../design_system/design_tokens.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import '../../dialogs/family/create_family_circle_dialog.dart';
import 'family_circle_detail_screen.dart';

class FamilyCirclesScreen extends StatefulWidget {
  const FamilyCirclesScreen({Key? key}) : super(key: key);

  @override
  State<FamilyCirclesScreen> createState() => _FamilyCirclesScreenState();
}

class _FamilyCirclesScreenState extends State<FamilyCirclesScreen>
    with SingleTickerProviderStateMixin {
  final FamilyCirclesService _circlesService = FamilyCirclesService();
  final ScrollController _scrollController = ScrollController();
  List<FamilyCircle> _circles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  int _currentPage = 1;
  bool _hasMore = true;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadCircles();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreCircles();
    }

    if (_scrollController.offset > 100) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  Future<void> _loadCircles() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 1;
    });

    try {
      final response = await _circlesService.getFamilyCircles(page: 1, pageSize: 20);

      if (!mounted) return;

      setState(() {
        _circles = response['circles'] as List<FamilyCircle>;
        _hasMore = response['hasMore'] as bool;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreCircles() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final response = await _circlesService.getFamilyCircles(
        page: _currentPage,
        pageSize: 20,
      );

      if (!mounted) return;

      setState(() {
        _circles.addAll(response['circles'] as List<FamilyCircle>);
        _hasMore = response['hasMore'] as bool;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _currentPage--;
        _isLoadingMore = false;
      });

      AppSnackbar.error(context, 'Failed to load more circles: $e');
    }
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 768) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadCircles,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            HeroHeader(
              title: 'Family Circles',
              subtitle: 'Organize your family and friends',
              icon: Icons.groups,
              gradientColors: const [
                MemoryHubColors.purple500,
                MemoryHubColors.pink500,
              ],
            ),
            if (_isLoading)
              SliverPadding(
                padding: Spacing.edgeInsetsAll(Spacing.lg),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    crossAxisSpacing: MemoryHubSpacing.lg,
                    mainAxisSpacing: MemoryHubSpacing.lg,
                    childAspectRatio: 1.2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerCard(),
                    childCount: 6,
                  ),
                ),
              )
            else if (_error.isNotEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Circles',
                  message: 'Failed to load family circles. Pull down to retry.',
                  actionLabel: 'Retry',
                  onAction: _loadCircles,
                  gradientColors: MemoryHubGradients.error.colors,
                ),
              )
            else if (_circles.isEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.groups,
                  title: 'No Circles Yet',
                  message:
                      'Create your first family circle to organize family members and friends.',
                  actionLabel: 'Create Circle',
                  onAction: _showCreateDialog,
                  gradientColors: const [
                    MemoryHubColors.purple500,
                    MemoryHubColors.pink500,
                  ],
                ),
              )
            else
              SliverPadding(
                padding: Spacing.edgeInsetsAll(Spacing.lg),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    crossAxisSpacing: MemoryHubSpacing.lg,
                    mainAxisSpacing: MemoryHubSpacing.lg,
                    childAspectRatio: 1.2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildCircleCard(_circles[index], index),
                    childCount: _circles.length,
                  ),
                ),
              ),
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Padded.all(
                  Spacing.lg,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            const SliverToBoxAdapter(
              child: VGap.xxxl(),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(
            parent: _fabAnimationController,
            curve: Curves.easeInOut,
          ),
        ),
        child: FloatingActionButton.extended(
          heroTag: 'family_circles_main_fab',
          onPressed: _showCreateDialog,
          icon: const Icon(Icons.add),
          label: const Text('Create Circle'),
          backgroundColor: MemoryHubColors.primary,
        ),
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateFamilyCircleDialog(
        onSubmit: _handleCreate,
      ),
    );
  }

  Future<void> _handleCreate(FamilyCircleCreate circleData) async {
    try {
      await _circlesService.createFamilyCircle(circleData);
      _loadCircles();
      if (mounted) {
        AppSnackbar.success(context, 'Circle created successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to create circle: $e');
      }
      rethrow;
    }
  }

  Widget _buildCircleCard(FamilyCircle circle, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index % 6) * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: MemoryHubElevation.md,
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.xlRadius,
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FamilyCircleDetailScreen(circle: circle),
              ),
            ).then((_) => _loadCircles());
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getCircleColor(circle.color).withValues(alpha: 0.1),
                  _getCircleColor(circle.color).withValues(alpha: 0.05),
                ],
              ),
            ),
            padding: Spacing.edgeInsetsAll(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getCircleColor(circle.color),
                        borderRadius: MemoryHubBorderRadius.fullRadius,
                      ),
                      child: circle.avatarUrl != null && circle.avatarUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: MemoryHubBorderRadius.fullRadius,
                              child: Image.network(
                                circle.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar(circle);
                                },
                              ),
                            )
                          : _buildDefaultAvatar(circle),
                    ),
                    const Spacer(),
                    Container(
                      padding: Spacing.edgeInsetsSymmetric(
                        horizontal: MemoryHubSpacing.md,
                        vertical: Spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: _getCircleColor(circle.color).withValues(alpha: 0.2),
                        borderRadius: MemoryHubBorderRadius.fullRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: _getCircleColor(circle.color),
                          ),
                          const HGap.xs(),
                          Text(
                            '${circle.memberCount}',
                            style: TextStyle(
                              fontWeight: MemoryHubTypography.semiBold,
                              color: _getCircleColor(circle.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const VGap.lg(),
                Text(
                  circle.name,
                  style: context.text.titleLarge?.copyWith(
                        fontWeight: MemoryHubTypography.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const VGap.xs(),
                Text(
                  circle.displayCircleType,
                  style: context.text.bodySmall?.copyWith(
                        color: MemoryHubColors.gray600,
                      ),
                ),
                if (circle.description != null && circle.description!.isNotEmpty) ...[
                  const VGap.sm(),
                  Text(
                    circle.description!,
                    style: context.text.bodyMedium?.copyWith(
                          color: MemoryHubColors.gray700,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                Text(
                  'Created ${DateFormat.yMMMd().format(circle.createdAt)}',
                  style: context.text.bodySmall?.copyWith(
                        color: MemoryHubColors.gray500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(FamilyCircle circle) {
    return Center(
      child: Icon(
        Icons.groups,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Color _getCircleColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return MemoryHubColors.purple500;
    }
    try {
      final hexColor = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return MemoryHubColors.purple500;
    }
  }

  Widget _buildShimmerCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: MemoryHubElevation.md,
      shape: RoundedRectangleBorder(
        borderRadius: MemoryHubBorderRadius.xlRadius,
      ),
      child: Padded.all(
        Spacing.lg,
        child: ShimmerLoading(
          isLoading: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerBox(
                    width: 60,
                    height: 60,
                    borderRadius: MemoryHubBorderRadius.fullRadius,
                  ),
                  const Spacer(),
                  ShimmerBox(
                    width: 60,
                    height: 28,
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                ],
              ),
              const VGap.lg(),
              ShimmerBox(
                width: 150,
                height: 20,
                borderRadius: MemoryHubBorderRadius.smRadius,
              ),
              const VGap.xs(),
              ShimmerBox(
                width: 100,
                height: 16,
                borderRadius: MemoryHubBorderRadius.smRadius,
              ),
              const VGap.sm(),
              ShimmerBox(
                width: double.infinity,
                height: 32,
                borderRadius: MemoryHubBorderRadius.smRadius,
              ),
              const Spacer(),
              ShimmerBox(
                width: 120,
                height: 14,
                borderRadius: MemoryHubBorderRadius.smRadius,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
