class RegexPatterns {
  RegexPatterns._();

  static final RegExp email = RegExp(
    r'^[\w\.-]+@[\w\.-]+\.\w+$',
  );

  static final RegExp phoneNumber = RegExp(
    r'^\+?[0-9]{10,15}$',
  );

  static final RegExp admissionNumber = RegExp(
    r'^[A-Za-z0-9\-_\/]+$',
  );

  static final RegExp password = RegExp(
    r'^.{6,}$',
  );

  static final RegExp name = RegExp(
    r"^[A-Za-zÀ-ÿ\u0600-\u06FF\s.'-]+$",
  );

  static final RegExp numeric = RegExp(
    r'^[0-9]+$',
  );

  static final RegExp decimal = RegExp(
    r'^\d+(\.\d+)?$',
  );
}