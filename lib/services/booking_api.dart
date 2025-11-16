import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';
import 'api_config.dart';

class BookingApi {
  static final BookingApi _instance = BookingApi._internal();
  factory BookingApi() => _instance;
  BookingApi._internal();

  String get baseUrl => ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    return await ApiConfig.getToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = await _getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Booking> createBooking({
    required String serviceId,
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
    required double duration,
    required BookingLocation location,
    String? specialInstructions,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'serviceId': serviceId,
        'bookingDate': bookingDate.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'duration': duration,
        'location': jsonEncode(location.toJson()),
        if (specialInstructions != null) 'specialInstructions': specialInstructions,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Booking.fromJson(data['data']['booking']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create booking');
      }
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  Future<List<Booking>> getMyBookings({String? status}) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/bookings/my-bookings')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookings = (data['data']['bookings'] as List)
            .map((b) => Booking.fromJson(b))
            .toList();
        return bookings;
      } else {
        throw Exception('Failed to fetch bookings');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  Future<Booking> getBooking(String bookingId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Booking.fromJson(data['data']['booking']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch booking');
      }
    } catch (e) {
      throw Exception('Error fetching booking: $e');
    }
  }

  Future<Booking> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'status': status.toString(),
      };

      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/status'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Booking.fromJson(data['data']['booking']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update booking status');
      }
    } catch (e) {
      throw Exception('Error updating booking status: $e');
    }
  }

  Future<Booking> addReview({
    required String bookingId,
    required double rating,
    String? comment,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'rating': rating,
        if (comment != null) 'comment': comment,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/review'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Booking.fromJson(data['data']['booking']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to add review');
      }
    } catch (e) {
      throw Exception('Error adding review: $e');
    }
  }
}

