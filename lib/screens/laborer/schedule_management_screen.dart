import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/service_provider.dart';
import '../../models/service_model.dart';

class ScheduleManagementScreen extends ConsumerStatefulWidget {
  final String? serviceId;

  const ScheduleManagementScreen({super.key, this.serviceId});

  @override
  ConsumerState<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends ConsumerState<ScheduleManagementScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Map<String, DaySchedule> _schedule = {};
  final Set<DateTime> _unavailableDates = {};

  @override
  void initState() {
    super.initState();
    _initializeSchedule();
    if (widget.serviceId != null) {
      _loadServiceSchedule();
    }
  }

  void _initializeSchedule() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    for (var day in days) {
      _schedule[day] = DaySchedule(day: day, isAvailable: false);
    }
  }

  Future<void> _loadServiceSchedule() async {
    if (widget.serviceId == null) return;
    try {
      final service = await ref.read(serviceProvider(widget.serviceId!).future);
      _schedule.clear();
      for (var daySchedule in service.availability.schedule) {
        _schedule[daySchedule.day] = daySchedule;
      }
      _unavailableDates.clear();
      _unavailableDates.addAll(service.availability.unavailableDates);
      setState(() {});
    } catch (e) {
      // Handle error
    }
  }

  bool _isUnavailable(DateTime day) {
    return _unavailableDates.any((unavailDate) =>
        unavailDate.year == day.year &&
        unavailDate.month == day.month &&
        unavailDate.day == day.day);
  }

  void _toggleUnavailableDate(DateTime day) {
    setState(() {
      if (_isUnavailable(day)) {
        _unavailableDates.removeWhere((unavailDate) =>
            unavailDate.year == day.year &&
            unavailDate.month == day.month &&
            unavailDate.day == day.day);
      } else {
        _unavailableDates.add(DateTime(day.year, day.month, day.day));
      }
    });
  }

  Future<void> _saveSchedule() async {
    if (widget.serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No service selected')),
      );
      return;
    }

    try {
      final notifier = ref.read(serviceNotifierProvider.notifier);
      await notifier.updateAvailability(
        serviceId: widget.serviceId!,
        schedule: _schedule.values.toList(),
        unavailableDates: _unavailableDates.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule saved successfully')),
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
        title: const Text('Manage Schedule'),
        backgroundColor: Colors.green,
        actions: [
          if (widget.serviceId != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSchedule,
            ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
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
              _toggleUnavailableDate(selectedDay);
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
            eventLoader: (day) {
              return _isUnavailable(day) ? [1] : [];
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Weekly Schedule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            for (var day in _schedule.keys) {
                              _schedule[day] = DaySchedule(
                                day: day,
                                startTime: '09:00',
                                endTime: '18:00',
                                isAvailable: true,
                              );
                            }
                          });
                        },
                        child: const Text('Available All Week'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            for (var day in _schedule.keys) {
                              _schedule[day] = DaySchedule(
                                day: day,
                                isAvailable: false,
                              );
                            }
                          });
                        },
                        child: const Text('Unavailable All Week'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                    .map((day) => _buildDaySchedule(day)),
              ],
            ),
          ),
        ],
      ),
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
                    startTime: schedule.startTime ?? '09:00',
                    endTime: schedule.endTime ?? '18:00',
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

