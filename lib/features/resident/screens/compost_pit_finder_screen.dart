import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/animated_button.dart';
import '../../../widgets/animated_card.dart';

class CompostPitFinderScreen extends StatefulWidget {
  const CompostPitFinderScreen({super.key});

  @override
  State<CompostPitFinderScreen> createState() => _CompostPitFinderScreenState();
}

class _CompostPitFinderScreenState extends State<CompostPitFinderScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _selectedFilter = 'All';
  String _selectedSort = 'Distance';
  bool _showMap = false;

  final List<String> _filters = ['All', 'Nearby', 'Open Now', 'Free', 'Paid'];
  final List<String> _sortOptions = ['Distance', 'Rating', 'Name'];

  final List<Map<String, dynamic>> _compostPits = [
    {
      'id': 1,
      'name': 'Tago Municipal Compost Center',
      'address': 'Poblacion, Tago, Surigao del Sur',
      'distance': '0.5 km',
      'rating': 4.8,
      'isOpen': true,
      'isFree': true,
      'phone': '+63 912 345 6789',
      'hours': '6:00 AM - 6:00 PM',
      'description': 'Main municipal compost facility with modern equipment',
      'latitude': 9.032007,
      'longitude': 126.185203,
      'features': [
        'Organic waste only',
        'Educational tours',
        'Free consultation'
      ],
    },
    {
      'id': 2,
      'name': 'Victoria Barangay Compost Site',
      'address': 'Victoria Barangay, Tago, Surigao del Sur',
      'distance': '1.2 km',
      'rating': 4.5,
      'isOpen': true,
      'isFree': true,
      'phone': '+63 912 345 6790',
      'hours': '7:00 AM - 5:00 PM',
      'description': 'Community-run compost facility in Victoria',
      'latitude': 9.035000,
      'longitude': 126.188000,
      'features': [
        'Community garden',
        'Workshop sessions',
        'Organic fertilizer'
      ],
    },
    {
      'id': 3,
      'name': 'DAYO-AY Barangay Compost Center',
      'address': 'DAYO-AY Barangay, Tago, Surigao del Sur',
      'distance': '1.8 km',
      'rating': 4.4,
      'isOpen': true,
      'isFree': true,
      'phone': '+63 912 345 6794',
      'hours': '6:00 AM - 6:00 PM',
      'description':
          'Community compost facility serving DAYO-AY barangay residents',
      'latitude': 9.033000,
      'longitude': 126.187000,
      'features': [
        'Community composting',
        'Educational programs',
        'Free organic fertilizer'
      ],
    },
    {
      'id': 4,
      'name': 'Eco-Garden Compost Hub',
      'address': 'Sitio Malipayon, Tago, Surigao del Sur',
      'distance': '2.5 km',
      'rating': 4.6,
      'isOpen': false,
      'isFree': false,
      'phone': '+63 912 345 6791',
      'hours': '8:00 AM - 4:00 PM',
      'description': 'Private eco-garden with premium compost services',
      'latitude': 9.030000,
      'longitude': 126.182000,
      'features': ['Premium compost', 'Garden supplies', 'Expert consultation'],
      'price': '₱50 per bag',
    },
    {
      'id': 5,
      'name': 'Green Valley Compost Facility',
      'address': 'Barangay San Isidro, Tago, Surigao del Sur',
      'distance': '3.5 km',
      'rating': 4.3,
      'isOpen': true,
      'isFree': true,
      'phone': '+63 912 345 6792',
      'hours': '6:30 AM - 5:30 PM',
      'description': 'Large-scale compost facility serving multiple barangays',
      'latitude': 9.028000,
      'longitude': 126.175000,
      'features': ['Large capacity', 'Bulk processing', 'Educational programs'],
    },
    {
      'id': 6,
      'name': 'Riverside Compost Center',
      'address': 'Near Tago River, Tago, Surigao del Sur',
      'distance': '4.2 km',
      'rating': 4.4,
      'isOpen': true,
      'isFree': true,
      'phone': '+63 912 345 6793',
      'hours': '7:00 AM - 6:00 PM',
      'description': 'Riverside compost facility with scenic location',
      'latitude': 9.025000,
      'longitude': 126.190000,
      'features': ['Scenic location', 'Riverside access', 'Family-friendly'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredPits = _getFilteredPits();

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
            const Text('Nearest Compost Pits'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusM),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                'assets/images/house.gif',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Nearest Compost Pits',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Find the nearest compost facilities in Tago, Surigao del Sur',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textLight,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedFilter,
                          decoration: InputDecoration(
                            labelText: 'Filter',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                          ),
                          items: _filters.map((String filter) {
                            return DropdownMenuItem<String>(
                              value: filter,
                              child: Text(filter),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedFilter = newValue!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSort,
                          decoration: InputDecoration(
                            labelText: 'Sort by',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                          ),
                          items: _sortOptions.map((String sort) {
                            return DropdownMenuItem<String>(
                              value: sort,
                              child: Text(sort),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSort = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Content
                Expanded(
                  child:
                      _showMap ? _buildMapView() : _buildListView(filteredPits),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> pits) {
    return ListView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      itemCount: pits.length,
      itemBuilder: (context, index) {
        final pit = pits[index];
        return AnimatedCard(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.white.withOpacity(0.8),
          borderRadius: AppConstants.borderRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pit['name'],
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pit['address'],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textLight,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: AppTheme.accentOrange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pit['rating'].toString(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: pit['isOpen']
                              ? AppTheme.lightGreen.withOpacity(0.2)
                              : AppTheme.accentOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pit['isOpen'] ? 'Open' : 'Closed',
                          style: TextStyle(
                            color: pit['isOpen']
                                ? AppTheme.primaryGreen
                                : AppTheme.accentOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  _buildDetailChip(
                    Icons.location_on,
                    pit['distance'],
                    AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    Icons.access_time,
                    pit['hours'],
                    AppTheme.accentOrange,
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    pit['isFree'] ? Icons.free_breakfast : Icons.attach_money,
                    pit['isFree'] ? 'Free' : pit['price'] ?? 'Paid',
                    pit['isFree'] ? AppTheme.lightGreen : AppTheme.accentOrange,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                pit['description'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textLight,
                    ),
              ),
              const SizedBox(height: 12),

              // Features
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (pit['features'] as List<String>).map((feature) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      feature,
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AnimatedButton(
                      text: 'Get Directions',
                      onPressed: () => _openDirections(pit),
                      icon: Icons.directions,
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Stack(
          children: [
            // Placeholder for map
            Container(
              width: double.infinity,
              height: double.infinity,
              color: AppTheme.lightGreen.withOpacity(0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: AppTheme.primaryGreen.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Map View',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Interactive map showing compost pit locations',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textLight,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Map overlay with pins
            Positioned(
              top: 20,
              left: 20,
              child: _buildMapPin('Tago Municipal', true),
            ),
            Positioned(
              top: 80,
              right: 40,
              child: _buildMapPin('Victoria Barangay', true),
            ),
            Positioned(
              top: 120,
              left: 30,
              child: _buildMapPin('DAYO-AY Barangay', true),
            ),
            Positioned(
              bottom: 100,
              left: 60,
              child: _buildMapPin('Eco-Garden', false),
            ),
            Positioned(
              bottom: 60,
              right: 80,
              child: _buildMapPin('Green Valley', true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPin(String name, bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? AppTheme.primaryGreen : AppTheme.accentOrange,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredPits() {
    List<Map<String, dynamic>> filtered = List.from(_compostPits);

    // Apply filters
    switch (_selectedFilter) {
      case 'Nearby':
        filtered = filtered
            .where((pit) =>
                double.parse(pit['distance'].replaceAll(' km', '')) <= 2.0)
            .toList();
        break;
      case 'Open Now':
        filtered = filtered.where((pit) => pit['isOpen']).toList();
        break;
      case 'Free':
        filtered = filtered.where((pit) => pit['isFree']).toList();
        break;
      case 'Paid':
        filtered = filtered.where((pit) => !pit['isFree']).toList();
        break;
    }

    // Apply sorting
    switch (_selectedSort) {
      case 'Distance':
        filtered.sort((a, b) =>
            double.parse(a['distance'].replaceAll(' km', ''))
                .compareTo(double.parse(b['distance'].replaceAll(' km', ''))));
        break;
      case 'Rating':
        filtered.sort((a, b) => b['rating'].compareTo(a['rating']));
        break;
      case 'Name':
        filtered.sort((a, b) => a['name'].compareTo(b['name']));
        break;
    }

    return filtered;
  }

  Future<void> _openDirections(Map<String, dynamic> pit) async {
    final double latitude = pit['latitude'];
    final double longitude = pit['longitude'];

    // Try to open Google Maps app first
    final googleMapsUri = Uri.parse(
      'comgooglemaps://?daddr=$latitude,$longitude&directionsmode=driving',
    );

    // Fallback: open Google Maps in browser / external app
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );

    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open directions')),
        );
      }
    }
  }

  Future<void> _makeCall(String phone) async {
    final url = 'tel:$phone';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make call')),
        );
      }
    }
  }
}
