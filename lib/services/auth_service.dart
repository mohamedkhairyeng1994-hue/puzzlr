import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.post('/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
    }) as Map<String, dynamic>;
    await _api.setToken(res['token'] as String?);
    return res['user'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post('/login', {
      'email': email,
      'password': password,
      'device_name': 'flutter',
    }) as Map<String, dynamic>;
    await _api.setToken(res['token'] as String?);
    return res['user'] as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (_) {
      // ignore — clearing token locally is enough
    }
    await _api.setToken(null);
  }
}
