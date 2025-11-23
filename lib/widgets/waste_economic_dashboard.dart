import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'waste_management_card.dart';
import 'waste_management_background.dart';

class WasteEconomicDashboard extends StatefulWidget {
  const WasteEconomicDashboard({super.key});

  @override
  State<WasteEconomicDashboard> createState() => _WasteEconomicDashboardState();
}

class _WasteEconomicDashboardState extends State<WasteEconomicDashboard> {
  String selectedWasteType = 'recycling';
  String selectedEconomicType = 'savings';

  @override
  Widget build(BuildContext context) {
    return WasteManagementBackground(
      showPatterns: true,
      showAnimations: true,
      primaryWasteType: selectedWasteType,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Waste & Economic Dashboard',
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: AppTheme.textDark),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.spacing8), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Waste Type Selection
              _buildWasteTypeSection(),
              const SizedBox(height: AppTheme.spacing8),
              
              // Economic Metrics Section
              _buildEconomicMetricsSection(),
              const SizedBox(height: AppTheme.spacing8),
              
              // Waste Management Cards
              _buildWasteManagementCards(),
              const SizedBox(height: AppTheme.spacing8),
              
              // Economic Cards
              _buildEconomicCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWasteTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Waste Types',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Wrap(
          spacing: AppTheme.spacing4,
          runSpacing: AppTheme.spacing4,
          children: [
            'recycling',
            'composting',
            'organic',
            'hazardous',
            'landfill',
          ].map((wasteType) => WasteTypeChip(
            wasteType: wasteType,
            isSelected: selectedWasteType == wasteType,
            onTap: () => setState(() => selectedWasteType = wasteType),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildEconomicMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Economic Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Wrap(
          spacing: AppTheme.spacing4,
          runSpacing: AppTheme.spacing4,
          children: [
            'savings',
            'efficiency',
            'value',
            'profit',
            'cost',
          ].map((economicType) => EconomicMetricChip(
            economicType: economicType,
            isSelected: selectedEconomicType == economicType,
            onTap: () => setState(() => selectedEconomicType = economicType),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildWasteManagementCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Waste Collection Status',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: AppTheme.spacing4,
          mainAxisSpacing: AppTheme.spacing4,
          children: [
            WasteManagementCard(
              wasteType: 'recycling',
              title: 'Recycling',
              subtitle: 'This week',
              amount: 45.2,
              unit: 'kg',
              status: 'collected',
              onTap: () {},
            ),
            WasteManagementCard(
              wasteType: 'composting',
              title: 'Composting',
              subtitle: 'This week',
              amount: 23.8,
              unit: 'kg',
              status: 'pending',
              onTap: () {},
            ),
            WasteManagementCard(
              wasteType: 'organic',
              title: 'Organic',
              subtitle: 'This week',
              amount: 67.5,
              unit: 'kg',
              status: 'in_progress',
              onTap: () {},
            ),
            WasteManagementCard(
              wasteType: 'hazardous',
              title: 'Hazardous',
              subtitle: 'This week',
              amount: 12.3,
              unit: 'kg',
              status: 'scheduled',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEconomicCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Economic Impact',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
              const SizedBox(height: AppTheme.spacing4),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: AppTheme.spacing4,
          mainAxisSpacing: AppTheme.spacing4, 
          children: [
            EconomicMetricCard(
              economicType: 'savings',
              title: 'Cost Savings',
              subtitle: 'This month',
              value: 1250.75,
              currency: '\$',
              status: 'positive',
              onTap: () {},
            ),
            EconomicMetricCard(
              economicType: 'efficiency',
              title: 'Efficiency',
              subtitle: 'This month',
              value: 87.5,
              currency: '%',
              status: 'optimized',
              onTap: () {},
            ),
            EconomicMetricCard(
              economicType: 'value',
              title: 'Value Created',
              subtitle: 'This month',
              value: 3200.50,
              currency: '\$',
              status: 'positive',
              onTap: () {},
            ),
            EconomicMetricCard(
              economicType: 'profit',
              title: 'Net Profit',
              subtitle: 'This month',
              value: 1950.25,
              currency: '\$',
              status: 'profitable',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}
