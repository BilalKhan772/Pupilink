class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int durationInDays;
  final List<String> features;
  final int? maxStudents;
  final int? maxStaff;
  final bool isActive;
  final bool isPopular;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.currency = 'PKR',
    required this.durationInDays,
    this.features = const [],
    this.maxStudents,
    this.maxStaff,
    this.isActive = true,
    this.isPopular = false,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlan.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return SubscriptionPlan(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: _subscriptionPlanDouble(map['price']),
      currency: map['currency'] as String? ?? 'PKR',
      durationInDays: _subscriptionPlanInt(
        map['durationInDays'],
      ),
      features: (map['features'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      maxStudents: map['maxStudents'] == null
          ? null
          : _subscriptionPlanInt(map['maxStudents']),
      maxStaff: map['maxStaff'] == null
          ? null
          : _subscriptionPlanInt(map['maxStaff']),
      isActive: map['isActive'] as bool? ?? true,
      isPopular: map['isPopular'] as bool? ?? false,
      createdAt: _subscriptionPlanDateTime(map['createdAt']),
      updatedAt: _subscriptionPlanDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'durationInDays': durationInDays,
      'features': features,
      'maxStudents': maxStudents,
      'maxStaff': maxStaff,
      'isActive': isActive,
      'isPopular': isPopular,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get hasUnlimitedStudents => maxStudents == null;

  bool get hasUnlimitedStaff => maxStaff == null;

  bool get hasValidPrice => price >= 0;

  bool get hasValidDuration => durationInDays > 0;

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    int? durationInDays,
    List<String>? features,
    int? maxStudents,
    int? maxStaff,
    bool? isActive,
    bool? isPopular,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      durationInDays: durationInDays ?? this.durationInDays,
      features: features ?? this.features,
      maxStudents: maxStudents ?? this.maxStudents,
      maxStaff: maxStaff ?? this.maxStaff,
      isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

double _subscriptionPlanDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _subscriptionPlanInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _subscriptionPlanDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  // Firestore Timestamp support without importing Firebase packages.
  if (value is String) return DateTime.tryParse(value);

  try {
    final dynamic date = value.toDate();
    if (date is DateTime) return date;
  } catch (_) {
    // Return null if the value is not a supported date format.
  }

  return null;
}