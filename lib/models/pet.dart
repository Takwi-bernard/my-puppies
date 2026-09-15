class Pet {
  final String id;
  final String name;
  final String species;
  final String? breed;
  final String? ageCategory;
  final String? gender;
  final String? size;
  final String? locationCity;
  final String? locationState;
  final String? bio;
  final double? adoptionFee;
  final String status;
  final String? coverPhotoUrl;
  final String? color; // New field for pet color

  Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.ageCategory,
    this.gender,
    this.size,
    this.locationCity,
    this.locationState,
    this.bio,
    this.adoptionFee,
    required this.status,
    this.coverPhotoUrl,
    this.color,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] as String,
      name: map['name'] as String,
      species: map['species'] as String,
      breed: map['breed'] as String?,
      ageCategory: map['age_category'] as String?,
      gender: map['gender'] as String?,
      size: map['size'] as String?,
      locationCity: map['location_city'] as String?,
      locationState: map['location_state'] as String?,
      bio: map['bio'] as String?,
      adoptionFee: (map['adoption_fee'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'available',
      coverPhotoUrl: map['cover_photo_url'] as String?,
      color: map['color'] as String?,
    );
  }
}