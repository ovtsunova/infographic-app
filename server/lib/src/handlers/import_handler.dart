import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../db/database.dart';
import '../utils/json_response.dart';

class ImportHandler {
  Future<Response> importStudents(Request request) async {
    try {
      final accountId = _getAccountId(request);

      if (accountId == null) {
        return JsonResponse.unauthorized('Не удалось определить пользователя');
      }

      final body = await _readJsonBody(request);
      final fileName = _readString(body, 'fileName', fallback: 'students.csv');
      final csvText = _readString(body, 'csvText');

      if (csvText.trim().isEmpty) {
        return JsonResponse.badRequest('Передайте содержимое CSV-файла');
      }

      final rows = _parseCsvWithHeader(csvText);

      if (rows.isEmpty) {
        return JsonResponse.badRequest('CSV-файл не содержит строк данных');
      }

      final conn = await Database.connection;
      var rowsSuccess = 0;
      final errors = <String>[];

      for (var index = 0; index < rows.length; index++) {
        final lineNumber = index + 2;
        final row = rows[index];

        try {
          final lastName = _cell(row, [
            'lastName',
            'lastname',
            'last_name',
            'фамилия',
          ]);

          final firstName = _cell(row, [
            'firstName',
            'firstname',
            'first_name',
            'имя',
          ]);

          final patronymic = _nullIfEmpty(
            _cell(row, [
              'patronymic',
              'middleName',
              'middle_name',
              'отчество',
            ]),
          );

          final recordBookNumber = _cell(row, [
            'recordBookNumber',
            'record_book_number',
            'bookNumber',
            'зачетка',
            'номерзачетки',
            'номер зачетки',
            'номер зачетной книжки',
          ]);

          final groupName = _cell(row, [
            'groupName',
            'group',
            'group_name',
            'группа',
          ]);

          if (lastName.isEmpty) {
            throw Exception('не указана фамилия');
          }

          if (firstName.isEmpty) {
            throw Exception('не указано имя');
          }

          if (recordBookNumber.isEmpty) {
            throw Exception('не указан номер зачетной книжки');
          }

          if (groupName.isEmpty) {
            throw Exception('не указана группа');
          }

          final groupId = await _findGroupId(conn, groupName);

          if (groupId == null) {
            throw Exception('группа "$groupName" не найдена');
          }

          await conn.execute(
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
              ON CONFLICT (RecordBookNumber)
              DO UPDATE SET
                LastName = EXCLUDED.LastName,
                FirstName = EXCLUDED.FirstName,
                Patronymic = EXCLUDED.Patronymic,
                Group_ID = EXCLUDED.Group_ID
            '''),
            parameters: {
              'lastName': lastName,
              'firstName': firstName,
              'patronymic': patronymic,
              'recordBookNumber': recordBookNumber,
              'groupId': groupId,
            },
          );

          rowsSuccess++;
        } catch (error) {
          errors.add('Строка $lineNumber: $error');
        }
      }

      await _saveImportFile(
        conn: conn,
        accountId: accountId,
        fileName: fileName,
        rowsTotal: rows.length,
        rowsSuccess: rowsSuccess,
        errors: errors,
      );

      return JsonResponse.ok({
        'success': errors.isEmpty,
        'message': _buildImportMessage(
          entityName: 'студентов',
          rowsSuccess: rowsSuccess,
          rowsFailed: errors.length,
        ),
        'data': {
          'fileName': fileName,
          'rowsTotal': rows.length,
          'rowsSuccess': rowsSuccess,
          'rowsFailed': errors.length,
          'errors': errors,
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> importGrades(Request request) async {
    try {
      final accountId = _getAccountId(request);

      if (accountId == null) {
        return JsonResponse.unauthorized('Не удалось определить пользователя');
      }

      final body = await _readJsonBody(request);
      final fileName = _readString(body, 'fileName', fallback: 'grades.csv');
      final csvText = _readString(body, 'csvText');

      if (csvText.trim().isEmpty) {
        return JsonResponse.badRequest('Передайте содержимое CSV-файла');
      }

      final rows = _parseCsvWithHeader(csvText);

      if (rows.isEmpty) {
        return JsonResponse.badRequest('CSV-файл не содержит строк данных');
      }

      final conn = await Database.connection;
      var rowsSuccess = 0;
      final errors = <String>[];

      for (var index = 0; index < rows.length; index++) {
        final lineNumber = index + 2;
        final row = rows[index];

        try {
          final recordBookNumber = _cell(row, [
            'recordBookNumber',
            'record_book_number',
            'bookNumber',
            'зачетка',
            'номерзачетки',
            'номер зачетки',
            'номер зачетной книжки',
          ]);

          final disciplineName = _cell(row, [
            'disciplineName',
            'discipline',
            'discipline_name',
            'дисциплина',
          ]);

          final studyYear = _cell(row, [
            'studyYear',
            'study_year',
            'учебныйгод',
            'учебный год',
          ]);

          final semester = _readIntFromText(
            _cell(row, [
              'semester',
              'семестр',
            ]),
          );

          final gradeValue = _readIntFromText(
            _cell(row, [
              'gradeValue',
              'grade',
              'grade_value',
              'оценка',
            ]),
          );

          final controlType = _cell(row, [
            'controlType',
            'control_type',
            'форма контроля',
            'формаконтроля',
          ], fallback: 'Контрольная работа');

          final gradeDate = _nullIfEmpty(
            _cell(row, [
              'gradeDate',
              'grade_date',
              'дата',
              'дата оценки',
              'датаоценки',
            ]),
          );

          if (recordBookNumber.isEmpty) {
            throw Exception('не указан номер зачетной книжки');
          }

          if (disciplineName.isEmpty) {
            throw Exception('не указана дисциплина');
          }

          if (studyYear.isEmpty) {
            throw Exception('не указан учебный год');
          }

          if (semester == null) {
            throw Exception('некорректный семестр');
          }

          if (gradeValue == null || gradeValue < 2 || gradeValue > 5) {
            throw Exception('оценка должна быть от 2 до 5');
          }

          if (controlType.isEmpty) {
            throw Exception('не указана форма контроля');
          }

          final studentId = await _findStudentId(conn, recordBookNumber);
          final disciplineId = await _findDisciplineId(conn, disciplineName);
          final periodId = await _findPeriodId(
            conn: conn,
            studyYear: studyYear,
            semester: semester,
          );

          if (studentId == null) {
            throw Exception(
              'студент с номером зачетной книжки "$recordBookNumber" не найден',
            );
          }

          if (disciplineId == null) {
            throw Exception('дисциплина "$disciplineName" не найдена');
          }

          if (periodId == null) {
            throw Exception(
              'период "$studyYear, семестр $semester" не найден',
            );
          }

          final parsedGradeDate = gradeDate == null
              ? DateTime.now()
              : DateTime.tryParse(gradeDate);

          if (parsedGradeDate == null) {
            throw Exception('дата оценки должна быть в формате YYYY-MM-DD');
          }

          await conn.execute(
            Sql.named('''
              INSERT INTO Grades (
                GradeValue,
                ControlType,
                GradeDate,
                Student_ID,
                Discipline_ID,
                Period_ID
              )
              VALUES (
                @gradeValue,
                @controlType,
                @gradeDate,
                @studentId,
                @disciplineId,
                @periodId
              )
              ON CONFLICT (Student_ID, Discipline_ID, Period_ID, ControlType)
              DO UPDATE SET
                GradeValue = EXCLUDED.GradeValue,
                GradeDate = EXCLUDED.GradeDate
            '''),
            parameters: {
              'gradeValue': gradeValue,
              'controlType': controlType,
              'gradeDate': parsedGradeDate,
              'studentId': studentId,
              'disciplineId': disciplineId,
              'periodId': periodId,
            },
          );

          rowsSuccess++;
        } catch (error) {
          errors.add('Строка $lineNumber: $error');
        }
      }

      await _saveImportFile(
        conn: conn,
        accountId: accountId,
        fileName: fileName,
        rowsTotal: rows.length,
        rowsSuccess: rowsSuccess,
        errors: errors,
      );

      return JsonResponse.ok({
        'success': errors.isEmpty,
        'message': _buildImportMessage(
          entityName: 'оценок',
          rowsSuccess: rowsSuccess,
          rowsFailed: errors.length,
        ),
        'data': {
          'fileName': fileName,
          'rowsTotal': rows.length,
          'rowsSuccess': rowsSuccess,
          'rowsFailed': errors.length,
          'errors': errors,
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> importAttendance(Request request) async {
    try {
      final accountId = _getAccountId(request);

      if (accountId == null) {
        return JsonResponse.unauthorized('Не удалось определить пользователя');
      }

      final body = await _readJsonBody(request);
      final fileName = _readString(
        body,
        'fileName',
        fallback: 'attendance.csv',
      );
      final csvText = _readString(body, 'csvText');

      if (csvText.trim().isEmpty) {
        return JsonResponse.badRequest('Передайте содержимое CSV-файла');
      }

      final rows = _parseCsvWithHeader(csvText);

      if (rows.isEmpty) {
        return JsonResponse.badRequest('CSV-файл не содержит строк данных');
      }

      final conn = await Database.connection;
      var rowsSuccess = 0;
      final errors = <String>[];

      for (var index = 0; index < rows.length; index++) {
        final lineNumber = index + 2;
        final row = rows[index];

        try {
          final recordBookNumber = _cell(row, [
            'recordBookNumber',
            'record_book_number',
            'bookNumber',
            'зачетка',
            'номерзачетки',
            'номер зачетки',
            'номер зачетной книжки',
          ]);

          final disciplineName = _cell(row, [
            'disciplineName',
            'discipline',
            'discipline_name',
            'дисциплина',
          ]);

          final studyYear = _cell(row, [
            'studyYear',
            'study_year',
            'учебныйгод',
            'учебный год',
          ]);

          final semester = _readIntFromText(
            _cell(row, [
              'semester',
              'семестр',
            ]),
          );

          final attendedCount = _readIntFromText(
            _cell(row, [
              'attendedCount',
              'attended_count',
              'presentCount',
              'посещено',
              'посещено занятий',
            ]),
          );

          final missedCount = _readIntFromText(
            _cell(row, [
              'missedCount',
              'missed_count',
              'absenceCount',
              'пропущено',
              'пропущено занятий',
            ]),
          );

          if (recordBookNumber.isEmpty) {
            throw Exception('не указан номер зачетной книжки');
          }

          if (disciplineName.isEmpty) {
            throw Exception('не указана дисциплина');
          }

          if (studyYear.isEmpty) {
            throw Exception('не указан учебный год');
          }

          if (semester == null) {
            throw Exception('некорректный семестр');
          }

          if (attendedCount == null || attendedCount < 0) {
            throw Exception('количество посещенных занятий некорректно');
          }

          if (missedCount == null || missedCount < 0) {
            throw Exception('количество пропущенных занятий некорректно');
          }

          final studentId = await _findStudentId(conn, recordBookNumber);
          final disciplineId = await _findDisciplineId(conn, disciplineName);
          final periodId = await _findPeriodId(
            conn: conn,
            studyYear: studyYear,
            semester: semester,
          );

          if (studentId == null) {
            throw Exception(
              'студент с номером зачетной книжки "$recordBookNumber" не найден',
            );
          }

          if (disciplineId == null) {
            throw Exception('дисциплина "$disciplineName" не найдена');
          }

          if (periodId == null) {
            throw Exception(
              'период "$studyYear, семестр $semester" не найден',
            );
          }

          await conn.execute(
            Sql.named('''
              INSERT INTO Attendance (
                AttendedCount,
                MissedCount,
                Student_ID,
                Discipline_ID,
                Period_ID
              )
              VALUES (
                @attendedCount,
                @missedCount,
                @studentId,
                @disciplineId,
                @periodId
              )
              ON CONFLICT (Student_ID, Discipline_ID, Period_ID)
              DO UPDATE SET
                AttendedCount = EXCLUDED.AttendedCount,
                MissedCount = EXCLUDED.MissedCount
            '''),
            parameters: {
              'attendedCount': attendedCount,
              'missedCount': missedCount,
              'studentId': studentId,
              'disciplineId': disciplineId,
              'periodId': periodId,
            },
          );

          rowsSuccess++;
        } catch (error) {
          errors.add('Строка $lineNumber: $error');
        }
      }

      await _saveImportFile(
        conn: conn,
        accountId: accountId,
        fileName: fileName,
        rowsTotal: rows.length,
        rowsSuccess: rowsSuccess,
        errors: errors,
      );

      return JsonResponse.ok({
        'success': errors.isEmpty,
        'message': _buildImportMessage(
          entityName: 'записей посещаемости',
          rowsSuccess: rowsSuccess,
          rowsFailed: errors.length,
        ),
        'data': {
          'fileName': fileName,
          'rowsTotal': rows.length,
          'rowsSuccess': rowsSuccess,
          'rowsFailed': errors.length,
          'errors': errors,
        },
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
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

      return int.tryParse(value?.toString() ?? '');
    }

    return null;
  }

  String _readString(
    Map<dynamic, dynamic> body,
    String key, {
    String fallback = '',
  }) {
    final value = body[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  String? _nullIfEmpty(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  int? _readIntFromText(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return int.tryParse(normalized);
  }

  Future<int?> _findGroupId(Connection conn, String groupName) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT ID_Group AS id
        FROM StudyGroups
        WHERE LOWER(GroupName) = LOWER(@groupName)
        LIMIT 1
      '''),
      parameters: {
        'groupName': groupName.trim(),
      },
    );

    if (result.isEmpty) {
      return null;
    }

    return _readInt(result.first.toColumnMap()['id']);
  }

  Future<int?> _findStudentId(
    Connection conn,
    String recordBookNumber,
  ) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT ID_Student AS id
        FROM Students
        WHERE LOWER(RecordBookNumber) = LOWER(@recordBookNumber)
        LIMIT 1
      '''),
      parameters: {
        'recordBookNumber': recordBookNumber.trim(),
      },
    );

    if (result.isEmpty) {
      return null;
    }

    return _readInt(result.first.toColumnMap()['id']);
  }

  Future<int?> _findDisciplineId(
    Connection conn,
    String disciplineName,
  ) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT ID_Discipline AS id
        FROM Disciplines
        WHERE LOWER(DisciplineName) = LOWER(@disciplineName)
        LIMIT 1
      '''),
      parameters: {
        'disciplineName': disciplineName.trim(),
      },
    );

    if (result.isEmpty) {
      return null;
    }

    return _readInt(result.first.toColumnMap()['id']);
  }

  Future<int?> _findPeriodId({
    required Connection conn,
    required String studyYear,
    required int semester,
  }) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT ID_Period AS id
        FROM StudyPeriods
        WHERE StudyYear = @studyYear
          AND Semester = @semester
        LIMIT 1
      '''),
      parameters: {
        'studyYear': studyYear.trim(),
        'semester': semester,
      },
    );

    if (result.isEmpty) {
      return null;
    }

    return _readInt(result.first.toColumnMap()['id']);
  }

  int? _readInt(dynamic value) {
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

  Future<void> _saveImportFile({
    required Connection conn,
    required int accountId,
    required String fileName,
    required int rowsTotal,
    required int rowsSuccess,
    required List<String> errors,
  }) async {
    final rowsFailed = errors.length;
    final status = rowsFailed == 0
        ? 'Успешно'
        : rowsSuccess == 0
            ? 'Ошибка'
            : 'Частично';

    final errorMessage = errors.isEmpty
        ? null
        : errors.take(30).join('\n');

    await conn.execute(
      Sql.named('''
        INSERT INTO ImportFiles (
          OriginalFileName,
          FileType,
          ImportStatus,
          RowsTotal,
          RowsSuccess,
          RowsFailed,
          ErrorMessage,
          Account_ID
        )
        VALUES (
          @fileName,
          'CSV',
          @status,
          @rowsTotal,
          @rowsSuccess,
          @rowsFailed,
          @errorMessage,
          @accountId
        )
      '''),
      parameters: {
        'fileName': fileName,
        'status': status,
        'rowsTotal': rowsTotal,
        'rowsSuccess': rowsSuccess,
        'rowsFailed': rowsFailed,
        'errorMessage': errorMessage,
        'accountId': accountId,
      },
    );
  }

  String _buildImportMessage({
    required String entityName,
    required int rowsSuccess,
    required int rowsFailed,
  }) {
    if (rowsFailed == 0) {
      return 'Импорт $entityName выполнен успешно. Загружено строк: $rowsSuccess.';
    }

    if (rowsSuccess == 0) {
      return 'Импорт $entityName завершился ошибкой. Ошибок: $rowsFailed.';
    }

    return 'Импорт $entityName выполнен частично. Успешно: $rowsSuccess, ошибок: $rowsFailed.';
  }

  List<Map<String, String>> _parseCsvWithHeader(String csvText) {
    final rows = _parseCsvRows(csvText)
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .toList();

    if (rows.length <= 1) {
      return [];
    }

    final headers = rows.first.map(_normalizeHeader).toList();
    final result = <Map<String, String>>[];

    for (final rawRow in rows.skip(1)) {
      final row = <String, String>{};

      for (var index = 0; index < headers.length; index++) {
        final header = headers[index];

        if (header.isEmpty) {
          continue;
        }

        final value = index < rawRow.length ? rawRow[index].trim() : '';
        row[header] = value;
      }

      result.add(row);
    }

    return result;
  }

  List<List<String>> _parseCsvRows(String text) {
    final delimiter = _detectDelimiter(text);
    final rows = <List<String>>[];
    var currentCell = StringBuffer();
    var currentRow = <String>[];
    var insideQuotes = false;

    for (var index = 0; index < text.length; index++) {
      final char = text[index];

      if (char == '"') {
        final nextChar = index + 1 < text.length ? text[index + 1] : null;

        if (insideQuotes && nextChar == '"') {
          currentCell.write('"');
          index++;
        } else {
          insideQuotes = !insideQuotes;
        }

        continue;
      }

      if (char == delimiter && !insideQuotes) {
        currentRow.add(currentCell.toString());
        currentCell = StringBuffer();
        continue;
      }

      if ((char == '\n' || char == '\r') && !insideQuotes) {
        if (char == '\r' &&
            index + 1 < text.length &&
            text[index + 1] == '\n') {
          index++;
        }

        currentRow.add(currentCell.toString());
        rows.add(currentRow);

        currentCell = StringBuffer();
        currentRow = [];
        continue;
      }

      currentCell.write(char);
    }

    currentRow.add(currentCell.toString());

    if (currentRow.any((cell) => cell.trim().isNotEmpty)) {
      rows.add(currentRow);
    }

    return rows;
  }

  String _detectDelimiter(String text) {
    final firstLine = text
        .split(RegExp(r'\r?\n'))
        .firstWhere(
          (line) => line.trim().isNotEmpty,
          orElse: () => '',
        );

    final semicolonCount = ';'.allMatches(firstLine).length;
    final commaCount = ','.allMatches(firstLine).length;
    final tabCount = '\t'.allMatches(firstLine).length;

    if (tabCount >= semicolonCount && tabCount >= commaCount && tabCount > 0) {
      return '\t';
    }

    if (semicolonCount >= commaCount) {
      return ';';
    }

    return ',';
  }

  String _normalizeHeader(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'[\s_\-]+'), '');
  }

  String _cell(
    Map<String, String> row,
    List<String> aliases, {
    String fallback = '',
  }) {
    for (final alias in aliases) {
      final key = _normalizeHeader(alias);
      final value = row[key];

      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return fallback;
  }
} 