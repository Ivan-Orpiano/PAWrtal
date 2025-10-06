class Appointment {
  final String? documentId;
  final String userId;
  final String clinicId;
  final String petId;
  final String service;
  final DateTime dateTime;
  final String status; // pending, accepted, in_progress, completed, no_show, declined, cancelled
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Medical record fields
  final DateTime? checkedInAt;
  final DateTime? serviceStartedAt;
  final DateTime? serviceCompletedAt;
  final String? diagnosis;
  final String? treatment;
  final String? prescription;
  final String? vetNotes;
  final List<String>? attachments;
  final double? totalCost;  // Keep but don't use
  final bool isPaid;  // Keep but don't use
  final String? paymentMethod;  // Keep but don't use
  final String? followUpInstructions;
  final DateTime? nextAppointmentDate;
  final Map<String, dynamic>? vitals;

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
    this.checkedInAt,
    this.serviceStartedAt,
    this.serviceCompletedAt,
    this.diagnosis,
    this.treatment,
    this.prescription,
    this.vetNotes,
    this.attachments,
    this.totalCost,
    this.isPaid = false,
    this.paymentMethod,
    this.followUpInstructions,
    this.nextAppointmentDate,
    this.vitals,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      documentId: map['\$id'],
      userId: map['userId'],
      clinicId: map['clinicId'] ?? '',
      petId: map['petId'] ?? '',
      service: map['service'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      checkedInAt: map['checkedInAt'] != null ? DateTime.parse(map['checkedInAt']) : null,
      serviceStartedAt: map['serviceStartedAt'] != null ? DateTime.parse(map['serviceStartedAt']) : null,
      serviceCompletedAt: map['serviceCompletedAt'] != null ? DateTime.parse(map['serviceCompletedAt']) : null,
      diagnosis: map['diagnosis'],
      treatment: map['treatment'],
      prescription: map['prescription'],
      vetNotes: map['vetNotes'],
      attachments: map['attachments'] != null ? List<String>.from(map['attachments']) : null,
      totalCost: map['totalCost']?.toDouble(),
      isPaid: map['isPaid'] ?? false,
      paymentMethod: map['paymentMethod'],
      followUpInstructions: map['followUpInstructions'],
      nextAppointmentDate: map['nextAppointmentDate'] != null ? DateTime.parse(map['nextAppointmentDate']) : null,
      vitals: map['vitals'],
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
      'checkedInAt': checkedInAt?.toIso8601String(),
      'serviceStartedAt': serviceStartedAt?.toIso8601String(),
      'serviceCompletedAt': serviceCompletedAt?.toIso8601String(),
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescription,
      'vetNotes': vetNotes,
      'attachments': attachments,
      'totalCost': totalCost,
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'followUpInstructions': followUpInstructions,
      'nextAppointmentDate': nextAppointmentDate?.toIso8601String(),
      'vitals': vitals,
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
    DateTime? checkedInAt,
    DateTime? serviceStartedAt,
    DateTime? serviceCompletedAt,
    String? diagnosis,
    String? treatment,
    String? prescription,
    String? vetNotes,
    List<String>? attachments,
    double? totalCost,
    bool? isPaid,
    String? paymentMethod,
    String? followUpInstructions,
    DateTime? nextAppointmentDate,
    Map<String, dynamic>? vitals,
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
      checkedInAt: checkedInAt ?? this.checkedInAt,
      serviceStartedAt: serviceStartedAt ?? this.serviceStartedAt,
      serviceCompletedAt: serviceCompletedAt ?? this.serviceCompletedAt,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      prescription: prescription ?? this.prescription,
      vetNotes: vetNotes ?? this.vetNotes,
      attachments: attachments ?? this.attachments,
      totalCost: totalCost ?? this.totalCost,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      followUpInstructions: followUpInstructions ?? this.followUpInstructions,
      nextAppointmentDate: nextAppointmentDate ?? this.nextAppointmentDate,
      vitals: vitals ?? this.vitals,
    );
  }

  // Helper methods
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';
  bool get isDeclined => status == 'declined';
  bool get hasArrived => checkedInAt != null;
  bool get hasServiceStarted => serviceStartedAt != null;
  bool get hasServiceCompleted => serviceCompletedAt != null;
  bool get hasMedicalRecord => diagnosis != null || treatment != null || prescription != null;

  // Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }

  // Check if appointment is in the past
  bool get isPast {
    final now = DateTime.now();
    final appointmentDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final today = DateTime(now.year, now.month, now.day);
    return appointmentDate.isBefore(today);
  }

  // Get service duration
  Duration? get serviceDuration {
    if (serviceStartedAt != null && serviceCompletedAt != null) {
      return serviceCompletedAt!.difference(serviceStartedAt!);
    }
    return null;
  }

  // Get waiting time
  Duration? get waitingTime {
    if (checkedInAt != null && serviceStartedAt != null) {
      return serviceStartedAt!.difference(checkedInAt!);
    }
    return null;
  }
}