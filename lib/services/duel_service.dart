import 'api_client.dart';

class DuelService {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> create(String difficulty) async =>
      (await _api.post('/duels', {'difficulty': difficulty}))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> join(String code) async =>
      (await _api.post('/duels/join', {'code': code}))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> show(int id) async =>
      (await _api.get('/duels/$id')) as Map<String, dynamic>;

  Future<Map<String, dynamic>> submit({
    required int id,
    required int moves,
    required int seconds,
  }) async =>
      (await _api.post('/duels/$id/submit', {
        'moves': moves,
        'seconds': seconds,
      })) as Map<String, dynamic>;

  Future<List<dynamic>> mine() async {
    final res = (await _api.get('/duels/mine')) as Map<String, dynamic>;
    return (res['duels'] as List<dynamic>?) ?? const [];
  }
}
