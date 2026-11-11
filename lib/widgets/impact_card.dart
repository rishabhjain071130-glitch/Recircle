import 'package:flutter/material.dart';

import '../models/impact_stats.dart';
import '../theme/app_theme.dart';

class ImpactCard extends StatelessWidget {
  final ImpactStats stats;
  final VoidCallback? onTap;

  const ImpactCard({super.key, required this.stats, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _ImpactMetric(
                      icon: Icons.eco_outlined,
                      value: '${stats.itemsReused}',
                      label: 'Items Reused',
                    ),
                  ),
                  _buildDivider(),
                  Expanded(
                    child: _ImpactMetric(
                      icon: Icons.recycling_outlined,
                      value: '${stats.itemsRecycled}',
                      label: 'Items Recycled',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 0.8),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _ImpactMetric(
                      icon: Icons.local_shipping_outlined,
                      value: '${stats.pickupsCompleted}',
                      label: 'Pickups',
                    ),
                  ),
                  _buildDivider(),
                  Expanded(
                    child: _ImpactMetric(
                      icon: Icons.stars_outlined,
                      value: '${stats.rewardPoints}',
                      label: 'Reward Points',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 35,
      width: 1,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }
}

class EnvironmentalImpactCard extends StatelessWidget {
  final double estimatedWasteDivertedKg;
  final VoidCallback? onInfoTap;

  const EnvironmentalImpactCard({
    super.key,
    required this.estimatedWasteDivertedKg,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedWeight = estimatedWasteDivertedKg >= 10
        ? estimatedWasteDivertedKg.toStringAsFixed(1)
        : estimatedWasteDivertedKg.toStringAsFixed(2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF5EA), Color(0xFFF7FBF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppTheme.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Waste Diverted',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedWeight,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'kg',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.subtitleGrey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Estimated from the category of items marked for reuse.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppTheme.subtitleGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onInfoTap,
            tooltip: 'How is this estimated?',
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ImpactMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentLightGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.subtitleGrey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
