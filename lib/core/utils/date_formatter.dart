import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  static DateTime parseApiDate(String dateTimeStr) {
    // Parse ISO format: "2026-05-04 09:15:01+05:30"
    return DateTime.parse(dateTimeStr.replaceFirst(' ', 'T'));
  }

  static String toISODate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}
