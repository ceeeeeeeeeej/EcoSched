import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class ScheduleCard extends StatelessWidget {
  final String date;
  final String time;
  final String type;
  final String status;
  final VoidCallback? onTap;

  const ScheduleCard({
    super.key,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = AppTheme.lightGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'confirmed':
        statusColor = AppTheme.primaryGreen;
        statusIcon = Icons.verified;
        break;
      case 'scheduled':
        statusColor = AppTheme.accentOrange;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = AppTheme.textLight;
        statusIcon = Icons.radio_button_unchecked;
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
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildScheduleInfo(
                        'Date',
                        date,
                        Icons.calendar_today,
                        AppTheme.primaryGreen,
                      ),
                    ),
                    Expanded(
                      child: _buildScheduleInfo(
                        'Time',
                        time,
                        Icons.access_time,
                        AppTheme.accentOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleInfo(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
