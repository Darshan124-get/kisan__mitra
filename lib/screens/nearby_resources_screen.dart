import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kisan_mitra/screens/profile_screen.dart';
import 'package:kisan_mitra/screens/settings_screen.dart';
import 'package:kisan_mitra/providers/service_provider.dart';
import 'package:kisan_mitra/providers/location_provider.dart';
import 'package:kisan_mitra/models/service_model.dart';
import 'package:kisan_mitra/screens/service_detail_screen.dart';
import 'package:kisan_mitra/screens/booking_screen.dart';
import 'package:kisan_mitra/utils/distance_calculator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyResourcesScreen extends ConsumerStatefulWidget {
  const NearbyResourcesScreen({super.key});

  @override
  ConsumerState<NearbyResourcesScreen> createState() => _NearbyResourcesScreenState();
}

class _NearbyResourcesScreenState extends ConsumerState<NearbyResourcesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationAsync = ref.read(currentLocationProvider);
      locationAsync.whenData((position) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: const Text('Nearby Resources'),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Labor',
            ),
            Tab(
              icon: Icon(Icons.agriculture),
              text: 'Tractors',
            ),
            Tab(
              icon: Icon(Icons.map),
              text: 'Map',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Labor Tab - Fetch from API
          _WorkerServicesTab(serviceType: 'worker_individual'),
          // Tractors Tab - Show all equipment services (tractor, cultivator, other, excluding workers)
          _TractorServicesTab(),
          // Map Tab
          _ServicesMapTab(currentLocation: _currentLocation),
        ],
      ),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.agriculture,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Kisan Mitra',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}

class _WorkerServicesTab extends ConsumerStatefulWidget {
  final String serviceType;

  const _WorkerServicesTab({required this.serviceType});

  @override
  ConsumerState<_WorkerServicesTab> createState() => _WorkerServicesTabState();
}

class _WorkerServicesTabState extends ConsumerState<_WorkerServicesTab> {
  bool _useDefaultLocation = false;
  double _defaultLat = 28.6139; // Delhi
  double _defaultLon = 77.2090;
  
  // Cache params to avoid recreating on every build
  late final AllServicesParams _params = AllServicesParams(
    serviceType: widget.serviceType,
    limit: 100,
  );

  Widget _buildServicesList(List<Service> services, double lat, double lon) {
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No services found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No ${widget.serviceType == 'worker_individual' ? 'worker' : 'tractor'} services available at the moment',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(allServicesProvider);
                ref.invalidate(currentLocationProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate distance and sort by nearest first (for display purposes)
    final servicesWithDistance = services.map((service) {
      final distance = DistanceCalculator.calculateDistance(
        startLatitude: lat,
        startLongitude: lon,
        endLatitude: service.location.latitude,
        endLongitude: service.location.longitude,
      );
      return {'service': service, 'distance': distance};
    }).toList();

    servicesWithDistance.sort((a, b) => 
      (a['distance'] as double).compareTo(b['distance'] as double)
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allServicesProvider);
        ref.invalidate(currentLocationProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: servicesWithDistance.length,
        itemBuilder: (context, index) {
          final item = servicesWithDistance[index];
          final service = item['service'] as Service;
          final distance = item['distance'] as double;
          return _ServiceCard(
            service: service,
            currentLatitude: lat,
            currentLongitude: lon,
            distance: distance,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fetch ALL services immediately (no need to wait for location)
    final servicesAsync = ref.watch(allServicesProvider(_params));
    
    // Get location for distance calculation (optional, doesn't block service fetching)
    final locationAsync = ref.watch(currentLocationProvider);
    
    return servicesAsync.when(
      data: (services) {
        // Get location for distance calculation
        return locationAsync.when(
          data: (position) {
            // Use default location if position is invalid or if user chose to use default
            final lat = _useDefaultLocation 
                ? _defaultLat 
                : (position.latitude.isFinite ? position.latitude : _defaultLat);
            final lon = _useDefaultLocation 
                ? _defaultLon 
                : (position.longitude.isFinite ? position.longitude : _defaultLon);
            return _buildServicesList(services, lat, lon);
          },
          loading: () => _buildServicesList(services, _defaultLat, _defaultLon),
          error: (error, stack) => _buildServicesList(services, _defaultLat, _defaultLon),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading all services...'),
            SizedBox(height: 8),
            Text(
              'Fetching from server',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      error: (error, stack) {
        print('Error in Worker services list: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Error loading services: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure the backend server is running on port 3000',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(allServicesProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TractorServicesTab extends ConsumerStatefulWidget {
  const _TractorServicesTab();

  @override
  ConsumerState<_TractorServicesTab> createState() => _TractorServicesTabState();
}

class _TractorServicesTabState extends ConsumerState<_TractorServicesTab> {
  bool _useDefaultLocation = false;
  double _defaultLat = 28.6139; // Delhi
  double _defaultLon = 77.2090;
  
  // Cache params to avoid recreating on every build
  // Fetch all services, then filter out workers on client side
  late final AllServicesParams _params = AllServicesParams(
    serviceType: null, // Fetch all services
    limit: 100,
  );
  
  // Filter out worker services - show only equipment services (tractor, cultivator, other)
  List<Service> _filterEquipmentServices(List<Service> allServices) {
    return allServices.where((service) {
      final type = service.serviceType.toString();
      return type != 'worker_individual' && type != 'worker_group';
    }).toList();
  }

  Widget _buildServicesList(List<Service> services, double lat, double lon) {
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No services found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No equipment services (tractor, cultivator, etc.) available at the moment',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(allServicesProvider);
                ref.invalidate(currentLocationProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate distance and sort by nearest first (for display purposes)
    final servicesWithDistance = services.map((service) {
      final distance = DistanceCalculator.calculateDistance(
        startLatitude: lat,
        startLongitude: lon,
        endLatitude: service.location.latitude,
        endLongitude: service.location.longitude,
      );
      return {'service': service, 'distance': distance};
    }).toList();

    servicesWithDistance.sort((a, b) => 
      (a['distance'] as double).compareTo(b['distance'] as double)
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allServicesProvider);
        ref.invalidate(currentLocationProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: servicesWithDistance.length,
        itemBuilder: (context, index) {
          final item = servicesWithDistance[index];
          final service = item['service'] as Service;
          final distance = item['distance'] as double;
          return _ServiceCard(
            service: service,
            currentLatitude: lat,
            currentLongitude: lon,
            distance: distance,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fetch ALL services immediately (no need to wait for location)
    final servicesAsync = ref.watch(allServicesProvider(_params));
    
    // Get location for distance calculation (optional, doesn't block service fetching)
    final locationAsync = ref.watch(currentLocationProvider);
    
    return servicesAsync.when(
      data: (allServices) {
        // Filter out worker services - show only equipment services
        final services = _filterEquipmentServices(allServices);
        
        // Get location for distance calculation
        return locationAsync.when(
          data: (position) {
            // Use default location if position is invalid or if user chose to use default
            final lat = _useDefaultLocation 
                ? _defaultLat 
                : (position.latitude.isFinite ? position.latitude : _defaultLat);
            final lon = _useDefaultLocation 
                ? _defaultLon 
                : (position.longitude.isFinite ? position.longitude : _defaultLon);
            return _buildServicesList(services, lat, lon);
          },
          loading: () => _buildServicesList(services, _defaultLat, _defaultLon),
          error: (error, stack) => _buildServicesList(services, _defaultLat, _defaultLon),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading all services...'),
            SizedBox(height: 8),
            Text(
              'Fetching from server',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      error: (error, stack) {
        print('Error in Tractor services list: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Error loading services: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure the backend server is running on port 3000',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(allServicesProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ServicesMapTab extends ConsumerWidget {
  final LatLng? currentLocation;

  const _ServicesMapTab({this.currentLocation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(currentLocationProvider);
    
    return locationAsync.when(
      data: (position) {
        final servicesAsync = ref.watch(nearbyServicesProvider(NearbyServicesParams(
          latitude: position.latitude,
          longitude: position.longitude,
          radius: 20,
        )));

        return servicesAsync.when(
          data: (services) {
            final markers = <MarkerId, Marker>{};
            
            // Add current location marker
            markers[const MarkerId('current_location')] = Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(position.latitude, position.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              infoWindow: const InfoWindow(title: 'Your Location'),
            );

            // Add service markers
            for (var i = 0; i < services.length; i++) {
              final service = services[i];
              final distance = DistanceCalculator.calculateDistance(
                startLatitude: position.latitude,
                startLongitude: position.longitude,
                endLatitude: service.location.latitude,
                endLongitude: service.location.longitude,
              );
              
              String snippet = '₹${service.pricePerHour}/hour';
              if (service.laborerName != null) {
                snippet += ' • ${service.laborerName}';
              }
              if (service.laborerPhone != null) {
                snippet += '\n📞 ${service.laborerPhone}';
              }
              snippet += '\n📍 ${DistanceCalculator.formatDistance(distance)} away';
              
              markers[MarkerId('service_$i')] = Marker(
                markerId: MarkerId('service_$i'),
                position: LatLng(
                  service.location.latitude,
                  service.location.longitude,
                ),
                infoWindow: InfoWindow(
                  title: service.title,
                  snippet: snippet,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailScreen(serviceId: service.id!),
                    ),
                  );
                },
              );
            }

            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 12,
              ),
              markers: markers.values.toSet(),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? distance;

  const _ServiceCard({
    required this.service,
    this.currentLatitude,
    this.currentLongitude,
    this.distance,
  });

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    // Format phone number - add country code if missing
    String formattedNumber = phoneNumber.trim();
    if (!formattedNumber.startsWith('+')) {
      // Assume Indian number if no country code
      if (!formattedNumber.startsWith('91')) {
        formattedNumber = '91$formattedNumber';
      }
      formattedNumber = '+$formattedNumber';
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: formattedNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch phone dialer')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(serviceId: service.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(12),
                bottom: service.images.isEmpty ? const Radius.circular(12) : Radius.zero,
              ),
              child: service.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: service.images.first,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 64),
                      ),
                    )
                  : Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No Image',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (service.laborerName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'By ${service.laborerName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(' ${service.rating > 0 ? service.rating.toStringAsFixed(1) : 'N/A'}'),
                      const SizedBox(width: 16),
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      Expanded(
                        child: Text(
                          ' ${service.location.address ?? 'Unknown'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.navigation, size: 16, color: Colors.green),
                        Text(
                          ' ${DistanceCalculator.formatDistance(distance!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${service.pricePerHour}/hour',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (service.laborerPhone != null)
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () => _makePhoneCall(service.laborerPhone!, context),
                          tooltip: 'Call ${service.laborerName ?? 'Laborer'}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Action buttons row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makePhoneCall(
                            service.laborerPhone ?? '',
                            context,
                          ),
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingScreen(service: service),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text('Book Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 