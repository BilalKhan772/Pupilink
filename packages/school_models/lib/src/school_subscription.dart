class SchoolSubscription {
  final String id;
  final String schoolId;
  final String planId;
  final String planName;
  final double price;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String paymentStatus;
  final String? transactionId;
  final String? paymentMethod;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SchoolSubscription({
    required this.id,
    required this.schoolId,
    required this.planId,
    required this.planName,
    required this.price,
    this.currency = 'PKR',
    required this.startDate,
    required this.endDate,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.transactionId,
    this.paymentMethod,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolSubscription.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return SchoolSubscription(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      planId: map['planId'] as String? ?? '',
      planName: map['planName'] as String? ?? '',
      price: _schoolSubscriptionDouble(map['price']),
      currency: map['currency'] as String? ?? 'PKR',
      startDate: _schoolSubscriptionDateTime(
        map['startDate'],
      ) ?? DateTime(2000),
      endDate: _schoolSubscriptionDateTime(
        map['endDate'],
      ) ?? DateTime(2000),
      status: map['status'] as String? ?? 'pending',
      paymentStatus:
          map['paymentStatus'] as String? ?? 'unpaid',
      transactionId: map['transactionId'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      paidAt: _schoolSubscriptionDateTime(map['paidAt']),
      createdAt: _schoolSubscriptionDateTime(map['createdAt']),
      updatedAt: _schoolSubscriptionDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'planId': planId,
      'planName': planName,
      'price': price,
      'currency': currency,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'paymentStatus': paymentStatus,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'paidAt': paidAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isActive => status == 'active';

  bool get isPending => status == 'pending';

  bool get isCancelled => status == 'cancelled';

  bool get isExpired =>
      status == 'expired' || DateTime.now().isAfter(endDate);

  bool get isPaid => paymentStatus == 'paid';

  bool get isUnpaid => paymentStatus == 'unpaid';

  bool get hasValidDateRange => endDate.isAfter(startDate);

  int get remainingDays {
    final difference = endDate.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }

  SchoolSubscription copyWith({
    String? id,
    String? schoolId,
    String? planId,
    String? planName,
    double? price,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? paymentStatus,
    String? transactionId,
    String? paymentMethod,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolSubscription(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

double _schoolSubscriptionDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

DateTime? _schoolSubscriptionDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  if (value is String) {
    return DateTime.tryParse(value);
  }

  try {
    final dynamic date = value.toDate();
    if (date is DateTime) return date;
  } catch (_) {
    // Unsupported date value.
  }

  return null;
}