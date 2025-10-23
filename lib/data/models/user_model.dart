class User {
  late String userId;
  late String name;
  late String email;
  late String role;
  String? phone;
  String? documentId;
  String? profilePictureId; // NEW: Profile picture field

  // ID verification fields
  bool idVerified;
  String? idVerifiedAt;
  String? verificationDocumentId; 

  // Archive/Soft Delete fields
  bool isArchived;
  String? archivedAt;
  String? archivedBy;
  String? archiveReason;
  String? archivedDocumentId;

  User.fromMap(Map<String, dynamic> map)
      : idVerified = map["idVerified"] as bool? ?? false,
        idVerifiedAt = map["idVerifiedAt"] as String?,
        verificationDocumentId = map["verificationDocumentId"] as String?,
        isArchived = map["isArchived"] as bool? ?? false,
        archivedAt = map["archivedAt"] as String?,
        archivedBy = map["archivedBy"] as String?,
        archiveReason = map["archiveReason"] as String?,
        archivedDocumentId = map["archivedDocumentId"] as String?,
        profilePictureId = map["profilePictureId"] as String? { // NEW
    documentId = map["\$id"] ?? '';
    userId = map["userId"] ?? '';
    name = map["name"] ?? '';
    phone = map["phone"] ?? '';
    email = map["email"] ?? '';
    role = map["role"] ?? 'user';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'profilePictureId': profilePictureId, 
      'idVerified': idVerified,
      'idVerifiedAt': idVerifiedAt,
      'verificationDocumentId': verificationDocumentId,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
      'archivedBy': archivedBy,
      'archiveReason': archiveReason,
      'archivedDocumentId': archivedDocumentId,
    };
  }

  // Helper getter to check if user needs ID verification
  bool get requiresIdVerification {
    return (role == 'customer' || role == 'user') && !idVerified;
  }

  // Helper getter for verification status display
  String get verificationStatusText {
    if (idVerified) {
      return 'ID Verified';
    } else if (role == 'admin' || role == 'staff') {
      return 'Verification Not Required';
    } else {
      return 'ID Not Verified';
    }
  }

  // Helper getter for archive status
  String get archiveStatusText {
    if (!isArchived) return 'Active';
    
    if (archivedAt != null) {
      try {
        final archived = DateTime.parse(archivedAt!);
        final deletionDate = archived.add(const Duration(days: 30));
        final now = DateTime.now();
        final daysLeft = deletionDate.difference(now).inDays;
        
        if (daysLeft <= 0) {
          return 'Pending Permanent Deletion';
        }
        return 'Archived ($daysLeft days left)';
      } catch (e) {
        return 'Archived';
      }
    }
    
    return 'Archived';
  }

  // Helper getter to check if user can be recovered
  bool get canBeRecovered {
    if (!isArchived || archivedAt == null) return false;
    
    try {
      final archived = DateTime.parse(archivedAt!);
      final deletionDate = archived.add(const Duration(days: 30));
      return DateTime.now().isBefore(deletionDate);
    } catch (e) {
      return false;
    }
  }

  // NEW: Helper getter to check if user has profile picture
  bool get hasProfilePicture {
    return profilePictureId != null && profilePictureId!.isNotEmpty;
  }
}