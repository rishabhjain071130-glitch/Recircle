import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../features/requests/data/recircle_api.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/recircle_branding.dart';

class NearbyPartnersScreen extends StatefulWidget {
  const NearbyPartnersScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<NearbyPartnersScreen> createState() => _NearbyPartnersScreenState();
}

class _NearbyPartnersScreenState extends State<NearbyPartnersScreen> {
  GoogleMapController? _mapController;
  Position? _position;
  List<Map<String, dynamic>> _partners = const [];
  String? _error;
  bool _loading = true;
  double _radiusKm = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final position = await _getCurrentPosition();
      final result = await widget.appState.api.get(
        '/partners/nearby?latitude=${position.latitude}&longitude=${position.longitude}&radiusKm=${_radiusKm}',
      );
      final items = ((result as List?) ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();

      if (!mounted) return;
      setState(() {
        _position = position;
        _partners = items;
        _loading = false;
      });
      await _moveCamera(LatLng(position.latitude, position.longitude));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } on LocationServiceDisabledException {
      if (!mounted) return;
      setState(() {
        _error = 'Location services are turned off. Enable location and retry.';
        _loading = false;
      });
    } on PermissionDeniedException {
      if (!mounted) return;
      setState(() {
        _error = 'Location permission is required to find nearby partners.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load nearby collection partners. Please retry.';
        _loading = false;
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException();
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<void> _moveCamera(LatLng target) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 13.5),
      ),
    );
  }

  Set<Marker> get _markers {
    return {
      if (_position != null)
        Marker(
          markerId: const MarkerId('customer-location'),
          position: LatLng(_position!.latitude, _position!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Your location'),
        ),
      ..._partners.map((partner) {
        final id = partner['partnerId']?.toString() ?? '';
        final lat = (partner['latitude'] as num?)?.toDouble();
        final lng = (partner['longitude'] as num?)?.toDouble();
        if (id.isEmpty || lat == null || lng == null) {
          return const Marker(markerId: MarkerId('invalid'));
        }
        return Marker(
          markerId: MarkerId('partner-${id}'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: partner['name']?.toString() ?? 'Collection partner',
            snippet: '${partner['distanceKm'] ?? '?'} km away',
          ),
          onTap: () => _showPartner(partner),
        );
      }),
    }.where((marker) => marker.markerId.value != 'invalid').toSet();
  }

  void _showPartner(Map<String, dynamic> partner) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              partner['name']?.toString() ?? 'Collection partner',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${partner['distanceKm'] ?? '?'} km away',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if ((partner['address']?.toString() ?? '').isNotEmpty)
              Text('${partner['address']}, ${partner['city'] ?? ''}'),
            if ((partner['serviceArea']?.toString() ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Service area: ${partner['serviceArea']}'),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Approved ReCircle collection partner'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, partner);
                },
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Use this partner for pickup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = _position == null
        ? const LatLng(27.4924, 77.6737)
        : LatLng(_position!.latitude, _position!.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const ReCircleBrandTitle('Nearby Partners'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 12,
            ),
            myLocationEnabled: _position != null,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            compassEnabled: true,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_position != null) {
                _moveCamera(
                  LatLng(_position!.latitude, _position!.longitude),
                );
              }
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.recycling_rounded,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _loading
                            ? 'Finding approved partners near you...'
                            : '${_partners.length} approved partner${_partners.length == 1 ? '' : 's'} within ${_radiusKm.toInt()} km',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_error != null)
            Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_off_outlined,
                        size: 42,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_loading && _error == null && _partners.isEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No approved collection partners are currently available in this area. Try again later or expand the search radius.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          if (_loading)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
