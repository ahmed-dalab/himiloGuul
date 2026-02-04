import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class SettingService {
  final Dio _dio;

  SettingService({Dio? dio}) : _dio = dio ?? Dio();

  Options _getAuthOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// GET /api/settings - Get app settings
  Future<Map<String, dynamic>> getSettings(String token) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.settings}',
        options: _getAuthOptions(token),
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to get settings: ${response.statusMessage}');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to get settings',
        );
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// PUT /api/settings - Update app settings (appName, contactEmail, timezone)
  Future<Map<String, dynamic>> updateSettings(
    String token, {
    String? appName,
    String? contactEmail,
    String? timezone,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (appName != null) data['appName'] = appName;
      if (contactEmail != null) data['contactEmail'] = contactEmail;
      if (timezone != null) data['timezone'] = timezone;

      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.settings}',
        data: data,
        options: _getAuthOptions(token),
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to update settings: ${response.statusMessage}');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to update settings',
        );
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}
