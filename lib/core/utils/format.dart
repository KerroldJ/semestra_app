import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formatting helpers shared across the timetable-oriented screens.
class Fmt {
  /// "09:00" (24h "HH:mm") -> ("9:00", "AM").
  static (String, String) time12Parts(String hhmm) {
    final t = parseHHmm(hhmm);
    if (t == null) return (hhmm, '');
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return ('$hour12:$minute', period);
  }

  /// "09:00" -> "9:00 AM"
  static String time12(String hhmm) {
    final (t, p) = time12Parts(hhmm);
    return p.isEmpty ? t : '$t $p';
  }

  static TimeOfDay? parseHHmm(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static String hhmmFromTod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Minutes between two "HH:mm" strings (0 if unparseable / negative).
  static int durationMinutes(String start, String end) {
    final s = parseHHmm(start);
    final e = parseHHmm(end);
    if (s == null || e == null) return 0;
    final mins = (e.hour * 60 + e.minute) - (s.hour * 60 + s.minute);
    return mins > 0 ? mins : 0;
  }

  static String dueLabel(DateTime due) {
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(due.year, due.month, due.day);
    final diff = d1.difference(d0).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return '${-diff}d overdue';
    if (diff < 7) return DateFormat('EEE').format(due);
    return DateFormat('MMM d').format(due);
  }

  static const List<String> weekdayAbbr = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
  ];
}
