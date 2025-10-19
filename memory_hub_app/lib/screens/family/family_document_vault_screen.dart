import 'package:flutter/material.dart';
import '../../widgets/enhanced_empty_state.dart';

class FamilyDocumentVaultScreen extends StatefulWidget {
  const FamilyDocumentVaultScreen({Key? key}) : super(key: key);

  @override
  State<FamilyDocumentVaultScreen> createState() =>
      _FamilyDocumentVaultScreenState();
}

class _FamilyDocumentVaultScreenState extends State<FamilyDocumentVaultScreen> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _folders = [
    {
      'name': 'Birth Certificates',
      'icon': Icons.badge,
      'count': 3,
      'color': const Color(0xFF7C3AED),
    },
    {
      'name': 'Medical Records',
      'icon': Icons.local_hospital,
      'count': 12,
      'color': const Color(0xFFEF4444),
    },
    {
      'name': 'Legal Documents',
      'icon': Icons.gavel,
      'count': 5,
      'color': const Color(0xFF6366F1),
    },
    {
      'name': 'Insurance',
      'icon': Icons.shield,
      'count': 8,
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Property Deeds',
      'icon': Icons.home,
      'count': 2,
      'color': const Color(0xFFF59E0B),
    },
    {
      'name': 'Education',
      'icon': Icons.school,
      'count': 15,
      'color': const Color(0xFF06B6D4),
    },
    {
      'name': 'Financial',
      'icon': Icons.account_balance,
      'count': 10,
      'color': const Color(0xFFEC4899),
    },
    {
      'name': 'Other Documents',
      'icon': Icons.folder,
      'count': 7,
      'color': const Color(0xFF8B5CF6),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Document Vault',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF14B8A6),
                      Color(0xFF2DD4BF),
                      Color(0xFF5EEAD4),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      bottom: -50,
                      child: Icon(
                        Icons.folder_special,
                        size: 200,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      top: 100,
                      child: Icon(
                        Icons.lock,
                        size: 30,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                    Positioned(
                      right: 80,
                      top: 120,
                      child: Icon(
                        Icons.verified_user,
                        size: 25,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
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
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF14B8A6).withOpacity(0.1),
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF14B8A6).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure Storage',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'All documents are encrypted and securely stored',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Document Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final folder = _folders[index];
                  return _buildFolderCard(folder);
                },
                childCount: _folders.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Upload Document'),
        backgroundColor: const Color(0xFF14B8A6),
      ),
    );
  }

  Widget _buildFolderCard(Map<String, dynamic> folder) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FolderDetailScreen(
                folderName: folder['name'],
                folderIcon: folder['icon'],
                folderColor: folder['color'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (folder['color'] as Color).withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      folder['color'] as Color,
                      (folder['color'] as Color).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (folder['color'] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  folder['icon'] as IconData,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                folder['name'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (folder['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${folder['count']} files',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: folder['color'] as Color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FolderDetailScreen extends StatelessWidget {
  final String folderName;
  final IconData folderIcon;
  final Color folderColor;

  const FolderDetailScreen({
    Key? key,
    required this.folderName,
    required this.folderIcon,
    required this.folderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: EnhancedEmptyState(
        icon: folderIcon,
        title: 'No Documents',
        message: 'Upload documents to this folder to keep them organized and secure.',
        actionLabel: 'Upload',
        onAction: () {},
        gradientColors: [
          folderColor,
          folderColor.withOpacity(0.7),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: folderColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
