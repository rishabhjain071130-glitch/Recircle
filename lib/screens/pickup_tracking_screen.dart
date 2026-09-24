import 'package:flutter/material.dart';
import '../models/pickup.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class PickupTrackingScreen extends StatefulWidget {
  final Pickup pickup;
  final AppState appState;

  const PickupTrackingScreen({
    super.key,
    required this.pickup,
    required this.appState,
  });

  @override
  State<PickupTrackingScreen> createState() => _PickupTrackingScreenState();
}

class _PickupTrackingScreenState extends State<PickupTrackingScreen> {
  late Pickup _currentPickup;

  @override
  void initState() {
    super.initState();
    _currentPickup = widget.pickup;
  }

  void _advanceDemoStatus() {
    widget.appState.advancePickupStatus(_currentPickup.id);
    final updated = widget.appState.pickups.firstWhere(
      (p) => p.id == _currentPickup.id,
      orElse: () => _currentPickup,
    );
    setState(() {
      _currentPickup = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to: ${_currentPickup.status.displayName}'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _currentPickup.timeline;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pickup #${_currentPickup.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currentPickup.itemName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLightGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentPickup.status.displayName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.category_outlined, 'Category', _currentPickup.category),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.scale_outlined, 'Quantity', _currentPickup.quantity),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.location_on_outlined, 'Pickup Address', _currentPickup.pickupAddress),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    'Scheduled Time',
                    '${_currentPickup.preferredDate}, ${_currentPickup.preferredTime}',
                  ),
                  if (_currentPickup.notes != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.note_outlined, 'Notes', _currentPickup.notes!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Demo Action Bar
            if (_currentPickup.status != PickupStatus.completed) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accentLightGreen.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_outlined, color: AppTheme.primaryGreen),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Demo Workflow: Advance status to simulate live collection partner updates.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.darkText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _advanceDemoStatus,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Next Step'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Timeline Header
            const Text(
              'Tracking Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 16),

            // Vertical Timeline
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timeline.length,
              itemBuilder: (context, index) {
                final item = timeline[index];
                final isLast = index == timeline.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: item.isCompleted ? AppTheme.primaryGreen : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.isCompleted ? Icons.check : Icons.circle,
                            size: 14,
                            color: item.isCompleted ? Colors.white : Colors.grey.shade500,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 48,
                            color: item.isCompleted ? AppTheme.primaryGreen : Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: item.isCompleted ? AppTheme.darkText : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: item.isCompleted ? AppTheme.subtitleGrey : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.subtitleGrey),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.subtitleGrey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
        ),
      ],
    );
  }
}
