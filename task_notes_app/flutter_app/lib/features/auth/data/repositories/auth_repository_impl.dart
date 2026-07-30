import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user.dart';

class AuthRepositoryImpl {
  final DioClient dioClient;

  AuthRepositoryImpl(this.dioClient);

  Future<AppUser> login(String email, String password) async {
    try {
      final response = await dioClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return _persistSessionAndReturnUser(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Login failed',
        statusCode: e.response?.statusCode,
        errorCode: e.response?.data['errorCode'],
      );
    }
  }

  Future<AppUser> register(String email, String password, String firstName, String lastName) async {
    try {
      final response = await dioClient.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });
      return _persistSessionAndReturnUser(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Registration failed',
        statusCode: e.response?.statusCode,
        errorCode: e.response?.data['errorCode'],
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    try {
      await dioClient.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException {
      // Best-effort server-side revoke; always clear local session regardless.
    }
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
  }

  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;
    try {
      final response = await dioClient.dio.get('/users/profile');
      return AppUser.fromJson(response.data['data']);
    } on DioException {
      return null;
    }
  }

  Future<AppUser> _persistSessionAndReturnUser(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['accessToken']);
    await prefs.setString('refresh_token', data['refreshToken']);
    final user = AppUser.fromJson(data['user']);
    await prefs.setString('user_id', user.id);
    return user;
  }
}
