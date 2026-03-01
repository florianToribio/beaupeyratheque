class Author {
  Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.birthDate,
    this.nationality,
    this.biography,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String?,
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate'] as String) : null,
      nationality: json['nationality'] as String?,
      biography: json['biography'] as String?,
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final DateTime? birthDate;
  final String? nationality;
  final String? biography;

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'birthDate': birthDate?.toIso8601String(),
      'nationality': nationality,
      'biography': biography,
    };
  }

  String get fullName => '$firstName $lastName';
}
