import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class InfographicsHandler {
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
        WHERE IsActive = TRUE
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

  Future<Response> getMyInfographics(Request request) async {
    try {
      final accountId = _getAccountId(request);

      if (accountId == null) {
        return JsonResponse.unauthorized('Не удалось определить пользователя');
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          SELECT
            i.ID_Infographic AS id,
            i.Title AS title,
            i.ChartType AS chart_type,
            i.Parameters AS parameters,
            i.ResultData AS result_data,
            i.CreationDate AS creation_date,
            i.Template_ID AS template_id,
            t.TemplateName AS template_name
          FROM Infographics i
          JOIN Accounts a ON i.Account_ID = a.ID_Account
          LEFT JOIN InfographicTemplates t ON i.Template_ID = t.ID_Template
          WHERE i.Account_ID = @accountId
            AND a.IsBlocked = FALSE
          ORDER BY i.CreationDate DESC
        '''),
        parameters: {
          'accountId': accountId,
        },
      );

      final items = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['id'],
          'title': data['title'],
          'chartType': data['chart_type'],
          'parameters': data['parameters'],
          'resultData': data['result_data'],
          'creationDate': data['creation_date'].toString(),
          'templateId': data['template_id'],
          'templateName': data['template_name'],
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': items,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> getAll(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute('''
        SELECT
          i.ID_Infographic AS id,
          i.Title AS title,
          i.ChartType AS chart_type,
          t.TemplateName AS template_name,
          u.LastName || ' ' || u.FirstName || ' ' || COALESCE(u.Patronymic, '') AS author,
          a.Email AS author_email,
          i.CreationDate AS creation_date
        FROM Infographics i
        JOIN Accounts a ON i.Account_ID = a.ID_Account
        JOIN Users u ON a.ID_Account = u.Account_ID
        LEFT JOIN InfographicTemplates t ON i.Template_ID = t.ID_Template
        WHERE a.IsBlocked = FALSE
        ORDER BY i.CreationDate DESC
      ''');

      final items = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['id'],
          'title': data['title'],
          'chartType': data['chart_type'],
          'templateName': data['template_name'],
          'author': data['author'],
          'authorEmail': data['author_email'],
          'creationDate': data['creation_date'].toString(),
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': items,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> save(Request request) async {
    try {
      final accountId = _getAccountId(request);

      if (accountId == null) {
        return JsonResponse.unauthorized('Не удалось определить пользователя');
      }

      final body = await _readJsonBody(request);
      final title = _readString(body, 'title');
      final chartType = _readString(body, 'chartType');
      final templateId = _readNullableInt(body, 'templateId');
      final parameters = body['parameters'];
      final resultData = body['resultData'];

      if (title.isEmpty) {
        return JsonResponse.badRequest('Введите название инфографики');
      }

      if (!['bar', 'line', 'pie', 'doughnut', 'card'].contains(chartType)) {
        return JsonResponse.badRequest('Недопустимый тип диаграммы');
      }

      if (parameters == null || parameters is! Map) {
        return JsonResponse.badRequest(
          'Передайте параметры построения инфографики',
        );
      }

      if (resultData == null || resultData is! Map) {
        return JsonResponse.badRequest(
          'Передайте данные результата инфографики',
        );
      }

      final conn = await Database.connection;

      await conn.execute(
        Sql.named('''
          CALL SaveInfographic(
            @title,
            @chartType,
            CAST(@parameters AS jsonb),
            CAST(@resultData AS jsonb),
            @accountId,
            @templateId
          )
        '''),
        parameters: {
          'title': title,
          'chartType': chartType,
          'parameters': jsonEncode(parameters),
          'resultData': jsonEncode(resultData),
          'accountId': accountId,
          'templateId': templateId,
        },
      );

      return JsonResponse.created({
        'success': true,
        'message': 'Инфографика успешно сохранена',
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      final accountId = _getAccountId(request);
      final infographicId = int.tryParse(id);

      if (accountId == null) {
        return JsonResponse.unauthorized('Не удалось определить пользователя');
      }

      if (infographicId == null) {
        return JsonResponse.badRequest(
          'Некорректный идентификатор инфографики',
        );
      }

      final role = _getRole(request);
      final isAdmin = role == 'Администратор';

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          DELETE FROM Infographics i
          WHERE i.ID_Infographic = @id
            AND (
              (
                @isAdmin = TRUE
                AND EXISTS (
                  SELECT 1
                  FROM Accounts owner_account
                  WHERE owner_account.ID_Account = i.Account_ID
                    AND owner_account.IsBlocked = FALSE
                )
              )
              OR
              (
                @isAdmin = FALSE
                AND i.Account_ID = @accountId
              )
            )
          RETURNING i.ID_Infographic
        '''),
        parameters: {
          'id': infographicId,
          'accountId': accountId,
          'isAdmin': isAdmin,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Инфографика не найдена');
      }

      return JsonResponse.ok({
        'success': true,
        'message': 'Инфографика успешно удалена',
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> recordExport(Request request, String id) async {
    try {
      final accountId = _getAccountId(request);
      final infographicId = int.tryParse(id);

      if (accountId == null) {
        return JsonResponse.unauthorized('Не удалось определить пользователя');
      }

      if (infographicId == null) {
        return JsonResponse.badRequest(
          'Некорректный идентификатор инфографики',
        );
      }

      final body = await _readJsonBody(request);
      final fileName = _readString(body, 'fileName');
      final fileFormat = _readString(body, 'fileFormat').toUpperCase();

      if (fileName.isEmpty) {
        return JsonResponse.badRequest('Введите имя экспортируемого файла');
      }

      if (!['PNG', 'PDF', 'JPG'].contains(fileFormat)) {
        return JsonResponse.badRequest('Недопустимый формат экспорта');
      }

      final role = _getRole(request);
      final isAdmin = role == 'Администратор';
      final conn = await Database.connection;

      final infographicResult = await conn.execute(
        Sql.named('''
          SELECT i.ID_Infographic
          FROM Infographics i
          JOIN Accounts a ON i.Account_ID = a.ID_Account
          WHERE i.ID_Infographic = @id
            AND a.IsBlocked = FALSE
            AND (
              @isAdmin = TRUE
              OR i.Account_ID = @accountId
            )
          LIMIT 1
        '''),
        parameters: {
          'id': infographicId,
          'accountId': accountId,
          'isAdmin': isAdmin,
        },
      );

      if (infographicResult.isEmpty) {
        return JsonResponse.forbidden(
          'Инфографика не найдена или недоступна для экспорта',
        );
      }

      final exportResult = await conn.execute(
        Sql.named('''
          INSERT INTO ExportedFiles (
            FileName,
            FileFormat,
            Infographic_ID
          )
          VALUES (
            @fileName,
            @fileFormat,
            @infographicId
          )
          RETURNING
            ID_Export AS id,
            FileName AS file_name,
            FileFormat AS file_format,
            ExportDate AS export_date,
            Infographic_ID AS infographic_id
        '''),
        parameters: {
          'fileName': fileName,
          'fileFormat': fileFormat,
          'infographicId': infographicId,
        },
      );

      final data = exportResult.first.toColumnMap();

      return JsonResponse.created({
        'success': true,
        'message': 'Экспорт инфографики записан в журнал',
        'data': {
          'id': data['id'],
          'fileName': data['file_name'],
          'fileFormat': data['file_format'],
          'exportDate': data['export_date'].toString(),
          'infographicId': data['infographic_id'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  int? _getAccountId(Request request) {
    final auth = request.context['auth'];

    if (auth is Map) {
      final value = auth['accountId'];

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      return int.tryParse(value.toString());
    }

    return null;
  }

  String? _getRole(Request request) {
    final auth = request.context['auth'];

    if (auth is Map) {
      return auth['role']?.toString();
    }

    return null;
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
    final value = body[key];

    return value == null ? '' : value.toString().trim();
  }

  int? _readNullableInt(Map<dynamic, dynamic> body, String key) {
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
}