import 'dart:math';

class CodeGenerator {
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final Random _random = Random();

  /// Generates a random 5-character alphanumeric code
  static String generateCode() {
    return String.fromCharCodes(
      Iterable.generate(
        5,
        (_) => _chars.codeUnitAt(_random.nextInt(_chars.length)),
      ),
    );
  }

  /// Validates that a code is exactly 5 alphanumeric characters
  static bool isValidCode(String code) {
    if (code.length != 5) return false;
    return code.toUpperCase().split('').every(
          (char) => _chars.contains(char),
        );
  }
}

