class Notification {
  final String id;
  final String customerId;
  final String customerName;
  final String message;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'],
      customerId: map['customerId'],
      customerName: map['customerName'],
      message: map['message'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}