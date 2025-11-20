import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import 'package:intl/intl.dart';
import '../../models/family/genealogy_person.dart';
import '../../models/memory.dart';
import '../../services/api_service.dart';
import '../../dialogs/family/add_relationship_dialog.dart';
import '../../services/family/genealogy/persons_service.dart';
import '../../services/family/genealogy/relationships_service.dart';

class PersonProfileScreen extends StatefulWidget {
  final GenealogyPerson person;

  const PersonProfileScreen({Key? key, required this.person}) : super(key: key);

  @override
  _PersonProfileScreenState createState() => _PersonProfileScreenState();
}

class _PersonProfileScreenState extends State<PersonProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final GenealogyPersonsService _personsService = GenealogyPersonsService();
  final GenealogyRelationshipsService _relationshipsService = GenealogyRelationshipsService();
  List<Memory> _memories = [];
  bool _isLoadingMemories = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    if (widget.person.linkedUserId == null) {
      // If not linked to a user, we might need to search by tag using the person's ID if that's how we implemented it.
      // The backend implementation uses 'tagged_family_members.user_id'.
      // If the person is just a tree node without a user account, we can't easily filter by ID unless we store the person ID in the tag.
      // For now, let's assume we are looking for memories where this person (if they have a user ID) is tagged.
      // If they don't have a linked user ID, we might not find anything unless we update the backend to search by person ID (tree node ID).
      // But the backend update I made filters by `tagged_family_members.user_id`.
      // So this only works for people who are also Users.
      // TODO: Update backend to allow tagging non-user family members or search by name?
      return;
    }

    setState(() {
      _isLoadingMemories = true;
    });

    try {
      final memories = await _apiService.searchMemories(
        personId: widget.person.linkedUserId,
      );
      setState(() {
        _memories = memories;
        _isLoadingMemories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMemories = false;
      });
      // Handle error silently or show snackbar
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddRelationshipDialog() async {
    try {
      final persons = await _personsService.getPersons();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AddRelationshipDialog(
          persons: persons.map((p) => p.toJson()).toList(),
          initialPersonId: widget.person.id,
          onSubmit: (data) async {
            try {
              await _relationshipsService.createRelationship(data);
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
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load persons: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.person.fullName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Add Relationship',
            onPressed: _showAddRelationshipDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'About'),
              Tab(text: 'Memories'),
              Tab(text: 'Timeline'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildMemoriesTab(),
                _buildTimelineTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(MemoryHubSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: widget.person.photoUrl != null
                ? NetworkImage(widget.person.photoUrl!)
                : null,
            child: widget.person.photoUrl == null
                ? Text(
                    widget.person.firstName[0],
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          HGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.person.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.person.relationshipLabel != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      widget.person.relationshipLabel!,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                VGap.xxs(),
                Text(
                  widget.person.lifespan != null ? '${widget.person.lifespan} years' : '',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(MemoryHubSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Biography', widget.person.biography ?? 'No biography available.'),
          VGap.md(),
          _buildInfoSection('Occupation', widget.person.occupation ?? 'Unknown'),
          VGap.md(),
          _buildInfoSection('Birth', 
            '${widget.person.dateOfBirth != null ? DateFormat.yMMMd().format(widget.person.dateOfBirth!) : 'Unknown'}\n${widget.person.placeOfBirth ?? ''}'),
          if (widget.person.isDeceased) ...[
            VGap.md(),
            _buildInfoSection('Death', 
              '${widget.person.dateOfDeath != null ? DateFormat.yMMMd().format(widget.person.dateOfDeath!) : 'Unknown'}\n${widget.person.placeOfDeath ?? ''}'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        VGap.xs(),
        Text(
          content,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildMemoriesTab() {
    if (_isLoadingMemories) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_memories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_album_outlined, size: 64, color: Colors.grey),
            VGap.md(),
            Text(
              'No memories found for ${widget.person.firstName}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(MemoryHubSpacing.xs),
      itemCount: _memories.length,
      itemBuilder: (context, index) {
        final memory = _memories[index];
        return Card(
          margin: EdgeInsets.all(MemoryHubSpacing.xs),
          child: ListTile(
            title: Text(memory.title),
            subtitle: memory.content.isNotEmpty ? Text(memory.content, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
            onTap: () {
              // Navigate to memory detail if needed
            },
          ),
        );
      },
    );
  }

  Widget _buildTimelineTab() {
    // Placeholder for timeline
    return const Center(
      child: Text('Timeline coming soon...'),
    );
  }
}
