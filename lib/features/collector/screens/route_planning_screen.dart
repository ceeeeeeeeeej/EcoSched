import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/animated_button.dart';
import '../../../core/services/pickup_service.dart';

class RoutePlanningScreen extends StatefulWidget {
  const RoutePlanningScreen({super.key});

  @override
  State<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends State<RoutePlanningScreen> {
  bool _isRouteStarted = false;
  int _currentStop = 0;

  @override
  Widget build(BuildContext context) {
    final pickupService = Provider.of<PickupService>(context);
    final stops = pickupService.scheduledPickups;
    final totalStops = stops.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Planning'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Route Status Card
                GlassmorphicContainer(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Downtown District',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
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
                              color: _isRouteStarted
                                  ? AppTheme.lightGreen
                                  : AppTheme.accentOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isRouteStarted ? 'In Progress' : 'Ready',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Stops',
                              '$totalStops',
                              Icons.location_on,
                              AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Completed',
                              '$_currentStop',
                              Icons.check_circle,
                              AppTheme.lightGreen,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Estimated Time',
                              '2h 30m',
                              Icons.timer,
                              AppTheme.accentOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stops List
                Expanded(
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Collection Stops',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: stops.length,
                            itemBuilder: (context, index) {
                              final stop = stops[index];
                              return _buildStopCard(
                                stop,
                                index,
                                totalStops,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Button
                AnimatedButton(
                  text: _isRouteStarted ? 'Complete Stop' : 'Start Route',
                  onPressed: () {
                    setState(() {
                      if (totalStops == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No scheduled pickups available'),
                          ),
                        );
                        return;
                      }

                      if (!_isRouteStarted) {
                        _isRouteStarted = true;
                        _currentStop = 0;
                      } else {
                        if (_currentStop < totalStops - 1) {
                          _currentStop++;
                        } else {
                          _isRouteStarted = false;
                          _currentStop = 0;
                          // Show completion dialog
                          _showCompletionDialog();
                        }
                      }
                    });
                  },
                  width: double.infinity,
                  icon: _isRouteStarted ? Icons.check : Icons.play_arrow,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
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

  Widget _buildStopCard(Map<String, dynamic> stop, int index, int totalStops) {
    Color statusColor;
    IconData statusIcon;

    String status;
    if (!_isRouteStarted) {
      status = 'pending';
    } else if (index < _currentStop) {
      status = 'completed';
    } else if (index == _currentStop) {
      status = 'current';
    } else {
      status = 'pending';
    }

    switch (status) {
      case 'completed':
        statusColor = AppTheme.lightGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'current':
        statusColor = AppTheme.primaryGreen;
        statusIcon = Icons.radio_button_checked;
        break;
      default:
        statusColor = AppTheme.textLight;
        statusIcon = Icons.radio_button_unchecked;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop['address'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stop['type']} • ${stop['time']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stop['time'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _openInGoogleMaps(stop['address'] as String),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(
                  Icons.map_outlined,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
                label: const Text(
                  'Navigate',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openInGoogleMaps(String address) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route Completed!'),
        content: const Text(
          'Great job! You\'ve completed all stops for this route.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
