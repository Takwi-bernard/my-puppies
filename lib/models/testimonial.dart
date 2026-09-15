class Testimonial {
  final String id;
  final String? photoUrl;
  final String description;
  final String? familyName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Testimonial({
    required this.id,
    this.photoUrl,
    required this.description,
    this.familyName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Testimonial.fromMap(Map<String, dynamic> map) {
    return Testimonial(
      id: map['id'] as String,
      photoUrl: map['photo_url'] as String?,
      description: map['description'] as String,
      familyName: map['family_name'] as String?,
      status: map['status'] as String? ?? 'published',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'photo_url': photoUrl,
      'description': description,
      'family_name': familyName,
      'status': status,
    };
  }
} 