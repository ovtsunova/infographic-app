import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class PeriodsHandler {
  Future<Response> getAll(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute(
        '''
        SELECT
          ID_Period AS id,
          StudyYear AS study_year,
          Semester AS semester,
          StartDate AS start_date,
          EndDate AS end_date
        FROM StudyPeriods
        ORDER BY StudyYear, Semester
        ''',
      );

      final periods = result.map((row) {
        final data = row.toColumnMap();

        return {
          'id': data['id'],
          'studyYear': data['study_year'],
          'semester': data['semester'],
          'startDate': _formatDate(data['start_date']),
          'endDate': _formatDate(data['end_date']),
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': periods,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> getById(Request request, String id) async {
    try {
      final periodId = int.tryParse(id);

      if (periodId == null) {
        return JsonResponse.badRequest(
          'Некорректный идентификатор учебного периода',
        );
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          SELECT
            ID_Period AS id,
            StudyYear AS study_year,
            Semester AS semester,
            StartDate AS start_date,
            EndDate AS end_date
          FROM StudyPeriods
          WHERE ID_Period = @id
          ''',
        ),
        parameters: {
          'id': periodId,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound(
          'Учебный период не найден',
        );
      }

      final data = result.first.toColumnMap();

      return JsonResponse.ok({
        'success': true,
        'data': {
          'id': data['id'],
          'studyYear': data['study_year'],
          'semester': data['semester'],
          'startDate': _formatDate(data['start_date']),
          'endDate': _formatDate(data['end_date']),
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> create(Request request) async {
    try {
      final body = await _readJsonBody(request);

      final studyYear = _readString(body, 'studyYear');
      final semester = _readInt(body, 'semester');
      final startDateText = _readString(body, 'startDate');
      final endDateText = _readString(body, 'endDate');

      final validationError = _validatePeriodData(
        studyYear: studyYear,
        semester: semester,
        startDateText: startDateText,
        endDateText: endDateText,
      );

      if (validationError != null) {
        return JsonResponse.badRequest(validationError);
      }

      final startDate = DateTime.parse(startDateText);
      final endDate = DateTime.parse(endDateText);

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          INSERT INTO StudyPeriods (
            StudyYear,
            Semester,
            StartDate,
            EndDate
          )
          VALUES (
            @studyYear,
            @semester,
            @startDate,
            @endDate
          )
          RETURNING
            ID_Period AS id,
            StudyYear AS study_year,
            Semester AS semester,
            StartDate AS start_date,
            EndDate AS end_date
          ''',
        ),
        parameters: {
          'studyYear': studyYear,
          'semester': semester,
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      final data = result.first.toColumnMap();

      return JsonResponse.created({
        'success': true,
        'message': 'Учебный период успешно добавлен',
        'data': {
          'id': data['id'],
          'studyYear': data['study_year'],
          'semester': data['semester'],
          'startDate': _formatDate(data['start_date']),
          'endDate': _formatDate(data['end_date']),
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> update(Request request, String id) async {
    try {
      final periodId = int.tryParse(id);

      if (periodId == null) {
        return JsonResponse.badRequest(
          'Некорректный идентификатор учебного периода',
        );
      }

      final body = await _readJsonBody(request);

      final studyYear = _readString(body, 'studyYear');
      final semester = _readInt(body, 'semester');
      final startDateText = _readString(body, 'startDate');
      final endDateText = _readString(body, 'endDate');

      final validationError = _validatePeriodData(
        studyYear: studyYear,
        semester: semester,
        startDateText: startDateText,
        endDateText: endDateText,
      );

      if (validationError != null) {
        return JsonResponse.badRequest(validationError);
      }

      final startDate = DateTime.parse(startDateText);
      final endDate = DateTime.parse(endDateText);

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          UPDATE StudyPeriods
          SET
            StudyYear = @studyYear,
            Semester = @semester,
            StartDate = @startDate,
            EndDate = @endDate
          WHERE ID_Period = @id
          RETURNING
            ID_Period AS id,
            StudyYear AS study_year,
            Semester AS semester,
            StartDate AS start_date,
            EndDate AS end_date
          ''',
        ),
        parameters: {
          'id': periodId,
          'studyYear': studyYear,
          'semester': semester,
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound(
          'Учебный период не найден',
        );
      }

      final data = result.first.toColumnMap();

      return JsonResponse.ok({
        'success': true,
        'message': 'Учебный период успешно обновлен',
        'data': {
          'id': data['id'],
          'studyYear': data['study_year'],
          'semester': data['semester'],
          'startDate': _formatDate(data['start_date']),
          'endDate': _formatDate(data['end_date']),
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      final periodId = int.tryParse(id);

      if (periodId == null) {
        return JsonResponse.badRequest(
          'Некорректный идентификатор учебного периода',
        );
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          DELETE FROM StudyPeriods
          WHERE ID_Period = @id
          RETURNING ID_Period
          ''',
        ),
        parameters: {
          'id': periodId,
        },
      );

      if (result.isEmpty) {
        return JsonResponse.notFound(
          'Учебный период не найден',
        );
      }

      return JsonResponse.ok({
        'success': true,
        'message': 'Учебный период успешно удален',
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

  String? _validatePeriodData({
    required String studyYear,
    required int? semester,
    required String startDateText,
    required String endDateText,
  }) {
    final studyYearPattern = RegExp(r'^\d{4}/\d{4}$');

    if (!studyYearPattern.hasMatch(studyYear)) {
      return 'Учебный год должен быть в формате 2025/2026';
    }

    if (semester == null) {
      return 'Введите номер семестра';
    }

    if (semester < 1 || semester > 12) {
      return 'Семестр должен быть в диапазоне от 1 до 12';
    }

    final startDate = DateTime.tryParse(startDateText);
    final endDate = DateTime.tryParse(endDateText);

    if (startDate == null) {
      return 'Дата начала должна быть в формате YYYY-MM-DD';
    }

    if (endDate == null) {
      return 'Дата окончания должна быть в формате YYYY-MM-DD';
    }

    if (startDate.isAfter(endDate)) {
      return 'Дата начала не может быть позже даты окончания';
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