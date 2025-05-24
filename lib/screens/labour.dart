import 'package:flutter/material.dart';

class TractorAvailability extends ChangeNotifier {
  Map<String, bool> availability = {
    "Ploughing": true,
    "Tilling": true,
    "Seeding": true,
  };

  void setAvailability(String workName, bool isAvailable) {
    availability[workName] = isAvailable;
    notifyListeners();
  }

  bool isAvailable(String workName) {
    return availability[workName] ?? false;
  }
}

class WorkPricePage extends StatefulWidget {
  const WorkPricePage({super.key});

  @override
  State<WorkPricePage> createState() => _WorkPricePageState();
}

class _WorkPricePageState extends State<WorkPricePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showGroupWorkers = false;
  
  // Filter states
  RangeValues _priceRange = const RangeValues(500, 2000);
  List<String> _selectedWorkTypes = [];
  List<String> _selectedFieldWorks = [];
  bool _showOnlyAvailable = false;
  bool _showOnlyRated = false;

  // Filter options
  final List<String> _workTypes = [
    'Weeding',
    'Harvesting',
    'Planting',
    'Irrigation',
    'Fertilizing',
    'Pesticide Application'
  ];

  final List<String> _fieldWorks = [
    'Organic Farming',
    'Chemical Farming',
    'Mixed Farming',
    'Hydroponics',
    'Greenhouse'
  ];

  final List<Map<String, dynamic>> allWorkers = [
    // Single Workers
    {
      "name": "Aarav Kumar",
      "details": "Experienced Harvester",
      "imageUrl": "https://randomuser.me/api/portraits/men/31.jpg",
      "rating": 4.9,
      "reviews": 52,
      "experience": "7 years",
      "skills": ["Wheat Harvesting", "Corn Harvesting", "Machine Operation"],
      "availability": "Available Now",
      "distance": "1.2 km away",
      "workType": "Harvesting",
      "pricePerHour": 200,
      "isGroup": false,
      "contact": "+91 98765 43210"
    },
    {
      "name": "Priya Singh",
      "details": "Expert Planter",
      "imageUrl": "https://randomuser.me/api/portraits/women/44.jpg",
      "rating": 4.8,
      "reviews": 40,
      "experience": "5 years",
      "skills": ["Rice Planting", "Seedling Care", "Row Planting"],
      "availability": "Available in 2 hours",
      "distance": "2.5 km away",
      "workType": "Planting",
      "pricePerHour": 180,
      "isGroup": false,
      "contact": "+91 91234 56780"
    },
    {
      "name": "Rohan Patel",
      "details": "Irrigation Specialist",
      "imageUrl": "https://randomuser.me/api/portraits/men/54.jpg",
      "rating": 4.7,
      "reviews": 36,
      "experience": "6 years",
      "skills": ["Drip Irrigation", "Sprinkler Systems"],
      "availability": "Available Now",
      "distance": "3.0 km away",
      "workType": "Irrigation",
      "pricePerHour": 220,
      "isGroup": false,
      "contact": "+91 99887 66554"
    },
    {
      "name": "Sneha Verma",
      "details": "Fertilizer Expert",
      "imageUrl": "https://randomuser.me/api/portraits/women/68.jpg",
      "rating": 4.6,
      "reviews": 28,
      "experience": "4 years",
      "skills": ["Organic Fertilizer", "Soil Testing"],
      "availability": "Available in 1 day",
      "distance": "1.8 km away",
      "workType": "Fertilizing",
      "pricePerHour": 210,
      "isGroup": false,
      "contact": "+91 90909 12345"
    },
    {
      "name": "Vikas Sharma",
      "details": "Pesticide Applicator",
      "imageUrl": "https://randomuser.me/api/portraits/men/77.jpg",
      "rating": 4.5,
      "reviews": 22,
      "experience": "3 years",
      "skills": ["Safe Spraying", "Pest Identification"],
      "availability": "Available Now",
      "distance": "2.2 km away",
      "workType": "Pesticide Application",
      "pricePerHour": 190,
      "isGroup": false,
      "contact": "+91 90000 88888"
    },
    // Group Workers
    {
      "name": "Field Force",
      "details": "Expert Weeding Team",
      "imageUrl": "https://images.unsplash.com/photo-1464983953574-0892a716854b?w=500",
      "rating": 4.8,
      "reviews": 48,
      "experience": "6 years",
      "skills": ["Weeding", "Soil Preparation", "Team Coordination"],
      "availability": "Available Now",
      "distance": "2.0 km away",
      "workType": "Weeding",
      "pricePerHour": 780,
      "isGroup": true,
      "teamSize": 5,
      "contact": "+91 80000 11111",
      "teamMembers": [
        {"name": "Harish", "role": "Team Lead", "imageUrl": "https://randomuser.me/api/portraits/men/41.jpg"},
        {"name": "Sanjana", "role": "Weeder", "imageUrl": "https://randomuser.me/api/portraits/women/42.jpg"},
        {"name": "Ritesh", "role": "Soil Specialist", "imageUrl": "https://randomuser.me/api/portraits/men/43.jpg"},
        {"name": "Karthik", "role": "Logistics", "imageUrl": "https://randomuser.me/api/portraits/men/44.jpg"},
        {"name": "Divya", "role": "Quality Control", "imageUrl": "https://randomuser.me/api/portraits/women/45.jpg"}
      ]
    },
    {
      "name": "Crop Care Crew",
      "details": "Pesticide Application Team",
      "imageUrl": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500",
      "rating": 4.7,
      "reviews": 39,
      "experience": "7 years",
      "skills": ["Pesticide Application", "Safety", "Disease Management"],
      "availability": "Available in 3 hours",
      "distance": "2.7 km away",
      "workType": "Pesticide Application",
      "pricePerHour": 820,
      "isGroup": true,
      "teamSize": 5,
      "contact": "+91 80000 22222",
      "teamMembers": [
        {"name": "Asha", "role": "Team Lead", "imageUrl": "https://randomuser.me/api/portraits/women/51.jpg"},
        {"name": "Naveen", "role": "Sprayer", "imageUrl": "https://randomuser.me/api/portraits/men/52.jpg"},
        {"name": "Rupal", "role": "Safety Officer", "imageUrl": "https://randomuser.me/api/portraits/women/53.jpg"},
        {"name": "Girish", "role": "Disease Specialist", "imageUrl": "https://randomuser.me/api/portraits/men/54.jpg"},
        {"name": "Mehul", "role": "Logistics", "imageUrl": "https://randomuser.me/api/portraits/men/55.jpg"}
      ]
    },
    {
      "name": "Fertile Minds",
      "details": "Fertilizing & Soil Team",
      "imageUrl": "https://images.unsplash.com/photo-1519125323398-675f0ddb6308?w=500",
      "rating": 4.9,
      "reviews": 44,
      "experience": "8 years",
      "skills": ["Fertilizing", "Soil Testing", "Organic Methods"],
      "availability": "Available in 1 day",
      "distance": "3.3 km away",
      "workType": "Fertilizing",
      "pricePerHour": 860,
      "isGroup": true,
      "teamSize": 5,
      "contact": "+91 80000 33333",
      "teamMembers": [
        {"name": "Shalini", "role": "Team Lead", "imageUrl": "https://randomuser.me/api/portraits/women/61.jpg"},
        {"name": "Vimal", "role": "Fertilizer Expert", "imageUrl": "https://randomuser.me/api/portraits/men/62.jpg"},
        {"name": "Rina", "role": "Soil Analyst", "imageUrl": "https://randomuser.me/api/portraits/women/63.jpg"},
        {"name": "Prakash", "role": "Logistics", "imageUrl": "https://randomuser.me/api/portraits/men/64.jpg"},
        {"name": "Neha", "role": "Quality Control", "imageUrl": "https://randomuser.me/api/portraits/women/65.jpg"}
      ]
    },
    // Add three new group workers
    {
      "name": "Agro Titans",
      "details": "Harvesting and Ploughing Team",
      "imageUrl": "https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=500",
      "rating": 4.8,
      "reviews": 60,
      "experience": "8 years",
      "skills": ["Harvesting", "Ploughing", "Team Coordination"],
      "availability": "Available Now",
      "distance": "2.4 km away",
      "workType": "Harvesting",
      "pricePerHour": 950,
      "isGroup": true,
      "teamSize": 5,
      "contact": "+91 80000 44444",
      "teamMembers": [
        {"name": "Ramesh", "role": "Team Lead", "imageUrl": "https://randomuser.me/api/portraits/men/81.jpg"},
        {"name": "Sita", "role": "Harvester", "imageUrl": "https://randomuser.me/api/portraits/women/82.jpg"},
        {"name": "Ajay", "role": "Plough Operator", "imageUrl": "https://randomuser.me/api/portraits/men/83.jpg"},
        {"name": "Kiran", "role": "Logistics", "imageUrl": "https://randomuser.me/api/portraits/men/84.jpg"},
        {"name": "Meena", "role": "Quality Control", "imageUrl": "https://randomuser.me/api/portraits/women/85.jpg"}
      ]
    },
    {
      "name": "Green Sprouts",
      "details": "Planting and Irrigation Team",
      "imageUrl": "https://images.unsplash.com/photo-1519125323398-675f0ddb6308?w=500",
      "rating": 4.7,
      "reviews": 55,
      "experience": "7 years",
      "skills": ["Planting", "Irrigation", "Modern Techniques"],
      "availability": "Available in 2 hours",
      "distance": "3.1 km away",
      "workType": "Planting",
      "pricePerHour": 900,
      "isGroup": true,
      "teamSize": 5,
      "contact": "+91 80000 55555",
      "teamMembers": [
        {"name": "Sunil", "role": "Team Lead", "imageUrl": "https://randomuser.me/api/portraits/men/91.jpg"},
        {"name": "Pooja", "role": "Planter", "imageUrl": "https://randomuser.me/api/portraits/women/92.jpg"},
        {"name": "Vivek", "role": "Irrigation Specialist", "imageUrl": "https://randomuser.me/api/portraits/men/93.jpg"},
        {"name": "Neha", "role": "Logistics", "imageUrl": "https://randomuser.me/api/portraits/women/94.jpg"},
        {"name": "Amit", "role": "Quality Control", "imageUrl": "https://randomuser.me/api/portraits/men/95.jpg"}
      ]
    },
    {
      "name": "Fertile Crew",
      "details": "Fertilizing and Pesticide Team",
      "imageUrl": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500",
      "rating": 4.9,
      "reviews": 62,
      "experience": "9 years",
      "skills": ["Fertilizing", "Pesticide Application", "Soil Testing"],
      "availability": "Available in 1 day",
      "distance": "2.8 km away",
      "workType": "Fertilizing",
      "pricePerHour": 980,
      "isGroup": true,
      "teamSize": 5,
      "contact": "+91 80000 66666",
      "teamMembers": [
        {"name": "Anil", "role": "Team Lead", "imageUrl": "https://randomuser.me/api/portraits/men/101.jpg"},
        {"name": "Rina", "role": "Fertilizer Expert", "imageUrl": "https://randomuser.me/api/portraits/women/102.jpg"},
        {"name": "Gopal", "role": "Pesticide Specialist", "imageUrl": "https://randomuser.me/api/portraits/men/103.jpg"},
        {"name": "Divya", "role": "Logistics", "imageUrl": "https://randomuser.me/api/portraits/women/104.jpg"},
        {"name": "Raj", "role": "Quality Control", "imageUrl": "https://randomuser.me/api/portraits/men/105.jpg"}
      ]
    }
  ];

  List<Map<String, dynamic>> get filteredWorkers {
    return allWorkers.where((worker) {
      // Group/Single filter
      if (_showGroupWorkers && !worker['isGroup']) return false;
      if (!_showGroupWorkers && worker['isGroup']) return false;

      // Price range filter
      final price = (worker['pricePerHour'] as int) * 8;
      if (price < _priceRange.start || price > _priceRange.end) return false;

      // Work type filter
      if (_selectedWorkTypes.isNotEmpty) {
        if (!_selectedWorkTypes.contains(worker['workType'])) return false;
      }

      // Field work filter
      if (_selectedFieldWorks.isNotEmpty) {
        final skills = worker['skills'] as List<dynamic>;
        if (!_selectedFieldWorks.any((fieldWork) => 
            skills.any((skill) => skill.toString().toLowerCase().contains(fieldWork.toLowerCase())))) {
          return false;
        }
      }

      // Availability filter
      if (_showOnlyAvailable) {
        if (!worker['availability'].toString().toLowerCase().contains('available now')) {
          return false;
        }
      }

      // Rating filter
      if (_showOnlyRated) {
        if ((worker['rating'] as double) < 4.0) return false;
      }

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

    final results = filteredWorkers.where((worker) {
      final name = worker['name'].toString().toLowerCase();
      final details = worker['details'].toString().toLowerCase();
      final workType = worker['workType'].toString().toLowerCase();
      final skills = (worker['skills'] as List<dynamic>)
          .map((skill) => skill.toString().toLowerCase())
          .toList();
      
      final searchQuery = query.toLowerCase();
      
      return name.contains(searchQuery) ||
          details.contains(searchQuery) ||
          workType.contains(searchQuery) ||
          skills.any((skill) => skill.contains(searchQuery));
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
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Workers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                      const Text(
                        'Price Range (₹/day)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                            child: Text(
                              'Min: ₹${_priceRange.start.round()}/day',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'Max: ₹${_priceRange.end.round()}/day',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RangeSlider(
                        values: _priceRange,
                        min: 500,
                        max: 2000,
                        divisions: 17,
                        activeColor: Colors.green,
                        inactiveColor: Colors.green.shade100,
                        labels: RangeLabels(
                          '₹${_priceRange.start.round()}/day',
                          '₹${_priceRange.end.round()}/day',
                        ),
                        onChanged: (values) {
                          setState(() {
                            _priceRange = values;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Work Types
                      const Text(
                        'Work Types',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: _workTypes.map((type) {
                          final isSelected = _selectedWorkTypes.contains(type);
                          return FilterChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedWorkTypes.add(type);
                                } else {
                                  _selectedWorkTypes.remove(type);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Field Works
                      const Text(
                        'Field Works',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: _fieldWorks.map((work) {
                          final isSelected = _selectedFieldWorks.contains(work);
                          return FilterChip(
                            label: Text(work),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedFieldWorks.add(work);
                                } else {
                                  _selectedFieldWorks.remove(work);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Additional Filters
                      const Text(
                        'Additional Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Show Only Available Now'),
                        value: _showOnlyAvailable,
                        onChanged: (value) {
                          setState(() {
                            _showOnlyAvailable = value;
                          });
                        },
                      ),
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
                          _priceRange = const RangeValues(500, 2000);
                          _selectedWorkTypes = [];
                          _selectedFieldWorks = [];
                          _showOnlyAvailable = false;
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
                            hintText: 'Search workers...',
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
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Single'),
                            selected: !_showGroupWorkers,
                            onSelected: (selected) {
                              setState(() {
                                _showGroupWorkers = false;
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: Colors.green.shade200,
                            labelStyle: TextStyle(
                              color: _showGroupWorkers ? Colors.grey : Colors.green.shade800,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Team'),
                            selected: _showGroupWorkers,
                            onSelected: (selected) {
                              setState(() {
                                _showGroupWorkers = true;
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: Colors.green.shade200,
                            labelStyle: TextStyle(
                              color: _showGroupWorkers ? Colors.green.shade800 : Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search, size: 22, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _isSearching = true;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.filter_list, size: 22, color: Colors.grey),
                            onPressed: _showFilterDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          Expanded(
            child: _isSearching
                ? _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No workers found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ..._searchResults.map((worker) => WorkerCard(
                                worker: worker,
                                showWorkType: true,
                              )),
                        ],
                      )
                : filteredWorkers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showGroupWorkers ? 'No group workers found' : 'No single workers found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_showGroupWorkers)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Group Workers',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                              ),
                            ),
                          ...filteredWorkers.map((worker) => WorkerCard(
                                worker: worker,
                                showWorkType: true,
                              )),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  final bool showWorkType;

  const WorkerCard({
    super.key,
    required this.worker,
    this.showWorkType = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerDetailPage(worker: worker),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Worker Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  worker['imageUrl'] as String,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 45),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              // Worker Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            worker['name'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: worker['isGroup'] ? Colors.orange.shade100 : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            worker['isGroup'] ? 'Team' : 'Single',
                            style: TextStyle(
                              color: worker['isGroup'] ? Colors.orange.shade800 : Colors.blue.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      worker['details'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green, size: 16),
                        Expanded(
                          child: Text(
                            ' ${worker['distance']}',
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          ' ${worker['rating']} (${worker['reviews']})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              worker['availability'] as String,
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '₹${(worker['pricePerHour'] as int) * 8}/day',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

class WorkerDetailPage extends StatelessWidget {
  final Map<String, dynamic> worker;

  const WorkerDetailPage({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    worker['imageUrl'] as String,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker['name'] as String,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              worker['details'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹${(worker['pricePerHour'] as int) * 8}/day',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Experience Section
                  const Text(
                    'Experience',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.work, color: Colors.blue.shade800),
                        const SizedBox(width: 12),
                        Text(
                          worker['experience'] as String,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Skills Section
                  const Text(
                    'Skills',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (worker['skills'] as List<dynamic>).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          skill as String,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Location and Availability
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Text(
                                worker['distance'] as String,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Text(
                                worker['availability'] as String,
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (worker['contact'] != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone, color: Colors.blue.shade700),
                          const SizedBox(width: 10),
                          Text(
                            worker['contact'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${worker['rating']} (${worker['reviews']} reviews)',
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Book Now Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
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
                      child: Text(
                        'Book ${worker['isGroup'] ? 'Team' : 'Worker'}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (worker['isGroup'] == true && worker['teamMembers'] != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Team Members',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate((worker['teamMembers'] as List).length, (index) {
                      final member = worker['teamMembers'][index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                member['imageUrl'],
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    member['role'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
