import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class ProfileHandler {
  Future<Response> getMe(Request request) async {
    try {
      final accountId = _getAccountId(request);

      if (accountId == null) {
        return JsonResponse.unauthorized('Не удалось определить пользователя');
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          SELECT
            a.ID_Account AS account_id,
            a.Email AS email,
            a.RegistrationDate AS registration_date,
            a.IsBlocked AS is_blocked,
            r.ID_Role AS role_id,
            r.RoleName AS role_name,
            u.ID_User AS user_id,
            u.LastName AS last_name,
            u.FirstName AS first_name,
            u.Patronymic AS patronymic
          FROM Accounts a
          JOIN Roles r ON a.Role_ID = r.ID_Role
          JOIN Users u ON u.Account_ID = a.ID_Account
          WHERE a.ID_Account = @accountId
          '''),
        parameters: {'accountId': accountId},
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Профиль пользователя не найден');
      }

      final data = result.first.toColumnMap();

      return JsonResponse.ok({
        'success': true,
        'data': {
          'accountId': data['account_id'],
          'userId': data['user_id'],
          'email': data['email'],
          'roleId': data['role_id'],
          'role': data['role_name'],
          'isBlocked': data['is_blocked'],
          'lastName': data['last_name'],
          'firstName': data['first_name'],
          'patronymic': data['patronymic'],
          'registrationDate': data['registration_date'].toString(),
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> updateProfile(Request request) async {
    try {
      final accountId = _getAccountId(request);

      if (accountId == null) {
        return JsonResponse.unauthorized('Не удалось определить пользователя');
      }

      final body = await _readJsonBody(request);

      final lastName = _readString(body, 'lastName');
      final firstName = _readString(body, 'firstName');
      final patronymic = _readNullableString(body, 'patronymic');

      if (lastName.isEmpty) {
        return JsonResponse.badRequest('Введите фамилию');
      }

      if (firstName.isEmpty) {
        return JsonResponse.badRequest('Введите имя');
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          UPDATE Users
          SET
            LastName = @lastName,
            FirstName = @firstName,
            Patronymic = @patronymic
          WHERE Account_ID = @accountId
          RETURNING
            ID_User AS user_id,
            LastName AS last_name,
            FirstName AS first_name,
            Patronymic AS patronymic
          '''),
        parameters: {
          'accountId': accountId,
          'lastName': lastName,
          'firstName': firstName,
          'patronymic': patronymic,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Профиль пользователя не найден');
      }

      final data = result.first.toColumnMap();

      return JsonResponse.ok({
        'success': true,
        'message': 'Профиль успешно обновлен',
        'data': {
          'userId': data['user_id'],
          'lastName': data['last_name'],
          'firstName': data['first_name'],
          'patronymic': data['patronymic'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> changePassword(Request request) async {
    try {
      final accountId = _getAccountId(request);
      final email = _getEmail(request);

      if (accountId == null || email == null) {
        return JsonResponse.unauthorized('Не удалось определить пользователя');
      }

      final body = await _readJsonBody(request);

      final oldPassword = _readString(body, 'oldPassword');
      final newPassword = _readString(body, 'newPassword');

      if (oldPassword.isEmpty || newPassword.isEmpty) {
        return JsonResponse.badRequest('Введите старый и новый пароль');
      }

      if (newPassword.length < 8) {
        return JsonResponse.badRequest(
          'Новый пароль должен содержать не менее 8 символов',
        );
      }

      final conn = await Database.connection;

      final checkResult = await conn.execute(
        Sql.named('''
          SELECT *
          FROM CheckUserPassword(@email, @oldPassword)
          '''),
        parameters: {'email': email, 'oldPassword': oldPassword},
      );

      if (checkResult.isEmpty) {
        return JsonResponse.unauthorized('Старый пароль указан неверно');
      }

      await conn.execute(
        Sql.named('''
          UPDATE Accounts
          SET PasswordHash = crypt(@newPassword, gen_salt('bf', 12))
          WHERE ID_Account = @accountId
          '''),
        parameters: {'accountId': accountId, 'newPassword': newPassword},
      );

      return JsonResponse.ok({
        'success': true,
        'message': 'Пароль успешно изменен',
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  int? _getAccountId(Request request) {
    final auth = request.context['auth'];

    if (auth is Map<String, dynamic>) {
      final value = auth['accountId'];

      if (value is int) {
        return value;
      }

      return int.tryParse(value.toString());
    }

    return null;
  }

  String? _getEmail(Request request) {
    final auth = request.context['auth'];

    if (auth is Map<String, dynamic>) {
      return auth['email']?.toString();
    }

    return null;
  }

  Future<Map<String, dynamic>> _readJsonBody(Request request) async {
    final bodyText = await request.readAsString();

    if (bodyText.trim().isEmpty) {
      return {};
    }

    final decoded = jsonDecode(bodyText);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return Map<String, dynamic>.from(decoded as Map);
  }

  String _readString(Map<String, dynamic> body, String key) {
    final value = body[key];
    return value == null ? '' : value.toString().trim();
  }

  String? _readNullableString(Map<String, dynamic> body, String key) {
    final value = body[key];

    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }
}
