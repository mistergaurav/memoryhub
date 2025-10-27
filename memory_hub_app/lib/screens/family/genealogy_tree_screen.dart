import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../widgets/person_card.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../dialogs/family/add_person_wizard.dart';
import '../../dialogs/family/add_relationship_dialog.dart';
import '../../widgets/default_avatar.dart';
import 'package:intl/intl.dart';

class GenealogyTreeScreen extends StatefulWidget {
  const GenealogyTreeScreen({Key? key}) : super(key: key);

  @override
  State<GenealogyTreeScreen> createState() => _GenealogyTreeScreenState();
}

class _GenealogyTreeScreenState extends State<GenealogyTreeScreen> {
  final FamilyService _familyService = FamilyService();
  List<Map<String, dynamic>> _persons = [];
  List<Map<String, dynamic>> _treeNodes = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedView = 'grid';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final persons = await _familyService.getPersons();
      final tree = await _familyService.getFamilyTree();
      setState(() {
        _persons = persons;
        _treeNodes = tree;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Genealogy Tree',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF59E0B),
                        Color(0xFFFBBF24),
                        Color(0xFFFDE047),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          Icons.account_tree,
                          size: 120,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(_selectedView == 'grid' ? Icons.list : Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _selectedView = _selectedView == 'grid' ? 'list' : 'grid';
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search feature coming soon')),
                    );
                  },
                ),
              ],
            ),
            if (_isLoading)
              _selectedView == 'grid'
                  ? SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const ShimmerCard(),
                          childCount: 6,
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: ShimmerListItem(),
                        ),
                        childCount: 5,
                      ),
                    )
            else if (_error.isNotEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Data',
                  message: 'Failed to load genealogy data. Pull to retry.',
                  actionLabel: 'Retry',
                  onAction: _loadData,
                ),
              )
            else if (_persons.isEmpty)
              SliverFillRemaining(
                child: EnhancedEmptyState(
                  icon: Icons.account_tree,
                  title: 'No Family Members Yet',
                  message: 'Start building your family tree by adding family members.',
                  actionLabel: 'Add Person',
                  onAction: _showAddPersonDialog,
                  gradientColors: const [
                    Color(0xFFF59E0B),
                    Color(0xFFFBBF24),
                  ],
                ),
              )
            else
              _selectedView == 'grid'
                  ? SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => PersonCard(person: _persons[index]),
                          childCount: _persons.length,
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => PersonCard(person: _persons[index], isGridView: false),
                        childCount: _persons.length,
                      ),
                    ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'genealogy_tree_fab',
        onPressed: _showAddPersonDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Person'),
        backgroundColor: const Color(0xFFF59E0B),
      ),
    );
  }




  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        return DateFormat('MMM d, yyyy').format(parsedDate);
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  void _showPersonDetails(Map<String, dynamic> person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PersonDetailSheet(person: person, familyService: _familyService),
    );
  }

  void _showPersonMenu(Map<String, dynamic> person) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFFF59E0B)),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditPersonDialog(person);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Color(0xFF06B6D4)),
              title: const Text('Add Relationship'),
              onTap: () {
                Navigator.pop(context);
                _showAddRelationshipDialog(person);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Person'),
                    content: const Text('Are you sure you want to delete this person?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  try {
                    await _familyService.deletePerson(person['id']);
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Person deleted successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete person: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPersonDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddPersonWizard(),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _showEditPersonDialog(Map<String, dynamic> person) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon! For now, please delete and re-add the person.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showAddRelationshipDialog(Map<String, dynamic> person) {
    showDialog(
      context: context,
      builder: (context) => AddRelationshipDialog(
        persons: _persons,
        onSubmit: _handleAddRelationship,
      ),
    );
  }

  Future<void> _handleAddPerson(Map<String, dynamic> data) async {
    try {
      await _familyService.createPerson(data);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Person added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add person: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _handleEditPerson(String personId, Map<String, dynamic> data) async {
    try {
      await _familyService.updatePerson(personId, data);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Person updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update person: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _handleAddRelationship(Map<String, dynamic> data) async {
    try {
      await _familyService.createRelationship(data);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relationship added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add relationship: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }
}

class PersonDetailSheet extends StatelessWidget {
  final Map<String, dynamic> person;
  final FamilyService familyService;

  const PersonDetailSheet({
    Key? key,
    required this.person,
    required this.familyService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firstName = person['first_name'] ?? '';
    final lastName = person['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final maidenName = person['maiden_name'];
    final birthDate = person['birth_date'];
    final birthPlace = person['birth_place'];
    final deathDate = person['death_date'];
    final deathPlace = person['death_place'];
    final occupation = person['occupation'];
    final biography = person['biography'];
    final photoUrl = person['photo_url'];
    final gender = person['gender'];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: gender == 'male'
                            ? [Colors.blue.shade400, Colors.blue.shade600]
                            : gender == 'female'
                                ? [Colors.pink.shade400, Colors.pink.shade600]
                                : [Colors.grey.shade400, Colors.grey.shade600],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: photoUrl != null
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  gender == 'male' ? Icons.male : gender == 'female' ? Icons.female : Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                );
                              },
                            )
                          : Icon(
                              gender == 'male' ? Icons.male : gender == 'female' ? Icons.female : Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isNotEmpty ? fullName : 'Unknown',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (maidenName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Maiden name: $maidenName',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (occupation != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            occupation,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (birthDate != null) ...[
                _buildInfoRow(Icons.cake, 'Birth', _formatDateWithPlace(birthDate, birthPlace)),
              ],
              if (deathDate != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.event_busy, 'Death', _formatDateWithPlace(deathDate, deathPlace)),
              ],
              if (biography != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Biography',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  biography,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.link),
                      label: const Text('Relationships'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateWithPlace(dynamic date, String? place) {
    final dateStr = _formatDate(date);
    if (place != null && place.isNotEmpty) {
      return '$dateStr\n$place';
    }
    return dateStr;
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        return DateFormat('MMMM d, yyyy').format(parsedDate);
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }
}
