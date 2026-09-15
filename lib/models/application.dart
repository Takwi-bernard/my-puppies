class Application {
  final String id;
  final String petId;
  final String? petName;
  final String? petCoverPhotoUrl;
  final String? applicantId; // null for a guest (unauthenticated) applicant
  final String? applicantName;
  final String? applicantEmail;
  final String? applicantPhone;
  final String status;
  final Map<String, dynamic>? answers;
  final DateTime createdAt;

  Application({
    required this.id,
    required this.petId,
    this.petName,
    this.petCoverPhotoUrl,
    this.applicantId,
    this.applicantName,
    this.applicantEmail,
    this.applicantPhone,
    required this.status,
    this.answers,
    required this.createdAt,
  });

  factory Application.fromMap(Map<String, dynamic> map) {
    final pet = map['pets'] as Map<String, dynamic>?;
    final profile = map['profiles'] as Map<String, dynamic>?;
    return Application(
      id: map['id'] as String,
      petId: map['pet_id'] as String,
      petName: pet?['name'] as String?,
      petCoverPhotoUrl: pet?['cover_photo_url'] as String?,
      applicantId: map['applicant_id'] as String?,
      applicantName: profile?['full_name'] as String?,
      applicantEmail: profile?['email'] as String?,
      applicantPhone: profile?['phone'] as String?,
      status: map['status'] as String? ?? 'submitted',
      answers: map['answers'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// True when this application was submitted without an account —
  /// there's no profiles row to join against, so all contact info comes
  /// straight from what they typed into the form (see `answers` below).
  bool get isGuest => applicantId == null;

  /// Prefers the contact details typed into the application form itself
  /// (answers) over the profile, since a guest applicant may not have
  /// an account/profile at all.
  String? get contactEmail => (answers?['email'] as String?) ?? applicantEmail;
  String? get contactPhone => (answers?['phone'] as String?) ?? applicantPhone;
  String? get displayName => (answers?['full_name'] as String?) ?? applicantName;
}