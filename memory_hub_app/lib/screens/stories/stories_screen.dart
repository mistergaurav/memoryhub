import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../design_system/design_system.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);
    try {
      final stories = await _apiService.getStories();
      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MemoryHubColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Stories', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: MemoryHubColors.white)),
        iconTheme: const IconThemeData(color: MemoryHubColors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: MemoryHubColors.white))
          : _stories.isEmpty
              ? _buildEmptyState()
              : _buildStoriesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/stories/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Story'),
        backgroundColor: context.colors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 80, color: MemoryHubColors.white.withOpacity(0.5)),
          const VGap.lg(),
          Text(
            'No Stories Yet',
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: MemoryHubColors.white,
            ),
          ),
          const VGap.xs(),
          Text(
            'Share your moments',
            style: context.text.bodyLarge?.copyWith(
              color: MemoryHubColors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stories.length,
      itemBuilder: (context, index) {
        final story = _stories[index];
        return _buildStoryCard(story);
      },
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    return Container(
      margin: EdgeInsets.onlyBottom16,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            MemoryHubColors.purple500.withOpacity(0.8),
            MemoryHubColors.pink500.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: story['media_url'] != null
            ? DecorationImage(
                image: NetworkImage(story['media_url']),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.pushNamed(context, '/stories/view', arguments: story['id']);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  MemoryHubColors.black.withOpacity(0.3),
                  Colors.transparent,
                  MemoryHubColors.black.withOpacity(0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: MemoryHubColors.white,
                      child: Text(
                        story['user']?['name']?[0] ?? 'U',
                        style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const HGap.sm(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story['user']?['name'] ?? 'Unknown',
                            style: context.text.bodyLarge?.copyWith(
                              color: MemoryHubColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${story['views'] ?? 0} views',
                            style: context.text.bodySmall?.copyWith(
                              color: MemoryHubColors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (story['content'] != null)
                  Text(
                    story['content'],
                    style: context.text.bodyLarge?.copyWith(
                      color: MemoryHubColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
