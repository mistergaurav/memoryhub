import 'package:flutter/material.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/design_system.dart';

class AddPersonToCircleDialog extends StatefulWidget {
  final Function(String userId, String relationshipType) onSubmit;

  const AddPersonToCircleDialog({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<AddPersonToCircleDialog> createState() => _AddPersonToCircleDialogState();
}

class _AddPersonToCircleDialogState extends State<AddPersonToCircleDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRelationship = 'friend';
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];

  final List<String> _relationshipTypes = [
    'friend',
    'close_friend',
    'best_friend',
    'boyfriend',
    'girlfriend',
    'ex',
    'family_member',
    'work_colleague',
    'acquaintance',
    'mentor',
    'mentee',
  ];

  final Map<String, String> _relationshipLabels = {
    'friend': '👥 Friend',
    'close_friend': '💛 Close Friend',
    'best_friend': '⭐ Best Friend',
    'boyfriend': '💙 Boyfriend',
    'girlfriend': '💗 Girlfriend',
    'ex': '🔄 Ex',
    'family_member': '👨‍👩‍👧‍👦 Family',
    'work_colleague': '💼 Colleague',
    'acquaintance': '🤝 Acquaintance',
    'mentor': '🎓 Mentor',
    'mentee': '📚 Mentee',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.xlRadius),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: EdgeInsets.all(MemoryHubSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(MemoryHubSpacing.md),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [MemoryHubColors.green500, MemoryHubColors.teal500],
                      ),
                      borderRadius: MemoryHubBorderRadius.mdRadius,
                    ),
                    child: const Icon(Icons.person_add, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: MemoryHubSpacing.md),
                  const Expanded(
                    child: Text(
                      'Add Person',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: MemoryHubTypography.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: MemoryHubSpacing.xl),
              Text(
                'Search Person',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: MemoryHubTypography.semiBold,
                    ),
              ),
              const SizedBox(height: MemoryHubSpacing.md),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Enter name or ID',
                  hintText: 'e.g., Aman Jha, Priya',
                  border: OutlineInputBorder(
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      _searchResults = [];
                    } else {
                      _searchResults = [
                        {'id': 'aman_jha', 'name': 'Aman Jha'},
                        {'id': 'priya_sharma', 'name': 'Priya Sharma'},
                        {'id': 'rahul_singh', 'name': 'Rahul Singh'},
                      ]
                          .where((p) =>
                              p['name']!.toLowerCase().contains(value.toLowerCase()))
                          .toList();
                    }
                  });
                },
              ),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: MemoryHubSpacing.md),
                Text(
                  'Results (${_searchResults.length})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: MemoryHubSpacing.sm),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: MemoryHubColors.gray300),
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                  ),
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final person = _searchResults[index];
                      return ListTile(
                        title: Text(person['name']),
                        leading: CircleAvatar(
                          child: Text(person['name'][0].toUpperCase()),
                        ),
                        onTap: () {
                          _searchController.text = person['name'];
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: MemoryHubSpacing.lg),
              Text(
                'Relationship Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: MemoryHubTypography.semiBold,
                    ),
              ),
              const SizedBox(height: MemoryHubSpacing.md),
              Wrap(
                spacing: MemoryHubSpacing.sm,
                runSpacing: MemoryHubSpacing.sm,
                children: _relationshipTypes.map((type) {
                  final isSelected = _selectedRelationship == type;
                  return FilterChip(
                    label: Text(_relationshipLabels[type] ?? type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedRelationship = type);
                    },
                    backgroundColor: MemoryHubColors.gray100,
                    selectedColor:
                        Theme.of(context).primaryColor.withOpacity(0.2),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : MemoryHubColors.gray300,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: MemoryHubSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: MemoryHubSpacing.md),
                  ElevatedButton(
                    onPressed: _isLoading || _searchController.text.isEmpty
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            final person = _searchResults.isNotEmpty
                                ? _searchResults[0]
                                : {
                                    'id': _searchController.text
                                        .toLowerCase()
                                        .replaceAll(' ', '_'),
                                    'name': _searchController.text,
                                  };
                            try {
                              await widget.onSubmit(person['id'], _selectedRelationship);
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              if (mounted) {
                                AppSnackbar.error(context, 'Failed: $e');
                              }
                            }
                            if (mounted) setState(() => _isLoading = false);
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MemoryHubSpacing.xl,
                        vertical: MemoryHubSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: MemoryHubBorderRadius.mdRadius,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
