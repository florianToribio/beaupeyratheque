part of 'api_service.dart';

extension ApiServiceBooks on ApiService {
  Future<List<Book>> getBooks({String? publicationYear}) async {
    final queryParams = <String, dynamic>{};
    if (publicationYear != null) queryParams['publicationYear'] = publicationYear;

    final response = await _dio.get<List<dynamic>>('/api/books', queryParameters: queryParams);
    final items = response.data ?? const [];
    return items.map((json) => Book.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Book>> getBooksByAuthor(int authorId, {String? publicationYear}) async {
    final queryParams = <String, dynamic>{};
    if (publicationYear != null) queryParams['publicationYear'] = publicationYear;

    final response = await _dio.get<List<dynamic>>('/api/authors/$authorId/books', queryParameters: queryParams);
    final items = response.data ?? const [];
    return items.map((json) => Book.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Book> getBook(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/books/$id');
    return Book.fromJson(response.data!);
  }

  Future<Book> createBook(Book book) async {
    final response = await _dio.post<Map<String, dynamic>>('/api/books', data: book.toJson());
    return Book.fromJson(response.data!);
  }

  Future<Book> updateBook(int id, Book book) async {
    final response = await _dio.put<Map<String, dynamic>>('/api/books/$id', data: book.toJson());
    return Book.fromJson(response.data!);
  }

  Future<void> deleteBook(int id) async {
    await _dio.delete<void>('/api/books/$id');
  }

  Future<Book> borrowBook(int id, int userId) async {
    final response = await _dio.post<Map<String, dynamic>>('/api/books/$id/borrow', data: {'userId': userId});
    return Book.fromJson(response.data!);
  }

  Future<Book> returnBook(int id) async {
    final response = await _dio.post<Map<String, dynamic>>('/api/books/$id/return');
    return Book.fromJson(response.data!);
  }
}
