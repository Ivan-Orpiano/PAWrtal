class Staff {
  late String name;
  late String department;
  String? createdBy;
  late String image;
  late String createdAt;
  late String email; // Display email (can be changed with template)
  late String authEmail; // CRITICAL: Authentication email (NEVER changes)
  String? phone;
  late String role;
  String? documentId;
  late String clinicId;
  late String userId;
  late List<String> authorities;
  late bool isActive;
  late String updatedAt;

  Staff({
    required this.name,
    required this.department,
    this.createdBy,
    required this.image,
    required this.createdAt,
    required this.email,
    required this.authEmail, // Authentication email
    this.phone,
    required this.role,
    this.documentId,
    required this.clinicId,
    required this.userId,
    required this.authorities,
    this.isActive = true,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Staff.fromMap(Map<String, dynamic> map) {
    name = map["name"] ?? 'Unknown';
    department = map["department"] ?? 'Unknown';
    createdBy = map["createdBy"]?.toString() ?? 'Unknown';
    image = map["image"] ?? '';
    createdAt = map["createdAt"] ?? '';
    email = map["email"] ?? '';
    // CRITICAL: Use authEmail if available, otherwise fallback to email
    authEmail = map["authEmail"] ?? map["email"] ?? '';
    phone = map["phone"];
    role = map["role"] ?? 'staff';
    documentId = map["\$id"] ?? '';
    clinicId = map["clinicId"] ?? '';
    userId = map["userId"] ?? '';
    authorities = List<String>.from(map["authorities"] ?? []);
    isActive = map["isActive"] ?? true;
    updatedAt = map["updatedAt"] ?? DateTime.now().toIso8601String();
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "department": department,
      "createdBy": createdBy ?? 'Unknown',
      "image": image,
      "createdAt": createdAt,
      "email": email, // Display email
      "authEmail": authEmail, // Authentication email (never changes)
      "phone": phone,
      "role": role,
      "clinicId": clinicId,
      "userId": userId,
      "authorities": authorities,
      "isActive": isActive,
      "updatedAt": updatedAt,
    };
  }

  Staff copyWith({
    String? name,
    String? department,
    String? createdBy,
    String? image,
    String? createdAt,
    String? email,
    String? authEmail,
    String? phone,
    String? role,
    String? documentId,
    String? clinicId,
    String? userId,
    List<String>? authorities,
    bool? isActive,
    String? updatedAt,
  }) {
    return Staff(
      name: name ?? this.name,
      department: department ?? this.department,
      createdBy: createdBy ?? this.createdBy,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      authEmail: authEmail ?? this.authEmail,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      documentId: documentId ?? this.documentId,
      clinicId: clinicId ?? this.clinicId,
      userId: userId ?? this.userId,
      authorities: authorities ?? this.authorities,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
