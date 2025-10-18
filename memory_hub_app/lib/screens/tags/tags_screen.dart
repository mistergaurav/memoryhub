import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

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
        title: Text('Tags', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_popularTags.isNotEmpty) ...[
                      Text(
                        'Popular Tags',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _popularTags.length.clamp(0, 6),
                        itemBuilder: (context, index) {
                          final tag = _popularTags[index];
                          return _buildPopularTagCard(tag);
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                    Text(
                      'All Tags',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    final color = colors[tag['name'].hashCode % colors.length];

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/tags/detail', arguments: tag['name']);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tag, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tag['name'],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${tag['count']} items',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey,
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
