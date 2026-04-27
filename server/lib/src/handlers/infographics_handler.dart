import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class InfographicsHandler {
  Future<Response> getTemplates(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute(
        '''
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
        ''',
      );

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
        Sql.named(
          '''
          SELECT
            ID_Infographic AS id,
            Title AS title,
            ChartType AS chart_type,
            Parameters AS parameters,
            ResultData AS result_data,
            CreationDate AS creation_date,
            Template_ID AS template_id
          FROM Infographics
          WHERE Account_ID = @accountId
          ORDER BY CreationDate DESC
          ''',
        ),
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

      final result = await conn.execute(
        '''
        SELECT *
        FROM InfographicsView
        ORDER BY "Дата создания" DESC
        ''',
      );

      final items = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['Код инфографики'],
          'title': data['Название'],
          'chartType': data['Тип диаграммы'],
          'templateName': data['Шаблон'],
          'author': data['Автор'],
          'authorEmail': data['Email автора'],
          'creationDate': data['Дата создания'].toString(),
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
        return JsonResponse.badRequest('Передайте параметры построения инфографики');
      }

      if (resultData == null || resultData is! Map) {
        return JsonResponse.badRequest('Передайте данные результата инфографики');
      }

      final conn = await Database.connection;

      await conn.execute(
        Sql.named(
          '''
          CALL SaveInfographic(
            @title,
            @chartType,
            @parameters,
            @resultData,
            @accountId,
            @templateId
          )
          ''',
        ),
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
        return JsonResponse.badRequest('Некорректный идентификатор инфографики');
      }

      final role = _getRole(request);
      final isAdmin = role == 'Администратор';

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          DELETE FROM Infographics
          WHERE ID_Infographic = @id
            AND (@isAdmin = TRUE OR Account_ID = @accountId)
          RETURNING ID_Infographic
          ''',
        ),
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

  String? _getRole(Request request) {
    final auth = request.context['auth'];

    if (auth is Map<String, dynamic>) {
      return auth['role']?.toString();
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

  int? _readNullableInt(Map<String, dynamic> body, String key) {
    final value = body[key];

    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }
}