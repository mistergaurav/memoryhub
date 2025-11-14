import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../design_system/design_tokens.dart';

class AddPersonWizard extends StatefulWidget {
  const AddPersonWizard({Key? key}) : super(key: key);

  @override
  State<AddPersonWizard> createState() => _AddPersonWizardState();
}

class _AddPersonWizardState extends State<AddPersonWizard> {
  final FamilyService _familyService = FamilyService();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  Map<String, dynamic>? _selectedExistingUser;
  String _firstName = '';
  String _lastName = '';
  String _maidenName = '';
  String _gender = 'unknown';
  bool _isAlive = true;
  String _birthDate = '';
  String _birthPlace = '';
  String _deathDate = '';
  String _deathPlace = '';
  String _biography = '';
  String _occupation = '';
  String _notes = '';
  String? _photoUrl;
  File? _photoFile;
  
  List<Map<String, dynamic>> _selectedRelationships = [];
  List<Map<String, dynamic>> _existingPersons = [];
  
  bool _sendInvitation = false;
  String _invitationMessage = '';
  
  bool _isLoading = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadExistingPersons();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadExistingPersons() async {
    try {
      final persons = await _familyService.getPersons();
      setState(() {
        _existingPersons = persons;
      });
    } catch (e) {
      print('Error loading persons: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load family members: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadExistingPersons,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      setState(() {
        _existingPersons = [];
      });
    }
  }
  
  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await _familyService.searchPlatformUsers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
    }
  }
  
  void _selectExistingUser(Map<String, dynamic> user) {
    setState(() {
      _selectedExistingUser = user;
      final fullName = user['full_name'] ?? user['username'] ?? '';
      final nameParts = fullName.split(' ');
      
      if (nameParts.length > 1) {
        _firstName = nameParts.first;
        _lastName = nameParts.skip(1).join(' ');
      } else {
        _firstName = nameParts.first;
        _lastName = user['username'] ?? 'User';
      }
      
      _firstNameController.text = _firstName;
      _lastNameController.text = _lastName;
    });
  }
  
  void _nextStep() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: MemoryHubAnimations.fast,
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: MemoryHubAnimations.fast,
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }
  
  bool _canProceedFromCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _selectedExistingUser != null || _firstName.isNotEmpty;
      case 1:
        return _firstName.isNotEmpty && _lastName.isNotEmpty;
      case 2:
        return true;
      case 3:
        return true;
      case 4:
        return true;
      default:
        return false;
    }
  }
  
  Future<void> _submitPerson() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final personData = {
        'first_name': _firstName,
        'last_name': _lastName,
        'maiden_name': _maidenName.isEmpty ? null : _maidenName,
        'gender': _gender,
        'birth_date': _birthDate.isEmpty ? null : _birthDate,
        'birth_place': _birthPlace.isEmpty ? null : _birthPlace,
        'death_date': _deathDate.isEmpty ? null : _deathDate,
        'death_place': _deathPlace.isEmpty ? null : _deathPlace,
        'is_alive': _isAlive,
        'biography': _biography.isEmpty ? null : _biography,
        'occupation': _occupation.isEmpty ? null : _occupation,
        'notes': _notes.isEmpty ? null : _notes,
        'photo_url': _photoUrl,
        'linked_user_id': _selectedExistingUser?['id'],
        'source': _selectedExistingUser != null ? 'platform_user' : 'manual',
        'relationships': _selectedRelationships.map((rel) => {
          'person_id': rel['personId'],
          'relationship_type': rel['type'],
          'notes': rel['notes'],
        }).toList(),
      };
      
      final createdPerson = await _familyService.createPerson(personData);
      
      if (_sendInvitation && _selectedExistingUser != null && _isAlive) {
        try {
          await _familyService.sendFamilyHubInvitation(
            createdPerson['id'],
            _selectedExistingUser!['id'],
            _invitationMessage.isEmpty ? null : _invitationMessage,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Person added but invitation failed: ${e.toString()}')),
            );
          }
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Person added successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add person: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(MemoryHubSpacing.lg),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: MemoryHubBorderRadius.xxlRadius,
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1SearchOrAdd(),
                  _buildStep2PersonDetails(),
                  _buildStep3Relationships(),
                  _buildStep4Invite(),
                  _buildStep5Confirm(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGenerateInviteLinkButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          final inviteLink = await _familyService.generateInviteLink();
          // Share the invite link
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to generate invite link: $e')),
          );
        }
      },
      icon: const Icon(Icons.link),
      label: const Text('Generate Invite Link'),
      style: ElevatedButton.styleFrom(
        backgroundColor: MemoryHubColors.cyan600,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(MemoryHubSpacing.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [MemoryHubColors.yellow500, MemoryHubColors.yellow400],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_add, color: Colors.white, size: 28),
          const SizedBox(width: MemoryHubSpacing.md),
          const Expanded(
            child: Text(
              'Add Person to Family Tree',
              style: TextStyle(
                color: Colors.white,
                fontSize: MemoryHubTypography.h3,
                fontWeight: MemoryHubTypography.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    final steps = ['Search', 'Details', 'Relations', 'Invite', 'Confirm'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(5, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted || isCurrent
                              ? MemoryHubColors.yellow500
                              : Colors.grey[300],
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrent ? Colors.white : Colors.grey[600],
                                    fontWeight: MemoryHubTypography.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: MemoryHubSpacing.xs),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrent ? MemoryHubColors.yellow500 : Colors.grey[600],
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < 4)
                  Container(
                    height: 2,
                    width: 20,
                    color: isCompleted ? MemoryHubColors.yellow500 : Colors.grey[300],
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildStep({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MemoryHubSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: MemoryHubTypography.h4, fontWeight: MemoryHubTypography.bold),
          ),
          const SizedBox(height: MemoryHubSpacing.sm),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: MemoryHubTypography.body2),
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildStep1SearchOrAdd() {
    return _buildStep(
      title: 'Step 1: Search or Add New Person',
      subtitle:
          'Start typing to search for existing users on our platform, or enter a name to create a new profile.',
      content: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search for existing user',
              hintText: 'Type name, email, or username...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _searchUsers(value);
            },
          ),
          const SizedBox(height: MemoryHubSpacing.lg),
          if (_searchResults.isNotEmpty) ...[
            const Text(
              'Platform Users Found:',
              style: TextStyle(fontWeight: MemoryHubTypography.bold),
            ),
            const SizedBox(height: MemoryHubSpacing.sm),
            ...(_searchResults.take(5).map((user) => _buildUserCard(user))),
          ] else if (_searchQuery.length >= 2 && !_isSearching) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No users found. Continue below to create a new profile.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
          const Divider(height: 32),
          const Text(
            'Or create a new profile:',
            style: TextStyle(fontWeight: MemoryHubTypography.bold),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          TextField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name *',
              border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
            ),
            onChanged: (value) {
              setState(() {
                _firstName = value;
              });
            },
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          TextField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
            ),
            onChanged: (value) {
              setState(() {
                _lastName = value;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserCard(Map<String, dynamic> user) {
    final isSelected = _selectedExistingUser?['id'] == user['id'];
    final alreadyLinked = user['already_linked'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? MemoryHubColors.yellow50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user['profile_photo'] != null
              ? NetworkImage(user['profile_photo'])
              : null,
          child: user['profile_photo'] == null
              ? Text(user['username']?[0]?.toUpperCase() ?? 'U')
              : null,
        ),
        title: Text(user['full_name'] ?? user['username'] ?? 'Unknown'),
        subtitle: Text(user['email'] ?? ''),
        trailing: alreadyLinked
            ? const Chip(
                label: Text('Already Linked', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.grey,
                labelStyle: TextStyle(color: Colors.white),
              )
            : isSelected
                ? const Icon(Icons.check_circle, color: MemoryHubColors.yellow500)
                : null,
        onTap: alreadyLinked
            ? null
            : () => _selectExistingUser(user),
        enabled: !alreadyLinked,
      ),
    );
  }
  
  Widget _buildStep2PersonDetails() {
    return _buildStep(
      title: 'Step 2: Person Details',
      subtitle: 'Enter or update the person\'s details.',
      content: Column(
        children: [
          TextField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name *',
              border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
            ),
            onChanged: (value) => setState(() => _firstName = value),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          TextField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name *',
              border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
            ),
            onChanged: (value) => setState(() => _lastName = value),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          TextField(
            decoration: InputDecoration(
              labelText: 'Maiden Name',
              border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
            ),
            onChanged: (value) => setState(() => _maidenName = value),
          ),
          const SizedBox(height: MemoryHubSpacing.lg),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
            ),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
              DropdownMenuItem(value: 'unknown', child: Text('Prefer not to say')),
            ],
            onChanged: (value) => setState(() => _gender = value ?? 'unknown'),
          ),
          const SizedBox(height: MemoryHubSpacing.lg),
          SwitchListTile(
            title: const Text('Status'),
            subtitle: Text(_isAlive ? 'Alive' : 'Deceased'),
            value: _isAlive,
            activeColor: MemoryHubColors.yellow500,
            onChanged: (value) => setState(() => _isAlive = value),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          TextField(
            decoration: InputDecoration(
              labelText: 'Birth Date (YYYY-MM-DD)',
              hintText: '1990-01-15',
              border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1800),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _birthDate = DateFormat('yyyy-MM-dd').format(date));
                  }
                },
              ),
            ),
            controller: TextEditingController(text: _birthDate),
            onChanged: (value) => setState(() => _birthDate = value),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          TextField(
            decoration: InputDecoration(
              labelText: 'Birth Place',
              border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
            ),
            onChanged: (value) => setState(() => _birthPlace = value),
          ),
          if (!_isAlive) ...[
            const SizedBox(height: MemoryHubSpacing.md),
            TextField(
              decoration: InputDecoration(
                labelText: 'Death Date (YYYY-MM-DD)',
                hintText: '2020-05-20',
                border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1800),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _deathDate = DateFormat('yyyy-MM-dd').format(date));
                    }
                  },
                ),
              ),
              controller: TextEditingController(text: _deathDate),
              onChanged: (value) => setState(() => _deathDate = value),
            ),
            const SizedBox(height: MemoryHubSpacing.md),
            TextField(
              decoration: InputDecoration(
                labelText: 'Death Place',
                border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
              ),
              onChanged: (value) => setState(() => _deathPlace = value),
            ),
          ],
          const SizedBox(height: MemoryHubSpacing.md),
          TextField(
            decoration: InputDecoration(
              labelText: 'Occupation',
              border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
            ),
            onChanged: (value) => setState(() => _occupation = value),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Biography',
              hintText: 'Brief life story...',
              border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
            ),
            onChanged: (value) => setState(() => _biography = value),
          ),
          const SizedBox(height: MemoryHubSpacing.md),
          TextField(
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
            ),
            onChanged: (value) => setState(() => _notes = value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep3Relationships() {
    return _buildStep(
      title: 'Step 3: Relationship Setup',
      subtitle:
          'Define how this person relates to existing family members. The tree will automatically update.',
      content: Column(
        children: [
          if (_existingPersons.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.people, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No family members yet',
                      style: TextStyle(fontSize: MemoryHubTypography.body1, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Skip this step for now. You can add relationships later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: MemoryHubTypography.body2, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ..._selectedRelationships.map((rel) => _buildRelationshipChip(rel)),
            const SizedBox(height: MemoryHubSpacing.md),
            ElevatedButton.icon(
              onPressed: _showAddRelationshipDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Relationship'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MemoryHubColors.yellow500,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        if (_selectedExistingUser == null && _isAlive) ...[
          const SizedBox(height: MemoryHubSpacing.xl),
          const Divider(),
          const SizedBox(height: MemoryHubSpacing.xl),
          const Center(
            child: Text(
              'Or, generate an invite link to share:',
              style: TextStyle(fontSize: MemoryHubTypography.body2, color: Colors.grey),
            ),
          ),
          const SizedBox(height: MemoryHubSpacing.lg),
          Center(child: _buildGenerateInviteLinkButton()),
        ],
        ],
      ),
    );
  }
  
  Widget _buildRelationshipChip(Map<String, dynamic> rel) {
    final person = _existingPersons.firstWhere(
      (p) => p['id'] == rel['personId'],
      orElse: () => {},
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: MemoryHubColors.yellow500,
          child: const Icon(Icons.link, color: Colors.white, size: 20),
        ),
        title: Text('${person['first_name'] ?? ''} ${person['last_name'] ?? ''}'),
        subtitle: Text(_getRelationshipLabel(rel['type'])),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _selectedRelationships.remove(rel);
            });
          },
        ),
      ),
    );
  }
  
  String _getRelationshipLabel(String type) {
    final labels = {
      'parent': 'Parent',
      'child': 'Child',
      'spouse': 'Spouse/Partner',
      'sibling': 'Sibling',
      'grandparent': 'Grandparent',
      'grandchild': 'Grandchild',
      'aunt_uncle': 'Aunt/Uncle',
      'niece_nephew': 'Niece/Nephew',
      'cousin': 'Cousin',
    };
    return labels[type] ?? type;
  }
  
  void _showAddRelationshipDialog() {
    String? selectedPersonId;
    String? selectedRelationType;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Relationship'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Person'),
                items: _existingPersons.map<DropdownMenuItem<String>>((person) {
                  return DropdownMenuItem<String>(
                    value: person['id'],
                    child: Text('${person['first_name']} ${person['last_name']}'),
                  );
                }).toList(),
                onChanged: (value) => setDialogState(() => selectedPersonId = value),
              ),
              const SizedBox(height: MemoryHubSpacing.lg),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Relationship Type'),
                items: const [
                  DropdownMenuItem(value: 'parent', child: Text('Parent')),
                  DropdownMenuItem(value: 'child', child: Text('Child')),
                  DropdownMenuItem(value: 'spouse', child: Text('Spouse/Partner')),
                  DropdownMenuItem(value: 'sibling', child: Text('Sibling')),
                  DropdownMenuItem(value: 'grandparent', child: Text('Grandparent')),
                  DropdownMenuItem(value: 'grandchild', child: Text('Grandchild')),
                  DropdownMenuItem(value: 'aunt_uncle', child: Text('Aunt/Uncle')),
                  DropdownMenuItem(value: 'niece_nephew', child: Text('Niece/Nephew')),
                  DropdownMenuItem(value: 'cousin', child: Text('Cousin')),
                ],
                onChanged: (value) => setDialogState(() => selectedRelationType = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedPersonId != null && selectedRelationType != null
                  ? () {
                      setState(() {
                        _selectedRelationships.add({
                          'personId': selectedPersonId,
                          'type': selectedRelationType,
                          'notes': null,
                        });
                      });
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MemoryHubColors.yellow500,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStep4Invite() {
    final canInvite = _isAlive;
    
    return _buildStep(
      title: 'Step 4: Invite to Family Hub',
      subtitle: canInvite
          ? 'Since this person is alive, you can invite them to join your family hub.'
          : 'This person is marked as deceased.',
      content: Column(
        children: [
          if (canInvite) ...[
            if (_selectedExistingUser != null) ...[
              SwitchListTile(
                title: const Text('Send Invitation'),
                subtitle: Text(
                    'Invite ${_selectedExistingUser!['full_name'] ?? _selectedExistingUser!['username']} to your family hub'),
                value: _sendInvitation,
                activeColor: MemoryHubColors.yellow500,
                onChanged: (value) => setState(() => _sendInvitation = value),
              ),
              if (_sendInvitation) ...[
                const SizedBox(height: MemoryHubSpacing.lg),
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Personal Message (Optional)',
                    hintText: 'Add a personal message to the invitation...',
                    border: OutlineInputBorder(borderRadius: MemoryHubBorderRadius.mdRadius),
                  ),
                  onChanged: (value) => setState(() => _invitationMessage = value),
                ),
                const SizedBox(height: MemoryHubSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(MemoryHubSpacing.lg),
                  decoration: BoxDecoration(
                    color: MemoryHubColors.yellow50,
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                    border: Border.all(color: MemoryHubColors.yellow500),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: MemoryHubColors.yellow500),
                      const SizedBox(width: MemoryHubSpacing.md),
                      Expanded(
                        child: Text(
                          'They will receive a notification and can accept to join your family network.',
                          style: TextStyle(fontSize: MemoryHubTypography.caption, color: Colors.grey[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const Center(
                child: Text(
                  'Generate an invite link to share:',
                  style: TextStyle(fontSize: MemoryHubTypography.body2, color: Colors.grey),
                ),
              ),
              const SizedBox(height: MemoryHubSpacing.lg),
              Center(child: _buildGenerateInviteLinkButton()),
            ],
          ] else ...[
            Center(
              child: Column(
                children: [
                  const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: MemoryHubSpacing.lg),
                  Text(
                    _selectedExistingUser == null
                        ? 'No invitation needed for manually added profiles'
                        : 'Invitations are only for living family members',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStep5Confirm() {
    return _buildStep(
      title: 'Step 5: Confirm & Add',
      subtitle: 'Review the information and click "Add to Tree" to finalize.',
      content: _buildSummaryCard(),
    );
  }
  
  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: MemoryHubBorderRadius.lgRadius),
      child: Padding(
        padding: const EdgeInsets.all(MemoryHubSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: MemoryHubColors.yellow500,
                  child: Text(
                    _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: MemoryHubTypography.bold),
                  ),
                ),
                const SizedBox(width: MemoryHubSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_firstName $_lastName',
                        style: const TextStyle(fontSize: MemoryHubTypography.h3, fontWeight: MemoryHubTypography.bold),
                      ),
                      if (_maidenName.isNotEmpty)
                        Text('(née $_maidenName)', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: MemoryHubSpacing.xs),
                      Chip(
                        label: Text(_isAlive ? 'Alive' : 'Deceased', style: const TextStyle(fontSize: MemoryHubTypography.caption)),
                        backgroundColor: _isAlive ? Colors.green[100] : Colors.grey[300],
                        labelStyle: TextStyle(color: _isAlive ? Colors.green[900] : Colors.grey[900]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildSummaryItem(Icons.cake, 'Birth', _birthDate.isEmpty ? 'Not specified' : '$_birthDate${_birthPlace.isNotEmpty ? ' in $_birthPlace' : ''}'),
            if (!_isAlive && _deathDate.isNotEmpty)
              _buildSummaryItem(Icons.event_busy, 'Death', '$_deathDate${_deathPlace.isNotEmpty ? ' in $_deathPlace' : ''}'),
            if (_occupation.isNotEmpty)
              _buildSummaryItem(Icons.work, 'Occupation', _occupation),
            if (_selectedExistingUser != null)
              _buildSummaryItem(Icons.link, 'Linked User', _selectedExistingUser!['username'] ?? 'Unknown'),
            if (_selectedRelationships.isNotEmpty)
              _buildSummaryItem(Icons.family_restroom, 'Relationships', '${_selectedRelationships.length} defined'),
            if (_sendInvitation)
              _buildSummaryItem(Icons.email, 'Invitation', 'Will be sent'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: MemoryHubColors.yellow500),
          const SizedBox(width: MemoryHubSpacing.md),
          Text('$label: ', style: const TextStyle(fontWeight: MemoryHubTypography.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
  
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(MemoryHubSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          if (_currentStep < 4)
            ElevatedButton(
              onPressed: _canProceedFromCurrentStep() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MemoryHubColors.yellow500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Next'),
            )
          else
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitPerson,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(_isLoading ? 'Adding...' : 'Add to Tree'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MemoryHubColors.yellow500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
}
