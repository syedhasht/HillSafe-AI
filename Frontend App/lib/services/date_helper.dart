import 'package:intl/intl.dart';

/// Centralized Date Helper for converting and formatting all timestamps
/// explicitly to Pakistan Standard Time (PST / UTC+5), rather than UTC ("Z") or client device local time.
class DateHelper {
  /// Converts any DateTime, dynamic ISO string, or timestamp to Pakistan Standard Time (UTC+5).
  /// This ensures that regardless of the device's local timezone settings,
  /// all times are cleanly mapped to Pakistan Standard Time.
  static DateTime toPakistanTime(dynamic value) {
    if (value == null) return DateTime.now().toUtc().add(const Duration(hours: 5));
    
    DateTime dt;
    if (value is DateTime) {
      dt = value;
    } else {
      dt = DateTime.tryParse(value.toString()) ?? DateTime.now();
    }
    
    // Convert to UTC first, then force the UTC+5 Pakistan Standard Time offset
    return dt.toUtc().add(const Duration(hours: 5));
  }

  /// Formats a dynamic timestamp or DateTime cleanly to Pakistan Standard Time (UTC+5)
  /// using the specified pattern (e.g., 'MMM d, h:mm a' or 'MMM d, yyyy • h:mm a').
  static String format(dynamic value, {String pattern = 'MMM d, h:mm a'}) {
    if (value == null) return 'Unknown time';
    final pstDateTime = toPakistanTime(value);
    return DateFormat(pattern).format(pstDateTime);
  }

  /// Calculates a correct time difference relative to the current Pakistan time
  static Duration getDifferenceFromNow(dynamic value) {
    final pstDateTime = toPakistanTime(value);
    final nowPst = DateTime.now().toUtc().add(const Duration(hours: 5));
    return nowPst.difference(pstDateTime);
  }
}
