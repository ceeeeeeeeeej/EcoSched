import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/utils/responsive.dart';
import '../../../widgets/glassmorphic_container.dart';

class ScheduleCard extends StatelessWidget {
  final String date;
  final String time;
  final String type;
  final String status;
  final bool isRescheduled;
  final DateTime? originalDate;
  final String? rescheduledReason;
  final VoidCallback? onTap;

  const ScheduleCard({
    super.key,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
    this.isRescheduled = false,
    this.originalDate,
    this.rescheduledReason,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark;

    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'confirmed':
        statusColor = AppTheme.primary;
        statusIcon = Icons.verified_rounded;
        break;
      case 'scheduled':
        statusColor = AppTheme.accentOrange;
        statusIcon = Icons.schedule_rounded;
        break;
      default:
        statusColor = AppTheme.textLight;
        statusIcon = Icons.radio_button_unchecked_rounded;
    }

    if (isRescheduled) {
      statusColor = AppTheme.accentOrange; // Or a specific warning color
      statusIcon = Icons.edit_calendar_rounded;
    }

    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacing(16)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          child: GlassmorphicContainer(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(20)),
            borderRadius: AppTheme.radiusXL,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: responsive.iconSize(20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  type,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textDark,
                                    fontSize: (theme.textTheme.titleMedium
                                                ?.fontSize ??
                                            16) *
                                        responsive.fontSizeMultiplier,
                                  ),
                                ),
                              ),
                              if (isRescheduled)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.accentOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: AppTheme.accentOrange
                                            .withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    'RESCHEDULED',
                                    style: TextStyle(
                                      fontSize:
                                          10 * responsive.fontSizeMultiplier,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentOrange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isRescheduled
                                ? 'Rescheduled from ${_formatOriginalDate(originalDate)}'
                                : 'Status: $status',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isRescheduled
                                  ? AppTheme.accentOrange
                                  : AppTheme.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(20)),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        context,
                        Icons.calendar_today_rounded,
                        date,
                        AppTheme.primary,
                        responsive,
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: AppTheme.textLight.withOpacity(0.1),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        context,
                        Icons.access_time_rounded,
                        time,
                        AppTheme.accentOrange,
                        responsive,
                      ),
                    ),
                  ],
                ),
                if (isRescheduled &&
                    rescheduledReason != null &&
                    rescheduledReason!.isNotEmpty) ...[
                  SizedBox(height: responsive.spacing(12)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(responsive.spacing(10)),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundSecondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: responsive.iconSize(14),
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rescheduledReason!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatOriginalDate(DateTime? date) {
    if (date == null) return 'original date';
    return DateFormat('MMM d').format(date);
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String value,
      Color color, Responsive responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon,
            color: color.withOpacity(0.7), size: responsive.iconSize(16)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
