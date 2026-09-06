/// Local username rules. Global uniqueness is intentionally out of scope for
/// the offline MVP — we only validate shape here.
class UsernameValidator {
  static const int minLength = 3;
  static const int maxLength = 20;

  /// Letters, digits, full stops and underscores; must start with a letter.
  static final RegExp _pattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9._]*$');

  /// Returns a human-readable error, or null when [value] is a valid username.
  static String? validate(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Pick a username';
    if (v.length < minLength) {
      return 'At least $minLength characters';
    }
    if (v.length > maxLength) {
      return 'At most $maxLength characters';
    }
    if (!_pattern.hasMatch(v)) {
      return 'Letters, numbers, full stops and underscores; start with a letter';
    }
    return null;
  }

  static bool isValid(String value) => validate(value) == null;

  /// True when [value] is within the allowed length range (checklist item).
  static bool lengthOk(String value) {
    final v = value.trim();
    return v.length >= minLength && v.length <= maxLength;
  }

  /// True when [value] uses only the allowed characters and starts with a
  /// letter (checklist item).
  static bool charsetOk(String value) {
    final v = value.trim();
    return v.isNotEmpty && _pattern.hasMatch(v);
  }
}
