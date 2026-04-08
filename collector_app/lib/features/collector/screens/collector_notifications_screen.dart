import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/reminder_service.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';

class CollectorNotificationsScreen extends StatelessWidget {
  const CollectorNotificationsScreen({super.key});

  String _relativeTime(DateTime date) {
    final now = DateTime.now().toUtc();
    final dateUtc = date.isUtc ? date : date.toUtc();
    final diff = now.difference(dateUtc);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final reminderService = context.watch<ReminderService>();
    final reminders = reminderService.reminders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: const BackButton(),
        actions: [
          TextButton(
            onPressed: reminderService.markAllAsRead,
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: GradientBackground(
        economyTheme: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 64,
                          color: AppTheme.textLight.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textLight,
                                  ),
                        ),
                      ],
                    ),
                  )
                : GlassmorphicContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Notifications',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: reminders.length,
                            itemBuilder: (context, index) {
                              final reminder = reminders[index];
                              final dynamic id = reminder['id'] ?? index;
                              final dynamic rawCreatedAt =
                                  reminder['createdAt'];
                              final DateTime createdAt =
                                  rawCreatedAt is DateTime
                                      ? rawCreatedAt
                                      : DateTime.now();
                              final String type =
                                  reminder['type']?.toString() ?? 'info';
                              final bool isRead = reminder['read'] == true;

                              return _NotificationCard(
                                title: reminder['title']?.toString() ??
                                    'Notification',
                                message: reminder['message']?.toString() ??
                                    'No message',
                                time: _relativeTime(createdAt),
                                type: type,
                                isRead: isRead,
                                onTap: () {
                                  reminderService.markAsRead(id.toString());
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final String type;
  final bool isRead;
  final VoidCallback? onTap;

  const _NotificationCard({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    IconData typeIcon;

    switch (type) {
      case 'success':
        typeColor = AppTheme.lightGreen;
        typeIcon = Icons.check_circle;
        break;
      case 'warning':
        typeColor = AppTheme.accentOrange;
        typeIcon = Icons.warning;
        break;
      case 'tip':
        typeColor = AppTheme.primaryGreen;
        typeIcon = Icons.lightbulb;
        break;
      case 'reminder':
        typeColor = AppTheme.primary;
        typeIcon = Icons.schedule;
        break;
      case 'alert':
        typeColor = AppTheme.accentOrange;
        typeIcon = Icons.notification_important;
        break;
      case 'announcement':
        typeColor = AppTheme.primaryGreen;
        typeIcon = Icons.campaign_rounded;
        break;
      default:
        typeColor = AppTheme.primaryGreen;
        typeIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? Colors.grey.withValues(alpha: 0.3)
              : typeColor.withValues(alpha: 0.5),
          width: isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isRead
                ? Colors.grey.withValues(alpha: 0.1)
                : typeColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
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
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        time,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                              fontSize: 10,
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
    );
  }
}
