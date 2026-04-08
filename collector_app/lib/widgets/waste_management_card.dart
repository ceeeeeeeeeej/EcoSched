import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class WasteManagementCard extends StatelessWidget {
  final String wasteType;
  final String title;
  final String subtitle;
  final double? amount;
  final String? unit;
  final String? status;
  final VoidCallback? onTap;
  final bool showIcon;
  final bool showGradient;

  const WasteManagementCard({
    super.key,
    required this.wasteType,        
    required this.title,
    required this.subtitle,
    this.amount,
    this.unit,
    this.status,
    this.onTap,
    this.showIcon = true,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: showGradient
            ? AppTheme.getWasteTypeDecoration(wasteType, isGradient: true)
            : BoxDecoration(
                color: AppTheme.getWasteTypeColor(wasteType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(
                  color: AppTheme.getWasteTypeColor(wasteType).withOpacity(0.3),
                  width: 1,
                ),
              ),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing8), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showIcon) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        AppTheme.getWasteTypeIcon(wasteType),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getWasteStatusColor(status!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              if (amount != null) ...[
                const SizedBox(height: AppTheme.spacing4),
                Row(
                  children: [
                    Text(
                      amount!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EconomicMetricCard extends StatelessWidget {
  final String economicType;
  final String title;
  final String subtitle;
  final double? value;
  final String? currency;
  final String? status;
  final VoidCallback? onTap;
  final bool showIcon;
  final bool showGradient;

  const EconomicMetricCard({
    super.key,
    required this.economicType,
    required this.title,
    required this.subtitle,
    this.value,
    this.currency,
    this.status,
    this.onTap,
    this.showIcon = true,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: showGradient
            ? AppTheme.getEconomicDecoration(economicType, isGradient: true)
            : BoxDecoration(
                color: AppTheme.getEconomicColor(economicType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(
                  color: AppTheme.getEconomicColor(economicType).withOpacity(0.3),
                  width: 1,
                ),
              ),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing8), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showIcon) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        AppTheme.getEconomicIcon(economicType),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getEconomicStatusColor(status!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              if (value != null) ...[
                const SizedBox(height: AppTheme.spacing4),
                Row(
                  children: [
                    Text(
                      value!.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (currency != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        currency!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WasteTypeChip extends StatelessWidget {
  final String wasteType;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showIcon;

  const WasteTypeChip({
    super.key,
    required this.wasteType,
    this.isSelected = false,
    this.onTap,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing4,
          vertical: AppTheme.spacing2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.getWasteTypeColor(wasteType)
              : AppTheme.getWasteTypeColor(wasteType).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: AppTheme.getWasteTypeColor(wasteType),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                AppTheme.getWasteTypeIcon(wasteType),
                color: isSelected
                    ? Colors.white
                    : AppTheme.getWasteTypeColor(wasteType),
                size: 16,
              ),
              const SizedBox(width: AppTheme.spacing2),
            ],
            Text(
              wasteType.toUpperCase(),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppTheme.getWasteTypeColor(wasteType),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EconomicMetricChip extends StatelessWidget {
  final String economicType;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showIcon;

  const EconomicMetricChip({
    super.key,
    required this.economicType,
    this.isSelected = false,
    this.onTap,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing4,
          vertical: AppTheme.spacing2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.getEconomicColor(economicType)
              : AppTheme.getEconomicColor(economicType).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),   
          border: Border.all(
            color: AppTheme.getEconomicColor(economicType),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                AppTheme.getEconomicIcon(economicType),
                color: isSelected
                    ? Colors.white
                    : AppTheme.getEconomicColor(economicType),
                size: 16,
              ),
              const SizedBox(width: AppTheme.spacing2),
            ],
            Text(
              economicType.toUpperCase(),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppTheme.getEconomicColor(economicType),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
