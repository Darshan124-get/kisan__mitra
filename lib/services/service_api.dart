import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';
import 'api_config.dart';
import 'aws_s3_service.dart';

class ServiceApi {
  static final ServiceApi _instance = ServiceApi._internal();
  factory ServiceApi() => _instance;
  ServiceApi._internal();

  String get baseUrl => ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    return await ApiConfig.getToken();
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  Future<Service> createService({
    required ServiceType serviceType,
    required String title,
    required String description,
    required double pricePerHour,
    double? pricePerDay,
    required ServiceLocation location,
    required ServiceAvailability availability,
    required List<String> images, // URLs or file paths
    required ServiceSpecifications specifications,
  }) async {
    try {
      // Upload images to S3 if they are local files
      List<String> imageUrls = [];
      for (var image in images) {
        if (image.startsWith('http://') || image.startsWith('https://')) {
          imageUrls.add(image);
        } else {
          // Assume it's a file path, upload to S3
          final file = File(image);
          if (await file.exists()) {
            final url = await AwsS3Service().uploadImage(file);
            imageUrls.add(url);
          }
        }
      }

      // Verify token exists and add debug logging
      final token = await _getToken();
      print('🔐 [ServiceApi] createService - Token check:');
      print('   Token exists: ${token != null}');
      if (token != null) {
        print('   Token length: ${token.length}');
        print('   Token preview: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      } else {
        print('   ❌ No token found!');
      }
      
      if (token == null || token.isEmpty) {
        print('   ❌ [ServiceApi] createService - No token, throwing exception');
        throw Exception('No authentication token found. Please login again.');
      }
      
      final headers = await _getHeaders();
      print('   ✅ [ServiceApi] createService - Headers prepared with token');
      
      final body = {
        'serviceType': serviceType.toString().split('.').last, // Remove enum prefix
        'title': title,
        'description': description,
        'pricePerHour': pricePerHour,
        if (pricePerDay != null) 'pricePerDay': pricePerDay,
        'location': location.toJson(),
        'availability': availability.toJson(),
        'images': imageUrls,
        'specifications': specifications.toJson(),
      };

      print('   📤 [ServiceApi] createService - Sending POST request to $baseUrl/services');
      final response = await http.post(
        Uri.parse('$baseUrl/services'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('   📥 [ServiceApi] createService - Response status: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('   ✅ [ServiceApi] createService - Service created successfully');
        print('   📸 [ServiceApi] Service images: ${data['data']?['service']?['images']}');
        final service = Service.fromJson(data['data']['service']);
        print('   📸 [ServiceApi] Parsed service images: ${service.images}');
        return service;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to create service';
        print('   ❌ [ServiceApi] createService - Error: $errorMessage (Status: ${response.statusCode})');
        
        if (response.statusCode == 401) {
          // Token expired or invalid - clear auth data
          print('   🔄 [ServiceApi] createService - 401 error, clearing token');
          await ApiConfig.clearToken();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', false);
          throw Exception('Authentication failed: $errorMessage. Please login again.');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('   ❌ [ServiceApi] createService - Exception caught: $e');
      print('   📋 [ServiceApi] createService - Full error details: ${e.toString()}');
      throw Exception('Error creating service: $e');
    }
  }

  Future<List<Service>> getMyServices() async {
    print('📋 [ServiceApi] getMyServices - Fetching services...');
    try {
      // Verify token exists
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/services/my-services'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final services = (data['data']['services'] as List)
            .map((s) {
              print('   📸 [ServiceApi] Raw service images from API: ${s['images']}');
              final service = Service.fromJson(s);
              print('   📸 [ServiceApi] Parsed service images: ${service.images}');
              return service;
            })
            .toList();
        print('📋 [ServiceApi] getMyServices - Fetched ${services.length} services');
        return services;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to fetch services';
        if (response.statusCode == 401) {
          // Token expired or invalid - clear auth data
          await ApiConfig.clearToken();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', false);
          throw Exception('Authentication failed: $errorMessage. Please login again.');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error fetching services: $e');
    }
  }

  Future<Service> getService(String serviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services/$serviceId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Service.fromJson(data['data']['service']);
      } else {
        throw Exception('Failed to fetch service');
      }
    } catch (e) {
      throw Exception('Error fetching service: $e');
    }
  }

  Future<Service> updateService({
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
      print('📝 [ServiceApi] updateService - Starting update for service: $serviceId');
      
      // Upload new images if any are local files
      List<String>? imageUrls;
      if (images != null && images.isNotEmpty) {
        print('📤 [ServiceApi] updateService - Processing ${images.length} images');
        imageUrls = [];
        for (var i = 0; i < images.length; i++) {
          final image = images[i];
          print('   Processing image $i: $image');
          if (image.startsWith('http://') || image.startsWith('https://')) {
            print('   ✅ Already a URL, skipping upload');
            imageUrls.add(image);
          } else {
            final file = File(image);
            if (await file.exists()) {
              print('   📤 Uploading local file to S3...');
              try {
                final url = await AwsS3Service().uploadImage(file);
                print('   ✅ Uploaded successfully: $url');
                imageUrls.add(url);
              } catch (e) {
                print('   ❌ Failed to upload image: $e');
                // Re-throw with more context
                throw Exception('Failed to upload image: $e');
              }
            } else {
              print('   ⚠️ File does not exist: $image');
            }
          }
        }
        print('📤 [ServiceApi] updateService - Total image URLs: ${imageUrls.length}');
      }

      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (pricePerHour != null) body['pricePerHour'] = pricePerHour;
      if (pricePerDay != null) body['pricePerDay'] = pricePerDay;
      if (location != null) body['location'] = jsonEncode(location.toJson());
      if (availability != null) body['availability'] = jsonEncode(availability.toJson());
      if (imageUrls != null) body['images'] = jsonEncode(imageUrls);
      if (specifications != null) body['specifications'] = jsonEncode(specifications.toJson());
      if (status != null) body['status'] = status.toString();

      print('📤 [ServiceApi] updateService - Sending PUT request to $baseUrl/services/$serviceId');
      final response = await http.put(
        Uri.parse('$baseUrl/services/$serviceId'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 [ServiceApi] updateService - Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [ServiceApi] updateService - Service updated successfully');
        print('   📸 [ServiceApi] Service images: ${data['data']?['service']?['images']}');
        final service = Service.fromJson(data['data']['service']);
        print('   📸 [ServiceApi] Parsed service images: ${service.images}');
        return service;
      } else {
        final error = jsonDecode(response.body);
        if (response.statusCode == 401) {
          // Token expired or invalid - clear auth data
          await ApiConfig.clearToken();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', false);
          throw Exception('Authentication failed: ${error['message'] ?? 'Please login again.'}');
        }
        throw Exception(error['message'] ?? error['error'] ?? 'Failed to update service');
      }
    } catch (e) {
      print('❌ [ServiceApi] updateService - Exception: $e');
      // Preserve the original error message if it's already descriptive
      if (e.toString().contains('Failed to upload image')) {
        throw e;
      }
      throw Exception('Error updating service: $e');
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/services/$serviceId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete service');
      }
    } catch (e) {
      throw Exception('Error deleting service: $e');
    }
  }

  Future<Service> updateAvailability({
    required String serviceId,
    bool? isAvailable,
    List<DaySchedule>? schedule,
    List<DateTime>? unavailableDates,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      
      if (isAvailable != null) body['isAvailable'] = isAvailable;
      if (schedule != null) {
        body['schedule'] = jsonEncode(schedule.map((s) => s.toJson()).toList());
      }
      if (unavailableDates != null) {
        body['unavailableDates'] = jsonEncode(
          unavailableDates.map((d) => d.toIso8601String()).toList()
        );
      }

      final response = await http.put(
        Uri.parse('$baseUrl/services/$serviceId/availability'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Service.fromJson(data['data']['service']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update availability');
      }
    } catch (e) {
      throw Exception('Error updating availability: $e');
    }
  }

  Future<Service> updateLocation({
    required String serviceId,
    required ServiceLocation location,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'coordinates': [location.longitude, location.latitude],
        'address': location.address,
        'village': location.village,
        'district': location.district,
        'state': location.state,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/services/$serviceId/location'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Service.fromJson(data['data']['service']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update location');
      }
    } catch (e) {
      throw Exception('Error updating location: $e');
    }
  }

  Future<List<Service>> getAllServices({
    String? serviceType,
    double? minPrice,
    double? maxPrice,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isAvailable,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      // Don't add latitude/longitude/radius if we want ALL services
      // Only add them if explicitly provided AND we want radius filtering
      if (latitude != null && longitude != null && radius != null) {
        queryParams['latitude'] = latitude.toString();
        queryParams['longitude'] = longitude.toString();
        queryParams['radius'] = radius.toString();
      }
      if (isAvailable != null) queryParams['isAvailable'] = isAvailable.toString();
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/services').replace(queryParameters: queryParams);
      print('Fetching all services from: $uri');
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle different response formats
        List<dynamic> servicesList;
        if (data['data'] != null && data['data']['services'] != null) {
          servicesList = data['data']['services'] as List;
        } else if (data['services'] != null) {
          servicesList = data['services'] as List;
        } else if (data is List) {
          servicesList = data;
        } else {
          print('Unexpected response format: $data');
          return [];
        }
        
        print('Found ${servicesList.length} services');
        final services = servicesList
            .map((s) => Service.fromJson(s))
            .toList();
        
        print('Parsed ${services.length} services successfully');
        return services;
      } else {
        final errorBody = response.body;
        print('Error response: $errorBody');
        throw Exception('Failed to fetch services (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      print('Error in getAllServices: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to server. Please check if the backend is running on port 3000.');
      }
      throw Exception('Error fetching services: $e');
    }
  }

  Future<List<Service>> getNearbyServices({
    required double latitude,
    required double longitude,
    double radius = 10,
    String? serviceType,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
        'limit': limit.toString(),
      };

      if (serviceType != null) queryParams['serviceType'] = serviceType;

      final uri = Uri.parse('$baseUrl/services/nearby').replace(queryParameters: queryParams);
      print('Fetching nearby services from: $uri');
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle different response formats
        List<dynamic> servicesList;
        if (data['data'] != null && data['data']['services'] != null) {
          servicesList = data['data']['services'] as List;
        } else if (data['services'] != null) {
          servicesList = data['services'] as List;
        } else if (data is List) {
          servicesList = data;
        } else {
          print('Unexpected response format: $data');
          return [];
        }
        
        final services = servicesList
            .map((s) => Service.fromJson(s))
            .toList();
        
        print('Parsed ${services.length} services');
        return services;
      } else {
        final errorBody = response.body;
        throw Exception('Failed to fetch nearby services (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      print('Error in getNearbyServices: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to server. Please check if the backend is running.');
      }
      throw Exception('Error fetching nearby services: $e');
    }
  }

  Future<List<Service>> searchServices({
    String? query,
    String? serviceType,
    double? minPrice,
    double? maxPrice,
    double? latitude,
    double? longitude,
    double? radius,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (query != null) queryParams['q'] = query;
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      if (radius != null) queryParams['radius'] = radius.toString();

      final uri = Uri.parse('$baseUrl/services/search').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final services = (data['data']['services'] as List)
            .map((s) => Service.fromJson(s))
            .toList();
        return services;
      } else {
        throw Exception('Failed to search services');
      }
    } catch (e) {
      throw Exception('Error searching services: $e');
    }
  }
}

