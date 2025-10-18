import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Account & Security',
      'description': 'Password, 2FA, and security settings',
      'icon': Icons.shield_outlined,
      'colors': [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      'route': '/settings/account-security',
      'items': 5,
    },
    {
      'title': 'Privacy & Sharing',
      'description': 'Control who sees your content',
      'icon': Icons.privacy_tip_outlined,
      'colors': [Color(0xFFEC4899), Color(0xFFF97316)],
      'route': '/settings/privacy',
      'items': 8,
    },
    {
      'title': 'Notifications',
      'description': 'Manage how you get notified',
      'icon': Icons.notifications_outlined,
      'colors': [Color(0xFF10B981), Color(0xFF14B8A6)],
      'route': '/settings/notifications',
      'items': 6,
    },
    {
      'title': 'Personalization',
      'description': 'Customize your experience',
      'icon': Icons.palette_outlined,
      'colors': [Color(0xFF8B5CF6), Color(0xFFD946EF)],
      'route': '/settings/personalization',
      'items': 4,
    },
    {
      'title': 'Family Hub',
      'description': 'Manage family features and members',
      'icon': Icons.family_restroom,
      'colors': [Color(0xFFF59E0B), Color(0xFFEF4444)],
      'route': '/family',
      'items': 12,
    },
    {
      'title': 'Support & Legal',
      'description': 'Help, about, and data rights',
      'icon': Icons.help_outline,
      'colors': [Color(0xFF6B7280), Color(0xFF4B5563)],
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
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                child: Container(),
              ),
              title: Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
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
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
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
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _searchQuery.isEmpty ? 'Categories' : 'Search Results',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = _filteredCategories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SettingsCategoryCard(
                      title: category['title'],
                      description: category['description'],
                      icon: category['icon'],
                      gradientColors: List<Color>.from(category['colors']),
                      itemCount: category['items'],
                      onTap: () {
                        Navigator.of(context).pushNamed(category['route']);
                      },
                    ),
                  );
                },
                childCount: _filteredCategories.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
