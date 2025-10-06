class User {
  User({required this.id, required this.email, this.displayName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'] as int, email: json['email'] as String, displayName: json['displayName'] as String?);
  }

  final int id;
  final String email;
  final String? displayName;

  String get label => displayName ?? email;
}
