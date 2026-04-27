import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class HealthHandler {
  Future<Response> health(Request request) async {
    return JsonResponse.ok({
      'success': true,
      'message': 'Сервер работает',
    });
  }

  Future<Response> dbHealth(Request request) async {
    final isConnected = await Database.checkConnection();

    if (!isConnected) {
      return JsonResponse.serverError(
        'Не удалось подключиться к базе данных',
      );
    }

    return JsonResponse.ok({
      'success': true,
      'message': 'Подключение к базе данных успешно установлено',
    });
  }
}