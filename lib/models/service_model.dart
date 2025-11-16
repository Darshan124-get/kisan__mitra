class Service {
  final String? id;
  final String laborerId;
  final ServiceType serviceType;
  final String title;
  final String description;
  final double pricePerHour;
  final double? pricePerDay;
  final ServiceLocation location;
  final ServiceAvailability availability;
  final List<String> images;
  final ServiceSpecifications specifications;
  final double rating;
  final int totalBookings;
  final List<ServiceReview> reviews;
  final ServiceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Laborer contact info (from populated laborerId)
  final String? laborerName;
  final String? laborerPhone;
  final String? laborerEmail;

  Service({
    this.id,
    required this.laborerId,
    required this.serviceType,
    required this.title,
    required this.description,
    required this.pricePerHour,
    this.pricePerDay,
    required this.location,
    required this.availability,
    required this.images,
    required this.specifications,
    this.rating = 0.0,
    this.totalBookings = 0,
    required this.reviews,
    this.status = ServiceStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.laborerName,
    this.laborerPhone,
    this.laborerEmail,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    // Extract laborer contact info if laborerId is populated
    final laborerData = json['laborerId'] is Map ? json['laborerId'] : null;
    
    return Service(
      id: json['_id'] ?? json['id'],
      laborerId: json['laborerId'] is String 
          ? json['laborerId'] 
          : json['laborerId']?['_id'] ?? json['laborerId']?['id'] ?? '',
      serviceType: ServiceType.fromString(json['serviceType'] ?? 'other'),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      pricePerDay: json['pricePerDay'] != null 
          ? (json['pricePerDay'] as num).toDouble() 
          : null,
      location: ServiceLocation.fromJson(json['location'] ?? {}),
      availability: ServiceAvailability.fromJson(json['availability'] ?? {}),
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : [],
      specifications: ServiceSpecifications.fromJson(
        json['specifications'] ?? {},
        json['serviceType'] ?? 'other'
      ),
      rating: (json['rating'] ?? 0).toDouble(),
      totalBookings: json['totalBookings'] ?? 0,
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
              .map((r) => ServiceReview.fromJson(r))
              .toList()
          : [],
      status: ServiceStatus.fromString(json['status'] ?? 'active'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      laborerName: laborerData?['name'] as String?,
      laborerPhone: laborerData?['phone'] as String?,
      laborerEmail: laborerData?['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'laborerId': laborerId,
      'serviceType': serviceType.toString(),
      'title': title,
      'description': description,
      'pricePerHour': pricePerHour,
      if (pricePerDay != null) 'pricePerDay': pricePerDay,
      'location': location.toJson(),
      'availability': availability.toJson(),
      'images': images,
      'specifications': specifications.toJson(),
      'rating': rating,
      'totalBookings': totalBookings,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Service copyWith({
    String? id,
    String? laborerId,
    ServiceType? serviceType,
    String? title,
    String? description,
    double? pricePerHour,
    double? pricePerDay,
    ServiceLocation? location,
    ServiceAvailability? availability,
    List<String>? images,
    ServiceSpecifications? specifications,
    double? rating,
    int? totalBookings,
    List<ServiceReview>? reviews,
    ServiceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? laborerName,
    String? laborerPhone,
    String? laborerEmail,
  }) {
    return Service(
      id: id ?? this.id,
      laborerId: laborerId ?? this.laborerId,
      serviceType: serviceType ?? this.serviceType,
      title: title ?? this.title,
      description: description ?? this.description,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      location: location ?? this.location,
      availability: availability ?? this.availability,
      images: images ?? this.images,
      specifications: specifications ?? this.specifications,
      rating: rating ?? this.rating,
      totalBookings: totalBookings ?? this.totalBookings,
      reviews: reviews ?? this.reviews,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      laborerName: laborerName ?? this.laborerName,
      laborerPhone: laborerPhone ?? this.laborerPhone,
      laborerEmail: laborerEmail ?? this.laborerEmail,
    );
  }
}

enum ServiceType {
  tractor,
  cultivator,
  workerIndividual,
  workerGroup,
  other;

  static ServiceType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'tractor':
        return ServiceType.tractor;
      case 'cultivator':
        return ServiceType.cultivator;
      case 'worker_individual':
      case 'workerindividual':
        return ServiceType.workerIndividual;
      case 'worker_group':
      case 'workergroup':
        return ServiceType.workerGroup;
      default:
        return ServiceType.other;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ServiceType.tractor:
        return 'tractor';
      case ServiceType.cultivator:
        return 'cultivator';
      case ServiceType.workerIndividual:
        return 'worker_individual';
      case ServiceType.workerGroup:
        return 'worker_group';
      case ServiceType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case ServiceType.tractor:
        return 'Tractor';
      case ServiceType.cultivator:
        return 'Cultivator';
      case ServiceType.workerIndividual:
        return 'Worker (Individual)';
      case ServiceType.workerGroup:
        return 'Worker (Group)';
      case ServiceType.other:
        return 'Other';
    }
  }
}

enum ServiceStatus {
  active,
  inactive,
  pending;

  static ServiceStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return ServiceStatus.active;
      case 'inactive':
        return ServiceStatus.inactive;
      case 'pending':
        return ServiceStatus.pending;
      default:
        return ServiceStatus.active;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ServiceStatus.active:
        return 'active';
      case ServiceStatus.inactive:
        return 'inactive';
      case ServiceStatus.pending:
        return 'pending';
    }
  }
}

class ServiceLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? village;
  final String? district;
  final String? state;

  ServiceLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.village,
    this.district,
    this.state,
  });

  factory ServiceLocation.fromJson(Map<String, dynamic> json) {
    List<double>? coordinates;
    if (json['coordinates'] != null && json['coordinates'] is List) {
      coordinates = (json['coordinates'] as List).map((e) => (e as num).toDouble()).toList();
    }

    return ServiceLocation(
      latitude: coordinates != null && coordinates.length >= 2 
          ? coordinates[1] 
          : (json['latitude'] ?? 0.0).toDouble(),
      longitude: coordinates != null && coordinates.length >= 2 
          ? coordinates[0] 
          : (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'],
      village: json['village'],
      district: json['district'],
      state: json['state'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'Point',
      'coordinates': [longitude, latitude],
      'address': address,
      'village': village,
      'district': district,
      'state': state,
    };
  }
}

class ServiceAvailability {
  final bool isAvailable;
  final List<DaySchedule> schedule;
  final List<DateTime> unavailableDates;

  ServiceAvailability({
    this.isAvailable = true,
    required this.schedule,
    required this.unavailableDates,
  });

  factory ServiceAvailability.fromJson(Map<String, dynamic> json) {
    return ServiceAvailability(
      isAvailable: json['isAvailable'] ?? true,
      schedule: json['schedule'] != null
          ? (json['schedule'] as List)
              .map((s) => DaySchedule.fromJson(s))
              .toList()
          : [],
      unavailableDates: json['unavailableDates'] != null
          ? (json['unavailableDates'] as List)
              .map((d) => DateTime.parse(d))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAvailable': isAvailable,
      'schedule': schedule.map((s) => s.toJson()).toList(),
      'unavailableDates': unavailableDates.map((d) => d.toIso8601String()).toList(),
    };
  }
}

class DaySchedule {
  final String day;
  final String? startTime;
  final String? endTime;
  final bool isAvailable;

  DaySchedule({
    required this.day,
    this.startTime,
    this.endTime,
    this.isAvailable = true,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      day: json['day'] ?? '',
      startTime: json['startTime'],
      endTime: json['endTime'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
    };
  }
}

class ServiceSpecifications {
  // For tractors/cultivators
  final String? modelYear;
  final String? enginePower;
  final String? fuelType;
  final String? transmission;
  final List<String> features;
  final String? maintenanceStatus;
  final DateTime? lastServiceDate;

  // For workers
  final String? experience;
  final List<String> skills;
  final int? teamSize;
  final List<TeamMember> teamMembers;

  ServiceSpecifications({
    this.modelYear,
    this.enginePower,
    this.fuelType,
    this.transmission,
    this.features = const [],
    this.maintenanceStatus,
    this.lastServiceDate,
    this.experience,
    this.skills = const [],
    this.teamSize,
    this.teamMembers = const [],
  });

  factory ServiceSpecifications.fromJson(Map<String, dynamic> json, String serviceType) {
    return ServiceSpecifications(
      modelYear: json['modelYear'],
      enginePower: json['enginePower'],
      fuelType: json['fuelType'],
      transmission: json['transmission'],
      features: json['features'] != null 
          ? List<String>.from(json['features']) 
          : [],
      maintenanceStatus: json['maintenanceStatus'],
      lastServiceDate: json['lastServiceDate'] != null
          ? DateTime.parse(json['lastServiceDate'])
          : null,
      experience: json['experience'],
      skills: json['skills'] != null 
          ? List<String>.from(json['skills']) 
          : [],
      teamSize: json['teamSize'],
      teamMembers: json['teamMembers'] != null
          ? (json['teamMembers'] as List)
              .map((m) => TeamMember.fromJson(m))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (modelYear != null) 'modelYear': modelYear,
      if (enginePower != null) 'enginePower': enginePower,
      if (fuelType != null) 'fuelType': fuelType,
      if (transmission != null) 'transmission': transmission,
      'features': features,
      if (maintenanceStatus != null) 'maintenanceStatus': maintenanceStatus,
      if (lastServiceDate != null) 'lastServiceDate': lastServiceDate!.toIso8601String(),
      if (experience != null) 'experience': experience,
      'skills': skills,
      if (teamSize != null) 'teamSize': teamSize,
      'teamMembers': teamMembers.map((m) => m.toJson()).toList(),
    };
  }
}

class TeamMember {
  final String name;
  final String role;

  TeamMember({
    required this.name,
    required this.role,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
    };
  }
}

class ServiceReview {
  final String farmerId;
  final String? farmerName;
  final double rating;
  final String? comment;
  final DateTime date;

  ServiceReview({
    required this.farmerId,
    this.farmerName,
    required this.rating,
    this.comment,
    required this.date,
  });

  factory ServiceReview.fromJson(Map<String, dynamic> json) {
    return ServiceReview(
      farmerId: json['farmerId'] is String 
          ? json['farmerId'] 
          : json['farmerId']?['_id'] ?? json['farmerId']?['id'] ?? '',
      farmerName: json['farmerId'] is Map 
          ? (json['farmerId']?['name'] as String?)
          : (json['farmerName'] as String?),
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmerId': farmerId,
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
    };
  }
}

