import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';

import '../config/app_env.dart';
import '../db/database.dart';
import '../utils/json_response.dart';

class BackupHandler {
  Future<Response> getBackups(Request request) async {
    try {
      final directory = await _ensureBackupDirectory();
      final files = await directory
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .where(_isAllowedBackupFile)
          .asyncMap(_backupFileToJson)
          .toList();

      files.sort((a, b) {
        final aDate = a['createdAt']?.toString() ?? '';
        final bDate = b['createdAt']?.toString() ?? '';

        return bDate.compareTo(aDate);
      });

      return JsonResponse.ok({
        'success': true,
        'data': files,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> createBackup(Request request) async {
    try {
      final body = await _readJsonBody(request);
      final directory = await _ensureBackupDirectory();
      final fileName = _buildBackupFileName(body['backupName']);
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);

      final args = [
        '-h',
        AppEnv.dbHost,
        '-p',
        AppEnv.dbPort.toString(),
        '-U',
        AppEnv.dbUser,
        '-d',
        AppEnv.dbName,
        '--clean',
        '--if-exists',
        '--no-owner',
        '--no-privileges',
        '-f',
        filePath,
      ];

      final result = await Process.run(
        AppEnv.pgDumpPath,
        args,
        environment: {
          'PGPASSWORD': AppEnv.dbPassword,
        },
        runInShell: Platform.isWindows,
      );

      if (result.exitCode != 0) {
        if (await file.exists()) {
          await file.delete();
        }

        return JsonResponse.badRequest(
          'Не удалось создать резервную копию. Проверьте путь к pg_dump и параметры подключения к PostgreSQL. ${_processOutput(result)}',
        );
      }

      final data = await _backupFileToJson(file);

      return JsonResponse.created({
        'success': true,
        'message': 'Резервная копия базы данных успешно создана',
        'data': data,
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Response> restoreBackup(Request request, String fileName) async {
    try {
      final safeFileName = _normalizeRouteFileName(fileName);

      if (!_isAllowedBackupFileName(safeFileName)) {
        return JsonResponse.badRequest('Некорректное имя файла резервной копии');
      }

      final directory = await _ensureBackupDirectory();
      final filePath = path.join(directory.path, safeFileName);
      final file = File(filePath);

      if (!await file.exists()) {
        return JsonResponse.notFound('Резервная копия не найдена');
      }

      await Database.close();

      final args = [
        '-h',
        AppEnv.dbHost,
        '-p',
        AppEnv.dbPort.toString(),
        '-U',
        AppEnv.dbUser,
        '-d',
        AppEnv.dbName,
        '-v',
        'ON_ERROR_STOP=1',
        '-f',
        filePath,
      ];

      final result = await Process.run(
        AppEnv.psqlPath,
        args,
        environment: {
          'PGPASSWORD': AppEnv.dbPassword,
        },
        runInShell: Platform.isWindows,
      );

      if (result.exitCode != 0) {
        return JsonResponse.badRequest(
          'Не удалось восстановить базу данных из резервной копии. Проверьте путь к psql и содержимое файла. ${_processOutput(result)}',
        );
      }

      return JsonResponse.ok({
        'success': true,
        'message': 'База данных успешно восстановлена из резервной копии',
        'data': await _backupFileToJson(file),
      });
    } catch (error) {
      return JsonResponse.serverError(error);
    }
  }

  Future<Map<String, dynamic>> _backupFileToJson(File file) async {
    final stat = await file.stat();

    return {
      'fileName': path.basename(file.path),
      'sizeBytes': stat.size,
      'createdAt': stat.changed.toIso8601String(),
      'modifiedAt': stat.modified.toIso8601String(),
      'extension': path.extension(file.path).replaceFirst('.', '').toUpperCase(),
    };
  }

  Future<Directory> _ensureBackupDirectory() async {
    final configuredPath = AppEnv.backupDirectory.trim();
    final directory = Directory(configuredPath.isEmpty ? 'backups' : configuredPath);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
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

    return {};
  }

  String _buildBackupFileName(dynamic rawName) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(
          RegExp(r'[:.]'),
          '-',
        );
    final baseName = _sanitizeFileBaseName(rawName?.toString() ?? '');

    if (baseName.isEmpty) {
      return 'backup_$timestamp.sql';
    }

    return '${baseName}_$timestamp.sql';
  }

  String _sanitizeFileBaseName(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
          RegExp(r'\s+'),
          '_',
        );
    final safe = normalized.replaceAll(RegExp(r'[^a-zа-яё0-9_-]', unicode: true), '');

    if (safe.length <= 60) {
      return safe;
    }

    return safe.substring(0, 60);
  }

  String _normalizeRouteFileName(String fileName) {
    final decoded = Uri.decodeComponent(fileName).trim();

    return path.basename(decoded);
  }

  bool _isAllowedBackupFile(File file) {
    return _isAllowedBackupFileName(path.basename(file.path));
  }

  bool _isAllowedBackupFileName(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    return fileName.isNotEmpty &&
        !fileName.contains('/') &&
        !fileName.contains('\\') &&
        (extension == '.sql' || extension == '.backup');
  }

  String _processOutput(ProcessResult result) {
    final stderrText = result.stderr?.toString().trim() ?? '';
    final stdoutText = result.stdout?.toString().trim() ?? '';
    final output = stderrText.isNotEmpty ? stderrText : stdoutText;

    if (output.isEmpty) {
      return '';
    }

    if (output.length <= 600) {
      return output;
    }

    return output.substring(0, 600);
  }
}
