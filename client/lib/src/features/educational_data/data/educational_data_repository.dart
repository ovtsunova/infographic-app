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

      return EducationalDataBundle(
        groups: groups,
        disciplines: disciplines,
        periods: periods,
        students: students,
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

    return 'Ошибка загрузки учебных данных';
  }
}

class EducationalDataException implements Exception {
  final String message;

  EducationalDataException(this.message);

  @override
  String toString() => message;
}