import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<LocationResult> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        throw Exception('Could not find location for "$address"');
      }
      final loc = locations.first;
      final placemarks = await placemarkFromCoordinates(
        loc.latitude,
        loc.longitude,
      );
      final formatted = placemarks.isNotEmpty
          ? _formatAddress(placemarks.first)
          : address;
      return LocationResult(
        latitude: loc.latitude,
        longitude: loc.longitude,
        address: formatted,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<LocationResult> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      final address = placemarks.isNotEmpty
          ? _formatAddress(placemarks.first)
          : '$latitude, $longitude';
      return LocationResult(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
    } catch (e) {
      return LocationResult(
        latitude: latitude,
        longitude: longitude,
        address: '$latitude, $longitude',
      );
    }
  }

  String _formatAddress(Placemark p) {
    final parts = <String>[
      if (p.street != null && p.street!.isNotEmpty) p.street!,
      if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
      if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
      if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
        p.administrativeArea!,
      if (p.country != null && p.country!.isNotEmpty) p.country!,
    ];
    return parts.join(', ');
  }
}
