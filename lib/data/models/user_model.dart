class User {
  late String userId;
  late String name;
  late String email;
  late String role;
  String? phone;
  String? documentId;

  User.fromMap(Map<String, dynamic> map){
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
    };
  }
}
