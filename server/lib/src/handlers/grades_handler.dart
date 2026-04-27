import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class GradesHandler {
  Future<Response> getAll(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute(
        '''
        SELECT
          gr.ID_Grade AS id,
          gr.GradeValue AS grade_value,
          gr.ControlType AS control_type,
          gr.GradeDate AS grade_date,
          s.ID_Student AS student_id,
          s.LastName || ' ' || s.FirstName || ' ' || COALESCE(s.Patronymic, '') AS student_name,
          d.ID_Discipline AS discipline_id,
          d.DisciplineName AS discipline_name,
          p.ID_Period AS period_id,
          p.StudyYear AS study_year,
          p.Semester AS semester
        FROM Grades gr
        JOIN Students s ON gr.Student_ID = s.ID_Student
        JOIN Disciplines d ON gr.Discipline_ID = d.ID_Discipline
        JOIN StudyPeriods p ON gr.Period_ID = p.ID_Period
        ORDER BY gr.ID_Grade
        ''',
      );

      final grades = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['id'],
          'gradeValue': data['grade_value'],
          'controlType': data['control_type'],
          'gradeDate': _formatDate(data['grade_date']),
          'studentId': data['student_id'],
          'studentName': data['student_name'],
          'disciplineId': data['discipline_id'],
          'disciplineName': data['discipline_name'],
          'periodId': data['period_id'],
          'studyYear': data['study_year'],
          'semester': data['semester'],
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': grades,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> create(Request request) async {
    try {
      final body = await _readJsonBody(request);

      final studentId = _readInt(body, 'studentId');
      final disciplineId = _readInt(body, 'disciplineId');
      final periodId = _readInt(body, 'periodId');
      final gradeValue = _readInt(body, 'gradeValue');
      final controlType = _readString(body, 'controlType');
      final gradeDateText = _readNullableString(body, 'gradeDate');

      final validationError = _validateGradeData(
        studentId: studentId,
        disciplineId: disciplineId,
        periodId: periodId,
        gradeValue: gradeValue,
        controlType: controlType,
      );

      if (validationError != null) {
        return JsonResponse.badRequest(validationError);
      }

      final gradeDate = gradeDateText == null || gradeDateText.isEmpty
          ? null
          : DateTime.tryParse(gradeDateText);

      final conn = await Database.connection;

      await conn.execute(
        Sql.named(
          '''
          CALL AddGrade(
            @studentId,
            @disciplineId,
            @periodId,
            @gradeValue,
            @controlType,
            @gradeDate
          )
          ''',
        ),
        parameters: {
          'studentId': studentId,
          'disciplineId': disciplineId,
          'periodId': periodId,
          'gradeValue': gradeValue,
          'controlType': controlType,
          'gradeDate': gradeDate,
        },
      );

      return JsonResponse.created({
        'success': true,
        'message': 'Оценка успешно добавлена',
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> update(Request request, String id) async {
    try {
      final gradeId = int.tryParse(id);

      if (gradeId == null) {
        return JsonResponse.badRequest('Некорректный идентификатор оценки');
      }

      final body = await _readJsonBody(request);

      final studentId = _readInt(body, 'studentId');
      final disciplineId = _readInt(body, 'disciplineId');
      final periodId = _readInt(body, 'periodId');
      final gradeValue = _readInt(body, 'gradeValue');
      final controlType = _readString(body, 'controlType');
      final gradeDateText = _readString(body, 'gradeDate');

      final validationError = _validateGradeData(
        studentId: studentId,
        disciplineId: disciplineId,
        periodId: periodId,
        gradeValue: gradeValue,
        controlType: controlType,
      );

      if (validationError != null) {
        return JsonResponse.badRequest(validationError);
      }

      final gradeDate = DateTime.tryParse(gradeDateText);

      if (gradeDate == null) {
        return JsonResponse.badRequest('Дата оценки должна быть в формате YYYY-MM-DD');
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          UPDATE Grades
          SET
            Student_ID = @studentId,
            Discipline_ID = @disciplineId,
            Period_ID = @periodId,
            GradeValue = @gradeValue,
            ControlType = @controlType,
            GradeDate = @gradeDate
          WHERE ID_Grade = @id
          RETURNING ID_Grade AS id
          ''',
        ),
        parameters: {
          'id': gradeId,
          'studentId': studentId,
          'disciplineId': disciplineId,
          'periodId': periodId,
          'gradeValue': gradeValue,
          'controlType': controlType,
          'gradeDate': gradeDate,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Оценка не найдена');
      }

      return JsonResponse.ok({
        'success': true,
        'message': 'Оценка успешно обновлена',
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      final gradeId = int.tryParse(id);

      if (gradeId == null) {
        return JsonResponse.badRequest('Некорректный идентификатор оценки');
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          DELETE FROM Grades
          WHERE ID_Grade = @id
          RETURNING ID_Grade
          ''',
        ),
        parameters: {
          'id': gradeId,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Оценка не найдена');
      }

      return JsonResponse.ok({
        'success': true,
        'message': 'Оценка успешно удалена',
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

  String? _validateGradeData({
    required int? studentId,
    required int? disciplineId,
    required int? periodId,
    required int? gradeValue,
    required String controlType,
  }) {
    if (studentId == null) {
      return 'Выберите студента';
    }

    if (disciplineId == null) {
      return 'Выберите дисциплину';
    }

    if (periodId == null) {
      return 'Выберите учебный период';
    }

    if (gradeValue == null || gradeValue < 2 || gradeValue > 5) {
      return 'Оценка должна быть в диапазоне от 2 до 5';
    }

    if (controlType.isEmpty) {
      return 'Введите форму контроля';
    }

    return null;
  }

  String? _formatDate(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value.toIso8601String().substring(0, 10);
    }

    return value.toString();
  }
}