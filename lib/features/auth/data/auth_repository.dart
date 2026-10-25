import '../../../core/services/cloudflare_service.dart';
import '../../../services/progres_api_service.dart';

abstract class IAuthRepository {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<Map<String, dynamic>?> getProfile(String matricule);
  Future<void> saveProfile(String matricule, Map<String, dynamic> data);
  Future<void> logout();
}

class AuthRepository implements IAuthRepository {
  final ProgresApiService _progresApi = ProgresApiService();
  final CloudflareService _cf = CloudflareService();

  @override
  Future<Map<String, dynamic>> login(String username, String password) {
    return _progresApi.loginAndFetchProfile(username, password);
  }

  @override
  Future<Map<String, dynamic>?> getProfile(String matricule) {
    return _cf.getProfileByMatricule(matricule);
  }

  @override
  Future<void> saveProfile(String matricule, Map<String, dynamic> data) {
    return _cf.saveProfile(matricule, data);
  }

  @override
  Future<void> logout() {
    return _progresApi.logout();
  }
}
