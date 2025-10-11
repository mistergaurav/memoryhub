import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/memory.dart';
import 'package:intl/intl.dart';

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
        title: const Text('Memories'),
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search memories...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: _handleSearch,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMemories,
              child: const Text('Retry'),
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
            const Icon(Icons.memory, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery != null
                  ? 'No memories found'
                  : 'No memories yet',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).pushNamed('/memories/create');
                if (result == true) {
                  _loadMemories();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Memory'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMemories,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _memories.length,
        itemBuilder: (context, index) {
          final memory = _memories[index];
          return _buildMemoryCard(memory);
        },
      ),
    );
  }

  Widget _buildMemoryCard(Memory memory) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                child: Image.network(
                  'http://localhost:8000${memory.mediaUrls.first}',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 64),
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
                    memory.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    memory.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  if (memory.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: memory.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Colors.deepPurple.shade50,
                          labelStyle: const TextStyle(fontSize: 12),
                          padding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.favorite,
                          size: 16,
                          color: memory.isLiked ? Colors.red : Colors.grey),
                      const SizedBox(width: 4),
                      Text('${memory.likeCount}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.visibility, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${memory.viewCount}'),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d, yyyy').format(memory.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
