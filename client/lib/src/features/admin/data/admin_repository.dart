import 'package:dio/dio.dart';

import 'package:client/src/core/network/api_client.dart';
import 'package:client/src/features/admin/data/admin_models.dart';

class AdminRepository {
  final ApiClient _apiClient;

  const AdminRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  Future<AdminDashboardStats> loadDashboard() async {
    try {
      final response = await _apiClient.dio.get('/admin/dashboard');
      final data = _readDataMap(response.data);

      return AdminDashboardStats.fromJson(data);
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }

  Future<List<AdminUser>> loadUsers() async {
    try {
      final response = await _apiClient.dio.get('/admin/users');

      return _readDataList(response.data).map(AdminUser.fromJson).toList();
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }

  Future<List<AdminRole>> loadRoles() async {
    try {
      final response = await _apiClient.dio.get('/admin/roles');

      return _readDataList(response.data).map(AdminRole.fromJson).toList();
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }

  Future<List<AdminAuditLog>> loadAuditLogs({
    int limit = 100,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/admin/audit-logs',
        queryParameters: {
          'limit': limit,
        },
      );

      return _readDataList(response.data).map(AdminAuditLog.fromJson).toList();
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }

  Future<List<AdminBackupFile>> loadBackups() async {
    try {
      final response = await _apiClient.dio.get('/admin/backups');

      return _readDataList(response.data).map(AdminBackupFile.fromJson).toList();
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }

  Future<void> createBackup({
    String? backupName,
  }) async {
    try {
      await _apiClient.dio.post(
        '/admin/backups',
        data: {
          'backupName': backupName,
        },
      );
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }

  Future<void> restoreBackup({
    required String fileName,
  }) async {
    try {
      await _apiClient.dio.post(
        '/admin/backups/${Uri.encodeComponent(fileName)}/restore',
      );
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }


  Future<List<AdminTemplate>> loadTemplates() async {
    try {
      final response = await _apiClient.dio.get('/admin/templates');

      return _readDataList(response.data).map(AdminTemplate.fromJson).toList();
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }

  Future<void> createTemplate({
    required String templateName,
    required String chartType,
    required String colorScheme,
    required String? description,
    required bool isActive,
  }) async {
    try {
      await _apiClient.dio.post(
        '/admin/templates',
        data: {
          'templateName': templateName,
          'chartType': chartType,
          'colorScheme': colorScheme,
          'description': description,
          'isActive': isActive,
        },
      );
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }

  Future<void> updateTemplate({
    required int id,
    required String templateName,
    required String chartType,
    required String colorScheme,
    required String? description,
    required bool isActive,
  }) async {
    try {
      await _apiClient.dio.put(
        '/admin/templates/$id',
        data: {
          'templateName': templateName,
          'chartType': chartType,
          'colorScheme': colorScheme,
          'description': description,
          'isActive': isActive,
        },
      );
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }

  Future<void> deleteTemplate({
    required int id,
  }) async {
    try {
      await _apiClient.dio.delete('/admin/templates/$id');
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }

  Future<void> changeUserRole({
    required int accountId,
    required int roleId,
  }) async {
    try {
      await _apiClient.dio.put(
        '/admin/users/$accountId/role',
        data: {
          'roleId': roleId,
        },
      );
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }

  Future<void> changeBlockStatus({
    required int accountId,
    required bool isBlocked,
  }) async {
    try {
      await _apiClient.dio.put(
        '/admin/users/$accountId/block',
        data: {
          'isBlocked': isBlocked,
        },
      );
    } on DioException catch (error) {
      throw AdminException(_readErrorMessage(error));
    } catch (error) {
      throw AdminException(error.toString());
    }
  }

  Map<String, dynamic> _readDataMap(dynamic responseData) {
    final responseMap = _asMap(responseData);
    final data = responseMap['data'];

    return _asMap(data);
  }

  List<Map<String, dynamic>> _readDataList(dynamic responseData) {
    final responseMap = _asMap(responseData);
    final data = responseMap['data'];

    if (data is List) {
      return data.whereType<Map>().map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
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
      final message = data['message'].toString();
      final details = data['error']?.toString();

      if (details != null && details.trim().isNotEmpty) {
        return '$message: $details';
      }

      return message;
    }

    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!;
    }

    return 'Ошибка выполнения административной операции';
  }
}

class AdminException implements Exception {
  final String message;

  const AdminException(this.message);

  @override
  String toString() => message;
}
