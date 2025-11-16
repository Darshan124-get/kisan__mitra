import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/booking_provider.dart';
import '../models/service_model.dart';
import '../models/booking_model.dart';
import '../services/location_service.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Service service;

  const BookingScreen({super.key, required this.service});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String? _startTime;
  String? _endTime;
  final _instructionsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  bool _isDateAvailable(DateTime day) {
    // Check if date is in unavailable dates
    final dateStr = day.toIso8601String().split('T')[0];
    final isUnavailable = widget.service.availability.unavailableDates.any((unavailDate) {
      return unavailDate.toIso8601String().split('T')[0] == dateStr;
    });
    if (isUnavailable) {
      return false;
    }

    // Check schedule for the day of week
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dayName = dayNames[day.weekday % 7];
    final daySchedule = widget.service.availability.schedule
        .firstWhere((s) => s.day == dayName, orElse: () => DaySchedule(day: dayName, isAvailable: false));

    return daySchedule.isAvailable;
  }

  double _calculatePrice() {
    if (_startTime == null || _endTime == null) return 0.0;

    // Parse times
    final startParts = _startTime!.split(':');
    final endParts = _endTime!.split(':');
    final startHour = int.parse(startParts[0]) + (int.parse(startParts[1]) / 60);
    final endHour = int.parse(endParts[0]) + (int.parse(endParts[1]) / 60);
    final duration = endHour - startHour;

    return widget.service.pricePerHour * duration;
  }

  Future<void> _submitBooking() async {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end time')),
      );
      return;
    }

    if (!_isDateAvailable(_selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected date is not available')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      final address = await locationService.getAddressFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Parse times to calculate duration
      final startParts = _startTime!.split(':');
      final endParts = _endTime!.split(':');
      final startHour = int.parse(startParts[0]) + (int.parse(startParts[1]) / 60);
      final endHour = int.parse(endParts[0]) + (int.parse(endParts[1]) / 60);
      final duration = endHour - startHour;

      final notifier = ref.read(bookingNotifierProvider.notifier);
      await notifier.createBooking(
        serviceId: widget.service.id!,
        bookingDate: _selectedDay,
        startTime: _startTime!,
        endTime: _endTime!,
        duration: duration,
        location: BookingLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
        ),
        specialInstructions: _instructionsController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${widget.service.pricePerHour}/hour',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Calendar
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              enabledDayPredicate: (day) {
                return day.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
                    _isDateAvailable(day);
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                disabledDecoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
              ),
            ),
            const SizedBox(height: 24),
            // Time Selection
            const Text(
              'Select Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      hintText: 'HH:MM',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _startTime = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      hintText: 'HH:MM',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _endTime = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Special Instructions
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Special Instructions (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Price Summary
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Price:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${_calculatePrice().toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Booking',
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
    );
  }
}

