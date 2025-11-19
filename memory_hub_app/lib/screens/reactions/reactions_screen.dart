import 'package:flutter/material.dart';
import '../../services/reactions_service.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/layout/gap.dart';

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
  final ReactionsService _reactionsService = ReactionsService();

  final List<String> _availableReactions = ['❤️', '👍', '😂', '😮', '😢', '🔥', '👏', '💯'];

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  Future<void> _loadReactions() async {
    setState(() => _isLoading = true);
    try {
      final reactionsData = await _reactionsService.getReactions(
        widget.targetType,
        widget.targetId,
      );
      
      final Map<String, List<Map<String, dynamic>>> groupedReactions = {};
      for (var reaction in reactionsData) {
        final emoji = reaction['reaction_type'] ?? '👍';
        if (!groupedReactions.containsKey(emoji)) {
          groupedReactions[emoji] = [];
        }
        groupedReactions[emoji]!.add({
          'userId': reaction['user_id'] ?? '',
          'userName': reaction['user_name'] ?? 'Unknown User',
          'avatar': reaction['avatar_url'],
        });
      }
      
      setState(() {
        _reactions = groupedReactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _reactions = {};
        _isLoading = false;
      });
    }
  }

  Future<void> _addReaction(String emoji) async {
    try {
      await _reactionsService.addReaction(
        widget.targetType,
        widget.targetId,
        emoji,
      );
      _loadReactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reacted with $emoji'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
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
      await _reactionsService.removeReaction(
        widget.targetType,
        widget.targetId,
        emoji,
      );
      _loadReactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reaction removed'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
              colors: [MemoryHubColors.indigo500, MemoryHubColors.purple500],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(MemoryHubSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: MemoryHubColors.gray200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'React to this',
                  style: TextStyle(fontWeight: MemoryHubTypography.bold),
                ),
                VGap(MemoryHubSpacing.md),
                Wrap(
                  spacing: MemoryHubSpacing.sm,
                  runSpacing: MemoryHubSpacing.sm,
                  children: _availableReactions.map((emoji) {
                    final count = _reactions[emoji]?.length ?? 0;
                    return InkWell(
                      onTap: () => _addReaction(emoji),
                      borderRadius: MemoryHubBorderRadius.fullRadius,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MemoryHubSpacing.md,
                          vertical: MemoryHubSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: count > 0 ? MemoryHubColors.indigo100 : MemoryHubColors.gray100,
                          borderRadius: MemoryHubBorderRadius.fullRadius,
                          border: Border.all(
                            color: count > 0 ? MemoryHubColors.indigo200 : MemoryHubColors.gray300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 20)),
                            if (count > 0) ...[
                              HGap(MemoryHubSpacing.xs + 2),
                              Text(
                                count.toString(),
                                style: TextStyle(
                                  fontWeight: MemoryHubTypography.bold,
                                  color: MemoryHubColors.indigo700,
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
            padding: EdgeInsets.symmetric(
              horizontal: MemoryHubSpacing.lg,
              vertical: MemoryHubSpacing.sm,
            ),
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
                            Icon(Icons.sentiment_satisfied, size: 64, color: MemoryHubColors.gray400),
                            VGap(MemoryHubSpacing.lg),
                            Text(
                              'No reactions yet',
                              style: TextStyle(color: MemoryHubColors.gray600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(MemoryHubSpacing.lg),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: MemoryHubSpacing.sm),
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
                                      padding: EdgeInsets.all(MemoryHubSpacing.xs / 2),
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
                                style: TextStyle(fontWeight: MemoryHubTypography.semiBold),
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
      padding: EdgeInsets.only(right: MemoryHubSpacing.sm),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            HGap(MemoryHubSpacing.xs),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: MemoryHubSpacing.xs + 2,
                vertical: MemoryHubSpacing.xs / 2,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : MemoryHubColors.gray200,
                borderRadius: MemoryHubBorderRadius.mdRadius,
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: MemoryHubTypography.bold,
                  color: isSelected ? MemoryHubColors.indigo600 : MemoryHubColors.gray700,
                ),
              ),
            ),
          ],
        ),
        onSelected: (selected) {
          setState(() => _selectedReaction = value);
        },
        selectedColor: MemoryHubColors.indigo100,
      ),
    );
  }
}
