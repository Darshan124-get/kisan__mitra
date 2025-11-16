import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/location_provider.dart';
import '../../providers/service_provider.dart';
import '../../models/service_model.dart';
import '../../services/location_service.dart';

class LocationManagerScreen extends ConsumerStatefulWidget {
  final String? serviceId;

  const LocationManagerScreen({super.key, this.serviceId});

  @override
  ConsumerState<LocationManagerScreen> createState() => _LocationManagerScreenState();
}

class _LocationManagerScreenState extends ConsumerState<LocationManagerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(28.6139, 77.2090);
  bool _shareLocation = true;
  double _serviceRadius = 10.0; // in kilometers
  final List<ServiceLocation> _locationHistory = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    if (widget.serviceId != null) {
      _loadServiceLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 14),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _loadServiceLocation() async {
    if (widget.serviceId == null) return;
    try {
      final service = await ref.read(serviceProvider(widget.serviceId!).future);
      setState(() {
        _selectedLocation = LatLng(
          service.location.latitude,
          service.location.longitude,
        );
        _locationHistory.add(service.location);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 14),
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _saveLocation() async {
    if (widget.serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No service selected')),
      );
      return;
    }

    try {
      final locationService = LocationService();
      final address = await locationService.getAddressFromCoordinates(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );

      final location = ServiceLocation(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        address: address,
      );

      final notifier = ref.read(serviceNotifierProvider.notifier);
      await notifier.updateLocation(
        serviceId: widget.serviceId!,
        location: location,
      );

      setState(() {
        _locationHistory.add(location);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Manager'),
        backgroundColor: Colors.green,
        actions: [
          if (widget.serviceId != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveLocation,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation,
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('service_location'),
                  position: _selectedLocation,
                  draggable: true,
                  onDragEnd: (LatLng position) {
                    setState(() {
                      _selectedLocation = position;
                    });
                  },
                ),
                if (_shareLocation)
                  Circle(
                    circleId: const CircleId('service_radius'),
                    center: _selectedLocation,
                    radius: _serviceRadius * 1000, // Convert to meters
                    fillColor: Colors.blue.withOpacity(0.2),
                    strokeColor: Colors.blue,
                    strokeWidth: 2,
                  ),
              },
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: (LatLng position) {
                setState(() {
                  _selectedLocation = position;
                });
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Share Location'),
                    const Spacer(),
                    Switch(
                      value: _shareLocation,
                      onChanged: (value) {
                        setState(() => _shareLocation = value);
                      },
                    ),
                  ],
                ),
                if (_shareLocation) ...[
                  const SizedBox(height: 12),
                  const Text('Service Radius (km)'),
                  Slider(
                    value: _serviceRadius,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_serviceRadius.toStringAsFixed(0)} km',
                    onChanged: (value) {
                      setState(() => _serviceRadius = value);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Use Current Location'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.serviceId != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Save Location'),
                        ),
                      ),
                  ],
                ),
                if (_locationHistory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Location History',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _locationHistory.length,
                      itemBuilder: (context, index) {
                        final location = _locationHistory[index];
                        return Card(
                          margin: const EdgeInsets.only(right: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  location.address ?? 'Unknown',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedLocation = LatLng(
                                        location.latitude,
                                        location.longitude,
                                      );
                                    });
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLngZoom(_selectedLocation, 14),
                                    );
                                  },
                                  child: const Text('Use'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

