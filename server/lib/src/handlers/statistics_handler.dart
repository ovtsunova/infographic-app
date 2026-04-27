import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class StatisticsHandler {
  Future<Response> getGroupStatistics(Request request) async {
    try {
      final conn = await Database.connection;

      final result = await conn.execute(
        '''
        SELECT *
        FROM GroupStatisticsView
        ORDER BY "Код группы"
        ''',
      );

      final data = result.map((row) {
        final item = row.toColumnMap();

        return {
          'groupId': item['Код группы'],
          'groupName': item['Группа'],
          'course': item['Курс'],
          'studyYear': item['Учебный год'],
          'studentsCount': item['Количество студентов'],
          'averageGrade': item['Средний балл'],
          'successRate': item['Процент успеваемости'],
          'debtorCount': item['Количество задолженностей'],
          'excellentCount': item['Количество отличников'],
          'attendanceRate': item['Средний процент посещаемости'],
        };
      }).toList();

      return JsonResponse.ok({
        'success': true,
        'data': data,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> getSummary(Request request) async {
    try {
      final groupId = int.tryParse(request.url.queryParameters['groupId'] ?? '');
      final periodId = int.tryParse(request.url.queryParameters['periodId'] ?? '');

      if (groupId == null || periodId == null) {
        return JsonResponse.badRequest(
          'Передайте параметры groupId и periodId',
        );
      }

      final conn = await Database.connection;

      final avgResult = await conn.execute(
        Sql.named(
          'SELECT get_group_avg_grade_period(@groupId, @periodId) AS value',
        ),
        parameters: {
          'groupId': groupId,
          'periodId': periodId,
        },
      );

      final successResult = await conn.execute(
        Sql.named(
          'SELECT get_group_success_rate_period(@groupId, @periodId) AS value',
        ),
        parameters: {
          'groupId': groupId,
          'periodId': periodId,
        },
      );

      final attendanceResult = await conn.execute(
        Sql.named(
          'SELECT get_group_attendance_rate_period(@groupId, @periodId) AS value',
        ),
        parameters: {
          'groupId': groupId,
          'periodId': periodId,
        },
      );

      return JsonResponse.ok({
        'success': true,
        'data': {
          'groupId': groupId,
          'periodId': periodId,
          'averageGrade': avgResult.first.toColumnMap()['value'],
          'successRate': successResult.first.toColumnMap()['value'],
          'attendanceRate': attendanceResult.first.toColumnMap()['value'],
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> getGradeDistribution(Request request) async {
    try {
      final groupId = int.tryParse(request.url.queryParameters['groupId'] ?? '');
      final disciplineId =
          int.tryParse(request.url.queryParameters['disciplineId'] ?? '');
      final periodId = int.tryParse(request.url.queryParameters['periodId'] ?? '');

      if (groupId == null || disciplineId == null || periodId == null) {
        return JsonResponse.badRequest(
          'Передайте параметры groupId, disciplineId и periodId',
        );
      }

      final conn = await Database.connection;

      final result = await conn.execute(
        Sql.named(
          '''
          SELECT *
          FROM get_grade_distribution(
            @groupId,
            @disciplineId,
            @periodId
          )
          ''',
        ),
        parameters: {
          'groupId': groupId,
          'disciplineId': disciplineId,
          'periodId': periodId,
        },
      );

      final labels = <String>[];
      final values = <int>[];

      for (final row in result) {
        final data = row.toColumnMap();
        labels.add(data['grade_label'].toString());
        values.add(int.parse(data['grade_count'].toString()));
      }

      return JsonResponse.ok({
        'success': true,
        'data': {
          'labels': labels,
          'values': values,
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }
}