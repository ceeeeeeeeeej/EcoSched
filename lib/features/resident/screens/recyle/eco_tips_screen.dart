// import 'package:flutter/material.dart';

// import '../../../core/theme/app_theme.dart';
// import '../../../core/utils/responsive.dart';
// import '../../../widgets/gradient_background.dart';

// class EcoTipsScreen extends StatelessWidget {
//   const EcoTipsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final responsive = context.responsive;
//     final theme = Theme.of(context);
//     final bool isDarkTheme = theme.brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Eco Tips & Guides'),
//         backgroundColor:
//             isDarkTheme ? AppTheme.backgroundSecondary : AppTheme.primaryGreen,
//         foregroundColor: AppTheme.textInverse,
//       ),
//       // Use themed scaffold background so dark mode is respected
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: GradientBackground(
//         economyTheme: true,
//         child: SafeArea(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               return SingleChildScrollView(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: responsive.horizontalPadding,
//                   vertical: responsive.verticalPadding,
//                 ),
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         width: double.infinity,
//                         padding: EdgeInsets.all(responsive.spacing(20)),
//                         decoration: BoxDecoration(
//                           // Card background follows current theme
//                           color: Theme.of(context).cardColor,
//                           borderRadius:
//                               BorderRadius.circular(AppTheme.radiusXL),
//                           boxShadow: AppTheme.shadowMedium,
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Small changes, big impact',
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .headlineSmall
//                                   ?.copyWith(
//                                     fontSize: (Theme.of(context)
//                                                 .textTheme
//                                                 .headlineSmall
//                                                 ?.fontSize ??
//                                             AppTheme.headlineSmall.fontSize!) *
//                                         responsive.fontSizeMultiplier,
//                                   ),
//                             ),
//                             SizedBox(height: responsive.spacing(8)),
//                             Text(
//                               'Discover simple ways to sort waste, reduce trash, and support composting in your community.',
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodyMedium
//                                   ?.copyWith(
//                                     fontSize: (Theme.of(context)
//                                                 .textTheme
//                                                 .bodyMedium
//                                                 ?.fontSize ??
//                                             AppTheme.bodyMedium.fontSize!) *
//                                         responsive.fontSizeMultiplier,
//                                   ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       SizedBox(height: responsive.spacing(24)),
//                       Text(
//                         'Getting Started',
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontSize: (Theme.of(context)
//                                           .textTheme
//                                           .titleLarge
//                                           ?.fontSize ??
//                                       AppTheme.titleLarge.fontSize!) *
//                                   responsive.fontSizeMultiplier,
//                             ),
//                       ),
//                       SizedBox(height: responsive.spacing(12)),
//                       _buildTipCard(
//                         context,
//                         title: 'Waste Sorting 101',
//                         description:
//                             'Separate biodegradable, recyclable, and residual waste. Use clear labels on your bins so the whole household can follow.',
//                         icon: Icons.recycling_rounded,
//                         color: AppTheme.recyclingBlue,
//                         responsive: responsive,
//                       ),
//                       SizedBox(height: responsive.spacing(12)),
//                       _buildTipCard(
//                         context,
//                         title: 'Reduce Plastics',
//                         description:
//                             'Bring your own eco-bag, water bottle, and containers when shopping to avoid single-use plastics.',
//                         icon: Icons.shopping_bag_outlined,
//                         color: AppTheme.accentOrange,
//                         responsive: responsive,
//                       ),
//                       SizedBox(height: responsive.spacing(24)),
//                       Text(
//                         'Compost & Organic Waste',
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontSize: (Theme.of(context)
//                                           .textTheme
//                                           .titleLarge
//                                           ?.fontSize ??
//                                       AppTheme.titleLarge.fontSize!) *
//                                   responsive.fontSizeMultiplier,
//                             ),
//                       ),
//                       SizedBox(height: responsive.spacing(12)),
//                       _buildTipCard(
//                         context,
//                         title: 'Start a Simple Compost Bin',
//                         description:
//                             'Collect fruit peels, vegetable scraps, and dry leaves in a covered container. Avoid meat, oil, and dairy.',
//                         icon: Icons.compost_rounded,
//                         color: AppTheme.organicGreen,
//                         responsive: responsive,
//                       ),
//                       SizedBox(height: responsive.spacing(12)),
//                       _buildTipCard(
//                         context,
//                         title: 'Support Local Compost Pits',
//                         description:
//                             'Bring your segregated organic waste to nearby compost facilities listed in EcoSched to support community composting.',
//                         icon: Icons.location_on_outlined,
//                         color: AppTheme.primaryGreen,
//                         responsive: responsive,
//                       ),
//                       SizedBox(height: responsive.spacing(24)),
//                       Text(
//                         'Smart Habits',
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontSize: (Theme.of(context)
//                                           .textTheme
//                                           .titleLarge
//                                           ?.fontSize ??
//                                       AppTheme.titleLarge.fontSize!) *
//                                   responsive.fontSizeMultiplier,
//                             ),
//                       ),
//                       SizedBox(height: responsive.spacing(12)),
//                       _buildTipCard(
//                         context,
//                         title: 'Prepare Before Collection Day',
//                         description:
//                             'Tie your bags securely, label them by waste type, and place them in an easy-to-access spot before the scheduled time.',
//                         icon: Icons.schedule_rounded,
//                         color: AppTheme.accentBlue,
//                         responsive: responsive,
//                       ),
//                       SizedBox(height: responsive.spacing(12)),
//                       _buildTipCard(
//                         context,
//                         title: 'Teach the Household',
//                         description:
//                             'Share these tips with family members so everyone helps keep your home and barangay clean.',
//                         icon: Icons.family_restroom_rounded,
//                         color: AppTheme.accentPurple,
//                         responsive: responsive,
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTipCard(
//     BuildContext context, {
//     required String title,
//     required String description,
//     required IconData icon,
//     required Color color,
//     required Responsive responsive,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(responsive.spacing(16)),
//       decoration: BoxDecoration(
//         // Card background follows current theme (light/dark)
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(AppTheme.radiusL),
//         boxShadow: AppTheme.shadowSmall,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               icon,
//               color: color,
//               size: responsive.iconSize(22),
//             ),
//           ),
//           SizedBox(width: responsive.spacing(12)),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         fontSize: (Theme.of(context)
//                                     .textTheme
//                                     .titleMedium
//                                     ?.fontSize ??
//                                 AppTheme.titleMedium.fontSize!) *
//                             responsive.fontSizeMultiplier,
//                       ),
//                 ),
//                 SizedBox(height: responsive.spacing(6)),
//                 Text(
//                   description,
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         fontSize:
//                             (Theme.of(context).textTheme.bodyMedium?.fontSize ??
//                                     AppTheme.bodyMedium.fontSize!) *
//                                 responsive.fontSizeMultiplier,
//                       ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
