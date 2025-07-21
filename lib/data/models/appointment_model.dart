class Appointment {
  final String userId;
  final String clinicId;
  final String petId;
  final String service;
  final DateTime dateTime;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.userId,
    required this.clinicId,
    required this.petId,
    required this.service,
    required this.dateTime,
    this.status = 'pending',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clinicId': clinicId,
      'petId': petId,
      'service': service,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
