import 'api_client.dart';

class ProfileService {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> fetch() async =>
      (await _api.get('/profile')) as Map<String, dynamic>;

  Future<Map<String, dynamic>> update({String? name}) async =>
      (await _api.patch('/profile', {
        if (name != null) 'name': name,
      })) as Map<String, dynamic>;

  Future<Map<String, dynamic>> useTry() async =>
      (await _api.post('/profile/tries/use')) as Map<String, dynamic>;

  Future<Map<String, dynamic>> watchAdForTry() async =>
      (await _api.post('/profile/tries/watch-ad')) as Map<String, dynamic>;

  Future<Map<String, dynamic>> spendFlames(int amount) async =>
      (await _api.post('/profile/flames/spend', {'amount': amount}))
          as Map<String, dynamic>;
}
