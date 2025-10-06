part of 'api_service.dart';

extension ApiServiceAuth on ApiService {
  Future<void> login(String email, String password) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/token',
      data: {'email': email, 'password': password},
      options: Options(headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}),
    );
  }

  Future<void> register(String email, String password, {String? displayName}) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/users',
      data: {
        'email': email,
        'password': password,
        if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
      },
      options: Options(headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}),
    );
  }
}
