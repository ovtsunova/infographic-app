import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class GroupsHandler {
  Future<Response> getAll(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute(
        '''
        SELECT
          ID_Group AS id,
          GroupName AS group_name,
          Course AS course,
          StudyYear AS study_year,
          DirectionName AS direction_name
        FROM StudyGroups
        ORDER BY ID_Group
        ''',
      );

      final groups = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['id'],
          'groupName': data['group_name'],
          'course': data['course'],
          'studyYear': data['study_year'],
          'directionName': data['direction_name'],
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': groups,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> getById(Request request, String id) async {
    try {
      final groupId = int.tryParse(id);

      if (groupId == null) {
        return JsonResponse.badRequest(
          'Некорректный идентификатор учебной группы',
        );
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          SELECT
            ID_Group AS id,
            GroupName AS group_name,
            Course AS course,
            StudyYear AS study_year,
            DirectionName AS direction_name
          FROM StudyGroups
          WHERE ID_Group = @id
          ''',
        ),
        parameters: {
          'id': groupId,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound(
          'Учебная группа не найдена',
        );
      }

      final data = result.first.toColumnMap();

      return JsonResponse.ok({
        'success': true,
        'data': {
          'id': data['id'],
          'groupName': data['group_name'],
          'course': data['course'],
          'studyYear': data['study_year'],
          'directionName': data['direction_name'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> create(Request request) async {
    try {
      final body = await _readJsonBody(request);

      final groupName = _readString(body, 'groupName');
      final course = _readInt(body, 'course');
      final studyYear = _readString(body, 'studyYear');
      final directionName = _readNullableString(body, 'directionName');

      final validationError = _validateGroupData(
        groupName: groupName,
        course: course,
        studyYear: studyYear,
      );

      if (validationError != null) {
        return JsonResponse.badRequest(validationError);
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          INSERT INTO StudyGroups (
            GroupName,
            Course,
            StudyYear,
            DirectionName
          )
          VALUES (
            @groupName,
            @course,
            @studyYear,
            @directionName
          )
          RETURNING
            ID_Group AS id,
            GroupName AS group_name,
            Course AS course,
            StudyYear AS study_year,
            DirectionName AS direction_name
          ''',
        ),
        parameters: {
          'groupName': groupName,
          'course': course,
          'studyYear': studyYear,
          'directionName': directionName,
        },
      );

      final data = result.first.toColumnMap();

      return JsonResponse.created({
        'success': true,
        'message': 'Учебная группа успешно добавлена',
        'data': {
          'id': data['id'],
          'groupName': data['group_name'],
          'course': data['course'],
          'studyYear': data['study_year'],
          'directionName': data['direction_name'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> update(Request request, String id) async {
    try {
      final groupId = int.tryParse(id);

      if (groupId == null) {
        return JsonResponse.badRequest(
          'Некорректный идентификатор учебной группы',
        );
      }

      final body = await _readJsonBody(request);

      final groupName = _readString(body, 'groupName');
      final course = _readInt(body, 'course');
      final studyYear = _readString(body, 'studyYear');
      final directionName = _readNullableString(body, 'directionName');

      final validationError = _validateGroupData(
        groupName: groupName,
        course: course,
        studyYear: studyYear,
      );

      if (validationError != null) {
        return JsonResponse.badRequest(validationError);
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          UPDATE StudyGroups
          SET
            GroupName = @groupName,
            Course = @course,
            StudyYear = @studyYear,
            DirectionName = @directionName
          WHERE ID_Group = @id
          RETURNING
            ID_Group AS id,
            GroupName AS group_name,
            Course AS course,
            StudyYear AS study_year,
            DirectionName AS direction_name
          ''',
        ),
        parameters: {
          'id': groupId,
          'groupName': groupName,
          'course': course,
          'studyYear': studyYear,
          'directionName': directionName,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound(
          'Учебная группа не найдена',
        );
      }

      final data = result.first.toColumnMap();

      return JsonResponse.ok({
        'success': true,
        'message': 'Учебная группа успешно обновлена',
        'data': {
          'id': data['id'],
          'groupName': data['group_name'],
          'course': data['course'],
          'studyYear': data['study_year'],
          'directionName': data['direction_name'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      final groupId = int.tryParse(id);

      if (groupId == null) {
        return JsonResponse.badRequest(
          'Некорректный идентификатор учебной группы',
        );
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          DELETE FROM StudyGroups
          WHERE ID_Group = @id
          RETURNING ID_Group
          ''',
        ),
        parameters: {
          'id': groupId,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound(
          'Учебная группа не найдена',
        );
      }

      return JsonResponse.ok({
        'success': true,
        'message': 'Учебная группа успешно удалена',
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

  int? _readInt(Map<String, dynamic> body, String key) {
    final value = body[key];

    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  String? _validateGroupData({
    required String groupName,
    required int? course,
    required String studyYear,
  }) {
    if (groupName.isEmpty) {
      return 'Введите название учебной группы';
    }

    if (groupName.length > 40) {
      return 'Название учебной группы не должно превышать 40 символов';
    }

    if (course == null) {
      return 'Введите курс учебной группы';
    }

    if (course < 1 || course > 6) {
      return 'Курс должен быть в диапазоне от 1 до 6';
    }

    final studyYearPattern = RegExp(r'^\d{4}/\d{4}$');

    if (!studyYearPattern.hasMatch(studyYear)) {
      return 'Учебный год должен быть в формате 2025/2026';
    }

    return null;
  }
}