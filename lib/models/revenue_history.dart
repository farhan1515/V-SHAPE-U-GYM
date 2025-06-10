class RevenueHistory {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final DateTime paymentDate;
  final String paymentType; // 'new' or 'renewal'
  final DateTime membershipStartDate;
  final DateTime membershipEndDate;

  RevenueHistory({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.paymentDate,
    required this.paymentType,
    required this.membershipStartDate,
    required this.membershipEndDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentType': paymentType,
      'membershipStartDate': membershipStartDate.toIso8601String(),
      'membershipEndDate': membershipEndDate.toIso8601String(),
    };
  }

  factory RevenueHistory.fromMap(Map<String, dynamic> map) {
    return RevenueHistory(
      id: map['id'],
      customerId: map['customerId'],
      customerName: map['customerName'],
      amount: map['amount'].toDouble(),
      paymentDate: DateTime.parse(map['paymentDate']),
      paymentType: map['paymentType'],
      membershipStartDate: DateTime.parse(map['membershipStartDate']),
      membershipEndDate: DateTime.parse(map['membershipEndDate']),
    );
  }
}
