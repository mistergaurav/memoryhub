import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NearbyPlacesScreen extends StatelessWidget {
  const NearbyPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Places', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 10,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            leading: const Icon(Icons.location_on),
            title: Text('Place $index', style: GoogleFonts.inter()),
            subtitle: const Text('Distance away'),
          ),
        ),
      ),
    );
  }
}
