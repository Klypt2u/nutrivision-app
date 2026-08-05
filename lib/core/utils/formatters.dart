import 'package:intl/intl.dart';

/// Light-weight formatting helpers used across the UI.
class Formatters {
  Formatters._();

  static final NumberFormat _kcal = NumberFormat.decimalPattern();
  static final NumberFormat _compact = NumberFormat.compact();
  static final DateFormat _date = DateFormat('EEE, MMM d');
  static final DateFormat _day  = DateFormat('EEE');
  static final DateFormat _time = DateFormat('h:mm a');

  static String kcal(num v) => '${_kcal.format(v.round())} kcal';
  static String grams(num v) => '${v.toStringAsFixed(0)} g';
  static String mg(num v)    => '${v.toStringAsFixed(0)} mg';
  static String ml(num v)    => '${_kcal.format(v.round())} ml';
  static String compact(num v) => _compact.format(v);

  static String date(DateTime d) => _date.format(d);
  static String day(DateTime d)  => _day.format(d).toUpperCase();
  static String time(DateTime d) => _time.format(d);

  static String duration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  /// Returns "Today" / "Yesterday" / formatted date.
  static String relativeDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) return DateFormat('EEEE').format(d);
    return _date.format(d);
  }
}
