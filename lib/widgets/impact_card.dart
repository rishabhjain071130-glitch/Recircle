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
