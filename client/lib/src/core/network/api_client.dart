import 'dart:async';

import 'package:dio/dio.dart';

import 'package:client/src/core/config/app_config.dart';
import 'package:client/src/core/storage/app_storage.dart';

class ApiClient {
  final AppStorage _storage;
  final StreamController<String> _authFailureController =
      StreamController<String>.broadcast();

  late final Dio dio;

  ApiClient({
    required AppStorage storage,
  }) : _storage = storage {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();

          if (token != null && token.trim().isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          if (_shouldForceLogout(error)) {
            final message = _readErrorMessage(error);

            await _storage.clearToken();

            if (!_authFailureController.isClosed) {
              _authFailureController.add(
                message.trim().isEmpty
                    ? 'Сессия завершена. Войдите в аккаунт повторно.'
                    : message,
              );
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  Stream<String> get authFailureStream {
    return _authFailureController.stream;
  }

  Future<void> dispose() async {
    await _authFailureController.close();
  }

  bool _shouldForceLogout(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = _readErrorMessage(error).toLowerCase();

    if (statusCode == 401) {
      return true;
    }

    if (statusCode == 403) {
      return message.contains('заблок') ||
          message.contains('blocked') ||
          message.contains('токен') ||
          message.contains('token') ||
          message.contains('просроч') ||
          message.contains('недейств');
    }

    return false;
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