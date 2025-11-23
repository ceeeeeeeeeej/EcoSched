import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final String type;
  final bool isRead;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
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
      default:
        typeColor = AppTheme.primaryGreen;
        typeIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRead 
                  ? Colors.white.withOpacity(0.7)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(
                color: isRead 
                    ? Colors.grey.withOpacity(0.3)
                    : typeColor.withOpacity(0.5),
                width: isRead ? 1 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isRead 
                      ? Colors.grey.withOpacity(0.1)
                      : typeColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
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
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
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
