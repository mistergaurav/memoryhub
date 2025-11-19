import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/layout/gap.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _tags = [];
  List<dynamic> _popularTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      final tags = await _apiService.getAllTags();
      final popular = await _apiService.getPopularTags();
      setState(() {
        _tags = tags;
        _popularTags = popular;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tags', style: GoogleFonts.inter(fontWeight: MemoryHubTypography.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/tags/management');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTags,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(MemoryHubSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_popularTags.isNotEmpty) ...[
                      Text(
                        'Popular Tags',
                        style: GoogleFonts.inter(
                          fontSize: MemoryHubTypography.h3,
                          fontWeight: MemoryHubTypography.bold,
                        ),
                      ),
                      const VGap.lg(),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: MemoryHubSpacing.md,
                          mainAxisSpacing: MemoryHubSpacing.md,
                        ),
                        itemCount: _popularTags.length.clamp(0, 6),
                        itemBuilder: (context, index) {
                          final tag = _popularTags[index];
                          return _buildPopularTagCard(tag);
                        },
                      ),
                      const VGap.xxl(),
                    ],
                    Text(
                      'All Tags',
                      style: GoogleFonts.inter(
                        fontSize: MemoryHubTypography.h3,
                        fontWeight: MemoryHubTypography.bold,
                      ),
                    ),
                    const VGap.lg(),
                    Wrap(
                      spacing: MemoryHubSpacing.sm,
                      runSpacing: MemoryHubSpacing.sm,
                      children: _tags.map((tag) => _buildTagChip(tag)).toList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPopularTagCard(Map<String, dynamic> tag) {
    final colors = [
      MemoryHubColors.purple500,
      MemoryHubColors.blue500,
      MemoryHubColors.green500,
      MemoryHubColors.amber500,
      MemoryHubColors.pink500,
      MemoryHubColors.teal500,
    ];
    final color = colors[tag['name'].hashCode % colors.length];

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/tags/detail', arguments: tag['name']);
      },
      borderRadius: MemoryHubBorderRadius.lgRadius,
      child: Container(
        padding: EdgeInsets.all(MemoryHubSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: MemoryHubBorderRadius.lgRadius,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tag, color: color, size: 20),
                const HGap.xs(),
                Expanded(
                  child: Text(
                    tag['name'],
                    style: GoogleFonts.inter(
                      fontWeight: MemoryHubTypography.bold,
                      fontSize: MemoryHubTypography.bodyLarge,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const VGap(4),
            Text(
              '${tag['count']} items',
              style: GoogleFonts.inter(
                fontSize: MemoryHubTypography.bodySmall,
                color: MemoryHubColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(Map<String, dynamic> tag) {
    return ActionChip(
      label: Text('${tag['name']} (${tag['count']})'),
      avatar: const Icon(Icons.tag, size: 16),
      onPressed: () {
        Navigator.pushNamed(context, '/tags/detail', arguments: tag['name']);
      },
    );
  }
}
