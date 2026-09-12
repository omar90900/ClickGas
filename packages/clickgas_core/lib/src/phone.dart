/// Jordanian mobile numbers only (the service operates in Jordan).
class JordanPhone {
  static final _e164 = RegExp(r'^\+9627[789]\d{7}$');

  /// Accepts "079 123 4567", "79 123 4567", "+962 79...", "00962 79..." and
  /// Arabic-Indic digits. Returns E.164 (+9627XXXXXXXX) or null if invalid.
  static String? normalize(String input) {
    var digits = _toAsciiDigits(input).replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00962')) digits = digits.substring(5);
    if (digits.startsWith('962')) digits = digits.substring(3);
    if (digits.startsWith('0')) digits = digits.substring(1);
    final e164 = '+962$digits';
    return _e164.hasMatch(e164) ? e164 : null;
  }

  /// +962791234567 -> 079 123 4567
  static String display(String e164) {
    if (!_e164.hasMatch(e164)) return e164;
    final local = '0${e164.substring(4)}';
    return '${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
  }

  static String _toAsciiDigits(String s) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final out = StringBuffer();
    for (final ch in s.split('')) {
      final i = arabic.indexOf(ch);
      out.write(i >= 0 ? '$i' : ch);
    }
    return out.toString();
  }
}

class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static bool isEmail(String v) => _email.hasMatch(v.trim());
}
