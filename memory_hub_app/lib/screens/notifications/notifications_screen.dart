import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/notifications_provider.dart';
import '../../models/notification.dart' as models;
import '../../widgets/gradient_container.dart';
import '../../widgets/animated_list_item.dart';
import '../../services/websocket_service.dart';

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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationsProvider>(context, listen: false);
      if (provider.notifications.isEmpty) {
        provider.loadNotifications();
      }
    });
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
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
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
            Colors.indigo,
            Colors.purple,
            Colors.pink,
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
                      color: Colors.white.withOpacity(0.9),
                    ),
                    if (provider.unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            provider.unreadCount > 99 ? '99+' : '${provider.unreadCount}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (provider.unreadCount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${provider.unreadCount} New',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _buildConnectionStatus(provider),
              ],
            ),
          ),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
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
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e', style: GoogleFonts.inter()),
                      backgroundColor: Colors.red,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : (isConnecting ? Colors.orange : Colors.red),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Live' : (isConnecting ? 'Connecting' : 'Offline'),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll notify you when something happens',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(NotificationsProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRead ? Colors.grey[200]! : Colors.blue[100]!,
          width: isRead ? 1 : 2,
        ),
      ),
      color: isRead ? Colors.white : Colors.blue[50],
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getColorForType(notification.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForType(notification.type),
                  color: _getColorForType(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
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
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    if (notification.type == models.NotificationType.healthRecordAssignment) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.visibility, size: 16),
                              label: Text('View Details', style: GoogleFonts.inter(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 8),
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
        return Colors.red;
      case models.NotificationType.comment:
        return Colors.blue;
      case models.NotificationType.healthRecordAssignment:
      case models.NotificationType.healthReminderAssignment:
        return Colors.teal;
      case models.NotificationType.healthRecordApproved:
        return Colors.green;
      case models.NotificationType.healthRecordRejected:
        return Colors.red;
      case models.NotificationType.follow:
        return Colors.green;
      case models.NotificationType.mention:
        return Colors.purple;
      case models.NotificationType.memoryShare:
        return Colors.orange;
      case models.NotificationType.hubInvite:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
