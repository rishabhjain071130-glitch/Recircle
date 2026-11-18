import 'package:flutter/material.dart';

import '../features/requests/data/recircle_api.dart';
import '../providers/app_state.dart';
import '../widgets/recircle_branding.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _partners = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _pickups = [];
  List<Map<String, dynamic>> _rates = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Map<String, dynamic> _map(dynamic value) => value is Map
      ? value.map((key, item) => MapEntry(key.toString(), item))
      : <String, dynamic>{};

  List<Map<String, dynamic>> _rows(dynamic value) {
    final data = _map(value);
    final entries = data['items'] is List ? data['items'] as List : value;
    if (entries is! List) return const [];
    return entries.whereType<Map>().map(_map).toList(growable: false);
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.appState.api.get('/admin/dashboard/stats'),
        widget.appState.api.get('/admin/partners'),
        widget.appState.api.get('/admin/customers?page=1&limit=50'),
        widget.appState.api.get('/admin/pickups?page=1&limit=50'),
        widget.appState.api.get('/admin/market-rates?page=1&limit=50'),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = _map(results[0]);
        _partners = _rows(results[1]);
        _customers = _rows(results[2]);
        _pickups = _rows(results[3]);
        _rates = _rows(results[4]);
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Admin data could not be loaded. Retry.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setPartnerStatus(
    Map<String, dynamic> partner,
    String status,
  ) async {
    final id = (partner['_id'] ?? partner['id'])?.toString();
    if (id == null || id.isEmpty) return;
    try {
      await widget.appState.api.patch('/admin/partners/$id/status', {
        'status': status,
      });
      await _refresh();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  Future<void> _publishRate(Map<String, dynamic> rate) async {
    final id = (rate['_id'] ?? rate['id'])?.toString();
    if (id == null || id.isEmpty) return;
    final status = rate['status']?.toString();
    try {
      if (status == 'published') {
        final reason = await _askForReason();
        if (reason == null) return;
        await widget.appState.api.post('/admin/market-rates/$id/unpublish', {
          'reason': reason,
        });
      } else {
        await widget.appState.api.post('/admin/market-rates/$id/publish', {});
      }
      await _refresh();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  Future<String?> _askForReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpublish rate sheet'),
        content: TextField(
          controller: controller,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Reason (required)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.length < 3) return;
              Navigator.pop(context, value);
            },
            child: const Text('Unpublish'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: Scaffold(
      appBar: AppBar(
        title: const ReCircleBrandTitle('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh admin data',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.appState.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Partners'),
            Tab(text: 'Customers'),
            Tab(text: 'Pickups'),
            Tab(text: 'Market rates'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          Expanded(
            child: TabBarView(
              children: [
                _overview(),
                _partnerList(),
                _customerList(),
                _pickupList(),
                _rateList(),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _overview() => RefreshIndicator(
    onRefresh: _refresh,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Service totals',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _stat('Customers', 'customers'),
            _stat('Partners', 'partners'),
            _stat('Pending partners', 'pendingPartners'),
            _stat('Pickups', 'pickups'),
            _stat('Completed', 'completedPickups'),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Admin actions use your signed-in server role.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _stat(String label, String key) =>
      Chip(label: Text('$label: ${_stats[key] ?? 0}'));

  Widget _partnerList() => _listOrEmpty(
    _partners,
    'No partner accounts found.',
    (partner) => ListTile(
      title: Text(partner['name']?.toString() ?? 'Partner'),
      subtitle: Text(
        '${partner['email'] ?? ''}\n${partner['partnerStatus'] ?? 'approved'} · ${partner['city'] ?? ''}',
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        tooltip: 'Change partner status',
        onSelected: (status) => _setPartnerStatus(partner, status),
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'approved', child: Text('Approve')),
          PopupMenuItem(value: 'rejected', child: Text('Reject')),
          PopupMenuItem(value: 'suspended', child: Text('Suspend')),
          PopupMenuItem(value: 'pending', child: Text('Set pending')),
        ],
      ),
    ),
  );

  Widget _customerList() => _listOrEmpty(
    _customers,
    'No customers found.',
    (customer) => ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(customer['name']?.toString() ?? 'Customer'),
      subtitle: Text(customer['email']?.toString() ?? ''),
      trailing: Text(customer['active'] == false ? 'Inactive' : 'Active'),
    ),
  );

  Widget _pickupList() => _listOrEmpty(_pickups, 'No pickup requests found.', (
    pickup,
  ) {
    final item = _map(pickup['item']);
    final customer = _map(pickup['customer']);
    return ListTile(
      leading: const Icon(Icons.local_shipping_outlined),
      title: Text(item['name']?.toString() ?? 'Item'),
      subtitle: Text(
        '${pickup['status'] ?? 'Submitted'} · ${customer['name'] ?? 'Customer'}',
      ),
    );
  });

  Widget _rateList() => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Admin-managed indicative rates · not guaranteed live market prices.',
        ),
      ),
      if (_rates.isEmpty)
        const ListTile(title: Text('No rate sheets found.'))
      else
        ..._rates.map((rate) {
          final materials = (rate['materials'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (entry) =>
                    '${entry['name']}: ₹${entry['indicative']}/${rate['unit'] ?? 'kg'}',
              )
              .join(', ');
          return Card(
            child: ListTile(
              title: Text(
                '${rate['effectiveDate'] ?? ''} · ${rate['status'] ?? 'draft'}',
              ),
              subtitle: Text(
                '$materials${rate['isDemo'] == true ? '\nDemo data' : ''}',
              ),
              isThreeLine: true,
              trailing: TextButton(
                onPressed: () => _publishRate(rate),
                child: Text(
                  rate['status'] == 'published' ? 'Unpublish' : 'Publish',
                ),
              ),
            ),
          );
        }),
    ],
  );

  Widget _listOrEmpty(
    List<Map<String, dynamic>> rows,
    String emptyMessage,
    Widget Function(Map<String, dynamic>) builder,
  ) => RefreshIndicator(
    onRefresh: _refresh,
    child: rows.isEmpty
        ? ListView(
            children: [
              const SizedBox(height: 48),
              Center(child: Text(emptyMessage)),
            ],
          )
        : ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => builder(rows[index]),
          ),
  );
}
