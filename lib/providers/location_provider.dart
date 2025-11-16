import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

// Provider for current location
final currentLocationProvider = FutureProvider<Position>((ref) async {
  final service = ref.read(locationServiceProvider);
  return await service.getCurrentLocation();
});

// StateNotifier for location updates
class LocationNotifier extends StateNotifier<AsyncValue<Position>> {
  final LocationService _service;

  LocationNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      state = const AsyncValue.loading();
      final position = await _service.getCurrentLocation();
      state = AsyncValue.data(position);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() => _loadCurrentLocation();

  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    return await _service.getAddressFromCoordinates(
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<Position?> getCoordinatesFromAddress(String address) async {
    return await _service.getCoordinatesFromAddress(address);
  }

  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return _service.calculateDistance(
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
    );
  }
}

final locationNotifierProvider = StateNotifierProvider<LocationNotifier, AsyncValue<Position>>((ref) {
  final service = ref.read(locationServiceProvider);
  return LocationNotifier(service);
});

