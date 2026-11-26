import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/pickup.dart';
import '../features/requests/data/recircle_api.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/recircle_branding.dart';
import 'pickup_tracking_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    widget.appState.refreshNotifications().catchError((_) {});
  }

  Future<void> _markAllRead() async {
    try {
      await widget.appState.markAllNotificationsRead();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (!notification.isRead) {
      try {
        await widget.appState.markNotificationRead(notification.id);
      } on ApiException catch (error) {
        if (mounted) _showError(error.message);
      }
    }
    final pickupId = notification.relatedPickupId;
    if (!mounted || pickupId == null || pickupId.isEmpty) return;

    Pickup? pickup;
    try {
      if (widget.appState.isPartner) {
        final eligible = await widget.appState.eligibleRequests();
        for (final candidate in eligible) {
          if (candidate.id == pickupId) pickup = candidate;
        }
      }
      pickup ??= await widget.appState.refreshRequest(pickupId);
    } on ApiException catch (error) {
      if (!mounted) return;
      for (final candidate in widget.appState.pickups) {
        if (candidate.id == pickupId) pickup = candidate;
      }
      if (pickup == null) {
        _showError(error.message);
        return;
      }
    }
    if (!mounted || pickup == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            PickupTrackingScreen(pickup: pickup!, appState: widget.appState),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final state = widget.appState;
        final notifications = state.notifications;
        return Scaffold(
          appBar: AppBar(
            title: const ReCircleBrandTitle('Notifications'),
            actions: [
              TextButton(
                onPressed: state.unreadNotificationCount == 0
                    ? null
                    : _markAllRead,
                child: const Text('Mark all read'),
              ),
            ],
          ),
          body: _buildBody(state, notifications),
        );
      },
    );
  }

  Widget _buildBody(AppState state, List<AppNotification> notifications) {
    if (state.loadingNotifications && notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.notificationError != null && notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40),
              const SizedBox(height: 12),
              Text(state.notificationError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    state.refreshNotifications().catchError((_) {}),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: state.refreshNotifications,
      child: notifications.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 160),
                Icon(
                  Icons.notifications_none_rounded,
                  size: 52,
                  color: AppTheme.subtitleGrey,
                ),
                SizedBox(height: 14),
                Center(
                  child: Text(
                    'You’re all caught up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
                SizedBox(height: 6),
                Center(
                  child: Text(
                    'Pickup updates will appear here.',
                    style: TextStyle(color: AppTheme.subtitleGrey),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) => _NotificationTile(
                notification: notifications[index],
                onTap: () => _openNotification(notifications[index]),
              ),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead ? Colors.white : AppTheme.accentLightGreen,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: notification.isRead
                    ? const Color(0xFFF0F2F0)
                    : Colors.white,
                foregroundColor: AppTheme.primaryGreen,
                child: Icon(_iconFor(notification.type)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              color: AppTheme.darkText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.subtitleGrey,
                        height: 1.35,
                      ),
                    ),
                    if (notification.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(notification.createdAt!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.subtitleGrey,
                        ),
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

  IconData _iconFor(String type) => switch (type) {
    'pickup_available' ||
    'pickup_assigned' ||
    'pickup_released' => Icons.local_shipping_outlined,
    'pickup_collected' => Icons.inventory_2_outlined,
    'pickup_processing' => Icons.recycling_outlined,
    'pickup_completed' => Icons.check_circle_outline,
    'pickup_cancelled' => Icons.event_busy_outlined,
    _ => Icons.notifications_none_rounded,
  };

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24 && now.day == local.day) {
      return '${difference.inHours}h ago';
    }
    final time =
        '${(local.hour % 12 == 0 ? 12 : local.hour % 12)}:'
        '${local.minute.toString().padLeft(2, '0')} '
        '${local.hour >= 12 ? 'PM' : 'AM'}';
    if (now.year == local.year &&
        now.month == local.month &&
        now.day == local.day) {
      return 'Today · $time';
    }
    if (now.difference(DateTime(now.year, now.month, now.day)).inDays == 0 &&
        DateTime(
              now.year,
              now.month,
              now.day,
            ).difference(DateTime(local.year, local.month, local.day)).inDays ==
            1) {
      return 'Yesterday · $time';
    }
    return '${local.day}/${local.month}/${local.year} · $time';
  }
}
