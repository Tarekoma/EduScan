/// First letter of the first two words in [className], e.g. "Senior A" -> "SA".
String classInitials(String className) {
  final words = className.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final letters = words.take(2).map((w) => w[0].toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}
