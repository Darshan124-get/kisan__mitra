import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';
import '../services/service_api.dart';

final serviceApiProvider = Provider<ServiceApi>((ref) => ServiceApi());

// Provider for all services (public)
final serviceListProvider = FutureProvider<List<Service>>((ref) async {
  final api = ref.read(serviceApiProvider);
  return await api.getAllServices();
});

// Provider for laborer's own services
final myServicesProvider = FutureProvider<List<Service>>((ref) async {
  final api = ref.read(serviceApiProvider);
  return await api.getMyServices();
});

// Provider for a single service by ID
final serviceProvider = FutureProvider.family<Service, String>((ref, serviceId) async {
  final api = ref.read(serviceApiProvider);
  return await api.getService(serviceId);
});

// Provider for all services filtered by type (no radius limit)
final allServicesProvider = FutureProvider.family<List<Service>, AllServicesParams>(
  (ref, params) async {
    final api = ref.read(serviceApiProvider);
    return await api.getAllServices(
      serviceType: params.serviceType,
      isAvailable: true,
      limit: params.limit,
    );
  },
);

class AllServicesParams {
  final String? serviceType;
  final int limit;

  AllServicesParams({
    this.serviceType,
    this.limit = 100, // Higher limit to show more services
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AllServicesParams &&
        other.serviceType == serviceType &&
        other.limit == limit;
  }

  @override
  int get hashCode => (serviceType?.hashCode ?? 0) ^ limit.hashCode;
}

// Provider for nearby services
final nearbyServicesProvider = FutureProvider.family<List<Service>, NearbyServicesParams>(
  (ref, params) async {
    final api = ref.read(serviceApiProvider);
    return await api.getNearbyServices(
      latitude: params.latitude,
      longitude: params.longitude,
      radius: params.radius,
      serviceType: params.serviceType,
      limit: params.limit,
    );
  },
);

class NearbyServicesParams {
  final double latitude;
  final double longitude;
  final double radius;
  final String? serviceType;
  final int limit;

  NearbyServicesParams({
    required this.latitude,
    required this.longitude,
    this.radius = 10,
    this.serviceType,
    this.limit = 20,
  });
}

// StateNotifier for service CRUD operations
class ServiceNotifier extends StateNotifier<AsyncValue<List<Service>>> {
  final ServiceApi _api;

  ServiceNotifier(this._api) : super(const AsyncValue.loading()) {
    _loadServices(showLoading: true);
  }

  Future<void> _loadServices({bool showLoading = false}) async {
    try {
      // Only show loading if explicitly requested (e.g., on initial load or manual refresh)
      if (showLoading) {
        state = const AsyncValue.loading();
      }
      final services = await _api.getMyServices();
      state = AsyncValue.data(services);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createService({
    required ServiceType serviceType,
    required String title,
    required String description,
    required double pricePerHour,
    double? pricePerDay,
    required ServiceLocation location,
    required ServiceAvailability availability,
    required List<String> images,
    required ServiceSpecifications specifications,
  }) async {
    try {
      await _api.createService(
        serviceType: serviceType,
        title: title,
        description: description,
        pricePerHour: pricePerHour,
        pricePerDay: pricePerDay,
        location: location,
        availability: availability,
        images: images,
        specifications: specifications,
      );
      // Refresh list without showing loading state
      await _loadServices(showLoading: false);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateService({
    required String serviceId,
    String? title,
    String? description,
    double? pricePerHour,
    double? pricePerDay,
    ServiceLocation? location,
    ServiceAvailability? availability,
    List<String>? images,
    ServiceSpecifications? specifications,
    ServiceStatus? status,
  }) async {
    try {
      await _api.updateService(
        serviceId: serviceId,
        title: title,
        description: description,
        pricePerHour: pricePerHour,
        pricePerDay: pricePerDay,
        location: location,
        availability: availability,
        images: images,
        specifications: specifications,
        status: status,
      );
      // Refresh list without showing loading state
      await _loadServices(showLoading: false);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _api.deleteService(serviceId);
      // Refresh list without showing loading state
      await _loadServices(showLoading: false);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAvailability({
    required String serviceId,
    bool? isAvailable,
    List<DaySchedule>? schedule,
    List<DateTime>? unavailableDates,
  }) async {
    try {
      await _api.updateAvailability(
        serviceId: serviceId,
        isAvailable: isAvailable,
        schedule: schedule,
        unavailableDates: unavailableDates,
      );
      // Refresh list without showing loading state
      await _loadServices(showLoading: false);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() => _loadServices(showLoading: true);
}

final serviceNotifierProvider = StateNotifierProvider<ServiceNotifier, AsyncValue<List<Service>>>((ref) {
  final api = ref.read(serviceApiProvider);
  return ServiceNotifier(api);
});

