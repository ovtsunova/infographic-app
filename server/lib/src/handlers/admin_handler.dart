import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class AdminHandler {
  Future<Response> getUsers(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute('''
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
        ORDER BY a.ID_Account
      ''');

      final users = result.map((row) {
        final data = row.toColumnMap();

        return {
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
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': users,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> getUserById(Request request, String id) async {
    try {
      final accountId = int.tryParse(id);

      if (accountId == null) {
        return JsonResponse.badRequest('Некорректный идентификатор аккаунта');
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
        parameters: {
          'accountId': accountId,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Пользователь не найден');
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

  Future<Response> getRoles(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute('''
        SELECT
          ID_Role AS id,
          RoleName AS role_name
        FROM Roles
        ORDER BY ID_Role
      ''');

      final roles = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['id'],
          'roleName': data['role_name'],
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': roles,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> changeUserRole(Request request, String id) async {
    try {
      final accountId = int.tryParse(id);

      if (accountId == null) {
        return JsonResponse.badRequest('Некорректный идентификатор аккаунта');
      }

      final body = await _readJsonBody(request);
      final roleId = _readInt(body, 'roleId');

      if (roleId == null) {
        return JsonResponse.badRequest('Передайте идентификатор роли');
      }

      final conn = await Database.connection;

      await conn.execute(
        Sql.named('''
          CALL SetAccountRole(@accountId, @roleId)
        '''),
        parameters: {
          'accountId': accountId,
          'roleId': roleId,
        },
      );

      return JsonResponse.ok({
        'success': true,
        'message': 'Роль пользователя успешно изменена',
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> changeBlockStatus(Request request, String id) async {
    try {
      final accountId = int.tryParse(id);

      if (accountId == null) {
        return JsonResponse.badRequest('Некорректный идентификатор аккаунта');
      }

      final body = await _readJsonBody(request);
      final isBlocked = body['isBlocked'];

      if (isBlocked is! bool) {
        return JsonResponse.badRequest(
          'Передайте isBlocked со значением true или false',
        );
      }

      final conn = await Database.connection;

      await conn.execute(
        Sql.named('''
          CALL SetAccountBlockStatus(@accountId, @isBlocked)
        '''),
        parameters: {
          'accountId': accountId,
          'isBlocked': isBlocked,
        },
      );

      return JsonResponse.ok({
        'success': true,
        'message': isBlocked
            ? 'Пользователь успешно заблокирован. Его данные и действия скрыты.'
            : 'Пользователь успешно разблокирован. Его данные снова отображаются.',
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> getAuditLogs(Request request) async {
    try {
      final limit = int.tryParse(
            request.url.queryParameters['limit'] ?? '',
          ) ??
          100;

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          SELECT
            al.ID_AuditLog AS id,
            al.ActionName AS action_name,
            al.EntityName AS entity_name,
            al.EntityID AS entity_id,
            al.OldValue AS old_value,
            al.NewValue AS new_value,
            al.ActionDate AS action_date,
            a.Email AS account_email
          FROM AuditLog al
          LEFT JOIN Accounts a ON al.Account_ID = a.ID_Account
          WHERE a.ID_Account IS NULL
             OR a.IsBlocked = FALSE
          ORDER BY al.ActionDate DESC
          LIMIT @limit
        '''),
        parameters: {
          'limit': limit,
        },
      );

      final logs = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['id'],
          'actionName': data['action_name'],
          'entityName': data['entity_name'],
          'entityId': data['entity_id'],
          'oldValue': data['old_value'],
          'newValue': data['new_value'],
          'actionDate': data['action_date'].toString(),
          'accountEmail': data['account_email'],
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': logs,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> getDashboard(Request request) async {
    try {
      final conn = await Database.connection;

      final usersCount = await conn.execute(
        'SELECT COUNT(*) AS value FROM Accounts',
      );

      final groupsCount = await conn.execute(
        'SELECT COUNT(*) AS value FROM StudyGroups',
      );

      final studentsCount = await conn.execute(
        'SELECT COUNT(*) AS value FROM Students',
      );

      final disciplinesCount = await conn.execute(
        'SELECT COUNT(*) AS value FROM Disciplines',
      );

      final infographicsCount = await conn.execute('''
        SELECT COUNT(*) AS value
        FROM Infographics i
        JOIN Accounts a ON i.Account_ID = a.ID_Account
        WHERE a.IsBlocked = FALSE
      ''');

      final blockedUsersCount = await conn.execute(
        'SELECT COUNT(*) AS value FROM Accounts WHERE IsBlocked = TRUE',
      );

      return JsonResponse.ok({
        'success': true,
        'data': {
          'usersCount': _readCount(usersCount),
          'groupsCount': _readCount(groupsCount),
          'studentsCount': _readCount(studentsCount),
          'disciplinesCount': _readCount(disciplinesCount),
          'infographicsCount': _readCount(infographicsCount),
          'blockedUsersCount': _readCount(blockedUsersCount),
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }


  Future<Response> getTemplates(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute('''
        SELECT
          ID_Template AS id,
          TemplateName AS template_name,
          ChartType AS chart_type,
          ColorScheme AS color_scheme,
          Description AS description,
          IsActive AS is_active
        FROM InfographicTemplates
        ORDER BY ID_Template
      ''');

      final templates = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['id'],
          'templateName': data['template_name'],
          'chartType': data['chart_type'],
          'colorScheme': data['color_scheme'],
          'description': data['description'],
          'isActive': data['is_active'],
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': templates,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> createTemplate(Request request) async {
    try {
      final body = await _readJsonBody(request);
      final templateName = _readString(body, 'templateName');
      final chartType = _readString(body, 'chartType');
      final colorScheme = _readString(body, 'colorScheme');
      final description = _readNullableString(body, 'description');
      final isActive = _readBool(body, 'isActive') ?? true;

      final validationMessage = _validateTemplateData(
        templateName: templateName,
        chartType: chartType,
        colorScheme: colorScheme,
      );

      if (validationMessage != null) {
        return JsonResponse.badRequest(validationMessage);
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          INSERT INTO InfographicTemplates (
            TemplateName,
            ChartType,
            ColorScheme,
            Description,
            IsActive
          )
          VALUES (
            @templateName,
            @chartType,
            @colorScheme,
            @description,
            @isActive
          )
          RETURNING
            ID_Template AS id,
            TemplateName AS template_name,
            ChartType AS chart_type,
            ColorScheme AS color_scheme,
            Description AS description,
            IsActive AS is_active
        '''),
        parameters: {
          'templateName': templateName,
          'chartType': chartType,
          'colorScheme': colorScheme,
          'description': description,
          'isActive': isActive,
        },
      );

      final data = result.first.toColumnMap();

      return JsonResponse.created({
        'success': true,
        'message': 'Шаблон инфографики успешно создан',
        'data': {
          'id': data['id'],
          'templateName': data['template_name'],
          'chartType': data['chart_type'],
          'colorScheme': data['color_scheme'],
          'description': data['description'],
          'isActive': data['is_active'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> updateTemplate(Request request, String id) async {
    try {
      final templateId = int.tryParse(id);

      if (templateId == null) {
        return JsonResponse.badRequest('Некорректный идентификатор шаблона');
      }

      final body = await _readJsonBody(request);
      final templateName = _readString(body, 'templateName');
      final chartType = _readString(body, 'chartType');
      final colorScheme = _readString(body, 'colorScheme');
      final description = _readNullableString(body, 'description');
      final isActive = _readBool(body, 'isActive') ?? true;

      final validationMessage = _validateTemplateData(
        templateName: templateName,
        chartType: chartType,
        colorScheme: colorScheme,
      );

      if (validationMessage != null) {
        return JsonResponse.badRequest(validationMessage);
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          UPDATE InfographicTemplates
          SET
            TemplateName = @templateName,
            ChartType = @chartType,
            ColorScheme = @colorScheme,
            Description = @description,
            IsActive = @isActive
          WHERE ID_Template = @templateId
          RETURNING
            ID_Template AS id,
            TemplateName AS template_name,
            ChartType AS chart_type,
            ColorScheme AS color_scheme,
            Description AS description,
            IsActive AS is_active
        '''),
        parameters: {
          'templateId': templateId,
          'templateName': templateName,
          'chartType': chartType,
          'colorScheme': colorScheme,
          'description': description,
          'isActive': isActive,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Шаблон инфографики не найден');
      }

      final data = result.first.toColumnMap();

      return JsonResponse.ok({
        'success': true,
        'message': 'Шаблон инфографики успешно обновлён',
        'data': {
          'id': data['id'],
          'templateName': data['template_name'],
          'chartType': data['chart_type'],
          'colorScheme': data['color_scheme'],
          'description': data['description'],
          'isActive': data['is_active'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> deleteTemplate(Request request, String id) async {
    try {
      final templateId = int.tryParse(id);

      if (templateId == null) {
        return JsonResponse.badRequest('Некорректный идентификатор шаблона');
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          DELETE FROM InfographicTemplates
          WHERE ID_Template = @templateId
          RETURNING ID_Template AS id
        '''),
        parameters: {
          'templateId': templateId,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Шаблон инфографики не найден');
      }

      return JsonResponse.ok({
        'success': true,
        'message': 'Шаблон инфографики успешно удалён',
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> getImportFiles(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute('''
        SELECT
          i.ID_ImportFile AS id,
          i.OriginalFileName AS original_file_name,
          i.FileType AS file_type,
          i.ImportStatus AS import_status,
          i.RowsTotal AS rows_total,
          i.RowsSuccess AS rows_success,
          i.RowsFailed AS rows_failed,
          i.ErrorMessage AS error_message,
          i.ImportDate AS import_date,
          a.Email AS account_email
        FROM ImportFiles i
        JOIN Accounts a ON i.Account_ID = a.ID_Account
        WHERE a.IsBlocked = FALSE
        ORDER BY i.ImportDate DESC
      ''');

      final files = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['id'],
          'originalFileName': data['original_file_name'],
          'fileType': data['file_type'],
          'importStatus': data['import_status'],
          'rowsTotal': data['rows_total'],
          'rowsSuccess': data['rows_success'],
          'rowsFailed': data['rows_failed'],
          'errorMessage': data['error_message'],
          'importDate': data['import_date'].toString(),
          'accountEmail': data['account_email'],
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': files,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> getExportedFiles(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute('''
        SELECT
          e.ID_Export AS id,
          e.FileName AS file_name,
          e.FileFormat AS file_format,
          e.ExportDate AS export_date,
          i.ID_Infographic AS infographic_id,
          i.Title AS infographic_title
        FROM ExportedFiles e
        JOIN Infographics i ON e.Infographic_ID = i.ID_Infographic
        JOIN Accounts a ON i.Account_ID = a.ID_Account
        WHERE a.IsBlocked = FALSE
        ORDER BY e.ExportDate DESC
      ''');

      final files = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['id'],
          'fileName': data['file_name'],
          'fileFormat': data['file_format'],
          'exportDate': data['export_date'].toString(),
          'infographicId': data['infographic_id'],
          'infographicTitle': data['infographic_title'],
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': files,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Map<dynamic, dynamic>> _readJsonBody(Request request) async {
    final bodyText = await request.readAsString();

    if (bodyText.trim().isEmpty) {
      return {};
    }

    final decoded = jsonDecode(bodyText);

    if (decoded is Map) {
      return decoded;
    }

    return Map.from(decoded as Map);
  }


  String _readString(Map<dynamic, dynamic> body, String key) {
    return body[key]?.toString().trim() ?? '';
  }

  String? _readNullableString(Map<dynamic, dynamic> body, String key) {
    final value = body[key]?.toString().trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  bool? _readBool(Map<dynamic, dynamic> body, String key) {
    final value = body[key];

    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    final text = value.toString().trim().toLowerCase();

    if (text == 'true' || text == '1' || text == 'yes') {
      return true;
    }

    if (text == 'false' || text == '0' || text == 'no') {
      return false;
    }

    return null;
  }

  String? _validateTemplateData({
    required String templateName,
    required String chartType,
    required String colorScheme,
  }) {
    if (templateName.isEmpty) {
      return 'Введите название шаблона';
    }

    if (templateName.length > 120) {
      return 'Название шаблона не должно превышать 120 символов';
    }

    if (!['bar', 'line', 'pie', 'doughnut', 'card'].contains(chartType)) {
      return 'Недопустимый тип диаграммы';
    }

    if (colorScheme.isEmpty) {
      return 'Введите цветовую схему шаблона';
    }

    if (colorScheme.length > 60) {
      return 'Цветовая схема не должна превышать 60 символов';
    }

    return null;
  }

  int? _readInt(Map<dynamic, dynamic> body, String key) {
    final value = body[key];

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

  int _readCount(Result result) {
    final value = result.first.toColumnMap()['value'];

    return int.parse(value.toString());
  }
}