import 'package:shelf/shelf.dart';

import '../services/token_service.dart';
import '../utils/json_response.dart';

class AuthMiddleware {
  AuthMiddleware({
    required TokenService tokenService,
  }) : _tokenService = tokenService;

  final TokenService _tokenService;

  Middleware requireAuth() {
    return (Handler innerHandler) {
      return (Request request) async {
        final authHeader = request.headers['authorization'];

        if (authHeader == null || authHeader.trim().isEmpty) {
          return JsonResponse.unauthorized(
            'Отсутствует токен авторизации',
          );
        }

        if (!authHeader.startsWith('Bearer ')) {
          return JsonResponse.unauthorized(
            'Некорректный формат токена авторизации',
          );
        }

        final token = authHeader.substring(7).trim();
        final payload = _tokenService.verifyToken(token);

        if (payload == null) {
          return JsonResponse.unauthorized(
            'Недействительный или просроченный токен',
          );
        }

        final updatedRequest = request.change(
          context: {
            ...request.context,
            'auth': payload,
          },
        );

        return innerHandler(updatedRequest);
      };
    };
  }

  Middleware requireAdmin() {
    return (Handler innerHandler) {
      return (Request request) async {
        final authHeader = request.headers['authorization'];

        if (authHeader == null || authHeader.trim().isEmpty) {
          return JsonResponse.unauthorized(
            'Отсутствует токен авторизации',
          );
        }

        if (!authHeader.startsWith('Bearer ')) {
          return JsonResponse.unauthorized(
            'Некорректный формат токена авторизации',
          );
        }

        final token = authHeader.substring(7).trim();
        final payload = _tokenService.verifyToken(token);

        if (payload == null) {
          return JsonResponse.unauthorized(
            'Недействительный или просроченный токен',
          );
        }

        final role = payload['role']?.toString();

        if (role != 'Администратор') {
          return JsonResponse.forbidden(
            'Доступ разрешен только администратору',
          );
        }

        final updatedRequest = request.change(
          context: {
            ...request.context,
            'auth': payload,
          },
        );

        return innerHandler(updatedRequest);
      };
    };
  }
}