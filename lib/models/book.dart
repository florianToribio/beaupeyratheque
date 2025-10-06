import 'package:beaupeyratheque_mobile/models/author.dart';

class Book {
  Book({
    required this.id,
    required this.title,
    required this.publicationYear,
    this.description,
    this.author,
    this.isBorrowed = false,
    this.borrowerId,
    this.borrowerName,
    this.imageUrl,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final borrower = json['borrower'] as Map<String, dynamic>?;
    return Book(
      id: json['id'] as int,
      title: json['title'] as String,
      publicationYear: json['publicationYear'] as int,
      description: json['description'] as String?,
      author: json['author'] != null ? Author.fromJson(json['author'] as Map<String, dynamic>) : null,
      isBorrowed: (json['borrowed'] as bool?) ?? false,
      borrowerId: borrower != null ? borrower['id'] as int? : null,
      borrowerName: borrower != null ? borrower['displayName'] as String? ?? borrower['email'] as String? : null,
      imageUrl: json['image'] as String?,
    );
  }

  final int id;
  final String title;
  final String? description;
  final int publicationYear;
  final Author? author;
  final bool isBorrowed;
  final int? borrowerId;
  final String? borrowerName;
  final String? imageUrl;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'publicationYear': publicationYear,
      'author': author != null ? '/api/authors/${author!.id}' : null,
      'image': imageUrl,
      'borrowed': isBorrowed,
      'borrower': borrowerId != null ? '/api/users/$borrowerId' : null,
    };
  }
}
