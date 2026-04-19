import 'api_client.dart';

class AchievementService {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> index() async =>
      (await _api.get('/achievements')) as Map<String, dynamic>;
}
