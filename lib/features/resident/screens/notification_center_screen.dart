import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
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
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Collection Completed',
      'message': 'Your waste was collected successfully at 9:15 AM',
      'time': '2 hours ago',
      'type': 'success',
      'read': false,
    },
    {
      'title': 'New Compost Pit Available',
      'message':
          'Victoria Barangay Compost Site is now open with extended hours',
      'time': '4 hours ago',
      'type': 'info',
      'read': false,
    },
    {
      'title': 'Feedback Response',
      'message':
          'Thank you for your feedback! We have implemented your suggestion about collection timing.',
      'time': '1 day ago',
      'type': 'success',
      'read': true,
    },
    {
      'title': 'Schedule Reminder',
      'message': 'Your next pickup is tomorrow at 9:00 AM',
      'time': '1 day ago',
      'type': 'info',
      'read': true,
    },
    {
      'title': 'Compost Workshop',
      'message':
          'Free composting workshop at Tago Municipal Compost Center this Saturday',
      'time': '2 days ago',
      'type': 'tip',
      'read': true,
    },
    {
      'title': 'Route Optimization',
      'message':
          'Your collection route has been optimized. New pickup time: 8:30 AM',
      'time': '2 days ago',
      'type': 'info',
      'read': true,
    },
    {
      'title': 'Recycling Tips',
      'message': 'Remember to separate your recyclables for better efficiency',
      'time': '3 days ago',
      'type': 'tip',
      'read': true,
    },
    {
      'title': 'Collection Delayed',
      'message': 'Your pickup has been delayed by 30 minutes due to traffic',
      'time': '1 week ago',
      'type': 'warning',
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['read']).length;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
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
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              return NotificationCard(
                                title: notification['title'],
                                message: notification['message'],
                                time: notification['time'],
                                type: notification['type'],
                                isRead: notification['read'],
                                onTap: () => _markAsRead(index),
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

  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['read'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
  }
}
