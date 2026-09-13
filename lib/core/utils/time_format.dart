import 'package:intl/intl.dart';

/// Shared display formatting for attendance times.
abstract final class TimeFormat {
  static final DateFormat _time = DateFormat('hh:mm a');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy • hh:mm a');
  static final DateFormat _date = DateFormat('EEE, d MMM yyyy');

  static String time(DateTime? value) =>
      value == null ? '—' : _time.format(value.toLocal());

  static String dateTime(DateTime? value) =>
      value == null ? '—' : _dateTime.format(value.toLocal());

  static String date(DateTime? value) =>
      value == null ? '—' : _date.format(value.toLocal());
}
