import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _searchResults = [];
  List<String> _recentSearches = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  String _selectedFilter = 'All';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    setState(() {
      _recentSearches = ['Family photos', 'Vacation 2024', 'Birthday party'];
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final results = await _apiService.globalSearch(query);
      setState(() {
        _searchResults = results['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _getSuggestions(String query) async {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    
    try {
      final result = await _apiService.getSearchSuggestions(query);
      setState(() {
        _suggestions = result;
      });
    } catch (e) {
      setState(() => _suggestions = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search memories, files, people...',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey,
                fontSize: 15,
              ),
              prefixIcon: const Icon(Icons.search, size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _suggestions = [];
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {});
              _getSuggestions(value);
            },
            onSubmitted: _performSearch,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              Navigator.pushNamed(context, '/search/advanced');
            },
            tooltip: 'Advanced Search',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return _buildInitialView();
    }

    if (_suggestions.isNotEmpty && _searchResults.isEmpty) {
      return _buildSuggestionsView();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyResults();
    }

    return _buildSearchResults();
  }

  Widget _buildInitialView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _recentSearches.clear());
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_recentSearches.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.history, size: 20),
                  title: Text(
                    _recentSearches[index],
                    style: GoogleFonts.inter(fontSize: 15),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _recentSearches.removeAt(index);
                      });
                    },
                  ),
                  onTap: () {
                    _searchController.text = _recentSearches[index];
                    _performSearch(_recentSearches[index]);
                  },
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          Text(
            'Popular Tags',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Family',
              'Travel',
              'Birthday',
              'Vacation',
              'Friends',
              'Work',
            ].map((tag) => ActionChip(
              label: Text(tag),
              avatar: const Icon(Icons.tag, size: 16),
              onPressed: () {
                _searchController.text = tag;
                _performSearch(tag);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, size: 20),
          title: Text(
            suggestion,
            style: GoogleFonts.inter(fontSize: 15),
          ),
          trailing: const Icon(Icons.north_west, size: 16),
          onTap: () {
            _searchController.text = suggestion;
            _performSearch(suggestion);
          },
        );
      },
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Memories', 'Files', 'People', 'Tags'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return _buildResultCard(result);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final type = result['type'] ?? 'unknown';
    IconData icon;
    Color color;
    
    switch (type) {
      case 'memory':
        icon = Icons.auto_stories;
        color = Colors.purple;
        break;
      case 'file':
        icon = Icons.insert_drive_file;
        color = Colors.blue;
        break;
      case 'user':
        icon = Icons.person;
        color = Colors.green;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          result['title'] ?? 'Untitled',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: result['description'] != null
            ? Text(
                result['description'],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to detail screen based on type
        },
      ),
    );
  }
}
