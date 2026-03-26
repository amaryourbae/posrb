import 'package:intl/intl.dart';

class AppDateFormatter {
  static DateTime _parse(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date.toLocal();
    if (date is String) {
      if (date.endsWith('Z')) {
        final parsed = DateTime.tryParse(date);
        if (parsed != null) return parsed.toLocal();
      } else {
        final parsed = DateTime.tryParse(date);
        if (parsed != null) {
          // If the string from Laravel doesn't end in Z, Dart might assume it's local.
          // The Laravel backend config/app.php is hardcoded to 'Asia/Jakarta' (UTC+7).
          if (!date.contains('+')) {
            final isoDate = date.replaceAll(' ', 'T');
            final withOffset = DateTime.tryParse('$isoDate+07:00');
            if (withOffset != null) return withOffset.toLocal();
          }
          return parsed.toLocal();
        }
      }
    }
    return DateTime.now();
  }

  static String formatTime(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = _parse(date);
      return DateFormat('HH:mm', 'id_ID').format(dt);
    } catch (e) {
      return date.toString();
    }
  }

  static String formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = _parse(date);
      return DateFormat('dd/MM/yyyy', 'id_ID').format(dt);
    } catch (e) {
      return date.toString();
    }
  }

  static String formatDateFull(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = _parse(date);
      return DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(dt);
    } catch (e) {
      return date.toString();
    }
  }

  static String formatLongDateFull(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = _parse(date);
      return DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (e) {
      return date.toString();
    }
  }

  static String formatDayDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = _parse(date);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
    } catch (e) {
      return date.toString();
    }
  }
}
