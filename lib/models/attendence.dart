class Attendance {
  final String id;
  final String customerId;
  final DateTime timestamp;

  Attendance({
    required this.id,
    required this.customerId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      customerId: map['customerId'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}