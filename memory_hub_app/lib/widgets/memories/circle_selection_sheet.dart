import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import 'package:memory_hub_app/design_system/layout/padded.dart';
import 'package:memory_hub_app/design_system/layout/gap.dart';
import 'package:memory_hub_app/design_system/components/buttons/primary_button.dart';
import 'package:memory_hub_app/services/family/core/family_circles_service.dart';
import 'package:memory_hub_app/models/family/family_circle.dart';

class CircleSelectionSheet extends StatefulWidget {
  final List<String> initialSelectedIds;
  final Function(List<String>) onSelectionChanged;

  const CircleSelectionSheet({
    super.key,
    required this.initialSelectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<CircleSelectionSheet> createState() => _CircleSelectionSheetState();
}

class _CircleSelectionSheetState extends State<CircleSelectionSheet> {
  final FamilyCirclesService _circlesService = FamilyCirclesService();
  final Set<String> _selectedIds = {};
  List<FamilyCircle> _circles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
    _loadCircles();
  }

  Future<void> _loadCircles() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await _circlesService.getFamilyCircles();
      final circles = result['circles'] as List<FamilyCircle>;

      setState(() {
        _circles = circles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String circleId) {
    setState(() {
      if (_selectedIds.contains(circleId)) {
        _selectedIds.remove(circleId);
      } else {
        _selectedIds.add(circleId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padded.lg(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Circles',
                  style: context.text.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _circles.isEmpty
                        ? const Center(child: Text('No circles found'))
                        : ListView.builder(
                            itemCount: _circles.length,
                            itemBuilder: (context, index) {
                              final circle = _circles[index];
                              final isSelected = _selectedIds.contains(circle.id);
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: context.colors.primaryContainer,
                                  child: Icon(Icons.diversity_3, color: context.colors.primary),
                                ),
                                title: Text(circle.name),
                                subtitle: Text('${circle.memberCount} members'),
                                trailing: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggleSelection(circle.id),
                                  shape: const CircleBorder(),
                                ),
                                onTap: () => _toggleSelection(circle.id),
                              );
                            },
                          ),
          ),
          Padded.lg(
            child: PrimaryButton(
              onPressed: () {
                widget.onSelectionChanged(_selectedIds.toList());
                Navigator.pop(context);
              },
              label: 'Confirm Selection (${_selectedIds.length})',
              fullWidth: true,
            ),
          ),
          VGap.lg(),
        ],
      ),
    );
  }
}
