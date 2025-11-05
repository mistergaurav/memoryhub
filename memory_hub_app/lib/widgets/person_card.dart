import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'default_avatar.dart';
import '../models/family/genealogy_person.dart';

class PersonCard extends StatelessWidget {
  final GenealogyPerson person;
  final bool isGridView;

  const PersonCard({
    Key? key,
    required this.person,
    this.isGridView = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isGridView ? _buildGridCard(context) : _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final fullName = person.fullName;
    final birthDate = person.dateOfBirth;
    final deathDate = person.dateOfDeath;
    final photoUrl = person.photoUrl;
    final gender = person.gender;
    final healthRecordsCount = person.healthRecordsCount;
    final hereditaryConditions = person.hereditaryConditions;
    final age = person.age;
    final lifespan = person.lifespan;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // _showPersonDetails(person);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  photoUrl != null
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return DefaultAvatar(gender: gender);
                          },
                        )
                      : DefaultAvatar(gender: gender),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: gender == 'male'
                            ? Colors.blue.withOpacity(0.8)
                            : gender == 'female'
                                ? Colors.pink.withOpacity(0.8)
                                : Colors.grey.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            gender == 'male' ? Icons.male : gender == 'female' ? Icons.female : Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (birthDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.cake,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatDate(birthDate),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (deathDate != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatDate(deathDate),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (age != null || lifespan != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        lifespan != null ? 'Lived $lifespan years' : 'Age: $age',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (healthRecordsCount > 0 || (hereditaryConditions != null && hereditaryConditions.isNotEmpty)) ...[
                      Flexible(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (healthRecordsCount > 0) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.health_and_safety, size: 12, color: Colors.red.shade400),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$healthRecordsCount',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (hereditaryConditions != null && hereditaryConditions.isNotEmpty) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.family_restroom, size: 12, color: Colors.purple.shade400),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${hereditaryConditions.length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.purple.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final fullName = person.fullName;
    final birthDate = person.dateOfBirth;
    final deathDate = person.dateOfDeath;
    final photoUrl = person.photoUrl;
    final gender = person.gender;
    final occupation = person.occupation;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // _showPersonDetails(person);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: gender == 'male'
                        ? [Colors.blue.shade400, Colors.blue.shade600]
                        : gender == 'female'
                            ? [Colors.pink.shade400, Colors.pink.shade600]
                            : [Colors.grey.shade400, Colors.grey.shade600],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              gender == 'male' ? Icons.male : gender == 'female' ? Icons.female : Icons.person,
                              color: Colors.white,
                              size: 32,
                            );
                          },
                        )
                      : Icon(
                          gender == 'male' ? Icons.male : gender == 'female' ? Icons.female : Icons.person,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (occupation != null) ...[
                      Text(
                        occupation,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (birthDate != null)
                      Text(
                        '${_formatDate(birthDate)}${deathDate != null ? ' - ${_formatDate(deathDate)}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
        ),
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
}
