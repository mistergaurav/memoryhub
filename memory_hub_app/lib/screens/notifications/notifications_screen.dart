import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/notifications_provider.dart';
import '../../models/notification.dart' as models;
import '../../widgets/gradient_container.dart';
import '../../widgets/animated_list_item.dart';
import '../../services/websocket_service.dart';
import '../../design_system/design_system.dart';
import '../../design_system/layout/padded.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      final provider = Provider.of<NotificationsProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading) {
        provider.loadMore();
      }
    }
  }

  Future<void> _onRefresh() async {
    final provider = Provider.of<NotificationsProvider>(context, listen: false);
    await provider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationsProvider(),
      child: Consumer<NotificationsProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(provider),
                if (provider.isLoading && provider.notifications.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.notifications.isEmpty)
                  _buildEmptyState()
                else
                  _buildNotificationsList(provider),
                if (provider.isLoading && provider.notifications.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padded(
                      padding: Spacing.edgeInsetsAll(Spacing.lg),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(NotificationsProvider provider) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: GradientContainer(
          height: 180,
          colors: [
            MemoryHubColors.indigo600,
            MemoryHubColors.purple600,
            MemoryHubColors.pink500,
          ],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Icon(
                      Icons.notifications,
                      size: 70,
                      color: MemoryHubColors.white.withValues(alpha: 0.9),
                    ),
                    if (provider.unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Padded(
                          padding: Spacing.edgeInsetsAll(Spacing.xs + 2),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: MemoryHubColors.red600,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              provider.unreadCount > 99 ? '99+' : '${provider.unreadCount}',
                              style: context.text.labelSmall?.copyWith(
                                color: MemoryHubColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (provider.unreadCount > 0) ...[
                  VGap.sm(),
                  Padded(
                    padding: Spacing.edgeInsetsSymmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.xs + 2,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: MemoryHubColors.white.withValues(alpha: 0.3),
                        borderRadius: MemoryHubBorderRadius.fullRadius,
                      ),
                      child: Text(
                        '${provider.unreadCount} New',
                        style: context.text.titleSmall?.copyWith(
                          color: MemoryHubColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                VGap(MemoryHubSpacing.sm),
                _buildConnectionStatus(provider),
              ],
            ),
          ),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontWeight: MemoryHubTypography.bold,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        if (provider.unreadCount > 0)
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            onPressed: () async {
              try {
                await provider.markAllAsRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'All notifications marked as read',
                        style: GoogleFonts.inter(),
                      ),
                      backgroundColor: MemoryHubColors.green600,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e', style: GoogleFonts.inter()),
                      backgroundColor: MemoryHubColors.red600,
                    ),
                  );
                }
              }
            },
            tooltip: 'Mark all as read',
          ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _onRefresh,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(NotificationsProvider provider) {
    final isConnected = provider.wsConnectionState == WebSocketConnectionState.connected;
    final isConnecting = provider.wsConnectionState == WebSocketConnectionState.connecting;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MemoryHubSpacing.md,
        vertical: MemoryHubSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: MemoryHubBorderRadius.mdRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? MemoryHubColors.green500 : (isConnecting ? MemoryHubColors.orange500 : MemoryHubColors.red500),
              shape: BoxShape.circle,
            ),
          ),
          HGap(MemoryHubSpacing.xs + 2),
          Text(
            isConnected ? 'Live' : (isConnecting ? 'Connecting' : 'Offline'),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: MemoryHubTypography.medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: MemoryHubColors.gray300,
            ),
            VGap(MemoryHubSpacing.lg),
            Text(
              'No notifications yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: MemoryHubColors.gray600,
              ),
            ),
            VGap(MemoryHubSpacing.sm),
            Text(
              'We\'ll notify you when something happens',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: MemoryHubColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(NotificationsProvider provider) {
    return SliverPadding(
      padding: EdgeInsets.all(MemoryHubSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final notification = provider.notifications[index];
            return AnimatedListItem(
              index: index,
              child: _buildNotificationCard(notification, provider),
            );
          },
          childCount: provider.notifications.length,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(models.Notification notification, NotificationsProvider provider) {
    final isRead = notification.isRead;
    final timeAgo = _getTimeAgo(notification.createdAt);

    return Card(
      elevation: isRead ? 0 : 2,
      margin: EdgeInsets.only(bottom: MemoryHubSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: MemoryHubBorderRadius.lgRadius,
        side: BorderSide(
          color: isRead ? MemoryHubColors.gray200 : MemoryHubColors.blue100,
          width: isRead ? 1 : 2,
        ),
      ),
      color: isRead ? Colors.white : MemoryHubColors.blue50,
      child: InkWell(
        onTap: () async {
          if (!isRead) {
            await provider.markAsRead(notification.id);
          }

          if (notification.type == models.NotificationType.healthRecordAssignment) {
            if (mounted) {
              final result = await Navigator.pushNamed(
                context,
                '/notifications/detail',
                arguments: notification.id,
              );

              if (result == true && mounted) {
                await provider.refresh();
              }
            }
          }
        },
        borderRadius: MemoryHubBorderRadius.lgRadius,
        child: Padding(
          padding: EdgeInsets.all(MemoryHubSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(MemoryHubSpacing.md),
                decoration: BoxDecoration(
                  color: _getColorForType(notification.type).withOpacity(0.2),
                  borderRadius: MemoryHubBorderRadius.mdRadius,
                ),
                child: Icon(
                  _getIconForType(notification.type),
                  color: _getColorForType(notification.type),
                  size: 24,
                ),
              ),
              HGap(MemoryHubSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: isRead ? MemoryHubTypography.medium : MemoryHubTypography.bold,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: MemoryHubColors.blue600,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    VGap(MemoryHubSpacing.xs + 2),
                    Text(
                      notification.message,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: MemoryHubColors.gray700,
                        height: 1.4,
                      ),
                    ),
                    VGap(MemoryHubSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: MemoryHubColors.gray500),
                        HGap(MemoryHubSpacing.xs),
                        Text(
                          timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: MemoryHubColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    if (notification.type == models.NotificationType.healthRecordAssignment) ...[
                      VGap(MemoryHubSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              label: 'View ${notification.title} details',
                              button: true,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.visibility, size: 16),
                                label: Text('View Details', style: GoogleFonts.inter(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: MemoryHubColors.blue600,
                                  padding: EdgeInsets.symmetric(vertical: MemoryHubSpacing.sm),
                                ),
                                onPressed: () async {
                                  if (!isRead) {
                                    await provider.markAsRead(notification.id);
                                  }

                                  if (mounted) {
                                    final result = await Navigator.pushNamed(
                                      context,
                                      '/notifications/detail',
                                      arguments: notification.id,
                                    );

                                    if (result == true && mounted) {
                                      await provider.refresh();
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIconForType(models.NotificationType type) {
    switch (type) {
      case models.NotificationType.like:
        return Icons.favorite;
      case models.NotificationType.comment:
        return Icons.comment;
      case models.NotificationType.follow:
        return Icons.person_add;
      case models.NotificationType.mention:
        return Icons.alternate_email;
      case models.NotificationType.memoryShare:
        return Icons.share;
      case models.NotificationType.hubInvite:
        return Icons.group_add;
      case models.NotificationType.healthRecordAssignment:
      case models.NotificationType.healthReminderAssignment:
        return Icons.medical_services;
      case models.NotificationType.healthRecordApproved:
        return Icons.check_circle;
      case models.NotificationType.healthRecordRejected:
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(models.NotificationType type) {
    switch (type) {
      case models.NotificationType.like:
        return MemoryHubColors.red600;
      case models.NotificationType.comment:
        return MemoryHubColors.blue600;
      case models.NotificationType.healthRecordAssignment:
      case models.NotificationType.healthReminderAssignment:
        return MemoryHubColors.teal600;
      case models.NotificationType.healthRecordApproved:
        return MemoryHubColors.green600;
      case models.NotificationType.healthRecordRejected:
        return MemoryHubColors.red600;
      case models.NotificationType.follow:
        return MemoryHubColors.green600;
      case models.NotificationType.mention:
        return MemoryHubColors.purple600;
      case models.NotificationType.memoryShare:
        return MemoryHubColors.orange500;
      case models.NotificationType.hubInvite:
        return MemoryHubColors.indigo600;
      default:
        return MemoryHubColors.gray500;
    }
  }
}
