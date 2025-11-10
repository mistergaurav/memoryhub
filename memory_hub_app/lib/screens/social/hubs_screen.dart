import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import 'hub_detail_screen.dart';
import '../../design_system/design_system.dart';

class HubsScreen extends StatefulWidget {
  const HubsScreen({super.key});

  @override
  State<HubsScreen> createState() => _HubsScreenState();
}

class _HubsScreenState extends State<HubsScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _hubs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHubs();
  }

  Future<void> _loadHubs() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/social/hubs'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        setState(() {
          _hubs = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createHub() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Hub'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Hub Name',
                hintText: 'Enter hub name',
              ),
            ),
            const VGap.md(),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final headers = await _authService.getAuthHeaders();
                await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/social/hubs'),
                  headers: headers,
                  body: jsonEncode({
                    'name': nameController.text,
                    'description': descController.text,
                    'privacy': 'private',
                  }),
                );
                Navigator.pop(context, true);
              }
            },
            label: 'Create',
          ),
        ],
      ),
    );

    if (result == true) {
      _loadHubs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Hubs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createHub,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hubs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.workspaces_outline,
                        size: 64,
                        color: context.colors.onSurface.withOpacity(0.3),
                      ),
                      const VGap.md(),
                      Text(
                        'No hubs yet',
                        style: context.text.titleMedium?.copyWith(
                          color: context.colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const VGap.sm(),
                      PrimaryButton(
                        onPressed: _createHub,
                        leading: const Icon(Icons.add),
                        label: 'Create Your First Hub',
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(Spacing.md),
                  itemCount: _hubs.length,
                  itemBuilder: (context, index) {
                    final hub = _hubs[index];
                    return AppCard(
                      margin: Spacing.edgeInsetsBottomSm,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(hub['name'][0].toUpperCase()),
                        ),
                        title: Text(hub['name']),
                        subtitle: Text(hub['description'] ?? ''),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${hub['member_count']} members',
                              style: context.text.bodySmall,
                            ),
                            Text(
                              hub['my_role'] ?? '',
                              style: context.text.labelSmall?.copyWith(
                                color: context.colors.primary,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HubDetailScreen(
                                hubId: hub['id'],
                                hubName: hub['name'],
                              ),
                            ),
                          ).then((_) => _loadHubs());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
