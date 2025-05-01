class Staff {
  late String name;
  late String department;
  String? createdBy;
  late String image;
  late String createdAt;
  late String email;
  late String role;
  String? documentId;
  late String clinicId;

  Staff.fromMap(Map<String, dynamic> map) {
    
    name = map["name"] ?? 'Unknown';
    department = map["department"] ?? 'Unknown'; 
    createdBy = map["createdBy"]?.toString() ?? 'Unknown';
    image = map["image"] ?? '';
    createdAt = map["createdAt"] ?? '';
    email = map["email"] ?? '';
    role = map["role"] ?? '';
    documentId = map["\$id"] ?? '';
    clinicId = map["clinicId"] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "department": department,
      "createdBy": createdBy ?? 'Unknown',
      "image": image,
      "createdAt": createdAt,
      "email": email,
      "role": role,
      "clinicId": clinicId,
    };
  }
}