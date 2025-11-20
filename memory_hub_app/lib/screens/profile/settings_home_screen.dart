import 'package:flutter/material.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/layout/gap.dart';
import '../../design_system/layout/padded.dart';
import '../../design_system/utils/context_ext.dart';
import '../../widgets/settings_category_card.dart';
import '../../widgets/gradient_container.dart';

class SettingsHomeScreen extends StatefulWidget {
  const SettingsHomeScreen({super.key});

  @override
  State<SettingsHomeScreen> createState() => _SettingsHomeScreenState();
}

class _SettingsHomeScreenState extends State<SettingsHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _categories = const [
    {
      'title': 'Account & Security',
      'description': 'Password, 2FA, and security settings',
      'icon': Icons.shield_outlined,
      'colors': [MemoryHubColors.indigo500, MemoryHubColors.purple500],
      'route': '/settings/account-security',
      'items': 5,
    },
    {
      'title': 'Privacy & Sharing',
      'description': 'Control who sees your content',
      'icon': Icons.privacy_tip_outlined,
      'colors': [MemoryHubColors.pink500, MemoryHubColors.orange500],
      'route': '/settings/privacy',
      'items': 8,
    },
    {
      'title': 'Notifications',
      'description': 'Manage how you get notified',
      'icon': Icons.notifications_outlined,
      'colors': [MemoryHubColors.green500, MemoryHubColors.teal500],
      'route': '/settings/notifications',
      'items': 6,
    },
    {
      'title': 'Personalization',
      'description': 'Customize your experience',
      'icon': Icons.palette_outlined,
      'colors': [MemoryHubColors.purple500, MemoryHubColors.pink500],
      'route': '/settings/personalization',
      'items': 4,
    },
    {
      'title': 'Family Hub',
      'description': 'Manage family features and members',
      'icon': Icons.family_restroom,
      'colors': [MemoryHubColors.amber500, MemoryHubColors.red500],
      'route': '/family',
      'items': 12,
    },
    {
      'title': 'Support & Legal',
      'description': 'Help, about, and data rights',
      'icon': Icons.help_outline,
      'colors': [MemoryHubColors.gray600, MemoryHubColors.gray700],
      'route': '/settings/support',
      'items': 7,
    },
  ];

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.isEmpty) {
      return _categories;
    }
    return _categories.where((category) {
      return category['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          category['description'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: GradientContainer(
                height: 180,
                colors: [
                  context.colors.primary,
                  context.colors.secondary,
                  context.colors.tertiary,
                ],
                child: Container(),
              ),
              title: Text(
                'Settings',
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onPrimary,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: MemoryHubSpacing.lg, bottom: MemoryHubSpacing.lg),
            ),
          ),
          SliverToBoxAdapter(
            child: Padded.all(
              MemoryHubSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: MemoryHubColors.gray100,
                      borderRadius: MemoryHubBorderRadius.mdRadius,
                      border: Border.all(color: MemoryHubColors.gray300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search settings...',
                        prefixIcon: const Icon(Icons.search, color: MemoryHubColors.gray600),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: MemoryHubSpacing.lg,
                          vertical: MemoryHubSpacing.lg,
                        ),
                      ),
                    ),
                  ),
                  const VGap.lg(),
                  Text(
                    _searchQuery.isEmpty ? 'Categories' : 'Search Results',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const VGap.md(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = _filteredCategories[index];
                  return Padded.only(
                    bottom: MemoryHubSpacing.lg,
                    child: SettingsCategoryCard(
                      title: category['title'] as String,
                      description: category['description'] as String,
                      icon: category['icon'] as IconData,
                      gradientColors: List<Color>.from(category['colors'] as List),
                      itemCount: category['items'] as int,
                      onTap: () {
                        Navigator.of(context).pushNamed(category['route'] as String);
                      },
                    ),
                  );
                },
                childCount: _filteredCategories.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: VGap(100),
          ),
        ],
      ),
    );
  }
}
