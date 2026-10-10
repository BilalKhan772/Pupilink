import 'dart:math';

class IdGenerator {
  IdGenerator._();

  static final Random _random = Random();

  static String generate() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = _random.nextInt(999999);

    return '$timestamp-$random';
  }

  static String generateWithPrefix(String prefix) {
    return '$prefix-${generate()}';
  }
}