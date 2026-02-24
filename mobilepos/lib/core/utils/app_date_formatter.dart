import 'package:intl/intl.dart';

class AppDateFormatter {
  static const Duration _jakartaOffset = Duration(hours: 7);

  static DateTime _toJakarta(DateTime date) {
    final utcBase = date.isUtc
        ? date
        : DateTime.utc(
            date.year,
            date.month,
            date.day,
            date.hour,
            date.minute,
            date.second,
          );

    return utcBase.add(_jakartaOffset);
  }

  static DateTime _parse(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) return DateTime.parse(date);
    return DateTime.now();
  }

  static String formatTime(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = _parse(date);
      final jakartaDate = _toJakarta(dt);
      return DateFormat('HH:mm', 'id_ID').format(jakartaDate);
    } catch (e) {
      return date.toString();
    }
  }

  static String formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = _parse(date);
      final jakartaDate = _toJakarta(dt);
      return DateFormat('dd/MM/yyyy', 'id_ID').format(jakartaDate);
    } catch (e) {
      return date.toString();
    }
  }

  static String formatDateFull(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = _parse(date);
      final jakartaDate = _toJakarta(dt);
      return DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(jakartaDate);
    } catch (e) {
      return date.toString();
    }
  }

  static String formatLongDateFull(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = _parse(date);
      final jakartaDate = _toJakarta(dt);
      return DateFormat(
        'EEEE, d MMMM yyyy, HH:mm',
        'id_ID',
      ).format(jakartaDate);
    } catch (e) {
      return date.toString();
    }
  }

  static String formatDayDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = _parse(date);
      final jakartaDate = _toJakarta(dt);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(jakartaDate);
    } catch (e) {
      return date.toString();
    }
  }
}
