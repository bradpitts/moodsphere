import 'package:intl/intl.dart';

class AppDateUtils {
  /// Format DateTime to readable string e.g. "Aug 13, 2026 05:50 PM"
  static String formatReadable(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }

  /// Get Month Name e.g. "August 2026"
  static String formatMonthYear(int year, int month) {
    final date = DateTime(year, month, 1);
    return DateFormat('MMMM yyyy').format(date);
  }
}
