import 'api_client.dart';

class LeaderboardService {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> bestMoves(String difficulty) async =>
      (await _api.get('/leaderboard/best-moves', query: {'difficulty': difficulty}))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> global() async =>
      (await _api.get('/leaderboard/global')) as Map<String, dynamic>;
}
