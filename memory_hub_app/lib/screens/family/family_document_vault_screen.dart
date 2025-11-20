import 'package:flutter/material.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../design_system/design_system.dart';
import '../../design_system/layout/padded.dart';

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
      'color': MemoryHubColors.purple600,
    },
    {
      'name': 'Medical Records',
      'icon': Icons.local_hospital,
      'count': 12,
      'color': MemoryHubColors.red500,
    },
    {
      'name': 'Legal Documents',
      'icon': Icons.gavel,
      'count': 5,
      'color': MemoryHubColors.indigo500,
    },
    {
      'name': 'Insurance',
      'icon': Icons.shield,
      'count': 8,
      'color': MemoryHubColors.green500,
    },
    {
      'name': 'Property Deeds',
      'icon': Icons.home,
      'count': 2,
      'color': MemoryHubColors.amber500,
    },
    {
      'name': 'Education',
      'icon': Icons.school,
      'count': 15,
      'color': MemoryHubColors.cyan500,
    },
    {
      'name': 'Financial',
      'icon': Icons.account_balance,
      'count': 10,
      'color': MemoryHubColors.pink500,
    },
    {
      'name': 'Other Documents',
      'icon': Icons.folder,
      'count': 7,
      'color': MemoryHubColors.purple500,
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
                      MemoryHubColors.teal500,
                      MemoryHubColors.teal400,
                      MemoryHubColors.teal300,
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
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      top: 100,
                      child: Icon(
                        Icons.lock,
                        size: 30,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    Positioned(
                      right: 80,
                      top: 120,
                      child: Icon(
                        Icons.verified_user,
                        size: 25,
                        color: Colors.white.withValues(alpha: 0.3),
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
            padding: EdgeInsets.all(MemoryHubSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: MemoryHubBorderRadius.xlRadius,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MemoryHubColors.teal500.withValues(alpha: 0.1),
                        Colors.white,
                      ],
                    ),
                    borderRadius: MemoryHubBorderRadius.xlRadius,
                  ),
                  padding: EdgeInsets.all(MemoryHubSpacing.xl),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(MemoryHubSpacing.lg),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [MemoryHubColors.teal500, MemoryHubColors.teal400],
                          ),
                          borderRadius: MemoryHubBorderRadius.lgRadius,
                          boxShadow: [
                            BoxShadow(
                              color: MemoryHubColors.teal500.withValues(alpha: 0.3),
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
                      HGap(MemoryHubSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure Storage',
                              style: TextStyle(
                                fontSize: MemoryHubTypography.h4,
                                fontWeight: MemoryHubTypography.bold,
                              ),
                            ),
                            VGap(MemoryHubSpacing.xs),
                            Text(
                              'All documents are encrypted and securely stored',
                              style: TextStyle(
                                fontSize: MemoryHubTypography.bodySmall,
                                color: MemoryHubColors.gray600,
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
            padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Document Categories',
                    style: TextStyle(
                      fontSize: MemoryHubTypography.h3,
                      fontWeight: MemoryHubTypography.bold,
                    ),
                  ),
                  VGap(MemoryHubSpacing.lg),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg),
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
          SliverToBoxAdapter(child: VGap(80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'family_document_vault_fab',
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Upload Document'),
        backgroundColor: MemoryHubColors.teal500,
      ),
    );
  }

  Widget _buildFolderCard(Map<String, dynamic> folder) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: MemoryHubBorderRadius.xlRadius,
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
        borderRadius: MemoryHubBorderRadius.xlRadius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: MemoryHubBorderRadius.xlRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (folder['color'] as Color).withValues(alpha: 0.1),
                Colors.white,
              ],
            ),
          ),
          padding: EdgeInsets.all(MemoryHubSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(MemoryHubSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      folder['color'] as Color,
                      (folder['color'] as Color).withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: MemoryHubBorderRadius.lgRadius,
                  boxShadow: [
                    BoxShadow(
                      color: (folder['color'] as Color).withValues(alpha: 0.3),
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
              VGap(MemoryHubSpacing.md),
              Text(
                folder['name'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: MemoryHubTypography.bodyMedium,
                  fontWeight: MemoryHubTypography.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              VGap(MemoryHubSpacing.xs),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MemoryHubSpacing.md,
                  vertical: MemoryHubSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: (folder['color'] as Color).withValues(alpha: 0.2),
                  borderRadius: MemoryHubBorderRadius.mdRadius,
                ),
                child: Text(
                  '${folder['count']} files',
                  style: TextStyle(
                    fontSize: MemoryHubTypography.bodySmall,
                    fontWeight: MemoryHubTypography.bold,
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
          folderColor.withValues(alpha: 0.7),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'folder_detail_fab_$folderName',
        onPressed: () {},
        backgroundColor: folderColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
