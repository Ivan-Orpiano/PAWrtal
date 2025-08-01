class Appointment {
  final String? documentId;
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
    this.documentId,
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

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      documentId: map['\$id'], // Get document ID from AppWrite
      userId: map['userId'] ?? '',
      clinicId: map['clinicId'] ?? '',
      petId: map['petId'] ?? '',
      service: map['service'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

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

  Appointment copyWith({
    String? documentId,
    String? userId,
    String? clinicId,
    String? petId,
    String? service,
    DateTime? dateTime,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      clinicId: clinicId ?? this.clinicId,
      petId: petId ?? this.petId,
      service: service ?? this.service,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
