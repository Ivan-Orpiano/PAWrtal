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

  // NEW: Individual vital fields (properly typed)
  final double? temperature;
  final double? weight;
  final String? bloodPressure;
  final int? heartRate;

  // DEPRECATED: Keep for backward compatibility, but prioritize individual fields
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
    this.temperature,
    this.weight,
    this.bloodPressure,
    this.heartRate,
    this.vitals,
    this.attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory MedicalRecord.fromAppointment(Appointment appointment, String vetId) {
    // Extract individual vitals from appointment.vitals map if available
    double? temp;
    double? wt;
    String? bp;
    int? hr;

    if (appointment.vitals != null) {
      temp = appointment.vitals!['temperature']?.toDouble();
      wt = appointment.vitals!['weight']?.toDouble();
      bp = appointment.vitals!['bloodPressure']?.toString();
      hr = appointment.vitals!['heartRate']?.toInt();
    }

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
      temperature: temp,
      weight: wt,
      bloodPressure: bp,
      heartRate: hr,
      vitals: appointment.vitals, // Keep for backward compatibility
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
      temperature: map['temperature']?.toDouble(),
      weight: map['weight']?.toDouble(),
      bloodPressure: map['bloodPressure'],
      heartRate: map['heartRate']?.toInt(),
      vitals: map['vitals'],
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    print('>>> MedicalRecord toMap() called');
    print('>>>   - temperature: $temperature');
    print('>>>   - weight: $weight');
    print('>>>   - bloodPressure: $bloodPressure');
    print('>>>   - heartRate: $heartRate');
    print('>>>   - vitals: $vitals');

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
      // CRITICAL: Individual vital fields - explicitly include even if null
      'temperature': temperature,
      'weight': weight,
      'bloodPressure': bloodPressure,
      'heartRate': heartRate,
      // CRITICAL: Keep the full vitals map
      'vitals': vitals,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  bool get hasVitals =>
      temperature != null ||
      weight != null ||
      bloodPressure != null ||
      heartRate != null;

  String get vitalsDisplay {
    if (!hasVitals) return 'No vitals recorded';

    final parts = <String>[];
    if (temperature != null) parts.add('Temp: ${temperature}°C');
    if (weight != null) parts.add('Weight: ${weight}kg');
    if (bloodPressure != null) parts.add('BP: $bloodPressure');
    if (heartRate != null) parts.add('HR: $heartRate bpm');

    return parts.join(' • ');
  }
}
