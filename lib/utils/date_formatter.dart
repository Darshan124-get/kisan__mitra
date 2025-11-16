import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  static String formatTime(String time) {
    // time is in HH:MM format
    final parts = time.split(':');
    if (parts.length == 2) {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    }
    return time;
  }

  static String formatDuration(double hours) {
    if (hours < 1) {
      return '${(hours * 60).round()} minutes';
    } else if (hours == hours.toInt()) {
      return '${hours.toInt()} hour${hours.toInt() > 1 ? 's' : ''}';
    } else {
      final wholeHours = hours.toInt();
      final minutes = ((hours - wholeHours) * 60).round();
      if (wholeHours == 0) {
        return '$minutes minutes';
      } else if (minutes == 0) {
        return '${wholeHours} hour${wholeHours > 1 ? 's' : ''}';
      } else {
        return '${wholeHours} hour${wholeHours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
      }
    }
  }
}

