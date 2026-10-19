import 'package:flutter/material.dart';

import '../features/requests/data/recircle_api.dart';
import '../models/pickup.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/recircle_branding.dart';

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key, required this.appState});
  final AppState appState;

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  List<Pickup> _eligible = [];
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshEligible();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refreshEligible() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _eligible = await widget.appState.eligibleRequests();
      await widget.appState.refreshRequests();
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Could not load requests. Check the connection and retry.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(Pickup pickup) async {
    final confirmed = await _confirm(
      title: 'Accept this request?',
      message: 'This assigns the pickup to your partner account.',
      action: 'Accept request',
    );
    if (!confirmed) return;
    try {
      await widget.appState.acceptRequest(pickup.id);
      await _refreshEligible();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request assigned to your account.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _advance(Pickup pickup) async {
    final target = switch (pickup.status) {
      PickupStatus.partnerAssigned => PickupStatus.collected,
      PickupStatus.collected => PickupStatus.processing,
      PickupStatus.processing => PickupStatus.completed,
      _ => null,
    };
    if (target == null) return;
    final label = switch (target) {
      PickupStatus.collected => 'mark this item as collected',
      PickupStatus.processing => 'mark delivery to the processing facility',
      PickupStatus.completed => 'mark processing as completed',
      _ => 'update this request',
    };
    if (!await _confirm(
      title: 'Confirm status update',
      message:
          'Are you sure you want to $label? This will be recorded in the request history.',
      action: 'Confirm',
    )) {
      return;
    }
    try {
      await widget.appState.updatePartnerStatus(pickup.id, target);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status saved to the shared pickup record.'),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const ReCircleBrandTitle('Partner Dashboard'),
      actions: [
        IconButton(
          onPressed: widget.appState.logout,
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
        ),
      ],
      bottom: TabBar(
        controller: _tabs,
        tabs: [
          const Tab(text: 'Available'),
          Tab(text: 'Assigned (${widget.appState.pickups.length})'),
        ],
      ),
    ),
    body: Column(
      children: [
        if (_error != null)
          MaterialBanner(
            content: Text(_error!),
            actions: [
              TextButton(
                onPressed: _refreshEligible,
                child: const Text('Retry'),
              ),
            ],
          ),
        if (_loading) const LinearProgressIndicator(),
        ListenableBuilder(
          listenable: widget.appState,
          builder: (context, _) {
            final assigned = widget.appState.pickups;
            int count(PickupStatus status) =>
                assigned.where((p) => p.status == status).length;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _summary('Available', _eligible.length),
                  _summary('Assigned', count(PickupStatus.partnerAssigned)),
                  _summary('Collected', count(PickupStatus.collected)),
                  _summary('Processing', count(PickupStatus.processing)),
                  _summary('Completed', count(PickupStatus.completed)),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              RefreshIndicator(
                onRefresh: _refreshEligible,
                child: _eligible.isEmpty && !_loading
                    ? ListView(
                        children: const [
                          SizedBox(height: 180),
                          Center(child: Text('No eligible requests right now')),
                        ],
                      )
                    : ListView(
                        children: _eligible
                            .map(
                              (pickup) => _requestCard(
                                pickup,
                                action: ElevatedButton(
                                  onPressed: () => _accept(pickup),
                                  child: const Text('Accept request'),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              ListenableBuilder(
                listenable: widget.appState,
                builder: (context, _) {
                  final assigned = widget.appState.pickups;
                  if (assigned.isEmpty) {
                    return const Center(
                      child: Text('No assigned requests yet'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: widget.appState.refreshRequests,
                    child: ListView(
                      children: assigned.map((pickup) {
                        final next = switch (pickup.status) {
                          PickupStatus.partnerAssigned => 'Mark Collected',
                          PickupStatus.collected => 'Received for Processing',
                          PickupStatus.processing => 'Complete',
                          _ => null,
                        };
                        return _requestCard(
                          pickup,
                          action: next == null
                              ? null
                              : ElevatedButton(
                                  onPressed: () => _advance(pickup),
                                  child: Text(next),
                                ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _summary(String label, int count) => Chip(
    label: Text('$label: $count'),
    backgroundColor: AppTheme.accentLightGreen,
    side: BorderSide.none,
  );

  Widget _requestCard(Pickup pickup, {Widget? action}) => Card(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pickup.itemName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            '${pickup.category} • ${pickup.quantity} item(s) • ${pickup.status.displayName}',
            style: const TextStyle(color: AppTheme.subtitleGrey),
          ),
          const SizedBox(height: 8),
          Text(
            pickup.pickupAddress.isEmpty
                ? 'Address and contact details are shown after acceptance.'
                : pickup.pickupAddress,
          ),
          if (pickup.preferredDate.isNotEmpty ||
              pickup.preferredTime.isNotEmpty)
            Text(
              'Preferred: ${pickup.preferredDate} · ${pickup.preferredTime}',
            ),
          if ((pickup.notes ?? '').isNotEmpty) Text('Notes: ${pickup.notes}'),
          Text(
            'Request ${pickup.id}',
            style: const TextStyle(fontSize: 11, color: AppTheme.subtitleGrey),
          ),
          if (pickup.statusHistory.isNotEmpty) ...[
            const Divider(),
            ...pickup.timeline.map(
              (event) => Text(
                '${event.title} · ${event.timestamp?.toLocal().toString().substring(0, 16) ?? ''}',
              ),
            ),
          ],
          if (action != null)
            Align(alignment: Alignment.centerRight, child: action),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showDetails(pickup),
              icon: const Icon(Icons.info_outline),
              label: const Text('Request details'),
            ),
          ),
        ],
      ),
    ),
  );

  void _showDetails(Pickup pickup) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pickup.itemName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Category: ${pickup.category}'),
              Text('Condition: ${pickup.itemCondition}'),
              Text('Quantity: ${pickup.quantity}'),
              if (pickup.pickupContactName.isNotEmpty)
                Text('Contact: ${pickup.pickupContactName}'),
              if (pickup.pickupContactPhone.isNotEmpty)
                Text('Phone: ${pickup.pickupContactPhone}'),
              if (pickup.pickupAddress.isNotEmpty)
                Text('Collection address: ${pickup.pickupAddress}'),
              Text(
                'Preferred window: ${pickup.preferredDate} · ${pickup.preferredTime}',
              ),
              if ((pickup.notes ?? '').isNotEmpty)
                Text('Customer notes: ${pickup.notes}'),
              Text('Created: ${pickup.createdAt.toLocal()}'),
              const SizedBox(height: 12),
              const Text(
                'Status history',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...pickup.timeline.map(
                (event) => Text(
                  '${event.title} · ${event.timestamp?.toLocal() ?? ''}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
