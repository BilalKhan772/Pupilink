extension StringExtension on String {
  String get capitalize {
    if (trim().isEmpty) {
      return this;
    }

    final value = trim();

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String get titleCase {
    if (trim().isEmpty) {
      return this;
    }

    return trim()
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String get initials {
    final words = trim().split(RegExp(r'\s+'));

    if (words.isEmpty) {
      return '';
    }

    return words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
  }

  bool get isNullOrEmpty => trim().isEmpty;

  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }

  String get snakeCase {
    return trim()
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceFirst(RegExp(r'^_'), '')
        .toLowerCase();
  }
}