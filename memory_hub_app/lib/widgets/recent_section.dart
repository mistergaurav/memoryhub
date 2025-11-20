import 'package:flutter/material.dart';
import '../../design_system/design_tokens.dart';

class RecentSection extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final IconData icon;
  final Color color;
  final VoidCallback onViewAll;

  const RecentSection({
    Key? key,
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
    required this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: MemoryHubSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: MemoryHubSpacing.sm),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index] as Map<String, dynamic>;
              return _buildRecentItemCard(context, item, color);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItemCard(BuildContext context, Map<String, dynamic> item, Color color) {
    final title = item['title'] as String? ?? 'Untitled';

    return Container(
      width: 200,
      margin: EdgeInsets.only(right: MemoryHubSpacing.md),
      child: Card(
        elevation: MemoryHubElevation.sm,
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.mdRadius,
        ),
        child: Container(
          padding: EdgeInsets.all(MemoryHubSpacing.md),
          decoration: BoxDecoration(
            borderRadius: MemoryHubBorderRadius.mdRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item['photo_count'] != null) ...[
                const SizedBox(height: MemoryHubSpacing.xs),
                Text(
                  '${item['photo_count']} photos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
