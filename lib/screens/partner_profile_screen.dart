import 'package:flutter/material.dart';

import '../features/requests/data/recircle_api.dart';
import '../models/partner_profile.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/recircle_branding.dart';
import 'pickup_booking_screen.dart';

class PartnerProfileScreen extends StatefulWidget {
  const PartnerProfileScreen({
    super.key,
    required this.appState,
    this.partnerId,
    this.initialProfile,
    this.ownProfile = false,
  });

  final AppState appState;
  final String? partnerId;
  final PartnerProfile? initialProfile;
  final bool ownProfile;

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  static const _types = [
    'Collector',
    'Recycler',
    'Refurbisher',
    'Reuse Center',
  ];
  static const _categories = [
    'Electronics',
    'Computers',
    'Mobile phones',
    'Batteries',
    'Appliances',
    'Cables',
  ];

  PartnerProfile? _profile;
  final Map<String, TextEditingController> _fields = {
    'name': TextEditingController(),
    'businessName': TextEditingController(),
    'phone': TextEditingController(),
    'address': TextEditingController(),
    'city': TextEditingController(),
    'pinCode': TextEditingController(),
    'serviceArea': TextEditingController(),
  };
  String? _partnerType;
  final Set<String> _acceptedCategories = {};
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  bool _available = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _loadProfile();
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final raw = widget.ownProfile
          ? await widget.appState.api.getOwnPartnerProfile()
          : await widget.appState.api.getPartnerProfile(
              widget.partnerId ?? _profile?.id ?? '',
            );
      final profile = PartnerProfile.fromJson(
        (raw as Map).cast<String, dynamic>(),
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
        _error = null;
      });
      _fillFields(profile);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
        if (!widget.ownProfile) _profile = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load this partner profile. Please retry.';
        if (!widget.ownProfile) _profile = null;
      });
    }
  }

  void _fillFields(PartnerProfile profile) {
    _fields['name']!.text = profile.name;
    _fields['businessName']!.text = profile.businessName;
    _fields['phone']!.text = profile.phone;
    _fields['address']!.text = profile.address;
    _fields['city']!.text = profile.city;
    _fields['pinCode']!.text = profile.pinCode;
    _fields['serviceArea']!.text = profile.serviceArea;
    _partnerType = _types.contains(profile.partnerType)
        ? profile.partnerType
        : null;
    _acceptedCategories
      ..clear()
      ..addAll(profile.acceptedCategories.where(_categories.contains));
    _available = profile.available;
  }

  Future<void> _save() async {
    final values = <String, dynamic>{
      for (final key in _fields.keys) key: _fields[key]!.text.trim(),
      'partnerAvailable': _available,
      'partnerType': _partnerType ?? '',
      'acceptedCategories': _acceptedCategories.toList(),
    };
    setState(() => _saving = true);
    try {
      final raw = await widget.appState.api.updateOwnPartnerProfile(values);
      final profile = PartnerProfile.fromJson(
        (raw as Map).cast<String, dynamic>(),
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _editing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Partner profile updated.')));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(
        title: ReCircleBrandTitle(
          widget.ownProfile ? 'Partner Profile' : 'Partner Details',
        ),
        actions: [
          if (widget.ownProfile && profile != null && !_editing)
            IconButton(
              tooltip: 'Edit profile',
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (!widget.ownProfile)
            IconButton(
              onPressed: _loadProfile,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _loading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : profile == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? 'Partner profile is unavailable.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadProfile,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : _buildProfile(profile),
    );
  }

  Widget _buildProfile(PartnerProfile profile) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (profile.businessName.isNotEmpty &&
                  profile.businessName != profile.name) ...[
                const SizedBox(height: 4),
                Text('Contact: ${profile.name}'),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      profile.isApproved
                          ? Icons.verified_rounded
                          : Icons.hourglass_top,
                      size: 18,
                    ),
                    label: Text(
                      profile.isApproved
                          ? 'Approved ReCircle partner'
                          : _statusLabel(profile.partnerStatus),
                    ),
                    backgroundColor: profile.isApproved
                        ? AppTheme.accentLightGreen
                        : Colors.orange.shade50,
                  ),
                  Chip(
                    avatar: Icon(
                      profile.available
                          ? Icons.check_circle_outline
                          : Icons.pause_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      profile.available ? 'Available' : 'Currently unavailable',
                    ),
                  ),
                  if (profile.distanceKm != null)
                    Chip(label: Text('${profile.distanceKm} km away')),
                ],
              ),
              if (profile.partnerType.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Partner type: ${profile.partnerType}'),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (_editing) ..._editFields() else ..._readOnlyFields(profile),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (widget.ownProfile && _editing) ...[
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Available for pickups'),
          value: _available,
          onChanged: profile.isApproved
              ? (value) => setState(() => _available = value)
              : null,
          subtitle: profile.isApproved
              ? null
              : const Text('Availability is enabled after admin approval.'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CircularProgressIndicator()
              : const Text('Save profile'),
        ),
        TextButton(
          onPressed: () {
            _fillFields(profile);
            setState(() {
              _editing = false;
              _error = null;
            });
          },
          child: const Text('Cancel'),
        ),
      ] else if (!widget.ownProfile && profile.isApproved) ...[
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: profile.available
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PickupBookingScreen(
                      appState: widget.appState,
                      preferredPartnerId: profile.id,
                      preferredPartnerName: profile.displayName,
                    ),
                  ),
                )
              : null,
          icon: const Icon(Icons.local_shipping_outlined),
          label: Text(
            profile.available ? 'Select Partner' : 'Partner unavailable',
          ),
        ),
      ],
    ],
  );

  List<Widget> _readOnlyFields(PartnerProfile profile) => [
    if (profile.partnerType.isNotEmpty)
      _info('Partner type', profile.partnerType),
    _info(
      'Pickup availability',
      profile.available ? 'Available' : 'Currently unavailable',
    ),
    if (profile.acceptedCategories.isNotEmpty)
      _info(
        'Accepted e-waste categories',
        profile.acceptedCategories.join(', '),
      ),
    if (profile.address.isNotEmpty || profile.city.isNotEmpty)
      _info(
        'Location',
        [
          profile.address,
          profile.city,
          profile.pinCode,
        ].where((part) => part.isNotEmpty).join(', '),
      ),
    if (profile.serviceArea.isNotEmpty)
      _info('Service area', profile.serviceArea),
    if (profile.phone.isNotEmpty) _info('Contact phone', profile.phone),
    if (profile.registeredAt != null)
      _info('Registered', _date(profile.registeredAt!)),
  ];

  List<Widget> _editFields() => [
    for (final entry in [
      ('Contact name', 'name'),
      ('Business name', 'businessName'),
      ('Phone', 'phone'),
      ('Address', 'address'),
      ('City', 'city'),
      ('Postal / PIN code', 'pinCode'),
      ('Service area', 'serviceArea'),
    ]) ...[
      TextField(
        controller: _fields[entry.$2],
        decoration: InputDecoration(labelText: entry.$1),
      ),
      const SizedBox(height: 8),
    ],
    DropdownButtonFormField<String>(
      initialValue: _partnerType,
      decoration: const InputDecoration(labelText: 'Partner type'),
      items: _types
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: (type) => setState(() => _partnerType = type),
    ),
    const SizedBox(height: 12),
    const Text(
      'Accepted e-waste categories',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    Wrap(
      spacing: 6,
      children: _categories
          .map(
            (category) => FilterChip(
              label: Text(category),
              selected: _acceptedCategories.contains(category),
              onSelected: (selected) => setState(
                () => selected
                    ? _acceptedCategories.add(category)
                    : _acceptedCategories.remove(category),
              ),
            ),
          )
          .toList(),
    ),
  ];

  Widget _info(String title, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      title,
      style: const TextStyle(fontSize: 13, color: AppTheme.subtitleGrey),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(fontSize: 16, color: AppTheme.darkText),
    ),
  );

  String _statusLabel(String value) => switch (value) {
    'rejected' => 'Application rejected',
    'suspended' => 'Account suspended',
    _ => 'Pending approval',
  };

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
