/// A calendar day rendered as `yyyy-MM-dd`, used as the attendance partition
/// key. String ordering matches chronological ordering, so range queries work
/// directly on this value.
abstract final class DateKey {
  static String of(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static String today() => of(DateTime.now());

  static DateTime parse(String key) => DateTime.parse(key);
}
