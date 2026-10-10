class PaymentRecord {
  final String id;
  final String schoolId;
  final String? subscriptionId;
  final String? planId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String status;
  final String? transactionId;
  final String? receiptUrl;
  final String? description;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentRecord({
    required this.id,
    required this.schoolId,
    this.subscriptionId,
    this.planId,
    required this.amount,
    this.currency = 'PKR',
    this.paymentMethod = 'manual',
    this.status = 'pending',
    this.transactionId,
    this.receiptUrl,
    this.description,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentRecord.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return PaymentRecord(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      subscriptionId: map['subscriptionId'] as String?,
      planId: map['planId'] as String?,
      amount: _paymentRecordDouble(map['amount']),
      currency: map['currency'] as String? ?? 'PKR',
      paymentMethod:
          map['paymentMethod'] as String? ?? 'manual',
      status: map['status'] as String? ?? 'pending',
      transactionId: map['transactionId'] as String?,
      receiptUrl: map['receiptUrl'] as String?,
      description: map['description'] as String?,
      paidAt: _paymentRecordDateTime(map['paidAt']),
      createdAt: _paymentRecordDateTime(map['createdAt']),
      updatedAt: _paymentRecordDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'subscriptionId': subscriptionId,
      'planId': planId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'status': status,
      'transactionId': transactionId,
      'receiptUrl': receiptUrl,
      'description': description,
      'paidAt': paidAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isPending => status == 'pending';

  bool get isPaid => status == 'paid';

  bool get isFailed => status == 'failed';

  bool get isRefunded => status == 'refunded';

  bool get hasValidAmount => amount >= 0;

  PaymentRecord copyWith({
    String? id,
    String? schoolId,
    String? subscriptionId,
    String? planId,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? status,
    String? transactionId,
    String? receiptUrl,
    String? description,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      planId: planId ?? this.planId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      description: description ?? this.description,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

double _paymentRecordDouble(dynamic value) {
  if (value is num) return value.toDouble();

  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }

  return 0.0;
}

DateTime? _paymentRecordDateTime(dynamic value) {
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