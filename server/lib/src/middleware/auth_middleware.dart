import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
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
        final authResult = await _authorize(request);

        if (authResult.response != null) {
          return authResult.response!;
        }

        return _runWithAuditAccount(
          request: authResult.request!,
          innerHandler: innerHandler,
        );
      };
    };
  }

  Middleware requireAdmin() {
    return (Handler innerHandler) {
      return (Request request) async {
        final authResult = await _authorize(request);

        if (authResult.response != null) {
          return authResult.response!;
        }

        final auth = authResult.request!.context['auth'];

        if (auth is! Map) {
          return JsonResponse.unauthorized(
            'Не удалось определить данные авторизации',
          );
        }

        final role = auth['role']?.toString();

        if (role != 'Администратор') {
          return JsonResponse.forbidden(
            'Доступ разрешен только администратору',
          );
        }

        return _runWithAuditAccount(
          request: authResult.request!,
          innerHandler: innerHandler,
        );
      };
    };
  }

  Future<Response> _runWithAuditAccount({
    required Request request,
    required Handler innerHandler,
  }) async {
    final accountId = _getAccountIdFromRequest(request);

    if (accountId == null) {
      return JsonResponse.unauthorized(
        'Не удалось определить аккаунт пользователя',
      );
    }

    await Database.setCurrentAccountId(accountId);

    try {
      return await innerHandler(request);
    } finally {
      try {
        await Database.clearCurrentAccountId();
      } catch (_) {
        // Очистка служебной переменной не должна ломать ответ API.
      }
    }
  }

  Future<_AuthResult> _authorize(Request request) async {
    final authHeader = request.headers['authorization'];

    if (authHeader == null || authHeader.trim().isEmpty) {
      return _AuthResult.response(
        JsonResponse.unauthorized('Отсутствует токен авторизации'),
      );
    }

    if (!authHeader.startsWith('Bearer ')) {
      return _AuthResult.response(
        JsonResponse.unauthorized(
          'Некорректный формат токена авторизации',
        ),
      );
    }

    final token = authHeader.substring(7).trim();
    final payload = _tokenService.verifyToken(token);

    if (payload == null) {
      return _AuthResult.response(
        JsonResponse.unauthorized(
          'Недействительный или просроченный токен',
        ),
      );
    }

    final accountId = _readAccountId(payload);

    if (accountId == null) {
      return _AuthResult.response(
        JsonResponse.unauthorized(
          'Не удалось определить аккаунт пользователя',
        ),
      );
    }

    try {
      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          SELECT
            a.ID_Account AS account_id,
            a.Email AS email,
            a.IsBlocked AS is_blocked,
            r.RoleName AS role_name
          FROM Accounts a
          JOIN Roles r ON a.Role_ID = r.ID_Role
          WHERE a.ID_Account = @accountId
        '''),
        parameters: {
          'accountId': accountId,
        },
      );

      if (result.isEmpty) {
        return _AuthResult.response(
          JsonResponse.unauthorized(
            'Аккаунт пользователя не найден',
          ),
        );
      }

      final data = result.first.toColumnMap();
      final isBlocked = data['is_blocked'] == true;

      if (isBlocked) {
        return _AuthResult.response(
          JsonResponse.forbidden(
            'Учетная запись заблокирована. Данные пользователя скрыты.',
          ),
        );
      }

      final actualPayload = <String, dynamic>{
        ...payload,
        'accountId': data['account_id'],
        'email': data['email'],
        'role': data['role_name'],
      };

      final updatedRequest = request.change(
        context: {
          ...request.context,
          'auth': actualPayload,
        },
      );

      return _AuthResult.request(updatedRequest);
    } catch (error) {
      return _AuthResult.response(JsonResponse.serverError(error));
    }
  }

  int? _getAccountIdFromRequest(Request request) {
    final auth = request.context['auth'];

    if (auth is Map) {
      return _readAccountId(auth);
    }

    return null;
  }

  int? _readAccountId(Map<dynamic, dynamic> payload) {
    final value = payload['accountId'];

    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }
}

class _AuthResult {
  final Request? request;
  final Response? response;

  const _AuthResult._({
    required this.request,
    required this.response,
  });

  factory _AuthResult.request(Request request) {
    return _AuthResult._(
      request: request,
      response: null,
    );
  }

  factory _AuthResult.response(Response response) {
    return _AuthResult._(
      request: null,
      response: response,
    );
  }
}