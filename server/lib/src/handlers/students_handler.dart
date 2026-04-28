import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class StudentsHandler {
  Future<Response> getAll(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute('''
        SELECT
          s.ID_Student AS id,
          s.LastName AS last_name,
          s.FirstName AS first_name,
          s.Patronymic AS patronymic,
          s.RecordBookNumber AS record_book_number,
          s.Group_ID AS group_id,
          g.GroupName AS group_name
        FROM Students s
        JOIN StudyGroups g ON s.Group_ID = g.ID_Group
        ORDER BY s.ID_Student
        ''');

      final students = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['id'],
          'lastName': data['last_name'],
          'firstName': data['first_name'],
          'patronymic': data['patronymic'],
          'recordBookNumber': data['record_book_number'],
          'groupId': data['group_id'],
          'groupName': data['group_name'],
        };
      }).toList();

      return JsonResponse.ok({'success': true, 'data': students});
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> getById(Request request, String id) async {
    try {
      final studentId = int.tryParse(id);

      if (studentId == null) {
        return JsonResponse.badRequest('Некорректный идентификатор студента');
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          SELECT
            s.ID_Student AS id,
            s.LastName AS last_name,
            s.FirstName AS first_name,
            s.Patronymic AS patronymic,
            s.RecordBookNumber AS record_book_number,
            s.Group_ID AS group_id,
            g.GroupName AS group_name
          FROM Students s
          JOIN StudyGroups g ON s.Group_ID = g.ID_Group
          WHERE s.ID_Student = @id
          '''),
        parameters: {'id': studentId},
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Студент не найден');
      }

      final data = result.first.toColumnMap();

      return JsonResponse.ok({
        'success': true,
        'data': {
          'id': data['id'],
          'lastName': data['last_name'],
          'firstName': data['first_name'],
          'patronymic': data['patronymic'],
          'recordBookNumber': data['record_book_number'],
          'groupId': data['group_id'],
          'groupName': data['group_name'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> create(Request request) async {
    try {
      final body = await _readJsonBody(request);

      final lastName = _readString(body, 'lastName');
      final firstName = _readString(body, 'firstName');
      final patronymic = _readNullableString(body, 'patronymic');
      final recordBookNumber = _readNullableString(body, 'recordBookNumber');
      final groupId = _readInt(body, 'groupId');

      final validationError = _validateStudentData(
        lastName: lastName,
        firstName: firstName,
        groupId: groupId,
      );

      if (validationError != null) {
        return JsonResponse.badRequest(validationError);
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          INSERT INTO Students (
            LastName,
            FirstName,
            Patronymic,
            RecordBookNumber,
            Group_ID
          )
          VALUES (
            @lastName,
            @firstName,
            @patronymic,
            @recordBookNumber,
            @groupId
          )
          RETURNING
            ID_Student AS id,
            LastName AS last_name,
            FirstName AS first_name,
            Patronymic AS patronymic,
            RecordBookNumber AS record_book_number,
            Group_ID AS group_id
          '''),
        parameters: {
          'lastName': lastName,
          'firstName': firstName,
          'patronymic': patronymic,
          'recordBookNumber': recordBookNumber,
          'groupId': groupId,
        },
      );

      final data = result.first.toColumnMap();

      return JsonResponse.created({
        'success': true,
        'message': 'Студент успешно добавлен',
        'data': {
          'id': data['id'],
          'lastName': data['last_name'],
          'firstName': data['first_name'],
          'patronymic': data['patronymic'],
          'recordBookNumber': data['record_book_number'],
          'groupId': data['group_id'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> update(Request request, String id) async {
    try {
      final studentId = int.tryParse(id);

      if (studentId == null) {
        return JsonResponse.badRequest('Некорректный идентификатор студента');
      }

      final body = await _readJsonBody(request);

      final lastName = _readString(body, 'lastName');
      final firstName = _readString(body, 'firstName');
      final patronymic = _readNullableString(body, 'patronymic');
      final recordBookNumber = _readNullableString(body, 'recordBookNumber');
      final groupId = _readInt(body, 'groupId');

      final validationError = _validateStudentData(
        lastName: lastName,
        firstName: firstName,
        groupId: groupId,
      );

      if (validationError != null) {
        return JsonResponse.badRequest(validationError);
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          UPDATE Students
          SET
            LastName = @lastName,
            FirstName = @firstName,
            Patronymic = @patronymic,
            RecordBookNumber = @recordBookNumber,
            Group_ID = @groupId
          WHERE ID_Student = @id
          RETURNING
            ID_Student AS id,
            LastName AS last_name,
            FirstName AS first_name,
            Patronymic AS patronymic,
            RecordBookNumber AS record_book_number,
            Group_ID AS group_id
          '''),
        parameters: {
          'id': studentId,
          'lastName': lastName,
          'firstName': firstName,
          'patronymic': patronymic,
          'recordBookNumber': recordBookNumber,
          'groupId': groupId,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Студент не найден');
      }

      final data = result.first.toColumnMap();

      return JsonResponse.ok({
        'success': true,
        'message': 'Студент успешно обновлен',
        'data': {
          'id': data['id'],
          'lastName': data['last_name'],
          'firstName': data['first_name'],
          'patronymic': data['patronymic'],
          'recordBookNumber': data['record_book_number'],
          'groupId': data['group_id'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      final studentId = int.tryParse(id);

      if (studentId == null) {
        return JsonResponse.badRequest('Некорректный идентификатор студента');
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named('''
          DELETE FROM Students
          WHERE ID_Student = @id
          RETURNING ID_Student
          '''),
        parameters: {'id': studentId},
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Студент не найден');
      }

      return JsonResponse.ok({
        'success': true,
        'message': 'Студент успешно удален',
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

  String? _validateStudentData({
    required String lastName,
    required String firstName,
    required int? groupId,
  }) {
    if (lastName.isEmpty) {
      return 'Введите фамилию студента';
    }

    if (firstName.isEmpty) {
      return 'Введите имя студента';
    }

    if (groupId == null) {
      return 'Выберите учебную группу';
    }

    return null;
  }
}
