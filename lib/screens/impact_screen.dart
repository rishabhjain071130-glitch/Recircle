import 'package:flutter/material.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/impact_card.dart';
import '../widgets/recircle_branding.dart';
import 'rewards_screen.dart';

class ImpactScreen extends StatelessWidget {
  final AppState appState;

  const ImpactScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final stats = appState.impactStats;

    return Scaffold(
      appBar: AppBar(
        title: const ReCircleBrandTitle('My Impact'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RewardsScreen(appState: appState),
                ),
              );
            },
            icon: const Icon(Icons.stars_outlined, color: Colors.amber),
            tooltip: 'Rewards',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLightGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sustainability Impact',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Track your contribution to a circular economy.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.subtitleGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentLightGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Demo totals · not measured or independently verified',
                style: TextStyle(fontSize: 12, color: AppTheme.darkText),
              ),
            ),

            const SizedBox(height: 20),

            // Main Impact Numbers Card
            ImpactCard(
              stats: stats,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RewardsScreen(appState: appState),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Circular Graphic Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Your ReCircle Journey',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Five steps towards zero waste',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subtitleGrey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Circular Visual Journey
                  _buildJourneyGraphic(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Reuse First Principle Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentLightGreen,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb,
                      color: AppTheme.primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Reuse First',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Every item reused means one less item sent for disposal or energy-intensive processing.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.darkText,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyGraphic() {
    final stages = [
      {
        'title': 'IDENTIFY',
        'icon': Icons.center_focus_strong,
        'desc': 'Scan unwanted item',
      },
      {'title': 'REUSE', 'icon': Icons.eco, 'desc': 'Upcycle with DIY guide'},
      {
        'title': 'RECYCLE',
        'icon': Icons.recycling,
        'desc': 'Book pickup request',
      },
      {
        'title': 'COLLECT',
        'icon': Icons.local_shipping,
        'desc': 'Partner doorstep pickup',
      },
      {
        'title': 'PROCESS',
        'icon': Icons.factory,
        'desc': 'Material sorting & processing',
      },
    ];

    return Column(
      children: stages.asMap().entries.map((entry) {
        final index = entry.key;
        final stage = entry.value;
        final isLast = index == stages.length - 1;

        return Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accentLightGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    stage['icon'] as IconData,
                    color: AppTheme.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        stage['desc'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.subtitleGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundLight,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
              ],
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 21, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 2,
                      height: 20,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}
