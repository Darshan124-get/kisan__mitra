import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/service_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/service_model.dart';
import '../../services/location_service.dart';
import '../../services/api_config.dart';

class AddEditServiceScreen extends ConsumerStatefulWidget {
  final String? serviceId;

  const AddEditServiceScreen({super.key, this.serviceId});

  @override
  ConsumerState<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends ConsumerState<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pricePerHourController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _addressController = TextEditingController();

  ServiceType _selectedServiceType = ServiceType.tractor;
  ServiceLocation? _location;
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(28.6139, 77.2090); // Default to Delhi
  List<String> _images = [];
  final ImagePicker _imagePicker = ImagePicker();

  // Specifications
  final _modelYearController = TextEditingController();
  final _enginePowerController = TextEditingController();
  String? _fuelType;
  String? _transmission;
  final List<String> _features = [];
  String? _maintenanceStatus;
  final _experienceController = TextEditingController();
  final List<String> _skills = [];
  int? _teamSize;
  final List<TeamMember> _teamMembers = [];

  // Availability
  final Map<String, DaySchedule> _schedule = {};
  final List<DateTime> _unavailableDates = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSchedule();
    _checkAuthToken();
    if (widget.serviceId != null) {
      _loadService();
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _checkAuthToken() async {
    final token = await ApiConfig.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showLoginRequiredDialog();
        });
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('You need to login first to create or edit services. Redirecting to login screen...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  void _initializeSchedule() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    for (var day in days) {
      _schedule[day] = DaySchedule(day: day, isAvailable: false);
    }
  }

  Future<void> _loadService() async {
    if (widget.serviceId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final service = await ref.read(serviceProvider(widget.serviceId!).future);
      _titleController.text = service.title;
      _descriptionController.text = service.description;
      _pricePerHourController.text = service.pricePerHour.toString();
      if (service.pricePerDay != null) {
        _pricePerDayController.text = service.pricePerDay.toString();
      }
      _selectedServiceType = service.serviceType;
      _location = service.location;
      _selectedLocation = LatLng(service.location.latitude, service.location.longitude);
      _addressController.text = service.location.address ?? '';
      _images = service.images;

      // Load specifications
      final specs = service.specifications;
      _modelYearController.text = specs.modelYear ?? '';
      _enginePowerController.text = specs.enginePower ?? '';
      _fuelType = specs.fuelType;
      _transmission = specs.transmission;
      _features.addAll(specs.features);
      _maintenanceStatus = specs.maintenanceStatus;
      _experienceController.text = specs.experience ?? '';
      _skills.addAll(specs.skills);
      _teamSize = specs.teamSize;
      _teamMembers.addAll(specs.teamMembers);

      // Load availability
      _schedule.clear();
      for (var daySchedule in service.availability.schedule) {
        _schedule[daySchedule.day] = daySchedule;
      }
      _unavailableDates.addAll(service.availability.unavailableDates);

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading service: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _location = ServiceLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });
      _getAddressFromLocation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _getAddressFromLocation() async {
    try {
      final locationService = LocationService();
      final address = await locationService.getAddressFromCoordinates(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );
      setState(() {
        _addressController.text = address;
        if (_location != null) {
          _location = ServiceLocation(
            latitude: _location!.latitude,
            longitude: _location!.longitude,
            address: address,
          );
        }
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _pickImage() async {
    // Show dialog to choose between camera and gallery
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    // Request permissions based on source
    bool hasPermission = false;
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      hasPermission = status.isGranted;
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to take photos.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        return;
      }
    } else {
      // For gallery, check storage permission
      if (Platform.isAndroid) {
        // Android 13+ uses READ_MEDIA_IMAGES, older versions use READ_EXTERNAL_STORAGE
        final androidInfo = await Permission.photos.status;
        if (androidInfo.isDenied) {
          final status = await Permission.photos.request();
          hasPermission = status.isGranted;
        } else {
          hasPermission = androidInfo.isGranted;
        }
      } else {
        // iOS uses photos permission
        final status = await Permission.photos.request();
        hasPermission = status.isGranted;
      }
      
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission is required to select images.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        return;
      }
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        setState(() {
          _images.add(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error picking image';
        if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please allow camera/gallery access in settings.';
        } else if (e.toString().contains('camera')) {
          errorMessage = 'Camera not available or error accessing camera.';
        } else {
          errorMessage = 'Error picking image: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    // Check token before saving
    final token = await ApiConfig.getToken();
    if (token == null || token.isEmpty) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(serviceNotifierProvider.notifier);

      final availability = ServiceAvailability(
        isAvailable: true,
        schedule: _schedule.values.toList(),
        unavailableDates: _unavailableDates,
      );

      final specifications = ServiceSpecifications(
        modelYear: _modelYearController.text.isEmpty ? null : _modelYearController.text,
        enginePower: _enginePowerController.text.isEmpty ? null : _enginePowerController.text,
        fuelType: _fuelType,
        transmission: _transmission,
        features: _features,
        maintenanceStatus: _maintenanceStatus,
        experience: _experienceController.text.isEmpty ? null : _experienceController.text,
        skills: _skills,
        teamSize: _teamSize,
        teamMembers: _teamMembers,
      );

      if (widget.serviceId != null) {
        await notifier.updateService(
          serviceId: widget.serviceId!,
          title: _titleController.text,
          description: _descriptionController.text,
          pricePerHour: double.parse(_pricePerHourController.text),
          pricePerDay: _pricePerDayController.text.isNotEmpty
              ? double.parse(_pricePerDayController.text)
              : null,
          location: _location,
          availability: availability,
          images: _images,
          specifications: specifications,
        );
      } else {
        await notifier.createService(
          serviceType: _selectedServiceType,
          title: _titleController.text,
          description: _descriptionController.text,
          pricePerHour: double.parse(_pricePerHourController.text),
          pricePerDay: _pricePerDayController.text.isNotEmpty
              ? double.parse(_pricePerDayController.text)
              : null,
          location: _location!,
          availability: availability,
          images: _images,
          specifications: specifications,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.serviceId != null
                ? 'Service updated successfully'
                : 'Service created successfully'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // Check if it's an authentication error
        if (errorMessage.contains('No authentication token') || 
            errorMessage.contains('Authentication failed') ||
            errorMessage.contains('401')) {
          _showLoginRequiredDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pricePerHourController.dispose();
    _pricePerDayController.dispose();
    _addressController.dispose();
    _modelYearController.dispose();
    _enginePowerController.dispose();
    _experienceController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && widget.serviceId != null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceId != null ? 'Edit Service' : 'Add Service'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveService,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Service Type
            _buildServiceTypeSelector(),
            const SizedBox(height: 16),
            // Basic Info
            _buildBasicInfoSection(),
            const SizedBox(height: 16),
            // Images
            _buildImagesSection(),
            const SizedBox(height: 16),
            // Location
            _buildLocationSection(),
            const SizedBox(height: 16),
            // Specifications
            _buildSpecificationsSection(),
            const SizedBox(height: 16),
            // Availability Schedule
            _buildAvailabilitySection(),
            const SizedBox(height: 32),
            // Save Button
            ElevatedButton(
              onPressed: _saveService,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Save Service',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ServiceType>(
          value: _selectedServiceType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: ServiceType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedServiceType = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pricePerHourController,
                decoration: const InputDecoration(
                  labelText: 'Price Per Hour (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _pricePerDayController,
                decoration: const InputDecoration(
                  labelText: 'Price Per Day (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _images.length + 1,
          itemBuilder: (context, index) {
            if (index == _images.length) {
              return InkWell(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_photo_alternate),
                ),
              );
            }

            final image = _images[index];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image.startsWith('http')
                      ? Image.network(image, fit: BoxFit.cover)
                      : Image.file(File(image), fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
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
                    _location = ServiceLocation(
                      latitude: position.latitude,
                      longitude: position.longitude,
                      address: _addressController.text,
                    );
                  });
                  _getAddressFromLocation();
                },
              ),
            },
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: (LatLng position) {
              setState(() {
                _selectedLocation = position;
                _location = ServiceLocation(
                  latitude: position.latitude,
                  longitude: position.longitude,
                  address: _addressController.text,
                );
              });
              _getAddressFromLocation();
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
              tooltip: 'Use Current Location',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecificationsSection() {
    if (_selectedServiceType == ServiceType.tractor ||
        _selectedServiceType == ServiceType.cultivator) {
      return _buildTractorSpecifications();
    } else if (_selectedServiceType == ServiceType.workerIndividual ||
        _selectedServiceType == ServiceType.workerGroup) {
      return _buildWorkerSpecifications();
    }
    return const SizedBox.shrink();
  }

  Widget _buildTractorSpecifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _modelYearController,
          decoration: const InputDecoration(
            labelText: 'Model Year',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _enginePowerController,
          decoration: const InputDecoration(
            labelText: 'Engine Power',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _fuelType,
          decoration: const InputDecoration(
            labelText: 'Fuel Type',
            border: OutlineInputBorder(),
          ),
          items: ['Diesel', 'Petrol', 'Electric', 'Other']
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) => setState(() => _fuelType = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _transmission,
          decoration: const InputDecoration(
            labelText: 'Transmission',
            border: OutlineInputBorder(),
          ),
          items: ['Manual', 'Automatic', 'Semi-Automatic']
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) => setState(() => _transmission = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _maintenanceStatus,
          decoration: const InputDecoration(
            labelText: 'Maintenance Status',
            border: OutlineInputBorder(),
          ),
          items: ['Excellent', 'Good', 'Fair', 'Poor']
              .map((status) => DropdownMenuItem(value: status, child: Text(status)))
              .toList(),
          onChanged: (value) => setState(() => _maintenanceStatus = value),
        ),
        const SizedBox(height: 12),
        const Text('Features'),
        Wrap(
          spacing: 8,
          children: [
            'Power Steering',
            'Air Conditioning',
            'GPS Navigation',
            'Digital Display',
            'Heavy Duty Tires',
          ].map((feature) {
            final isSelected = _features.contains(feature);
            return FilterChip(
              label: Text(feature),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _features.add(feature);
                  } else {
                    _features.remove(feature);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWorkerSpecifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _experienceController,
          decoration: const InputDecoration(
            labelText: 'Experience',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Skills'),
        Wrap(
          spacing: 8,
          children: [
            'Weeding',
            'Harvesting',
            'Planting',
            'Irrigation',
            'Fertilizing',
            'Pesticide Application',
          ].map((skill) {
            final isSelected = _skills.contains(skill);
            return FilterChip(
              label: Text(skill),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _skills.add(skill);
                  } else {
                    _skills.remove(skill);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_selectedServiceType == ServiceType.workerGroup) ...[
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Team Size',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _teamSize = int.tryParse(value);
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Team Members'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  _showAddTeamMemberDialog();
                },
              ),
            ],
          ),
          ..._teamMembers.asMap().entries.map((entry) {
            return ListTile(
              title: Text(entry.value.name),
              subtitle: Text(entry.value.role),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _teamMembers.removeAt(entry.key);
                  });
                },
              ),
            );
          }),
        ],
      ],
    );
  }

  void _showAddTeamMemberDialog() {
    final nameController = TextEditingController();
    final roleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Team Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _teamMembers.add(TeamMember(
                  name: nameController.text,
                  role: roleController.text,
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Availability Schedule',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
            .map((day) => _buildDaySchedule(day)),
      ],
    );
  }

  Widget _buildDaySchedule(String day) {
    final schedule = _schedule[day] ?? DaySchedule(day: day, isAvailable: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Switch(
              value: schedule.isAvailable,
              onChanged: (value) {
                setState(() {
                  _schedule[day] = DaySchedule(
                    day: day,
                    startTime: schedule.startTime,
                    endTime: schedule.endTime,
                    isAvailable: value,
                  );
                });
              },
            ),
            const SizedBox(width: 8),
            Text(day),
          ],
        ),
        children: schedule.isAvailable
            ? [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: schedule.startTime,
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            hintText: 'HH:MM',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _schedule[day] = DaySchedule(
                                day: day,
                                startTime: value,
                                endTime: schedule.endTime,
                                isAvailable: true,
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: schedule.endTime,
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            hintText: 'HH:MM',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _schedule[day] = DaySchedule(
                                day: day,
                                startTime: schedule.startTime,
                                endTime: value,
                                isAvailable: true,
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            : [],
      ),
    );
  }
}

