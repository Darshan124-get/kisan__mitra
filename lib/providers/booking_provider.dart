import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/booking_api.dart';

final bookingApiProvider = Provider<BookingApi>((ref) => BookingApi());

// Provider for all bookings (public)
final bookingListProvider = FutureProvider<List<Booking>>((ref) async {
  final api = ref.read(bookingApiProvider);
  return await api.getMyBookings();
});

// Provider for user's bookings with status filter
final myBookingsProvider = FutureProvider.family<List<Booking>, String?>((ref, status) async {
  final api = ref.read(bookingApiProvider);
  return await api.getMyBookings(status: status);
});

// Provider for a single booking by ID
final bookingProvider = FutureProvider.family<Booking, String>((ref, bookingId) async {
  final api = ref.read(bookingApiProvider);
  return await api.getBooking(bookingId);
});

// StateNotifier for booking operations
class BookingNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  final BookingApi _api;
  String? _currentStatusFilter;

  BookingNotifier(this._api) : super(const AsyncValue.loading()) {
    _loadBookings(showLoading: true);
  }

  Future<void> _loadBookings({String? status, bool showLoading = false}) async {
    try {
      // Only show loading if explicitly requested (e.g., on initial load or manual refresh)
      if (showLoading) {
        state = const AsyncValue.loading();
      }
      _currentStatusFilter = status;
      final bookings = await _api.getMyBookings(status: status);
      state = AsyncValue.data(bookings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createBooking({
    required String serviceId,
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
    required double duration,
    required BookingLocation location,
    String? specialInstructions,
  }) async {
    try {
      await _api.createBooking(
        serviceId: serviceId,
        bookingDate: bookingDate,
        startTime: startTime,
        endTime: endTime,
        duration: duration,
        location: location,
        specialInstructions: specialInstructions,
      );
      // Refresh list without showing loading state
      await _loadBookings(status: _currentStatusFilter, showLoading: false);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    try {
      await _api.updateBookingStatus(
        bookingId: bookingId,
        status: status,
      );
      // Refresh list without showing loading state
      await _loadBookings(status: _currentStatusFilter, showLoading: false);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addReview({
    required String bookingId,
    required double rating,
    String? comment,
  }) async {
    try {
      await _api.addReview(
        bookingId: bookingId,
        rating: rating,
        comment: comment,
      );
      // Refresh list without showing loading state
      await _loadBookings(status: _currentStatusFilter, showLoading: false);
    } catch (e) {
      rethrow;
    }
  }

  void filterByStatus(String? status) {
    _loadBookings(status: status, showLoading: true);
  }

  Future<void> refresh() => _loadBookings(status: _currentStatusFilter, showLoading: true);
}

final bookingNotifierProvider = StateNotifierProvider<BookingNotifier, AsyncValue<List<Booking>>>((ref) {
  final api = ref.read(bookingApiProvider);
  return BookingNotifier(api);
});

