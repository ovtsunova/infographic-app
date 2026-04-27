import 'package:dio/dio.dart';

import 'package:client/src/core/network/api_client.dart';
import 'package:client/src/features/saved_infographics/data/saved_infographics_models.dart';

class SavedInfographicsRepository {
  final ApiClient _apiClient;

  SavedInfographicsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  Future<List<SavedInfographic>> loadMyInfographics() async {
    try {
      final response = await _apiClient.dio.get('/infographics/my');

      return _readDataList(response.data)
          .map(SavedInfographic.fromJson)
          .toList();
    } on DioException catch (error) {
      throw SavedInfographicsException(_readErrorMessage(error));
    } catch (error) {
      throw SavedInfographicsException(error.toString());
    }
  }

  Future<void> saveInfographic({
    required String title,
    required String chartType,
    required Map<String, dynamic> parameters,
    required Map<String, dynamic> resultData,
    int? templateId,
  }) async {
    try {
      await _apiClient.dio.post(
        '/infographics',
        data: {
          'title': title.trim(),
          'chartType': chartType,
          'templateId': templateId,
          'parameters': parameters,
          'resultData': resultData,
        },
      );
    } on DioException catch (error) {
      throw SavedInfographicsException(_readErrorMessage(error));
    } catch (error) {
      throw SavedInfographicsException(error.toString());
    }
  }

  Future<void> deleteInfographic({
    required int id,
  }) async {
    try {
      await _apiClient.dio.delete('/infographics/$id');
    } on DioException catch (error) {
      throw SavedInfographicsException(_readErrorMessage(error));
    } catch (error) {
      throw SavedInfographicsException(error.toString());
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

    return 'Ошибка выполнения операции с инфографикой';
  }
}

class SavedInfographicsException implements Exception {
  final String message;

  const SavedInfographicsException(this.message);

  @override
  String toString() => message;
}