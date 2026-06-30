import 'package:intl/intl.dart';

class QDDateUtils {
  static String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);
  static String formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final dt = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return time24;
    }
  }
  static String formatDateTime(DateTime dt) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(dt);

  static String greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static String dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEE, dd MMM').format(date);
  }

  // Returns "In 45 minutes" or "45 minutes ago"
  static String relativeTime(DateTime dateTime, String time24) {
    try {
      final parts = time24.split(':');
      final apptTime = DateTime(
        dateTime.year, dateTime.month, dateTime.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
      final diff = apptTime.difference(DateTime.now());
      if (diff.inMinutes > 0) {
        if (diff.inHours >= 1) return 'In ${diff.inHours}h ${diff.inMinutes % 60}m';
        return 'In ${diff.inMinutes} minutes';
      } else {
        return '${diff.inMinutes.abs()} minutes ago';
      }
    } catch (_) {
      return '';
    }
  }
}
