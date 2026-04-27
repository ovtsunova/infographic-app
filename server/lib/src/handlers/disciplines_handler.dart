import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class DisciplinesHandler {
  Future<Response> getAll(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute(
        '''
        SELECT
          ID_Discipline AS id,
          DisciplineName AS discipline_name,
          Description AS description,
          TeacherName AS teacher_name
        FROM Disciplines
        ORDER BY ID_Discipline
        ''',
      );

      final disciplines = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['id'],
          'disciplineName': data['discipline_name'],
          'description': data['description'],
          'teacherName': data['teacher_name'],
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': disciplines,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> getById(Request request, String id) async {
    try {
      final disciplineId = int.tryParse(id);

      if (disciplineId == null) {
        return JsonResponse.badRequest(
          'Некорректный идентификатор дисциплины',
        );
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          SELECT
            ID_Discipline AS id,
            DisciplineName AS discipline_name,
            Description AS description,
            TeacherName AS teacher_name
          FROM Disciplines
          WHERE ID_Discipline = @id
          ''',
        ),
        parameters: {
          'id': disciplineId,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound(
          'Дисциплина не найдена',
        );
      }

      final data = result.first.toColumnMap();

      return JsonResponse.ok({
        'success': true,
        'data': {
          'id': data['id'],
          'disciplineName': data['discipline_name'],
          'description': data['description'],
          'teacherName': data['teacher_name'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> create(Request request) async {
    try {
      final body = await _readJsonBody(request);

      final disciplineName = _readString(body, 'disciplineName');
      final description = _readNullableString(body, 'description');
      final teacherName = _readNullableString(body, 'teacherName');

      final validationError = _validateDisciplineData(
        disciplineName: disciplineName,
      );

      if (validationError != null) {
        return JsonResponse.badRequest(validationError);
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          INSERT INTO Disciplines (
            DisciplineName,
            Description,
            TeacherName
          )
          VALUES (
            @disciplineName,
            @description,
            @teacherName
          )
          RETURNING
            ID_Discipline AS id,
            DisciplineName AS discipline_name,
            Description AS description,
            TeacherName AS teacher_name
          ''',
        ),
        parameters: {
          'disciplineName': disciplineName,
          'description': description,
          'teacherName': teacherName,
        },
      );

      final data = result.first.toColumnMap();

      return JsonResponse.created({
        'success': true,
        'message': 'Дисциплина успешно добавлена',
        'data': {
          'id': data['id'],
          'disciplineName': data['discipline_name'],
          'description': data['description'],
          'teacherName': data['teacher_name'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> update(Request request, String id) async {
    try {
      final disciplineId = int.tryParse(id);

      if (disciplineId == null) {
        return JsonResponse.badRequest(
          'Некорректный идентификатор дисциплины',
        );
      }

      final body = await _readJsonBody(request);

      final disciplineName = _readString(body, 'disciplineName');
      final description = _readNullableString(body, 'description');
      final teacherName = _readNullableString(body, 'teacherName');

      final validationError = _validateDisciplineData(
        disciplineName: disciplineName,
      );

      if (validationError != null) {
        return JsonResponse.badRequest(validationError);
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          UPDATE Disciplines
          SET
            DisciplineName = @disciplineName,
            Description = @description,
            TeacherName = @teacherName
          WHERE ID_Discipline = @id
          RETURNING
            ID_Discipline AS id,
            DisciplineName AS discipline_name,
            Description AS description,
            TeacherName AS teacher_name
          ''',
        ),
        parameters: {
          'id': disciplineId,
          'disciplineName': disciplineName,
          'description': description,
          'teacherName': teacherName,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound(
          'Дисциплина не найдена',
        );
      }

      final data = result.first.toColumnMap();

      return JsonResponse.ok({
        'success': true,
        'message': 'Дисциплина успешно обновлена',
        'data': {
          'id': data['id'],
          'disciplineName': data['discipline_name'],
          'description': data['description'],
          'teacherName': data['teacher_name'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      final disciplineId = int.tryParse(id);

      if (disciplineId == null) {
        return JsonResponse.badRequest(
          'Некорректный идентификатор дисциплины',
        );
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          DELETE FROM Disciplines
          WHERE ID_Discipline = @id
          RETURNING ID_Discipline
          ''',
        ),
        parameters: {
          'id': disciplineId,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound(
          'Дисциплина не найдена',
        );
      }

      return JsonResponse.ok({
        'success': true,
        'message': 'Дисциплина успешно удалена',
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

  String? _validateDisciplineData({
    required String disciplineName,
  }) {
    if (disciplineName.isEmpty) {
      return 'Введите название дисциплины';
    }

    if (disciplineName.length > 120) {
      return 'Название дисциплины не должно превышать 120 символов';
    }

    return null;
  }
}