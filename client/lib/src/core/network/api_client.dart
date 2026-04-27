import 'package:dio/dio.dart';

import 'package:client/src/core/config/app_config.dart';
import 'package:client/src/core/storage/app_storage.dart';

class ApiClient {
  final AppStorage _storage;

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
      ),
    );
  }
}