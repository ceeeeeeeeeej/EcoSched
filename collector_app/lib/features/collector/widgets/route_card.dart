import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class RouteCard extends StatelessWidget {
  final String routeName;
  final int stops;
  final String estimatedTime;
  final String status;
  final bool isRescheduled;
  final bool isSpecial;
  final DateTime? originalDate;
  final String? rescheduledReason;
  final String? barangay;
  final String? residentName;
  final String? pickupLocation;
  final String? purok;
  final String? street;
  final String? residentBarangay;
  final String? residentAge;
  final String? wasteType;
  final String? estimatedQuantity;
  final String? specialInstructions;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;

  const RouteCard({
    super.key,
    required this.routeName,
    required this.stops,
    required this.estimatedTime,
    required this.status,
    this.isRescheduled = false,
    this.isSpecial = false,
    this.originalDate,
    this.rescheduledReason,
    this.barangay,
    this.residentName,
    this.pickupLocation,
    this.purok,
    this.street,
    this.residentBarangay,
    this.residentAge,
    this.wasteType,
    this.estimatedQuantity,
    this.specialInstructions,
    this.onTap,
    this.onAction,
    this.actionLabel,
    this.actionIcon,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'on_the_way':
      case 'in progress':
        statusColor = AppTheme.primary;
        statusIcon = Icons.local_shipping_rounded;
        break;
      default:
        statusColor = AppTheme.accentOrange;
        statusIcon = Icons.schedule_rounded;
    }

    if (isRescheduled) {
      statusColor = AppTheme.accentOrange;
      statusIcon = Icons.edit_calendar_rounded;
    }

    return Tooltip(
      message: barangay != null && barangay!.isNotEmpty
          ? '📍 Barangay: ${_toTitleCase(barangay!)}'
          : routeName,
      preferBelow: true,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: responsive.spacing(16)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(20)),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.backgroundSecondary
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(
                  color: statusColor.withOpacity(isDark ? 0.35 : 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
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
                                    routeName,
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
                                      color: AppTheme.accentOrange
                                          .withOpacity(0.1),
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
                                  : estimatedTime,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isRescheduled
                                    ? AppTheme.accentOrange
                                    : AppTheme.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (barangay != null && barangay!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 12,
                                    color: AppTheme.primary.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _toTitleCase(barangay!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      _buildStatusBadge(status, statusColor),
                    ],
                  ),
                                  // Special Collection Details Section
                  if (isSpecial &&
                      (residentName != null ||
                          pickupLocation != null ||
                          purok != null ||
                          street != null ||
                          residentBarangay != null ||
                          residentAge != null ||
                          wasteType != null ||
                          estimatedQuantity != null ||
                          specialInstructions != null)) ...[
                    SizedBox(height: responsive.spacing(16)),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.backgroundSecondary.withOpacity(0.5)
                            : AppTheme.backgroundSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        border: Border.all(
                          color: AppTheme.textLight
                              .withOpacity(isDark ? 0.2 : 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (residentName != null && residentName!.isNotEmpty)
                            _buildDetailRow(
                              Icons.person_rounded,
                              'Resident',
                              residentName!,
                              responsive,
                              theme,
                              isProminent: true,
                            ),
                          if (purok != null ||
                              street != null ||
                              residentBarangay != null) ...[
                            SizedBox(height: responsive.spacing(12)),
                            _buildDetailRow(
                              Icons.location_on_rounded,
                              'Address',
                              [
                                if (purok != null && purok!.isNotEmpty)
                                  'Prk. $purok',
                                if (street != null && street!.isNotEmpty)
                                  street,
                                if (residentBarangay != null &&
                                    residentBarangay!.isNotEmpty)
                                  residentBarangay,
                              ].join(', '),
                              responsive,
                              theme,
                            ),
                          ],
                          if (residentAge != null && residentAge!.isNotEmpty) ...[
                            SizedBox(height: responsive.spacing(12)),
                            _buildDetailRow(
                              Icons.cake_rounded,
                              'Age',
                              residentAge!,
                              responsive,
                              theme,
                            ),
                          ],
                          if (pickupLocation != null &&
                              pickupLocation!.isNotEmpty) ...[
                            SizedBox(height: responsive.spacing(12)),
                            _buildDetailRow(
                              Icons.place_rounded,
                              'Pickup Point',
                              pickupLocation!,
                              responsive,
                              theme,
                            ),
                          ],
                          if (wasteType != null && wasteType!.isNotEmpty) ...[
                            SizedBox(height: responsive.spacing(12)),
                            _buildDetailRow(
                              Icons.delete_outline_rounded,
                              'Waste Type',
                              wasteType!,
                              responsive,
                              theme,
                            ),
                          ],
                          if (estimatedQuantity != null &&
                              estimatedQuantity!.isNotEmpty) ...[
                            SizedBox(height: responsive.spacing(12)),
                            _buildDetailRow(
                              Icons.inventory_2_outlined,
                              'Quantity',
                              estimatedQuantity!,
                              responsive,
                              theme,
                            ),
                          ],
                          if (specialInstructions != null &&
                              specialInstructions!.isNotEmpty) ...[
                            SizedBox(height: responsive.spacing(12)),
                            _buildDetailRow(
                              Icons.message_outlined,
                              'Message / Instructions',
                              specialInstructions!,
                              responsive,
                              theme,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  if (isRescheduled &&
                      rescheduledReason != null &&
                      rescheduledReason!.isNotEmpty) ...[
                    SizedBox(height: responsive.spacing(12)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(responsive.spacing(10)),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary.withValues(alpha: 0.5),
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
                  if (actionLabel != null || onSecondaryAction != null) ...[
                    SizedBox(height: responsive.spacing(20)),
                    Row(
                      children: [
                        if (actionLabel != null)
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: onAction,
                              icon: Icon(actionIcon ?? Icons.play_arrow_rounded,
                                  size: 20),
                              label: Text(
                                actionLabel ?? 'Confirm Arrival',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: statusColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    vertical: responsive.spacing(14)),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusL),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        if (onAction != null && onSecondaryAction != null)
                          const SizedBox(width: 12),
                        if (onSecondaryAction != null)
                          Expanded(
                            flex: 1,
                            child: OutlinedButton.icon(
                              onPressed: onSecondaryAction,
                              icon: Icon(
                                  secondaryActionIcon ?? Icons.update_rounded,
                                  size: 18),
                              label: Text(
                                secondaryActionLabel ?? 'Reschedule',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textDark,
                                side: BorderSide(
                                    color: AppTheme.textDark.withValues(alpha: 0.1)),
                                padding: EdgeInsets.symmetric(
                                    vertical: responsive.spacing(14)),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusL),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
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

  String _toTitleCase(String text) {
    return text
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Responsive responsive,
    ThemeData theme, {
    bool isProminent = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: responsive.iconSize(16),
          color: isProminent ? AppTheme.primary : AppTheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10 * responsive.fontSizeMultiplier,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textLight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isProminent ? FontWeight.w900 : FontWeight.w600,
                  color: isProminent ? AppTheme.primary : AppTheme.textDark,
                  fontSize: (isProminent ? 16 : 13) * responsive.fontSizeMultiplier,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
