import 'api_client.dart';

class DailyService {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> today() async =>
      (await _api.get('/daily')) as Map<String, dynamic>;

  Future<Map<String, dynamic>> complete({
    required String difficulty,
    required int moves,
    required int seconds,
  }) async =>
      (await _api.post('/daily/complete', {
        'difficulty': difficulty,
        'moves': moves,
        'seconds': seconds,
      })) as Map<String, dynamic>;

  Future<Map<String, dynamic>> leaderboard({
    required String difficulty,
    String? date,
  }) async =>
      (await _api.get('/daily/leaderboard', query: {
        'difficulty': difficulty,
        if (date != null) 'date': date,
      })) as Map<String, dynamic>;
}
