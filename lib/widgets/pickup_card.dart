import 'package:flutter/material.dart';
import '../models/pickup.dart';
import '../theme/app_theme.dart';

class PickupCard extends StatelessWidget {
  final Pickup pickup;
  final VoidCallback onTap;

  const PickupCard({
    super.key,
    required this.pickup,
    required this.onTap,
  });

  Color _getStatusColor(PickupStatus status) {
    switch (status) {
      case PickupStatus.booked:
        return Colors.blue;
      case PickupStatus.partnerAssigned:
        return Colors.orange;
      case PickupStatus.pickupInProgress:
        return AppTheme.primaryGreen;
      case PickupStatus.collected:
        return Colors.teal;
      case PickupStatus.processing:
        return Colors.indigo;
      case PickupStatus.completed:
        return Colors.green.shade800;
    }
  }

  Color _getStatusBgColor(PickupStatus status) {
    switch (status) {
      case PickupStatus.booked:
        return Colors.blue.shade50;
      case PickupStatus.partnerAssigned:
        return Colors.orange.shade50;
      case PickupStatus.pickupInProgress:
        return AppTheme.accentLightGreen;
      case PickupStatus.collected:
        return Colors.teal.shade50;
      case PickupStatus.processing:
        return Colors.indigo.shade50;
      case PickupStatus.completed:
        return Colors.green.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(pickup.status);
    final statusBgColor = _getStatusBgColor(pickup.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentLightGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_shipping_outlined,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup #${pickup.id}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText,
                              ),
                            ),
                            Text(
                              pickup.category,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.subtitleGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        pickup.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Item',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.subtitleGrey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pickup.itemName} (${pickup.quantity})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Schedule',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.subtitleGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pickup.preferredDate}, ${pickup.preferredTime}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
