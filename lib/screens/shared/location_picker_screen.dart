import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final String title;
  final LatLng? initialLocation;

  const LocationPickerScreen({
    super.key,
    this.title = 'Pick location',
    this.initialLocation,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _searchController = TextEditingController();
  final _locationService = LocationService();
  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  String _selectedAddress = '';
  bool _isLoading = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLatLng = widget.initialLocation;
      _updateMarker(widget.initialLocation!);
      _reverseGeocode(widget.initialLocation!);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final pos = await _locationService.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      _selectedLatLng = latLng;
      _updateMarker(latLng);
      _reverseGeocode(latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final result = await _locationService.getAddressFromCoordinates(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
      if (mounted) {
        setState(() => _selectedAddress = result.address);
        _searchController.text = result.address;
      }
    } catch (_) {}
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final result = await _locationService.getLocationFromAddress(query);
      final latLng = LatLng(result.latitude, result.longitude);
      _selectedLatLng = latLng;
      _selectedAddress = result.address;
      _updateMarker(latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateMarker(LatLng latLng) {
    _markers = {
      Marker(
        markerId: const MarkerId('selected'),
        position: latLng,
        draggable: true,
        onDragEnd: (newPos) {
          _selectedLatLng = newPos;
          _reverseGeocode(newPos);
        },
      ),
    };
  }

  void _onMapTapped(LatLng latLng) {
    _selectedLatLng = latLng;
    _updateMarker(latLng);
    _reverseGeocode(latLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _selectedLatLng != null
                ? () => Navigator.pop(context, {
                      'latitude': _selectedLatLng!.latitude,
                      'longitude': _selectedLatLng!.longitude,
                      'address': _selectedAddress,
                    })
                : null,
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _selectedAddress = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onSubmitted: (_) => _searchLocation(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLatLng ??
                              const LatLng(-1.2921, 36.8219),
                          zoom: _selectedLatLng != null ? 15 : 12,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        onTap: _onMapTapped,
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'zoom_in',
                              onPressed: () =>
                                  _mapController?.animateCamera(
                                CameraUpdate.zoomIn(),
                              ),
                              child: const Icon(Icons.add),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'zoom_out',
                              onPressed: () =>
                                  _mapController?.animateCamera(
                                CameraUpdate.zoomOut(),
                              ),
                              child: const Icon(Icons.remove),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'my_location',
                              onPressed: _getCurrentLocation,
                              child: const Icon(Icons.my_location),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedAddress.isNotEmpty)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 80,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedAddress,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
