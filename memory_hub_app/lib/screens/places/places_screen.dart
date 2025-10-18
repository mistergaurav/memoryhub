import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

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
        title: Text('Places', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
          Icon(Icons.explore_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Find Nearby Places',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enable location to discover nearby places',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
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
          Icon(Icons.place_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No Places Yet',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your favorite places',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.place,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          place['name'] ?? 'Untitled',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place['address'] != null) ...[
              const SizedBox(height: 4),
              Text(
                place['address'],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${place['memory_count'] ?? 0} memories',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
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
