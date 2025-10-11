class User {
  late String userId;
  late String name;
  late String email;
  late String role;
  String? phone;
  String? documentId;

  // New fields for ID verification
  bool idVerified;
  String? idVerifiedAt;

  User.fromMap(Map<String, dynamic> map)
      : idVerified = map["idVerified"] as bool? ?? false,
        idVerifiedAt = map["idVerifiedAt"] as String? {
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
      'idVerified': idVerified,
      'idVerifiedAt': idVerifiedAt,
    };
  }

// Helper getter to check if user needs ID verification
  bool get requiresIdVerification {
    // Only regular users need verification
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
}