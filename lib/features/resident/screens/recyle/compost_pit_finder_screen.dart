// import 'package:ecosched/core/providers/app_state_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:provider/provider.dart';
// import '../../../core/theme/app_theme.dart';
// import '../../../core/constants/app_constants.dart';
// import '../../../widgets/gradient_background.dart';

// class CompostPitFinderScreen extends StatefulWidget {
//   const CompostPitFinderScreen({super.key});

//   @override
//   State<CompostPitFinderScreen> createState() => _CompostPitFinderScreenState();
// }

// class _CompostPitFinderScreenState extends State<CompostPitFinderScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _fadeController;
//   late Animation<double> _fadeAnimation;

//   bool _isSatelliteView = false;

//   final List<Map<String, dynamic>> _compostPits = [
// //     {
// //       'id': 1,
// //       'name': 'Tago Municipal Compost Center',
// //       'address': 'Poblacion, Tago, Surigao del Sur',
// //       'distance': '0.5 km',
// //       'rating': 4.8,
// //       'isOpen': true,
// //       'isFree': true,
// //       'phone': '+63 912 345 6789',
// //       'hours': '6:00 AM - 6:00 PM',
// //       'description': 'Main municipal compost facility with modern equipment',
// //       'latitude': 9.032007,
// //       'longitude': 126.185203,
// //       'features': [
// //         'Organic waste only',
// //         'Educational tours',
// //         'Free consultation'
// //       ],
// //     },
// //     {
// //       'id': 2,
// //       'name': 'Victoria Barangay Compost Site',
// //       'address': 'Victoria Barangay, Tago, Surigao del Sur',
// //       'distance': '1.2 km',
// //       'rating': 4.5,
// //       'isOpen': true,
// //       'isFree': true,
// //       'phone': '+63 912 345 6790',
// //       'hours': '7:00 AM - 5:00 PM',
// //       'description': 'Community-run compost facility in Victoria',
// //       'latitude': 9.035000,
// //       'longitude': 126.188000,
// //       'features': [
// //         'Community garden',
// //         'Workshop sessions',
// //         'Organic fertilizer'
// //       ],
// //     },
// //     {
// //       'id': 3,
// //       'name': 'DAYO-AY Barangay Compost Center',
// //       'address': 'DAYO-AY Barangay, Tago, Surigao del Sur',
// //       'distance': '1.8 km',
// //       'rating': 4.4,
// //       'isOpen': true,
// //       'isFree': true,
// //       'phone': '+63 912 345 6794',
// //       'hours': '6:00 AM - 6:00 PM',
// //       'description':
// //           'Community compost facility serving DAYO-AY barangay residents',
// //       'latitude': 9.033000,
// //       'longitude': 126.187000,
// //       'features': [
// //         'Community composting',
// //         'Educational programs',
// //         'Free organic fertilizer'
// //       ],
// //     },
// //     {
// //       'id': 4,
// //       'name': 'Eco-Garden Compost Hub',
// //       'address': 'Sitio Malipayon, Tago, Surigao del Sur',
// //       'distance': '2.5 km',
// //       'rating': 4.6,
// //       'isOpen': false,
// //       'isFree': false,
// //       'phone': '+63 912 345 6791',
// //       'hours': '8:00 AM - 4:00 PM',
// //       'description': 'Private eco-garden with premium compost services',
// //       'latitude': 9.030000,
// //       'longitude': 126.182000,
// //       'features': ['Premium compost', 'Garden supplies', 'Expert consultation'],
// //       'price': '₱50 per bag',
// //     },
// //     {
// //       'id': 5,
// //       'name': 'Green Valley Compost Facility',
// //       'address': 'Barangay San Isidro, Tago, Surigao del Sur',
// //       'distance': '3.5 km',
// //       'rating': 4.3,
// //       'isOpen': true,
// //       'isFree': true,
// //       'phone': '+63 912 345 6792',
// //       'hours': '6:30 AM - 5:30 PM',
// //       'description': 'Large-scale compost facility serving multiple barangays',
// //       'latitude': 9.028000,
// //       'longitude': 126.175000,
// //       'features': ['Large capacity', 'Bulk processing', 'Educational programs'],
// //     },
// //     {
// //       'id': 6,
// //       'name': 'Riverside Compost Center',
// //       'address': 'Near Tago River, Tago, Surigao del Sur',
// //       'distance': '4.2 km',
// //       'rating': 4.4,
// //       'isOpen': true,
// //       'isFree': true,
// //       'phone': '+63 912 345 6793',
// //       'hours': '7:00 AM - 6:00 PM',
// //       'description': 'Riverside compost facility with scenic location',
// //       'latitude': 9.025000,
// //       'longitude': 126.190000,
//       'features': ['Scenic location', 'Riverside access', 'Family-friendly'],
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _fadeController = AnimationController(
//       duration: AppConstants.mediumAnimation,
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeInOut,
//     ));

//     _fadeController.forward();
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'EcoSched',
//                   style: AppTheme.titleLarge.copyWith(
//                     color: AppTheme.textInverse,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(AppTheme.radiusM),
//                   ),
//                   clipBehavior: Clip.antiAlias,
//                   child: Image.asset(
//                     'assets/images/house.gif',
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 2),
//           ],
//         ),
//         centerTitle: false,
//         backgroundColor:
//             isDarkTheme ? AppTheme.backgroundSecondary : AppTheme.primaryGreen,
//         elevation: 0,
//         actions: [
//           IconButton(
//             tooltip: _isSatelliteView ? 'Show map view' : 'Show satellite view',
//             icon: Icon(
//               _isSatelliteView ? Icons.map : Icons.satellite_alt_outlined,
//             ),
//             onPressed: () {
//               setState(() {
//                 _isSatelliteView = !_isSatelliteView;
//               });
//             },
//           ),
//         ],
//       ),
//       body: GradientBackground(
//         child: SafeArea(
//           child: FadeTransition(
//             opacity: _fadeAnimation,
//             child: _buildMapView(),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMapView() {
//     final filteredPits = _compostPits.where((pit) {
//       final name = pit['name'] as String;
//       return name == 'Victoria Barangay Compost Site' ||
//           name == 'DAYO-AY Barangay Compost Center';
//     }).toList();

//     final double averageLat = filteredPits
//             .map((pit) => pit['latitude'] as double)
//             .reduce((a, b) => a + b) /
//         filteredPits.length;
//     final double averageLng = filteredPits
//             .map((pit) => pit['longitude'] as double)
//             .reduce((a, b) => a + b) /
//         filteredPits.length;
//     final LatLng center = LatLng(averageLat, averageLng);

//     return Container(
//       margin:
//           const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(AppConstants.borderRadius),
//         border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(AppConstants.borderRadius),
//         child: Stack(
//           children: [
//             FlutterMap(
//               options: MapOptions(
//                 initialCenter: center,
//                 initialZoom: 14,
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate: _isSatelliteView
//                       ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
//                       : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                   userAgentPackageName: 'com.ecosched.app',
//                 ),
//                 MarkerLayer(
//                   markers: filteredPits.map((pit) {
//                     final double lat = pit['latitude'] as double;
//                     final double lng = pit['longitude'] as double;
//                     return Marker(
//                       width: 120,
//                       height: 80,
//                       point: LatLng(lat, lng),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(8),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.15),
//                                   blurRadius: 4,
//                                   offset: const Offset(0, 2),
//                                 ),
//                               ],
//                             ),
//                             child: Text(
//                               pit['name'],
//                               style: TextStyle(
//                                 color: AppTheme.textDark,
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           const Icon(
//                             Icons.location_on,
//                             color: AppTheme.primaryGreen,
//                             size: 30,
//                           ),
//                         ],
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ],
//             ),
//             Positioned(
//               top: 12,
//               left: 12,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.55),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: const [
//                     Icon(
//                       Icons.delete_outline,
//                       color: Colors.white,
//                       size: 16,
//                     ),
//                     SizedBox(width: 6),
//                     Text(
//                       'Nearest Trash Bin',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
