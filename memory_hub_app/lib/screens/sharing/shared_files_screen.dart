import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';

class SharedFilesScreen extends StatelessWidget {
  const SharedFilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shared with Me',
          style: context.text.titleLarge?.copyWith(fontWeight: MemoryHubTypography.bold),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(Spacing.xl),
        itemCount: 10,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: Spacing.md),
          child: AppCard(
            child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.1),
                borderRadius: MemoryHubBorderRadius.mdRadius,
              ),
              child: Icon(Icons.insert_drive_file, color: context.colors.primary),
            ),
            title: Text(
              'Shared File $index',
              style: context.text.bodyLarge?.copyWith(fontWeight: MemoryHubTypography.semiBold),
            ),
            subtitle: Text(
              'Shared by User Name',
              style: context.text.bodySmall,
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'download', child: Text('Download')),
                PopupMenuItem(value: 'remove', child: Text('Remove Access')),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
