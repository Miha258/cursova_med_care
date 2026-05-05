import 'dart:convert';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final ApiService _api;
  AuthRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  // POST /auth/login — bcrypt(rounds=12) перевірка на сервері
  Future<AuthResponse> login(String email, String password) async {
    final response = await _api.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    final auth = AuthResponse.fromJson(response.data);
    // Зберігаємо токени у flutter_secure_storage (Keychain/EncryptedSharedPrefs)
    await SecureStorage.instance.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    await SecureStorage.instance.saveUser(jsonEncode(auth.user.toJson()));
    return auth;
  }

  Future<void> logout() => SecureStorage.instance.clearAll();

  Future<UserModel?> getCachedUser() async {
    final userJson = await SecureStorage.instance.getUser();
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson));
  }

  Future<bool> isAuthenticated() async {
    final token = await SecureStorage.instance.getAccessToken();
    return token != null;
  }
}
