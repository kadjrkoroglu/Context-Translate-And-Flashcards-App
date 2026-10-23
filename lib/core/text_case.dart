/// First letter in upper case, the rest as typed: "car" → "Car".
/// Turkish and Azerbaijani turn "i" into "İ"; without a [language], letters
/// only Turkish has (ğ, ı, ş) tell.
String capitalizeFirst(String text, {String? language}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return trimmed;
  final first = String.fromCharCode(trimmed.runes.first);
  final rest = trimmed.substring(first.length);
  final turkic =
      language == 'Turkish' ||
      language == 'Azerbaijani' ||
      (language == null && RegExp('[ğışĞİŞ]').hasMatch(trimmed));
  return (first == 'i' && turkic ? 'İ' : first.toUpperCase()) + rest;
}
