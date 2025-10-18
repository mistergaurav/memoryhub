import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareBottomSheet extends StatelessWidget {
  final String shareUrl;
  final String title;
  final String description;
  final bool showShareToHub;
  final VoidCallback? onShareToHub;

  const ShareBottomSheet({
    super.key,
    required this.shareUrl,
    required this.title,
    required this.description,
    this.showShareToHub = false,
    this.onShareToHub,
  });

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: shareUrl));
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareViaApps(BuildContext context) async {
    try {
      await Share.share(
        '$title\n\n$description\n\n$shareUrl',
        subject: title,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share $title',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          
          // Copy Link Option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.link, color: Colors.blue),
            ),
            title: const Text('Copy Link'),
            subtitle: const Text('Copy link to clipboard'),
            onTap: () => _copyToClipboard(context),
          ),
          
          // Share via Apps Option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.share_outlined, color: Colors.green),
            ),
            title: const Text('Share via Apps'),
            subtitle: const Text('Share through messaging apps'),
            onTap: () => _shareViaApps(context),
          ),
          
          // Share to Hub Option (conditional)
          if (showShareToHub)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.workspaces, color: Colors.purple),
              ),
              title: const Text('Share to Hub'),
              subtitle: const Text('Share to a community hub'),
              onTap: () {
                Navigator.pop(context);
                onShareToHub?.call();
              },
            ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String shareUrl,
    required String title,
    required String description,
    bool showShareToHub = false,
    VoidCallback? onShareToHub,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        shareUrl: shareUrl,
        title: title,
        description: description,
        showShareToHub: showShareToHub,
        onShareToHub: onShareToHub,
      ),
    );
  }
}
