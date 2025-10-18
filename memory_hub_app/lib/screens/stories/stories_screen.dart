import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Stories', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _stories.isEmpty
              ? _buildEmptyState()
              : _buildStoriesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/stories/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Story'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 80, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No Stories Yet',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your moments',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
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
      margin: const EdgeInsets.only(bottom: 16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.8),
            Colors.pink.withOpacity(0.8),
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
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
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
                      backgroundColor: Colors.white,
                      child: Text(
                        story['user']?['name']?[0] ?? 'U',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story['user']?['name'] ?? 'Unknown',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${story['views'] ?? 0} views',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
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
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
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
