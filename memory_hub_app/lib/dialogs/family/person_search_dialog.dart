import 'package:flutter/material.dart';
import '../../models/family/genealogy_person.dart';
import '../../services/family/genealogy/persons_service.dart';
import '../../widgets/person_card.dart';

class PersonSearchDialog extends StatefulWidget {
  final Function(GenealogyPerson) onPersonSelected;

  const PersonSearchDialog({
    Key? key,
    required this.onPersonSelected,
  }) : super(key: key);

  @override
  State<PersonSearchDialog> createState() => _PersonSearchDialogState();
}

class _PersonSearchDialogState extends State<PersonSearchDialog> {
  final GenealogyPersonsService _personsService = GenealogyPersonsService();
  final TextEditingController _searchController = TextEditingController();
  List<GenealogyPerson> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _searchQuery = query;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final results = await _personsService.searchPersons(query);
      if (mounted && query == _searchQuery) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Search Family Members',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchQuery.length < 2) {
      return const Center(
        child: Text(
          'Type at least 2 characters to search',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_searchQuery"',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final person = _searchResults[index];
        return PersonCard(
          person: person,
          isGridView: false,
          onTap: () => widget.onPersonSelected(person),
        );
      },
    );
  }
}
