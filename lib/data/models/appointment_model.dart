class Appointment {
  final String userId;
  final String clinicId;
  final String petName;
  final String service;
  final String time;
  final DateTime date;
  final String status;

  Appointment({
    required this.userId,
    required this.clinicId,
    required this.petName,
    required this.service,
    required this.time,
    required this.date,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clinicId': clinicId,
      'petName': petName,
      'service': service,
      'time': time,
      'date': date.toIso8601String(),
      'status': status,
    };
  }
}
