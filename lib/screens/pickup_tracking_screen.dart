import 'dart:async';

import 'package:flutter/material.dart';

import '../features/requests/data/recircle_api.dart';
import '../models/pickup.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/recircle_branding.dart';

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
  Timer? _refreshTimer;
  bool _refreshing = false;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _currentPickup = widget.pickup;
    _lastUpdated = DateTime.now();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refresh(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final refreshed = await widget.appState.refreshRequest(_currentPickup.id);
      if (!mounted) return;
      if (refreshed != null) {
        final statusChanged = refreshed.status != _currentPickup.status;
        setState(() {
          _currentPickup = refreshed;
          _lastUpdated = DateTime.now();
        });
        if (!silent && statusChanged) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pickup status updated to ${refreshed.status.displayName}.',
              ),
            ),
          );
        }
      }
    } on ApiException catch (error) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not refresh pickup status.')),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _currentPickup.timeline;

    return Scaffold(
      appBar: AppBar(
        title: ReCircleBrandTitle('Request #${_currentPickup.id}'),
        actions: [
          IconButton(
            onPressed: _refreshing ? null : () => _refresh(),
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh status',
          ),
        ],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemName = Text(
                        _currentPickup.itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      );
                      final status = Container(
                        constraints: const BoxConstraints(maxWidth: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLightGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentPickup.status.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      );
                      if (constraints.maxWidth < 350) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            itemName,
                            Align(
                              alignment: Alignment.centerRight,
                              child: status,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: itemName),
                          const SizedBox(width: 8),
                          status,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.category_outlined,
                    'Category',
                    _currentPickup.category,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.scale_outlined,
                    'Quantity',
                    _currentPickup.quantity,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    'Pickup Address',
                    _currentPickup.pickupAddress,
                  ),
                  if (_currentPickup.partnerName != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.verified_user_outlined,
                      'Collection Partner',
                      _currentPickup.partnerName!,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    'Scheduled Time',
                    '${_currentPickup.preferredDate}, ${_currentPickup.preferredTime}',
                  ),
                  if (_currentPickup.notes != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.note_outlined,
                      'Notes',
                      _currentPickup.notes!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Timeline Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tracking Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
                if (_lastUpdated case final lastUpdated?)
                  Text(
                    'Updated ${_formatTime(lastUpdated)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.subtitleGrey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Status refreshes automatically every 20 seconds while this screen is open.',
              style: TextStyle(fontSize: 12, color: AppTheme.subtitleGrey),
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
                            color: item.isCompleted
                                ? AppTheme.primaryGreen
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.isCompleted ? Icons.check : Icons.circle,
                            size: 14,
                            color: item.isCompleted
                                ? Colors.white
                                : Colors.grey.shade500,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 48,
                            color: item.isCompleted
                                ? AppTheme.primaryGreen
                                : Colors.grey.shade300,
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
                                color: item.isCompleted
                                    ? AppTheme.darkText
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: item.isCompleted
                                    ? AppTheme.subtitleGrey
                                    : Colors.grey.shade400,
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
            style: const TextStyle(fontSize: 13, color: AppTheme.subtitleGrey),
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
