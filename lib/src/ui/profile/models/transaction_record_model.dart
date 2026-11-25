class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.referenceId,
    required this.paymentMethod,
    required this.status,
    this.applicationRef,
    this.category,
    this.receiptUrl,
  });

  final String id;
  final String title;
  final String amount;
  final DateTime date;
  final String referenceId;
  final String paymentMethod;
  final String status; // 'completed', 'pending', 'failed'
  final String? applicationRef;
  final String? category;
  final String? receiptUrl;

  bool get isCompleted => status.toLowerCase() == 'completed' || status.toLowerCase() == 'success';
  bool get isPending => status.toLowerCase() == 'pending' || status.toLowerCase().contains('verif');
  bool get isFailed => status.toLowerCase() == 'failed';

  TransactionRecord copyWith({
    String? id,
    String? title,
    String? amount,
    DateTime? date,
    String? referenceId,
    String? paymentMethod,
    String? status,
    String? applicationRef,
    String? category,
    String? receiptUrl,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      referenceId: referenceId ?? this.referenceId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      applicationRef: applicationRef ?? this.applicationRef,
      category: category ?? this.category,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'referenceId': referenceId,
      'paymentMethod': paymentMethod,
      'status': status,
      'applicationRef': applicationRef,
      'category': category,
      'receiptUrl': receiptUrl,
    };
  }

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as String? ?? 'TX-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Consultation Retainer',
      amount: json['amount'] as String? ?? 'PKR 0',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      referenceId: json['referenceId'] as String? ?? 'REF-0000',
      paymentMethod: json['paymentMethod'] as String? ?? 'Online Payment',
      status: json['status'] as String? ?? 'completed',
      applicationRef: json['applicationRef'] as String?,
      category: json['category'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
    );
  }
}
