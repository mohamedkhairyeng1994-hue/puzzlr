import 'api_client.dart';

class SolveService {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> submit({
    required String difficulty,
    required int moves,
    required int seconds,
    required bool usedPowerups,
    bool isTimeAttack = false,
    bool isCustomPhoto = false,
    bool isDaily = false,
  }) async {
    return (await _api.post('/solves', {
      'difficulty': difficulty,
      'moves': moves,
      'seconds': seconds,
      'used_powerups': usedPowerups,
      'is_time_attack': isTimeAttack,
      'is_custom_photo': isCustomPhoto,
      'is_daily': isDaily,
    })) as Map<String, dynamic>;
  }

  Future<List<dynamic>> history() async =>
      (await _api.get('/solves')) as List<dynamic>;
}
