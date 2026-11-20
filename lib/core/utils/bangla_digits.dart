const _banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

String toBanglaNumber(int number) {
  final str = number.toString();
  return str.split('').map((c) => _banglaDigits[int.parse(c)]).join();
}

/// Replaces every ASCII digit in [value] with its Bangla digit, leaving other
/// characters (decimal points, colons, slashes) alone.
String bn(Object value) {
  return value.toString().replaceAllMapped(
    RegExp(r'[0-9]'),
    (m) => _banglaDigits[int.parse(m.group(0)!)],
  );
}

/// Formats a score: whole numbers without decimals, halves with one place.
String bnScore(double value) {
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return bn(text);
}
