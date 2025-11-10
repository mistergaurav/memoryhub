import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _service = AdminService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _users = [];
  int _currentPage = 1;
  int _totalPages = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getUsers(
        page: _currentPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      setState(() {
        _users = data['users'] ?? [];
        _totalPages = data['pages'] ?? 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _search() {
    setState(() {
      _searchQuery = _searchController.text;
      _currentPage = 1;
    });
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: const Text('No users found'))
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final isActive = user['is_active'] ?? true;
                            final role = user['role'] ?? 'user';
                            final stats = user['stats'] ?? {};
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    (user['full_name'] ?? user['email'] ?? '?')[0].toUpperCase(),
                                  ),
                                ),
                                title: Text(user['full_name'] ?? user['email'] ?? 'Unknown'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['email'] ?? ''),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text(
                                            role.toUpperCase(),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          backgroundColor: role == 'admin' ? Colors.purple : Colors.blue,
                                          labelStyle: const TextStyle(color: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${stats['memories'] ?? 0} memories, ${stats['files'] ?? 0} files',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: Text(isActive ? 'Deactivate' : 'Activate'),
                                      onTap: () => _toggleUserStatus(user['id'], isActive),
                                    ),
                                    PopupMenuItem(
                                      child: Text(role == 'admin' ? 'Make User' : 'Make Admin'),
                                      onTap: () => _toggleUserRole(user['id'], role),
                                    ),
                                    PopupMenuItem(
                                      child: const Text(
                                        'Delete User',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onTap: () => _confirmDeleteUser(user['id'], user['email']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadUsers();
                          }
                        : null,
                  ),
                  Text('Page $_currentPage of $_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _loadUsers();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _service.updateUserStatus(userId, !currentStatus);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${!currentStatus ? "activated" : "deactivated"}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleUserRole(String userId, String currentRole) async {
    try {
      final newRole = currentRole == 'admin' ? 'user' : 'admin';
      await _service.updateUserRole(userId, newRole);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User role updated to $newRole')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _confirmDeleteUser(String userId, String email) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete User'),
          content: Text('Are you sure you want to delete $email? This will delete all their data and cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _service.deleteUser(userId);
                  await _loadUsers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User deleted')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
