import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/reminder_service.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../widgets/notification_card.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
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
    final unreadCount = reminderService.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/house.gif',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Notifications'),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: reminderService.markAllAsRead,
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Summary Card

                // Notifications List
                Expanded(
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        
                        // --- QUICK DEBUG BUTTON REMOVED ---

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
                              return NotificationCard(
                                title: (reminder['title']?.toString() ??
                                    'Notification'),
                                message: (reminder['message']?.toString() ??
                                        'No message')
                                    .toString(),
                                time: _relativeTime(createdAt),
                                type: (reminder['type']?.toString() ?? 'info'),
                                isRead: reminder['read'] == true,
                                onTap: () {
                                  if (id != null) {
                                    reminderService.markAsRead(id.toString());
                                  }
                                  
                                  final typeStr = (reminder['type']?.toString() ?? 'info').toLowerCase();
                                  final titleStr = (reminder['title']?.toString() ?? '').toLowerCase();
                                  
                                  int targetNavIndex = 0; // Home by default
                                  
                                  if (typeStr == 'special_collection_status' || titleStr.contains('special collection')) {
                                    targetNavIndex = 3; // Special Collection Tab (Nav Index 3)
                                  } else if (typeStr == 'feedback_update' || titleStr.contains('feedback')) {
                                    targetNavIndex = 1; // Feedback Tab (Nav Index 1)
                                  }
                                  
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    AppRoutes.residentDashboard,
                                    (route) => false,
                                    arguments: {'initialNavIndex': targetNavIndex},
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textLight,
              ),
        ),
      ],
    );
  }
}
