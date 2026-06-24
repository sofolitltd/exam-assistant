const _banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

String toBanglaNumber(int number) {
  final str = number.toString();
  return str.split('').map((c) => _banglaDigits[int.parse(c)]).join();
}
