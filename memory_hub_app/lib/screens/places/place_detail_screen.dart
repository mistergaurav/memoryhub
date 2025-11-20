import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';

class PlaceDetailScreen extends StatelessWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Place Details', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 10,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            title: Text('Memory at this place $index', style: context.text.bodyMedium),
          ),
        ),
      ),
    );
  }
}
