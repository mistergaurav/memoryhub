import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import 'family_albums_screen.dart';
import 'family_timeline_screen.dart';
import 'family_calendar_screen.dart';
import 'family_milestones_screen.dart';
import 'family_recipes_screen.dart';
import 'legacy_letters_screen.dart';
import 'family_traditions_screen.dart';
import 'parental_controls_screen.dart';
import 'family_document_vault_screen.dart';
import 'genealogy_tree_screen.dart';
import 'health_records_screen.dart';

class FamilyHubDashboardScreen extends StatefulWidget {
  const FamilyHubDashboardScreen({Key? key}) : super(key: key);

  @override
  State<FamilyHubDashboardScreen> createState() => _FamilyHubDashboardScreenState();
}

class _FamilyHubDashboardScreenState extends State<FamilyHubDashboardScreen> {
  final FamilyService _familyService = FamilyService();
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _familyService.getFamilyDashboard();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Family Hub',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7C3AED),
                        Color(0xFFEC4899),
                        Color(0xFF06B6D4),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Icon(
                          Icons.family_restroom,
                          size: 200,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Family Features',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureGrid(),
                  const SizedBox(height: 24),
                  if (!_isLoading) _buildQuickStats(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {
        'title': 'Family Albums',
        'icon': Icons.photo_library,
        'gradient': const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
        ),
        'screen': const FamilyAlbumsScreen(),
      },
      {
        'title': 'Timeline',
        'icon': Icons.timeline,
        'gradient': const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
        ),
        'screen': const FamilyTimelineScreen(),
      },
      {
        'title': 'Calendar',
        'icon': Icons.calendar_today,
        'gradient': const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
        ),
        'screen': const FamilyCalendarScreen(),
      },
      {
        'title': 'Milestones',
        'icon': Icons.celebration,
        'gradient': const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        ),
        'screen': const FamilyMilestonesScreen(),
      },
      {
        'title': 'Recipes',
        'icon': Icons.restaurant_menu,
        'gradient': const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
        ),
        'screen': const FamilyRecipesScreen(),
      },
      {
        'title': 'Legacy Letters',
        'icon': Icons.mail,
        'gradient': const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
        ),
        'screen': const LegacyLettersScreen(),
      },
      {
        'title': 'Traditions',
        'icon': Icons.local_florist,
        'gradient': const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
        ),
        'screen': const FamilyTraditionsScreen(),
      },
      {
        'title': 'Parental Controls',
        'icon': Icons.shield,
        'gradient': const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
        ),
        'screen': const ParentalControlsScreen(),
      },
      {
        'title': 'Document Vault',
        'icon': Icons.folder_special,
        'gradient': const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
        ),
        'screen': const FamilyDocumentVaultScreen(),
      },
      {
        'title': 'Genealogy Tree',
        'icon': Icons.account_tree,
        'gradient': const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        ),
        'screen': const GenealogyTreeScreen(),
      },
      {
        'title': 'Health Records',
        'icon': Icons.health_and_safety,
        'gradient': const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
        ),
        'screen': const HealthRecordsScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(
          title: feature['title'] as String,
          icon: feature['icon'] as IconData,
          gradient: feature['gradient'] as LinearGradient,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => feature['screen'] as Widget,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Albums',
                _dashboardData['albums_count']?.toString() ?? '0',
                Icons.photo_library,
                const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Events',
                _dashboardData['events_count']?.toString() ?? '0',
                Icons.event,
                const Color(0xFFEC4899),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Milestones',
                _dashboardData['milestones_count']?.toString() ?? '0',
                Icons.celebration,
                const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Recipes',
                _dashboardData['recipes_count']?.toString() ?? '0',
                Icons.restaurant_menu,
                const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
