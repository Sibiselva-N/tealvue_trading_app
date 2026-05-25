import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTime(DateTime dateTime) {
    // Convert to IST (UTC+5:30) for display
    final istTime = dateTime.toLocal();
    return DateFormat('HH:mm').format(istTime);
  }

  static String formatDate(DateTime dateTime) {
    final istTime = dateTime.toLocal();
    return DateFormat('dd MMM').format(istTime);
  }

  static String formatFullDate(DateTime dateTime) {
    final istTime = dateTime.toLocal();
    return DateFormat('dd MMM yyyy').format(istTime);
  }

  static DateTime parseApiDate(String dateTimeStr) {
    // Parse ISO format: "2026-05-04 09:15:01+05:30"
    // Remove timezone and parse
    String cleanStr = dateTimeStr.replaceFirst('+05:30', '');
    return DateTime.parse(cleanStr.replaceFirst(' ', 'T'));
  }

  static String toISODate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}