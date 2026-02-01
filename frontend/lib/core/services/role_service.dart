import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class RoleService {
  final Dio _dio;

  RoleService({Dio? dio}) : _dio = dio ?? Dio();

  // Helper method to get auth headers
  Options _getAuthOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // POST /api/roles - Create role (admin only)
  Future<Map<String, dynamic>> createRole(
    String token, {
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.roles}',
        data: {'name': name},
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to create role: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final msg = data is Map ? (data['message'] ?? data['error'] ?? 'Failed to create role') : 'Failed to create role';
        throw Exception(msg is String ? msg : 'Failed to create role');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error creating role: $e');
    }
  }

  // GET /api/roles - Get all roles (admin only)
  Future<Map<String, dynamic>> getAllRoles(String token) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.roles}',
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get roles: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final msg = data is Map ? (data['message'] ?? data['error'] ?? 'Failed to get roles') : 'Failed to get roles';
        throw Exception(msg is String ? msg : 'Failed to get roles');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting roles: $e');
    }
  }

  // GET /api/roles/:id - Get role by ID (admin only)
  Future<Map<String, dynamic>> getRoleById(String token, String id) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.roles}/$id',
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get role: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final msg = data is Map ? (data['message'] ?? data['error'] ?? 'Failed to get role') : 'Failed to get role';
        throw Exception(msg is String ? msg : 'Failed to get role');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting role: $e');
    }
  }

  // PUT /api/roles/:id - Update role (admin only)
  Future<Map<String, dynamic>> updateRole(
    String token,
    String id, {
    required String name,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.roles}/$id',
        data: {'name': name},
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update role: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final msg = data is Map ? (data['message'] ?? data['error'] ?? 'Failed to update role') : 'Failed to update role';
        throw Exception(msg is String ? msg : 'Failed to update role');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating role: $e');
    }
  }

  // DELETE /api/roles/:id - Delete role (admin only)
  Future<void> deleteRole(String token, String id) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.roles}/$id',
        options: _getAuthOptions(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete role: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final msg = data is Map ? (data['message'] ?? data['error'] ?? 'Failed to delete role') : 'Failed to delete role';
        throw Exception(msg is String ? msg : 'Failed to delete role');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting role: $e');
    }
  }
}
