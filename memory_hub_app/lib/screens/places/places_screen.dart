import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../design_system/design_system.dart';
import '../../design_system/layout/padded.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _places = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlaces();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    setState(() => _isLoading = true);
    try {
      final places = await _apiService.getPlaces();
      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Places', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.colors.primary,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.colors.outline,
          labelStyle: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Saved Places'),
            Tab(text: 'Nearby'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedPlaces(),
          _buildNearbyPlaces(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/places/create');
        },
        icon: const Icon(Icons.add_location),
        label: const Text('Add Place'),
      ),
    );
  }

  Widget _buildSavedPlaces() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_places.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return _buildPlaceCard(place);
      },
    );
  }

  Widget _buildNearbyPlaces() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, size: 80, color: context.colors.outline.withOpacity(0.5)),
          VGap.lg(),
          Text(
            'Find Nearby Places',
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          VGap.xs(),
          Text(
            'Enable location to discover nearby places',
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.outline,
            ),
          ),
          VGap.xl(),
          FilledButton.icon(
            onPressed: () {
              // Request location permission
            },
            icon: const Icon(Icons.location_on),
            label: const Text('Enable Location'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.place_outlined, size: 80, color: context.colors.outline.withOpacity(0.5)),
          VGap.lg(),
          Text(
            'No Places Yet',
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          VGap.xs(),
          Text(
            'Add your favorite places',
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MemoryHubColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colors.primary.withOpacity(0.2),
                context.colors.secondary.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.place,
            color: context.colors.primary,
            size: 24,
          ),
        ),
        title: Text(
          place['name'] ?? 'Untitled',
          style: context.text.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place['address'] != null) ...[
              VGap.xxs(),
              Text(
                place['address'],
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.outline,
                ),
              ),
            ],
            VGap.xs(),
            Text(
              '${place['memory_count'] ?? 0} memories',
              style: context.text.labelSmall?.copyWith(
                color: context.colors.primary,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pushNamed(context, '/places/detail', arguments: place['id']);
        },
      ),
    );
  }
}
