import 'package:flutter/material.dart';

class VetClinicRegistrationRequest {
  String? documentId;
  String clinicName;
  String barangay;
  String contactNumber;
  String email;
  List<String> documentFileIds; // IDs of uploaded files in Appwrite Storage
  String status; // 'pending', 'approved', 'rejected'
  String? reviewedBy; // userId of admin who reviewed
  String? reviewNotes; // Notes from admin
  DateTime submittedAt;
  DateTime? reviewedAt;
  
  VetClinicRegistrationRequest({
    this.documentId,
    required this.clinicName,
    required this.barangay,
    required this.contactNumber,
    required this.email,
    required this.documentFileIds,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewNotes,
    required this.submittedAt,
    this.reviewedAt,
  });

  // From Appwrite Document
  factory VetClinicRegistrationRequest.fromMap(Map<String, dynamic> map) {
    return VetClinicRegistrationRequest(
      documentId: map['\$id'],
      clinicName: map['clinicName'] ?? '',
      barangay: map['barangay'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      email: map['email'] ?? '',
      documentFileIds: List<String>.from(map['documentFileIds'] ?? []),
      status: map['status'] ?? 'pending',
      reviewedBy: map['reviewedBy'],
      reviewNotes: map['reviewNotes'],
      submittedAt: DateTime.parse(map['submittedAt']),
      reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt']) : null,
    );
  }

  // To Appwrite Document
  Map<String, dynamic> toMap() {
    return {
      'clinicName': clinicName,
      'barangay': barangay,
      'contactNumber': contactNumber,
      'email': email,
      'documentFileIds': documentFileIds,
      'status': status,
      'reviewedBy': reviewedBy ?? '',
      'reviewNotes': reviewNotes ?? '',
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String() ?? '',
    };
  }

  // Full address
  String get fullAddress => 'Brgy. $barangay, San Jose del Monte, Bulacan';

  // Status color
  Color get statusColor {
    switch (status) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFFFF9800);
    }
  }

  // Status icon
  IconData get statusIcon {
    switch (status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  // Copy with
  VetClinicRegistrationRequest copyWith({
    String? documentId,
    String? clinicName,
    String? barangay,
    String? contactNumber,
    String? email,
    List<String>? documentFileIds,
    String? status,
    String? reviewedBy,
    String? reviewNotes,
    DateTime? submittedAt,
    DateTime? reviewedAt,
  }) {
    return VetClinicRegistrationRequest(
      documentId: documentId ?? this.documentId,
      clinicName: clinicName ?? this.clinicName,
      barangay: barangay ?? this.barangay,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      documentFileIds: documentFileIds ?? this.documentFileIds,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}