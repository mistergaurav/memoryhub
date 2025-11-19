import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../widgets/user_search_autocomplete.dart';
import 'user_profile_view_screen.dart';
import '../../design_system/design_system.dart';

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
        return MemoryHubColors.purple500;
      case 'admin':
        return MemoryHubColors.blue500;
      case 'member':
        return MemoryHubColors.green500;
      default:
        return MemoryHubColors.gray500;
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
            Icon(Icons.edit, color: context.colors.primary),
            const HGap.md(),
            Text(
              'Edit Hub',
              style: context.text.titleMedium?.copyWith(fontWeight: MemoryHubTypography.bold),
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
                style: context.text.bodyMedium?.copyWith(
                  color: MemoryHubColors.gray600,
                ),
              ),
              const VGap.lg(),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Hub Name',
                  hintText: 'Enter hub name',
                  prefixIcon: const Icon(Icons.workspaces),
                  border: OutlineInputBorder(
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                ),
              ),
              const VGap.lg(),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: MemoryHubBorderRadius.mdRadius,
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
            child: const Text('Cancel'),
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
                  AppSnackbar.success(context, 'Hub updated successfully!');
                  _loadHubInfo();
                } else {
                  final error = jsonDecode(response.body);
                  AppSnackbar.error(context, error['detail'] ?? 'Failed to update hub');
                }
              } catch (e) {
                nameController.dispose();
                descController.dispose();
                Navigator.pop(context);
                AppSnackbar.error(context, 'Error: $e');
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
            Icon(Icons.share, color: context.colors.primary),
            const HGap.md(),
            Text(
              'Share Hub',
              style: context.text.titleMedium?.copyWith(fontWeight: MemoryHubTypography.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this hub with others',
              style: context.text.bodyMedium?.copyWith(
                color: MemoryHubColors.gray600,
              ),
            ),
            const VGap.lg(),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: MemoryHubColors.gray100,
                borderRadius: MemoryHubBorderRadius.smRadius,
                border: Border.all(color: MemoryHubColors.gray300),
              ),
              child: SelectableText(
                hubUrl,
                style: context.text.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
            const VGap.md(),
            Text(
              'Copy this link and share it with people you want to invite to this hub',
              style: context.text.bodySmall?.copyWith(
                color: MemoryHubColors.gray600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Copy hub URL to clipboard
              await Clipboard.setData(ClipboardData(text: hubUrl));
              if (mounted) {
                AppSnackbar.success(context, 'Link copied to clipboard!');
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
              Icon(Icons.person_add, color: context.colors.primary),
              const HGap.md(),
              Expanded(
                child: Text(
                  'Add Member to Hub',
                  style: context.text.titleMedium?.copyWith(fontWeight: MemoryHubTypography.bold),
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
                    style: context.text.bodyMedium?.copyWith(color: MemoryHubColors.gray600),
                  ),
                  const VGap.lg(),
                  UserSearchAutocomplete(
                    onUserSelected: (user) {
                      setState(() {
                        selectedUser = {'id': user.id, 'full_name': user.fullName, 'email': user.email};
                      });
                    },
                    helpText: 'Search for users in your family circles',
                  ),
                  if (selectedUser != null) ...[
                    const VGap.lg(),
                    Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer.withOpacity(0.3),
                        borderRadius: MemoryHubBorderRadius.mdRadius,
                        border: Border.all(
                          color: context.colors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: context.colors.primary,
                            child: Text(
                              (selectedUser!['full_name'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const HGap.md(),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedUser!['full_name'] ?? 'Unknown',
                                  style: context.text.bodyMedium?.copyWith(
                                    fontWeight: MemoryHubTypography.semiBold,
                                  ),
                                ),
                                Text(
                                  selectedUser!['email'] ?? '',
                                  style: context.text.bodySmall?.copyWith(
                                    color: MemoryHubColors.gray600,
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
                  const VGap.xl(),
                  Text(
                    'Select Role',
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: MemoryHubTypography.semiBold,
                    ),
                  ),
                  const VGap.sm(),
                  ValueListenableBuilder<String>(
                    valueListenable: selectedRole,
                    builder: (context, role, _) {
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: role == 'member' 
                                  ? MemoryHubColors.green500.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: MemoryHubBorderRadius.smRadius,
                              border: Border.all(
                                color: role == 'member'
                                    ? MemoryHubColors.green500
                                    : MemoryHubColors.gray300,
                              ),
                            ),
                            child: RadioListTile<String>(
                              value: 'member',
                              groupValue: role,
                              onChanged: (value) => selectedRole.value = value!,
                              title: Row(
                                children: [
                                  Icon(Icons.person, size: 20, color: MemoryHubColors.green500),
                                  const HGap.sm(),
                                  Text(
                                    'Member',
                                    style: context.text.bodyMedium?.copyWith(
                                      fontWeight: MemoryHubTypography.semiBold,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Can view and share memories',
                                style: context.text.bodySmall,
                              ),
                            ),
                          ),
                          const VGap.sm(),
                          Container(
                            decoration: BoxDecoration(
                              color: role == 'admin' 
                                  ? MemoryHubColors.blue500.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: MemoryHubBorderRadius.smRadius,
                              border: Border.all(
                                color: role == 'admin'
                                    ? MemoryHubColors.blue500
                                    : MemoryHubColors.gray300,
                              ),
                            ),
                            child: RadioListTile<String>(
                              value: 'admin',
                              groupValue: role,
                              onChanged: (value) => selectedRole.value = value!,
                              title: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings, size: 20, color: MemoryHubColors.blue500),
                                  const HGap.sm(),
                                  Text(
                                    'Admin',
                                    style: context.text.bodyMedium?.copyWith(
                                      fontWeight: MemoryHubTypography.semiBold,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Can manage members and settings',
                                style: context.text.bodySmall,
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
              child: const Text('Cancel'),
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
                            AppSnackbar.success(
                              context,
                              '${selectedUser!['full_name']} added to hub!',
                            );
                            _loadMembers();
                          }
                        } else {
                          final error = jsonDecode(response.body);
                          if (mounted) {
                            AppSnackbar.error(
                              context,
                              error['detail'] ?? 'Failed to add member',
                            );
                          }
                        }
                      } catch (e) {
                        selectedRole.dispose();
                        Navigator.pop(context);
                        if (mounted) {
                          AppSnackbar.error(context, 'Error: $e');
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
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Padded.lg(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.workspaces,
                        color: context.colors.primary,
                        size: 28,
                      ),
                      const HGap.md(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _hubInfo!['name'] ?? '',
                              style: context.text.titleLarge?.copyWith(
                                fontWeight: MemoryHubTypography.bold,
                              ),
                            ),
                            if (_hubInfo!['description'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: Spacing.xxs),
                                child: Text(
                                  _hubInfo!['description'],
                                  style: context.text.bodyMedium?.copyWith(
                                    color: MemoryHubColors.gray600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: MemoryHubSpacing.xxxl),
                  _buildInfoRow(
                    Icons.privacy_tip_outlined,
                    'Privacy',
                    _hubInfo!['privacy']?.toString().toUpperCase() ?? 'PRIVATE',
                  ),
                  const VGap.md(),
                  _buildInfoRow(
                    Icons.people,
                    'Members',
                    '${_hubInfo!['member_count'] ?? 0} members',
                  ),
                  const VGap.md(),
                  _buildInfoRow(
                    Icons.person,
                    'Your Role',
                    _hubInfo!['my_role']?.toString().toUpperCase() ?? 'MEMBER',
                  ),
                  const VGap.md(),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Created',
                    _formatDate(_hubInfo!['created_at']),
                  ),
                  if (_hubInfo!['tags'] != null && (_hubInfo!['tags'] as List).isNotEmpty) ...[
                    const Divider(height: MemoryHubSpacing.xxxl),
                    Text(
                      'Tags',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: MemoryHubTypography.bold,
                      ),
                    ),
                    const VGap.md(),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: (_hubInfo!['tags'] as List)
                          .map((tag) => Chip(
                                label: Text(tag.toString()),
                                backgroundColor: context.colors.primaryContainer,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const VGap.lg(),
          if (_hubInfo!['my_role'] == 'owner' || _hubInfo!['my_role'] == 'admin')
            AppCard(
              child: Padded.lg(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hub Actions',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: MemoryHubTypography.bold,
                      ),
                    ),
                    const VGap.md(),
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
            Icon(Icons.people_outline, size: 64, color: MemoryHubColors.gray400),
            const VGap.lg(),
            Text(
              'No members yet',
              style: context.text.titleMedium?.copyWith(color: MemoryHubColors.gray600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: AppCard(
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
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: MemoryHubTypography.semiBold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(member['role'] ?? 'member').withOpacity(0.1),
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRoleIcon(member['role'] ?? 'member'),
                        size: 14,
                        color: _getRoleColor(member['role'] ?? 'member'),
                      ),
                      const HGap.xs(),
                      Text(
                        member['role']?.toString().toUpperCase() ?? 'MEMBER',
                        style: context.text.labelSmall?.copyWith(
                          color: _getRoleColor(member['role'] ?? 'member'),
                          fontWeight: MemoryHubTypography.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Joined ${_formatDate(member['joined_at'])}',
              style: context.text.bodySmall?.copyWith(color: MemoryHubColors.gray600),
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
        ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: MemoryHubColors.gray600),
        const HGap.md(),
        Text(
          '$label:',
          style: context.text.bodyMedium?.copyWith(
            color: MemoryHubColors.gray700,
            fontWeight: MemoryHubTypography.medium,
          ),
        ),
        const HGap.sm(),
        Expanded(
          child: Text(
            value,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: MemoryHubTypography.semiBold,
            ),
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
