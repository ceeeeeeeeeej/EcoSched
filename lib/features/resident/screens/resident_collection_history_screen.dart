import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/animated_card.dart';

class ResidentCollectionHistoryScreen extends StatefulWidget {
  const ResidentCollectionHistoryScreen({super.key});

  @override
  State<ResidentCollectionHistoryScreen> createState() =>
      _ResidentCollectionHistoryScreenState();
}

class _ResidentCollectionHistoryScreenState
    extends State<ResidentCollectionHistoryScreen> {
  final List<Map<String, dynamic>> _historyData = [
    {
      'date': '2024-01-15',
      'type': 'Biodegradable',
      'status': 'Collected',
      'schedule': '08:00 AM',
      'volume': '2 bags',
    },
    {
      'date': '2024-01-12',
      'type': 'Non-biodegradable',
      'status': 'Collected',
      'schedule': '09:30 AM',
      'volume': '1 bag',
    },
    {
      'date': '2024-01-08',
      'type': 'Recyclable',
      'status': 'Missed',
      'schedule': '08:15 AM',
      'volume': '1 bag',
    },
    {
      'date': '2024-01-03',
      'type': 'Biodegradable',
      'status': 'Collected',
      'schedule': '07:45 AM',
      'volume': '3 bags',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.textInverse,
      ),
      body: GradientBackground(
        economyTheme: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                GlassmorphicContainer(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "This Month's Overview",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'Total Pickups',
                              '8',
                              Icons.delete_outline,
                              AppTheme.getEconomicColor('efficiency'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'On-time',
                              '6',
                              Icons.check_circle,
                              AppTheme.getEconomicColor('savings'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'Missed',
                              '2',
                              Icons.error_outline,
                              AppTheme.getEconomicColor('cost'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'Next Pickup',
                              'Tomorrow',
                              Icons.event,
                              AppTheme.getEconomicColor('value'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Collections',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _historyData.length,
                            itemBuilder: (context, index) {
                              final history = _historyData[index];
                              return _buildHistoryCard(context, history);
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

  Widget _buildSummaryCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Use themed card color so it adapts in dark mode
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> history) {
    final String date = history['date'] as String;
    final String type = history['type'] as String;
    final String status = history['status'] as String;
    final String schedule = history['schedule'] as String;
    final String volume = history['volume'] as String;

    final bool isCollected = status.toLowerCase() == 'collected';
    final bool isMissed = status.toLowerCase() == 'missed';
    final Color typeColor = AppTheme.getWasteTypeColor(type);
    final IconData typeIcon = AppTheme.getWasteTypeIcon(type);
    final Color statusColor = isCollected
        ? AppTheme.successGreen
        : isMissed
            ? AppTheme.errorRed
            : AppTheme.getWasteStatusColor(status);

    final textTheme = Theme.of(context).textTheme;

    return AnimatedCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      // Use themed card color so it adapts in dark mode
      backgroundColor: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCollected ? Icons.check_circle : Icons.error_outline,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: AppTheme.textLight,
              ),
              const SizedBox(width: 4),
              Text(
                date,
                style: textTheme.bodySmall?.copyWith(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 16, color: AppTheme.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      schedule,
                      style: textTheme.bodyMedium?.copyWith(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2,
                        size: 16, color: AppTheme.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      volume,
                      style: textTheme.bodyMedium?.copyWith(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
