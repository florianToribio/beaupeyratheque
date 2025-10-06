part of 'api_service.dart';

extension ApiServiceAuthors on ApiService {
  Future<List<Author>> getAuthors({String? nationality}) async {
    final queryParams = <String, dynamic>{};
    if (nationality != null) queryParams['nationality'] = nationality;

    final response = await _dio.get<List<dynamic>>('/api/authors', queryParameters: queryParams);
    final items = response.data ?? const [];
    return items.map((json) => Author.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Author> getAuthor(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/authors/$id');
    return Author.fromJson(response.data!);
  }

  Future<Author> createAuthor(Author author) async {
    final response = await _dio.post<Map<String, dynamic>>('/api/authors', data: author.toJson());
    return Author.fromJson(response.data!);
  }

  Future<Author> updateAuthor(int id, Author author) async {
    final response = await _dio.put<Map<String, dynamic>>('/api/authors/$id', data: author.toJson());
    return Author.fromJson(response.data!);
  }

  Future<void> deleteAuthor(int id) async {
    await _dio.delete<void>('/api/authors/$id');
  }
}
