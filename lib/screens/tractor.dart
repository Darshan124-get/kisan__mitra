import 'package:flutter/material.dart';

class TractorWork {
  final String id;
  final String name;
  final String imageUrl;
  final String ownerName;
  final String ownerPhone;
  final String location;
  final double pricePerHour;
  final List<String> services;
  final String description;
  final double rating;
  final int reviews;
  final String modelYear;
  final String enginePower;
  final String fuelType;
  final String transmission;
  final List<String> features;
  final String maintenanceStatus;
  final String lastServiceDate;

  const TractorWork({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.ownerName,
    required this.ownerPhone,
    required this.location,
    required this.pricePerHour,
    required this.services,
    required this.description,
    required this.rating,
    required this.reviews,
    required this.modelYear,
    required this.enginePower,
    required this.fuelType,
    required this.transmission,
    required this.features,
    required this.maintenanceStatus,
    required this.lastServiceDate,
  });
}

class TractorListPage extends StatefulWidget {
  const TractorListPage({super.key});

  static const List<TractorWork> tractors = [
    TractorWork(
      id: '1',
      name: 'John Deere 5075E',
      imageUrl: 'data:image/jpeg;base64,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',
      ownerName: 'Rajesh Kumar',
      ownerPhone: '+91 98765 43210',
      location: 'Village: Ramgarh, District: Jaipur',
      pricePerHour: 1200,
      services: ['Ploughing', 'Tilling', 'Seeding', 'Harvesting'],
      description: 'Well-maintained John Deere tractor with experienced operator. Available for all types of farming operations.',
      rating: 4.5,
      reviews: 28,
      modelYear: '2020',
      enginePower: '75 HP',
      fuelType: 'Diesel',
      transmission: 'Manual',
      features: ['Power Steering', 'Air Conditioning', 'Digital Display', 'GPS Navigation'],
      maintenanceStatus: 'Excellent',
      lastServiceDate: '2024-02-15',
    ),
    TractorWork(
      id: '2',
      name: 'Mahindra 575 DI',
      imageUrl: 'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=500',
      ownerName: 'Suresh Patel',
      ownerPhone: '+91 98765 43211',
      location: 'Village: Devgarh, District: Udaipur',
      pricePerHour: 1000,
      services: ['Ploughing', 'Tilling', 'Transport'],
      description: 'Powerful Mahindra tractor with modern implements. Specialized in deep ploughing and tilling.',
      rating: 4.2,
      reviews: 15,
      modelYear: '2019',
      enginePower: '65 HP',
      fuelType: 'Diesel',
      transmission: 'Manual',
      features: ['Power Steering', 'Digital Display', 'Heavy Duty Tires'],
      maintenanceStatus: 'Good',
      lastServiceDate: '2024-01-20',
    ),
    TractorWork(
      id: '3',
      name: 'Swaraj 744 FE',
      imageUrl: 'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=500',
      ownerName: 'Mohan Singh',
      ownerPhone: '+91 98765 43212',
      location: 'Village: Kheda, District: Ahmedabad',
      pricePerHour: 900,
      services: ['Ploughing', 'Seeding', 'Spraying'],
      description: 'Fuel-efficient Swaraj tractor perfect for small to medium-sized farms.',
      rating: 4.7,
      reviews: 32,
      modelYear: '2021',
      enginePower: '55 HP',
      fuelType: 'Diesel',
      transmission: 'Manual',
      features: ['Power Steering', 'Digital Display', 'Eco Mode'],
      maintenanceStatus: 'Excellent',
      lastServiceDate: '2024-03-01',
    ),
  ];

  @override
  State<TractorListPage> createState() => _TractorListPageState();
}

class _TractorListPageState extends State<TractorListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<TractorWork> _searchResults = [];

  // Filter states
  RangeValues _priceRange = const RangeValues(800, 2000);
  List<String> _selectedServices = [];
  List<String> _selectedFeatures = [];
  bool _showOnlyRated = false;

  // Filter options (from all tractors)
  List<String> get _allServices => TractorListPage.tractors
      .expand((t) => t.services)
      .toSet()
      .toList();
  List<String> get _allFeatures => TractorListPage.tractors
      .expand((t) => t.features)
      .toSet()
      .toList();

  List<TractorWork> get filteredTractors {
    return TractorListPage.tractors.where((tractor) {
      // Price range filter
      if (tractor.pricePerHour < _priceRange.start || tractor.pricePerHour > _priceRange.end) return false;
      // Services filter
      if (_selectedServices.isNotEmpty && !_selectedServices.any((s) => tractor.services.contains(s))) return false;
      // Features filter
      if (_selectedFeatures.isNotEmpty && !_selectedFeatures.any((f) => tractor.features.contains(f))) return false;
      // Rating filter
      if (_showOnlyRated && tractor.rating < 4.0) return false;
      return true;
    }).toList();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    final results = filteredTractors.where((tractor) {
      final name = tractor.name.toLowerCase();
      final owner = tractor.ownerName.toLowerCase();
      final services = tractor.services.map((s) => s.toLowerCase()).toList();
      final features = tractor.features.map((f) => f.toLowerCase()).toList();
      final searchQuery = query.toLowerCase();
      return name.contains(searchQuery) ||
          owner.contains(searchQuery) ||
          services.any((s) => s.contains(searchQuery)) ||
          features.any((f) => f.contains(searchQuery));
    }).toList();
    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Tractors',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Range
                      const Text('Price Range (₹/hour)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text('Min: ₹${_priceRange.start.round()}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text('Max: ₹${_priceRange.end.round()}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RangeSlider(
                        values: _priceRange,
                        min: 800,
                        max: 2000,
                        divisions: 12,
                        activeColor: Colors.green,
                        inactiveColor: Colors.green.shade100,
                        labels: RangeLabels('₹${_priceRange.start.round()}', '₹${_priceRange.end.round()}'),
                        onChanged: (values) {
                          setState(() {
                            _priceRange = values;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Services
                      const Text('Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 8,
                        children: _allServices.map((service) {
                          final isSelected = _selectedServices.contains(service);
                          return FilterChip(
                            label: Text(service),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedServices.add(service);
                                } else {
                                  _selectedServices.remove(service);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Features
                      const Text('Features', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 8,
                        children: _allFeatures.map((feature) {
                          final isSelected = _selectedFeatures.contains(feature);
                          return FilterChip(
                            label: Text(feature),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedFeatures.add(feature);
                                } else {
                                  _selectedFeatures.remove(feature);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Rating
                      SwitchListTile(
                        title: const Text('Show Only Highly Rated (4.0+)'),
                        value: _showOnlyRated,
                        onChanged: (value) {
                          setState(() {
                            _showOnlyRated = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _priceRange = const RangeValues(800, 2000);
                          _selectedServices = [];
                          _selectedFeatures = [];
                          _showOnlyRated = false;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        this.setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Tractors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _isSearching
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search tractors...',
                            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                                setState(() {
                                  _isSearching = false;
                                });
                              },
                            ),
                          ),
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          onChanged: _performSearch,
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          Expanded(
            child: _isSearching
                ? _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No tractors found', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          ..._searchResults.map((tractor) => TractorCard(tractor: tractor)),
                        ],
                      )
                : filteredTractors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.agriculture, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No tractors found', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          ...filteredTractors.map((tractor) => TractorCard(tractor: tractor)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class TractorCard extends StatelessWidget {
  final TractorWork tractor;

  const TractorCard({super.key, required this.tractor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TractorDetailPage(tractor: tractor),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tractor Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  tractor.imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.agriculture, size: 60),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Tractor Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tractor.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Owner: ${tractor.ownerName}',
                      style: const TextStyle(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        Text(
                          ' ${tractor.rating} (${tractor.reviews} reviews)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${tractor.pricePerHour}/hour',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip('${tractor.enginePower}', Icons.speed),
                        _buildInfoChip(tractor.modelYear, Icons.calendar_today),
                        _buildInfoChip(tractor.fuelType, Icons.local_gas_station),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class TractorDetailPage extends StatelessWidget {
  final TractorWork tractor;

  const TractorDetailPage({super.key, required this.tractor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tractor.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tractor Image
            Stack(
              children: [
                Image.network(
                  tractor.imageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${tractor.rating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Text(
                    '₹${tractor.pricePerHour}/hour',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Specifications
                  const Text(
                    'Specifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSpecificationGrid(),
                  const SizedBox(height: 16),
                  // Owner Details
                  const Text(
                    'Owner Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Name', tractor.ownerName),
                  _buildDetailRow('Phone', tractor.ownerPhone),
                  _buildDetailRow('Location', tractor.location),
                  const SizedBox(height: 16),
                  // Services
                  const Text(
                    'Available Services',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tractor.services.map((service) {
                      return Chip(
                        label: Text(service),
                        backgroundColor: Colors.green.shade100,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Features
                  const Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tractor.features.map((feature) {
                      return Chip(
                        label: Text(feature),
                        backgroundColor: Colors.blue.shade100,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Maintenance
                  const Text(
                    'Maintenance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Status', tractor.maintenanceStatus),
                  _buildDetailRow('Last Service', tractor.lastServiceDate),
                  const SizedBox(height: 16),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tractor.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  // Book Now Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement booking functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking functionality coming soon!'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildSpecificationItem('Model Year', tractor.modelYear, Icons.calendar_today),
        _buildSpecificationItem('Engine Power', tractor.enginePower, Icons.speed),
        _buildSpecificationItem('Fuel Type', tractor.fuelType, Icons.local_gas_station),
        _buildSpecificationItem('Transmission', tractor.transmission, Icons.settings),
      ],
    );
  }

  Widget _buildSpecificationItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
} 