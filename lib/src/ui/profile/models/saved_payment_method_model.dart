class SavedPaymentMethod {
  const SavedPaymentMethod({
    required this.id,
    required this.type, // 'card', 'bank', 'wallet'
    required this.brand, // 'Visa', 'Mastercard', 'PayPak', etc.
    required this.last4,
    required this.holderName,
    required this.expiry,
    this.isDefault = false,
  });

  final String id;
  final String type;
  final String brand;
  final String last4;
  final String holderName;
  final String expiry;
  final bool isDefault;

  SavedPaymentMethod copyWith({
    String? id,
    String? type,
    String? brand,
    String? last4,
    String? holderName,
    String? expiry,
    bool? isDefault,
  }) {
    return SavedPaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      holderName: holderName ?? this.holderName,
      expiry: expiry ?? this.expiry,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'brand': brand,
      'last4': last4,
      'holderName': holderName,
      'expiry': expiry,
      'isDefault': isDefault,
    };
  }

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['id'] as String? ?? 'PM-${DateTime.now().millisecondsSinceEpoch}',
      type: json['type'] as String? ?? 'card',
      brand: json['brand'] as String? ?? 'Card',
      last4: json['last4'] as String? ?? '0000',
      holderName: json['holderName'] as String? ?? 'Cardholder',
      expiry: json['expiry'] as String? ?? '12/28',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
