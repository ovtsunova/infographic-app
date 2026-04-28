import 'package:dio/dio.dart';

import 'package:client/src/core/network/api_client.dart';

import 'educational_data_models.dart';

class EducationalDataRepository {
  final ApiClient _apiClient;

  EducationalDataRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  Future<EducationalDataBundle> loadAll() async {
    try {
      final responses = await Future.wait([
        _apiClient.dio.get('/groups'),
        _apiClient.dio.get('/disciplines'),
        _apiClient.dio.get('/periods'),
        _apiClient.dio.get('/students'),
        _apiClient.dio.get('/grades'),
        _apiClient.dio.get('/attendance'),
      ]);

      final groups = _readDataList(responses[0].data)
          .map(StudyGroup.fromJson)
          .toList();

      final disciplines = _readDataList(responses[1].data)
          .map(Discipline.fromJson)
          .toList();

      final periods = _readDataList(responses[2].data)
          .map(StudyPeriod.fromJson)
          .toList();

      final students = _readDataList(responses[3].data)
          .map(Student.fromJson)
          .toList();

      final grades = _readDataList(responses[4].data)
          .map(GradeRecord.fromJson)
          .toList();

      final attendance = _readDataList(responses[5].data)
          .map(AttendanceRecord.fromJson)
          .toList();

      return EducationalDataBundle(
        groups: groups,
        disciplines: disciplines,
        periods: periods,
        students: students,
        grades: grades,
        attendance: attendance,
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> createGroup({
    required String groupName,
    required int course,
    required String studyYear,
    String? directionName,
  }) async {
    try {
      await _apiClient.dio.post(
        '/groups',
        data: {
          'groupName': groupName.trim(),
          'course': course,
          'studyYear': studyYear.trim(),
          'directionName': _nullIfEmpty(directionName),
        },
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> updateGroup({
    required int id,
    required String groupName,
    required int course,
    required String studyYear,
    String? directionName,
  }) async {
    try {
      await _apiClient.dio.put(
        '/groups/$id',
        data: {
          'groupName': groupName.trim(),
          'course': course,
          'studyYear': studyYear.trim(),
          'directionName': _nullIfEmpty(directionName),
        },
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> deleteGroup({
    required int id,
  }) async {
    try {
      await _apiClient.dio.delete('/groups/$id');
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> createDiscipline({
    required String disciplineName,
    String? description,
    String? teacherName,
  }) async {
    try {
      await _apiClient.dio.post(
        '/disciplines',
        data: {
          'disciplineName': disciplineName.trim(),
          'description': _nullIfEmpty(description),
          'teacherName': _nullIfEmpty(teacherName),
        },
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> updateDiscipline({
    required int id,
    required String disciplineName,
    String? description,
    String? teacherName,
  }) async {
    try {
      await _apiClient.dio.put(
        '/disciplines/$id',
        data: {
          'disciplineName': disciplineName.trim(),
          'description': _nullIfEmpty(description),
          'teacherName': _nullIfEmpty(teacherName),
        },
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> deleteDiscipline({
    required int id,
  }) async {
    try {
      await _apiClient.dio.delete('/disciplines/$id');
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> createPeriod({
    required String studyYear,
    required int semester,
    required String startDate,
    required String endDate,
  }) async {
    try {
      await _apiClient.dio.post(
        '/periods',
        data: {
          'studyYear': studyYear.trim(),
          'semester': semester,
          'startDate': startDate.trim(),
          'endDate': endDate.trim(),
        },
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> updatePeriod({
    required int id,
    required String studyYear,
    required int semester,
    required String startDate,
    required String endDate,
  }) async {
    try {
      await _apiClient.dio.put(
        '/periods/$id',
        data: {
          'studyYear': studyYear.trim(),
          'semester': semester,
          'startDate': startDate.trim(),
          'endDate': endDate.trim(),
        },
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> deletePeriod({
    required int id,
  }) async {
    try {
      await _apiClient.dio.delete('/periods/$id');
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> createStudent({
    required String lastName,
    required String firstName,
    String? patronymic,
    String? recordBookNumber,
    required int groupId,
  }) async {
    try {
      await _apiClient.dio.post(
        '/students',
        data: {
          'lastName': lastName.trim(),
          'firstName': firstName.trim(),
          'patronymic': _nullIfEmpty(patronymic),
          'recordBookNumber': _nullIfEmpty(recordBookNumber),
          'groupId': groupId,
        },
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> updateStudent({
    required int id,
    required String lastName,
    required String firstName,
    String? patronymic,
    String? recordBookNumber,
    required int groupId,
  }) async {
    try {
      await _apiClient.dio.put(
        '/students/$id',
        data: {
          'lastName': lastName.trim(),
          'firstName': firstName.trim(),
          'patronymic': _nullIfEmpty(patronymic),
          'recordBookNumber': _nullIfEmpty(recordBookNumber),
          'groupId': groupId,
        },
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> deleteStudent({
    required int id,
  }) async {
    try {
      await _apiClient.dio.delete('/students/$id');
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> createGrade({
    required int studentId,
    required int disciplineId,
    required int periodId,
    required int gradeValue,
    required String controlType,
    String? gradeDate,
  }) async {
    try {
      await _apiClient.dio.post(
        '/grades',
        data: {
          'studentId': studentId,
          'disciplineId': disciplineId,
          'periodId': periodId,
          'gradeValue': gradeValue,
          'controlType': controlType.trim(),
          'gradeDate': _nullIfEmpty(gradeDate),
        },
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> updateGrade({
    required int id,
    required int studentId,
    required int disciplineId,
    required int periodId,
    required int gradeValue,
    required String controlType,
    required String gradeDate,
  }) async {
    try {
      await _apiClient.dio.put(
        '/grades/$id',
        data: {
          'studentId': studentId,
          'disciplineId': disciplineId,
          'periodId': periodId,
          'gradeValue': gradeValue,
          'controlType': controlType.trim(),
          'gradeDate': gradeDate.trim(),
        },
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> deleteGrade({
    required int id,
  }) async {
    try {
      await _apiClient.dio.delete('/grades/$id');
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> createAttendance({
    required int studentId,
    required int disciplineId,
    required int periodId,
    required int attendedCount,
    required int missedCount,
  }) async {
    try {
      await _apiClient.dio.post(
        '/attendance',
        data: {
          'studentId': studentId,
          'disciplineId': disciplineId,
          'periodId': periodId,
          'attendedCount': attendedCount,
          'missedCount': missedCount,
        },
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> updateAttendance({
    required int id,
    required int studentId,
    required int disciplineId,
    required int periodId,
    required int attendedCount,
    required int missedCount,
  }) async {
    try {
      await _apiClient.dio.put(
        '/attendance/$id',
        data: {
          'studentId': studentId,
          'disciplineId': disciplineId,
          'periodId': periodId,
          'attendedCount': attendedCount,
          'missedCount': missedCount,
        },
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<void> deleteAttendance({
    required int id,
  }) async {
    try {
      await _apiClient.dio.delete('/attendance/$id');
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  Future<CsvImportResult> importCsv({
    required String endpoint,
    required String fileName,
    required String csvText,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          'fileName': fileName.trim().isEmpty ? 'import.csv' : fileName.trim(),
          'csvText': csvText,
        },
      );

      final responseMap = _asMap(response.data);
      final data = _asMap(responseMap['data']);

      return CsvImportResult.fromJson(
        message: responseMap['message']?.toString(),
        json: data,
      );
    } on DioException catch (error) {
      throw EducationalDataException(_readErrorMessage(error));
    } catch (error) {
      throw EducationalDataException(error.toString());
    }
  }

  List<Map<String, dynamic>> _readDataList(dynamic responseData) {
    final responseMap = _asMap(responseData);
    final data = responseMap['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  String _readErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!;
    }

    return 'Ошибка выполнения операции с учебными данными';
  }

  String? _nullIfEmpty(String? value) {
    if (value == null) {
      return null;
    }

    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }
}

class CsvImportResult {
  final String fileName;
  final int rowsTotal;
  final int rowsSuccess;
  final int rowsFailed;
  final List<String> errors;
  final String message;

  const CsvImportResult({
    required this.fileName,
    required this.rowsTotal,
    required this.rowsSuccess,
    required this.rowsFailed,
    required this.errors,
    required this.message,
  });

  factory CsvImportResult.fromJson({
    required String? message,
    required Map<String, dynamic> json,
  }) {
    final rawErrors = json['errors'];

    return CsvImportResult(
      fileName: json['fileName']?.toString() ?? 'import.csv',
      rowsTotal: _readIntValue(json['rowsTotal']),
      rowsSuccess: _readIntValue(json['rowsSuccess']),
      rowsFailed: _readIntValue(json['rowsFailed']),
      errors: rawErrors is List
          ? rawErrors.map((item) => item.toString()).toList()
          : const [],
      message: message?.trim().isNotEmpty == true
          ? message!.trim()
          : 'Импорт CSV завершен',
    );
  }

  String get detailedMessage {
    final buffer = StringBuffer(message);
    buffer.write(' Всего строк: $rowsTotal.');
    buffer.write(' Успешно: $rowsSuccess.');
    buffer.write(' Ошибок: $rowsFailed.');

    if (errors.isNotEmpty) {
      buffer.write('\n');
      buffer.write(errors.take(5).join('\n'));

      if (errors.length > 5) {
        buffer.write('\nИ еще ошибок: ${errors.length - 5}.');
      }
    }

    return buffer.toString();
  }

  static int _readIntValue(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }
}

class EducationalDataException implements Exception {
  final String message;

  EducationalDataException(this.message);

  @override
  String toString() => message;
}