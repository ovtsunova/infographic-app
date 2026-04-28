import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../services/token_service.dart';
import '../utils/json_response.dart';

class AuthHandler {
  AuthHandler({required TokenService tokenService})
    : _tokenService = tokenService;

  final TokenService _tokenService;

  Future<Response> register(Request request) async {
    try {
      final body = await _readJsonBody(request);

      final email = _readString(body, 'email');
      final password = _readString(body, 'password');
      final lastName = _readString(body, 'lastName');
      final firstName = _readString(body, 'firstName');
      final patronymic = _readNullableString(body, 'patronymic');

      if (email.isEmpty ||
          password.isEmpty ||
          lastName.isEmpty ||
          firstName.isEmpty) {
        return JsonResponse.badRequest(
          'Заполните email, пароль, фамилию и имя',
        );
      }

      final conn = await Database.connection;

      await conn.execute(
        Sql.named('''
          CALL RegisterUser(
            @email,
            @password,
            @lastName,
            @firstName,
            @patronymic
          )
          '''),
        parameters: {
          'email': email,
          'password': password,
          'lastName': lastName,
          'firstName': firstName,
          'patronymic': patronymic,
        },
      );

      return JsonResponse.created({
        'success': true,
        'message': 'Пользователь успешно зарегистрирован',
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> login(Request request) async {
    try {
      final body = await _readJsonBody(request);

      final email = _readString(body, 'email');
      final password = _readString(body, 'password');

      if (email.isEmpty || password.isEmpty) {
        return JsonResponse.badRequest('Введите email и пароль');
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          SELECT *
          FROM CheckUserPassword(@email, @password)
          '''),
        parameters: {'email': email, 'password': password},
      );

      if (result.isEmpty) {
        return JsonResponse.unauthorized(
          'Неверная электронная почта или пароль',
        );
      }

      final row = result.first.toColumnMap();

      final isBlocked = row['is_blocked'] as bool;

      if (isBlocked) {
        return JsonResponse.forbidden('Учетная запись заблокирована');
      }

      final accountId = row['account_id'] as int;
      final userEmail = row['email'] as String;
      final roleName = row['role_name'] as String;

      final token = _tokenService.createToken(
        accountId: accountId,
        email: userEmail,
        roleName: roleName,
      );

      return JsonResponse.ok({
        'success': true,
        'message': 'Вход выполнен успешно',
        'token': token,
        'user': {
          'accountId': accountId,
          'email': userEmail,
          'role': roleName,
          'isBlocked': isBlocked,
          'lastName': row['last_name'],
          'firstName': row['first_name'],
          'patronymic': row['patronymic'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
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

    if (value == null) {
      return '';
    }

    return value.toString().trim();
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
