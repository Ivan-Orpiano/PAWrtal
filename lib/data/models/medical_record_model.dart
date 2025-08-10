import 'package:capstone_app/data/models/appointment_model.dart';

class MedicalRecord {
  final String? id;
  final String petId;
  final String clinicId;
  final String vetId;
  final String appointmentId;
  final DateTime visitDate;
  final String service;
  final String diagnosis;
  final String treatment;
  final String? prescription;
  final String? notes;
  final Map<String, dynamic>? vitals;
  final List<String>? attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicalRecord({
    this.id,
    required this.petId,
    required this.clinicId,
    required this.vetId,
    required this.appointmentId,
    required this.visitDate,
    required this.service,
    required this.diagnosis,
    required this.treatment,
    this.prescription,
    this.notes,
    this.vitals,
    this.attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory MedicalRecord.fromAppointment(Appointment appointment, String vetId) {
    return MedicalRecord(
      petId: appointment.petId,
      clinicId: appointment.clinicId,
      vetId: vetId,
      appointmentId: appointment.documentId!,
      visitDate: appointment.serviceCompletedAt ?? appointment.updatedAt,
      service: appointment.service,
      diagnosis: appointment.diagnosis ?? '',
      treatment: appointment.treatment ?? '',
      prescription: appointment.prescription,
      notes: appointment.vetNotes,
      vitals: appointment.vitals,
      attachments: appointment.attachments,
    );
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['\$id'],
      petId: map['petId'],
      clinicId: map['clinicId'],
      vetId: map['vetId'],
      appointmentId: map['appointmentId'],
      visitDate: DateTime.parse(map['visitDate']),
      service: map['service'],
      diagnosis: map['diagnosis'],
      treatment: map['treatment'],
      prescription: map['prescription'],
      notes: map['notes'],
      vitals: map['vitals'],
      attachments: map['attachments'] != null ? List<String>.from(map['attachments']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'clinicId': clinicId,
      'vetId': vetId,
      'appointmentId': appointmentId,
      'visitDate': visitDate.toIso8601String(),
      'service': service,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescription,
      'notes': notes,
      'vitals': vitals,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}