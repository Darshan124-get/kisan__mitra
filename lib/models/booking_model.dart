class Booking {
  final String? id;
  final String serviceId;
  final String? serviceTitle;
  final String farmerId;
  final String? farmerName;
  final String? farmerPhone;
  final String laborerId;
  final String? laborerName;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final double duration;
  final double totalPrice;
  final BookingStatus status;
  final BookingLocation location;
  final String? specialInstructions;
  final BookingReview? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    this.id,
    required this.serviceId,
    this.serviceTitle,
    required this.farmerId,
    this.farmerName,
    this.farmerPhone,
    required this.laborerId,
    this.laborerName,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.totalPrice,
    this.status = BookingStatus.pending,
    required this.location,
    this.specialInstructions,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'],
      serviceId: json['serviceId'] is String 
          ? json['serviceId'] 
          : json['serviceId']?['_id'] ?? json['serviceId']?['id'] ?? '',
      serviceTitle: json['serviceId'] is Map 
          ? (json['serviceId']?['title'] as String?)
          : (json['serviceTitle'] as String?),
      farmerId: json['farmerId'] is String 
          ? json['farmerId'] 
          : json['farmerId']?['_id'] ?? json['farmerId']?['id'] ?? '',
      farmerName: json['farmerId'] is Map 
          ? (json['farmerId']?['name'] as String?)
          : (json['farmerName'] as String?),
      farmerPhone: json['farmerId'] is Map 
          ? (json['farmerId']?['phone'] as String?)
          : (json['farmerPhone'] as String?),
      laborerId: json['laborerId'] is String 
          ? json['laborerId'] 
          : json['laborerId']?['_id'] ?? json['laborerId']?['id'] ?? '',
      laborerName: json['laborerId'] is Map 
          ? (json['laborerId']?['name'] as String?)
          : (json['laborerName'] as String?),
      bookingDate: json['bookingDate'] != null
          ? DateTime.parse(json['bookingDate'])
          : DateTime.now(),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      duration: (json['duration'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: BookingStatus.fromString(json['status'] ?? 'pending'),
      location: BookingLocation.fromJson(json['location'] ?? {}),
      specialInstructions: json['specialInstructions'],
      review: json['review'] != null 
          ? BookingReview.fromJson(json['review']) 
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'serviceId': serviceId,
      'farmerId': farmerId,
      'laborerId': laborerId,
      'bookingDate': bookingDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'totalPrice': totalPrice,
      'status': status.toString(),
      'location': location.toJson(),
      if (specialInstructions != null) 'specialInstructions': specialInstructions,
      if (review != null) 'review': review!.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Booking copyWith({
    String? id,
    String? serviceId,
    String? serviceTitle,
    String? farmerId,
    String? farmerName,
    String? laborerId,
    String? laborerName,
    DateTime? bookingDate,
    String? startTime,
    String? endTime,
    double? duration,
    double? totalPrice,
    BookingStatus? status,
    BookingLocation? location,
    String? specialInstructions,
    BookingReview? review,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      laborerId: laborerId ?? this.laborerId,
      laborerName: laborerName ?? this.laborerName,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      location: location ?? this.location,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool canBeCancelled() {
    return status == BookingStatus.pending || status == BookingStatus.confirmed;
  }

  bool canBeCompleted() {
    return status == BookingStatus.confirmed;
  }
}

enum BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  static BookingStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  @override
  String toString() {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class BookingLocation {
  final double latitude;
  final double longitude;
  final String? address;

  BookingLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory BookingLocation.fromJson(Map<String, dynamic> json) {
    return BookingLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}

class BookingReview {
  final double rating;
  final String? comment;
  final DateTime date;

  BookingReview({
    required this.rating,
    this.comment,
    required this.date,
  });

  factory BookingReview.fromJson(Map<String, dynamic> json) {
    return BookingReview(
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
    };
  }
}

