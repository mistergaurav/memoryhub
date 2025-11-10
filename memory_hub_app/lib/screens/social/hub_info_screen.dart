import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../widgets/user_search_autocomplete.dart';
import 'user_profile_view_screen.dart';

class HubInfoScreen extends StatefulWidget {
  final String hubId;
  final String hubName;

  const HubInfoScreen({
    super.key,
    required this.hubId,
    required this.hubName,
  });

  @override
  State<HubInfoScreen> createState() => _HubInfoScreenState();
}

class _HubInfoScreenState extends State<HubInfoScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _hubInfo;
  List<dynamic> _members = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHubInfo();
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHubInfo() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/social/hubs/${widget.hubId}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        setState(() {
          _hubInfo = jsonDecode(response.body);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading hub info: $e')),
        );
      }
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/social/hubs/${widget.hubId}/members'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        setState(() {
          _members = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading members: $e')),
        );
      }
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM d, y').format(dt);
    } catch (e) {
      return '';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'member':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Icons.star;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'member':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  Future<void> _showEditHubDialog() async {
    final nameController = TextEditingController(text: _hubInfo?['name'] ?? '');
    final descController = TextEditingController(text: _hubInfo?['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Edit Hub',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update hub information',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Hub Name',
                  hintText: 'Enter hub name',
                  prefixIcon: const Icon(Icons.workspaces),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              descController.dispose();
              Navigator.pop(context);
            },
            label: 'Cancel',
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a hub name')),
                );
                return;
              }

              try {
                final headers = await _authService.getAuthHeaders();
                final response = await http.put(
                  Uri.parse('${ApiConfig.baseUrl}/social/hubs/${widget.hubId}'),
                  headers: headers,
                  body: jsonEncode({
                    'name': name,
                    'description': descController.text.trim(),
                  }),
                );

                nameController.dispose();
                descController.dispose();
                Navigator.pop(context);

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Hub updated successfully!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadHubInfo();
                } else {
                  final error = jsonDecode(response.body);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error['detail'] ?? 'Failed to update hub'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                nameController.dispose();
                descController.dispose();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _shareHub() {
    final hubUrl = '${ApiConfig.baseUrl}/hub/${widget.hubId}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Share Hub',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this hub with others',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                hubUrl,
                style: GoogleFonts.sourceCodePro(fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Copy this link and share it with people you want to invite to this hub',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            label: 'Close',
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Copy hub URL to clipboard
              await Clipboard.setData(ClipboardData(text: hubUrl));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Link copied to clipboard!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMembersDialog() async {
    Map<String, dynamic>? selectedUser;
    final selectedRole = ValueNotifier<String>('member');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add Member to Hub',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search for a user from your family circles',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  UserSearchAutocomplete(
                    onUserSelected: (user) {
                      setState(() {
                        selectedUser = {'id': user.id, 'full_name': user.fullName, 'email': user.email};
                      });
                    },
                    helpText: 'Search for users in your family circles',
                  ),
                  if (selectedUser != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              (selectedUser!['full_name'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedUser!['full_name'] ?? 'Unknown',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  selectedUser!['email'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                selectedUser = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Select Role',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String>(
                    valueListenable: selectedRole,
                    builder: (context, role, _) {
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: role == 'member' 
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: role == 'member'
                                    ? Colors.green
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: RadioListTile<String>(
                              value: 'member',
                              groupValue: role,
                              onChanged: (value) => selectedRole.value = value!,
                              title: Row(
                                children: [
                                  Icon(Icons.person, size: 20, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Member',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Can view and share memories',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: role == 'admin' 
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: role == 'admin'
                                    ? Colors.blue
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: RadioListTile<String>(
                              value: 'admin',
                              groupValue: role,
                              onChanged: (value) => selectedRole.value = value!,
                              title: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings, size: 20, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Admin',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Can manage members and settings',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                selectedRole.dispose();
                Navigator.pop(context);
              },
              label: 'Cancel',
            ),
            ElevatedButton.icon(
              onPressed: selectedUser == null
                  ? null
                  : () async {
                      try {
                        final headers = await _authService.getAuthHeaders();
                        final response = await http.post(
                          Uri.parse('${ApiConfig.baseUrl}/social/hubs/${widget.hubId}/members'),
                          headers: headers,
                          body: jsonEncode({
                            'user_id': selectedUser!['id'],
                            'role': selectedRole.value,
                          }),
                        );

                        selectedRole.dispose();
                        Navigator.pop(context);

                        if (response.statusCode == 200 || response.statusCode == 201) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${selectedUser!['full_name']} added to hub!',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            _loadMembers();
                          }
                        } else {
                          final error = jsonDecode(response.body);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error['detail'] ?? 'Failed to add member'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        selectedRole.dispose();
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(widget.hubName),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          backgroundImage: _hubInfo?['avatar_url'] != null
                              ? NetworkImage(ApiConfig.getAssetUrl(_hubInfo!['avatar_url']))
                              : null,
                          child: _hubInfo?['avatar_url'] == null
                              ? Icon(
                                  Icons.workspaces,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Info', icon: Icon(Icons.info_outline)),
                    Tab(text: 'Members', icon: Icon(Icons.people_outline)),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildMembersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    if (_hubInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.workspaces,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _hubInfo!['name'] ?? '',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (_hubInfo!['description'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _hubInfo!['description'],
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    Icons.privacy_tip_outlined,
                    'Privacy',
                    _hubInfo!['privacy']?.toString().toUpperCase() ?? 'PRIVATE',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.people,
                    'Members',
                    '${_hubInfo!['member_count'] ?? 0} members',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.person,
                    'Your Role',
                    _hubInfo!['my_role']?.toString().toUpperCase() ?? 'MEMBER',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Created',
                    _formatDate(_hubInfo!['created_at']),
                  ),
                  if (_hubInfo!['tags'] != null && (_hubInfo!['tags'] as List).isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_hubInfo!['tags'] as List)
                          .map((tag) => Chip(
                                label: Text(tag.toString()),
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_hubInfo!['my_role'] == 'owner' || _hubInfo!['my_role'] == 'admin')
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hub Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Edit Hub'),
                      onTap: () => _showEditHubDialog(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add),
                      title: const Text('Add Members'),
                      onTap: () => _showAddMembersDialog(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.share),
                      title: const Text('Share Hub'),
                      onTap: () => _shareHub(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No members yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: member['user_avatar'] != null
                  ? NetworkImage(ApiConfig.getAssetUrl(member['user_avatar']))
                  : null,
              child: member['user_avatar'] == null
                  ? Text(
                      (member['user_name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    member['user_name'] ?? 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(member['role'] ?? 'member').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRoleIcon(member['role'] ?? 'member'),
                        size: 14,
                        color: _getRoleColor(member['role'] ?? 'member'),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member['role']?.toString().toUpperCase() ?? 'MEMBER',
                        style: TextStyle(
                          fontSize: 11,
                          color: _getRoleColor(member['role'] ?? 'member'),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Joined ${_formatDate(member['joined_at'])}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileViewScreen(
                    userId: member['user_id'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
