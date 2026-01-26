import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class PermissionService {
  final Dio _dio;

  PermissionService({Dio? dio}) : _dio = dio ?? Dio();

  // Helper method to get auth headers
  Options _getAuthOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // POST /api/permissions - Create permission (admin only)
  Future<Map<String, dynamic>> createPermission(
    String token, {
    required String name,
    required String menuId,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.permissions}',
        data: {
          'name': name,
          'menuId': menuId,
        },
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to create permission: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to create permission');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error creating permission: $e');
    }
  }

  // GET /api/permissions - Get all permissions (admin only)
  Future<Map<String, dynamic>> getAllPermissions(
    String token, {
    String? menuId,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (menuId != null) queryParams['menuId'] = menuId;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.permissions}',
        queryParameters: queryParams,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get permissions: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get permissions');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting permissions: $e');
    }
  }

  // GET /api/permissions/:id - Get permission by ID (admin only)
  Future<Map<String, dynamic>> getPermissionById(String token, String id) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.permissions}/$id',
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get permission: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get permission');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting permission: $e');
    }
  }

  // PUT /api/permissions/:id - Update permission (admin only)
  Future<Map<String, dynamic>> updatePermission(
    String token,
    String id, {
    String? name,
    String? menuId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (menuId != null) data['menuId'] = menuId;

      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.permissions}/$id',
        data: data,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update permission: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update permission');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating permission: $e');
    }
  }

  // DELETE /api/permissions/:id - Delete permission (admin only)
  Future<void> deletePermission(String token, String id) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.permissions}/$id',
        options: _getAuthOptions(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete permission: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete permission');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting permission: $e');
    }
  }
}
