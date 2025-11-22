import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import 'package:memory_hub_app/design_system/layout/padded.dart';
import 'package:memory_hub_app/design_system/layout/gap.dart';
import 'package:memory_hub_app/design_system/components/buttons/primary_button.dart';
import 'package:memory_hub_app/services/family/core/relationships_service.dart';

class UserSelectionSheet extends StatefulWidget {
  final List<String> initialSelectedIds;
  final Function(List<String>) onSelectionChanged;

  const UserSelectionSheet({
    super.key,
    required this.initialSelectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<UserSelectionSheet> createState() => _UserSelectionSheetState();
}

class _UserSelectionSheetState extends State<UserSelectionSheet> {
  final RelationshipsService _relationshipsService = RelationshipsService();
  final Set<String> _selectedIds = {};
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      
      // Fetch friends and family
      // We'll fetch both and combine them
      final friendsData = await _relationshipsService.getRelationships(
        statusFilter: 'accepted',
        relationshipTypeFilter: 'friend',
      );
      
      final familyData = await _relationshipsService.getRelationships(
        statusFilter: 'accepted',
        relationshipTypeFilter: 'family',
      );

      final List<Map<String, dynamic>> allUsers = [];
      
      // Process friends
      if (friendsData['data'] != null) {
        for (var item in friendsData['data']) {
          if (item['related_user'] != null) {
             allUsers.add(item['related_user']);
          }
        }
      }

      // Process family
      if (familyData['data'] != null) {
        for (var item in familyData['data']) {
          if (item['related_user'] != null) {
             // Avoid duplicates
             if (!allUsers.any((u) => u['id'] == item['related_user']['id'])) {
               allUsers.add(item['related_user']);
             }
          }
        }
      }

      setState(() {
        _users = allUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedIds.contains(userId)) {
        _selectedIds.remove(userId);
      } else {
        _selectedIds.add(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padded.lg(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Users',
                  style: context.text.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _users.isEmpty
                        ? const Center(child: Text('No friends or family found'))
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              final isSelected = _selectedIds.contains(user['id']);
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user['avatar_url'] != null
                                      ? NetworkImage(user['avatar_url'])
                                      : null,
                                  child: user['avatar_url'] == null
                                      ? Text((user['full_name'] ?? '?')[0].toUpperCase())
                                      : null,
                                ),
                                title: Text(user['full_name'] ?? 'Unknown'),
                                trailing: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggleSelection(user['id']),
                                  shape: const CircleBorder(),
                                ),
                                onTap: () => _toggleSelection(user['id']),
                              );
                            },
                          ),
          ),
          Padded.lg(
            child: PrimaryButton(
              onPressed: () {
                widget.onSelectionChanged(_selectedIds.toList());
                Navigator.pop(context);
              },
              label: 'Confirm Selection (${_selectedIds.length})',
              fullWidth: true,
            ),
          ),
          VGap.lg(),
        ],
      ),
    );
  }
}
