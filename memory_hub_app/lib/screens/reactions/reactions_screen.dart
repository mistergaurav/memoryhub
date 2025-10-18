import 'package:flutter/material.dart';

class ReactionsScreen extends StatefulWidget {
  final String targetId;
  final String targetType; // 'memory', 'comment', 'story'

  const ReactionsScreen({
    Key? key,
    required this.targetId,
    required this.targetType,
  }) : super(key: key);

  @override
  State<ReactionsScreen> createState() => _ReactionsScreenState();
}

class _ReactionsScreenState extends State<ReactionsScreen> {
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _reactions = {};
  String _selectedReaction = 'all';

  final List<String> _availableReactions = ['❤️', '👍', '😂', '😮', '😢', '🔥', '👏', '💯'];

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  Future<void> _loadReactions() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Load from API endpoint /api/v1/reactions/{targetType}/{targetId}
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _reactions = {
          '❤️': [
            {'userId': '1', 'userName': 'John Doe', 'avatar': null},
            {'userId': '2', 'userName': 'Jane Smith', 'avatar': null},
          ],
          '👍': [
            {'userId': '3', 'userName': 'Bob Johnson', 'avatar': null},
          ],
          '😂': [
            {'userId': '4', 'userName': 'Alice Brown', 'avatar': null},
            {'userId': '5', 'userName': 'Charlie Wilson', 'avatar': null},
            {'userId': '6', 'userName': 'Diana Martinez', 'avatar': null},
          ],
          '🔥': [
            {'userId': '7', 'userName': 'Eve Davis', 'avatar': null},
          ],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addReaction(String emoji) async {
    try {
      // TODO: Call API endpoint POST /api/v1/reactions/{targetType}/{targetId}
      await Future.delayed(const Duration(milliseconds: 300));
      _loadReactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reacted with $emoji'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    }
  }

  Future<void> _removeReaction(String emoji) async {
    try {
      // TODO: Call API endpoint DELETE /api/v1/reactions/{targetType}/{targetId}/{emoji}
      await Future.delayed(const Duration(milliseconds: 300));
      _loadReactions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove reaction: $e')),
        );
      }
    }
  }

  int get _totalReactions {
    return _reactions.values.fold(0, (sum, users) => sum + users.length);
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_selectedReaction == 'all') {
      final allUsers = <Map<String, dynamic>>[];
      _reactions.forEach((emoji, users) {
        for (var user in users) {
          allUsers.add({...user, 'reaction': emoji});
        }
      });
      return allUsers;
    } else {
      return _reactions[_selectedReaction]
              ?.map((user) => {...user, 'reaction': _selectedReaction})
              .toList() ??
          [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reactions ($_totalReactions)'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.purple.shade400],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'React to this',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableReactions.map((emoji) {
                    final count = _reactions[emoji]?.length ?? 0;
                    return InkWell(
                      onTap: () => _addReaction(emoji),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: count > 0 ? Colors.indigo.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: count > 0 ? Colors.indigo.shade200 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 20)),
                            if (count > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                count.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All', _totalReactions),
                  ..._reactions.entries.map((entry) {
                    return _buildFilterChip(entry.key, entry.key, entry.value.length);
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sentiment_satisfied, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No reactions yet',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: user['avatar'] != null
                                        ? NetworkImage(user['avatar'])
                                        : null,
                                    child: user['avatar'] == null
                                        ? Text(user['userName'][0].toUpperCase())
                                        : null,
                                  ),
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        user['reaction'],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                user['userName'],
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              trailing: user['userId'] == '1' // TODO: Check if current user
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => _removeReaction(user['reaction']),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedReaction == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.indigo : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        onSelected: (selected) {
          setState(() => _selectedReaction = value);
        },
        selectedColor: Colors.indigo.shade100,
      ),
    );
  }
}
