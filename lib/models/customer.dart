class Customer {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String gender;
  final double weight;
  final String trainingType;
  final DateTime startDate;
  final DateTime endDate;
  final double fees;
  final String paymentStatus;
  final String paymentType;
  final String? planId;
  final String? profilePic; // base64 encoded image

  Customer({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.gender,
    required this.weight,
    required this.trainingType,
    required this.startDate,
    required this.endDate,
    required this.fees,
    required this.paymentStatus,
    required this.paymentType,
    this.planId,
    this.profilePic,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'phoneNumber': phoneNumber,
      'gender': gender,
      'weight': weight,
      'trainingType': trainingType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'fees': fees,
      'paymentStatus': paymentStatus,
      'paymentType': paymentType,
      'planId': planId,
      'profilePic': profilePic,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      dateOfBirth: DateTime.parse(map['dateOfBirth']),
      phoneNumber: map['phoneNumber'] ?? '',
      gender: map['gender'],
      weight: (map['weight'] is int)
          ? (map['weight'] as int).toDouble()
          : (map['weight'] as num).toDouble(),
      trainingType: map['trainingType'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      fees: (map['fees'] is int)
          ? (map['fees'] as int).toDouble()
          : (map['fees'] as num).toDouble(),
      paymentStatus: map['paymentStatus'] ?? 'Pending',
      paymentType: map['paymentType'] ?? 'CASH',
      planId: map['planId'],
      profilePic: map['profilePic'],
    );
  }
}
