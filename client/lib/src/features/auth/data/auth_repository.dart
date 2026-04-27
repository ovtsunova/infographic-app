import 'package:dio/dio.dart';

import 'package:client/src/core/network/api_client.dart';
import 'package:client/src/core/storage/app_storage.dart';
import 'package:client/src/shared/models/app_user.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final AppStorage _storage;

  AuthRepository({
    required ApiClient apiClient,
    required AppStorage storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = _asMap(response.data);
      final token = data['token']?.toString();

      if (token == null || token.trim().isEmpty) {
        throw AuthException('Сервер не вернул токен авторизации');
      }

      await _storage.saveToken(token);

      final userJson = _asMap(data['user']);
      return AppUser.fromJson(userJson);
    } on DioException catch (error) {
      throw AuthException(_readErrorMessage(error));
    } catch (error) {
      throw AuthException(error.toString());
    }
  }

  Future<void> register({
    required String lastName,
    required String firstName,
    required String? patronymic,
    required String email,
    required String password,
  }) async {
    try {
      await _apiClient.dio.post(
        '/auth/register',
        data: {
          'lastName': lastName.trim(),
          'firstName': firstName.trim(),
          'patronymic': patronymic?.trim(),
          'email': email.trim(),
          'password': password,
        },
      );
    } on DioException catch (error) {
      throw AuthException(_readErrorMessage(error));
    } catch (error) {
      throw AuthException(error.toString());
    }
  }

  Future<AppUser> getMe() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      final data = _asMap(response.data);

      final userJson = _asMap(data['data']);
      return AppUser.fromJson(userJson);
    } on DioException catch (error) {
      throw AuthException(_readErrorMessage(error));
    } catch (error) {
      throw AuthException(error.toString());
    }
  }

  Future<void> logout() async {
    await _storage.clearToken();
  }

  Future<String?> getSavedToken() {
    return _storage.getToken();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  String _readErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!;
    }

    return 'Ошибка соединения с сервером';
  }
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}