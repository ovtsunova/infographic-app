import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class AttendanceHandler {
  Future<Response> getAll(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute(
        '''
        SELECT
          a.ID_Attendance AS id,
          a.AttendedCount AS attended_count,
          a.MissedCount AS missed_count,
          s.ID_Student AS student_id,
          s.LastName || ' ' || s.FirstName || ' ' || COALESCE(s.Patronymic, '') AS student_name,
          d.ID_Discipline AS discipline_id,
          d.DisciplineName AS discipline_name,
          p.ID_Period AS period_id,
          p.StudyYear AS study_year,
          p.Semester AS semester
        FROM Attendance a
        JOIN Students s ON a.Student_ID = s.ID_Student
        JOIN Disciplines d ON a.Discipline_ID = d.ID_Discipline
        JOIN StudyPeriods p ON a.Period_ID = p.ID_Period
        ORDER BY a.ID_Attendance
        ''',
      );

      final attendance = result.map((row) {
        final data = row.toColumnMap();

        final attended = data['attended_count'] as int;
        final missed = data['missed_count'] as int;
        final total = attended + missed;
        final rate = total == 0 ? 0 : attended / total * 100;

        return {
          'id': data['id'],
          'attendedCount': attended,
          'missedCount': missed,
          'totalClasses': total,
          'attendanceRate': double.parse(rate.toStringAsFixed(2)),
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
        'data': attendance,
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
      final attendedCount = _readInt(body, 'attendedCount');
      final missedCount = _readInt(body, 'missedCount');

      final validationError = _validateAttendanceData(
        studentId: studentId,
        disciplineId: disciplineId,
        periodId: periodId,
        attendedCount: attendedCount,
        missedCount: missedCount,
      );

      if (validationError != null) {
        return JsonResponse.badRequest(validationError);
      }

      final conn = await Database.connection;

      await conn.execute(
        Sql.named(
          '''
          CALL AddAttendance(
            @studentId,
            @disciplineId,
            @periodId,
            @attendedCount,
            @missedCount
          )
          ''',
        ),
        parameters: {
          'studentId': studentId,
          'disciplineId': disciplineId,
          'periodId': periodId,
          'attendedCount': attendedCount,
          'missedCount': missedCount,
        },
      );

      return JsonResponse.created({
        'success': true,
        'message': 'Посещаемость успешно добавлена',
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> update(Request request, String id) async {
    try {
      final attendanceId = int.tryParse(id);

      if (attendanceId == null) {
        return JsonResponse.badRequest('Некорректный идентификатор посещаемости');
      }

      final body = await _readJsonBody(request);

      final studentId = _readInt(body, 'studentId');
      final disciplineId = _readInt(body, 'disciplineId');
      final periodId = _readInt(body, 'periodId');
      final attendedCount = _readInt(body, 'attendedCount');
      final missedCount = _readInt(body, 'missedCount');

      final validationError = _validateAttendanceData(
        studentId: studentId,
        disciplineId: disciplineId,
        periodId: periodId,
        attendedCount: attendedCount,
        missedCount: missedCount,
      );

      if (validationError != null) {
        return JsonResponse.badRequest(validationError);
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          UPDATE Attendance
          SET
            Student_ID = @studentId,
            Discipline_ID = @disciplineId,
            Period_ID = @periodId,
            AttendedCount = @attendedCount,
            MissedCount = @missedCount
          WHERE ID_Attendance = @id
          RETURNING ID_Attendance
          ''',
        ),
        parameters: {
          'id': attendanceId,
          'studentId': studentId,
          'disciplineId': disciplineId,
          'periodId': periodId,
          'attendedCount': attendedCount,
          'missedCount': missedCount,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Запись посещаемости не найдена');
      }

      return JsonResponse.ok({
        'success': true,
        'message': 'Посещаемость успешно обновлена',
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      final attendanceId = int.tryParse(id);

      if (attendanceId == null) {
        return JsonResponse.badRequest('Некорректный идентификатор посещаемости');
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          DELETE FROM Attendance
          WHERE ID_Attendance = @id
          RETURNING ID_Attendance
          ''',
        ),
        parameters: {
          'id': attendanceId,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound('Запись посещаемости не найдена');
      }

      return JsonResponse.ok({
        'success': true,
        'message': 'Посещаемость успешно удалена',
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

  String? _validateAttendanceData({
    required int? studentId,
    required int? disciplineId,
    required int? periodId,
    required int? attendedCount,
    required int? missedCount,
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

    if (attendedCount == null || attendedCount < 0) {
      return 'Количество посещенных занятий должно быть больше либо равно 0';
    }

    if (missedCount == null || missedCount < 0) {
      return 'Количество пропущенных занятий должно быть больше либо равно 0';
    }

    return null;
  }
}