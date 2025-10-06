part of 'api_service.dart';

extension ApiServiceUsers on ApiService {
  Future<List<User>> getUsers() async {
    final response = await _dio.get<List<dynamic>>('/api/users');
    final items = response.data ?? const [];
    return items.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
  }
}
