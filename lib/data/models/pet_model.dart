class Pet {
  late String petId;
  late String userId;
  late String name;
  late String type;
  late String breed;
  String? color;
  String? image;
  String? notes;
  double? weight;
  String? createdAt;
  String? documentId;
  String? gender;

  Pet({
    required this.petId,
    required this.userId,
    required this.name,
    required this.type,
    required this.breed,
    this.color,
    this.image,
    this.notes,
    this.weight,
    this.createdAt,
    this.documentId,
    this.gender,
  });

  Pet.fromMap(Map<String, dynamic> map) {
    petId = map['petId'] ?? '';
    userId = map['userId'] ?? '';
    name = map['name'] ?? '';
    type = map['type'] ?? '';
    breed = map['breed'] ?? '';
    color = map['color'] ?? '';
    image = map['image'] ?? '';
    notes = map['notes'];
    weight = (map['weight'] as num?)?.toDouble() ?? 0.0;
    createdAt = map['\$createdAt'] ?? '';
    documentId = map['\$id'] ?? '';
    gender = map['gender'] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'userId': userId,
      'name': name,
      'type': type,
      'breed': breed,
      'color': color,
      'image': image,
      'notes': notes,
      'weight': weight,
      'gender': gender,
    };
  }

  Pet copyWith({
    String? petId,
    String? userId,
    String? name,
    String? type,
    String? breed,
    String? color,
    String? image,
    String? notes,
    double? weight,
    String? createdAt,
    String? documentId,
    String? gender,
  }) {
    return Pet(
      petId: petId ?? this.petId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      color: color ?? this.color,
      image: image ?? this.image,
      notes: notes ?? this.notes,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      documentId: documentId ?? this.documentId,
      gender: gender ?? this.gender,
    );
  }
}
