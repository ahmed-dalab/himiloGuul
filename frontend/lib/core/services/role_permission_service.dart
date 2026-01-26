import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class RolePermissionService {
  final Dio _dio;

  RolePermissionService({Dio? dio}) : _dio = dio ?? Dio();

  // Helper method to get auth headers
  Options _getAuthOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // POST /api/role-permissions - Create role-permission assignment (admin only)
  Future<Map<String, dynamic>> createRolePermission(
    String token, {
    required String roleId,
    required String permissionId,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.rolePermissions}',
        data: {
          'roleId': roleId,
          'permissionId': permissionId,
        },
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to create role-permission: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to create role-permission');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error creating role-permission: $e');
    }
  }

  // GET /api/role-permissions - Get all role-permission assignments (admin only)
  Future<Map<String, dynamic>> getAllRolePermissions(
    String token, {
    String? roleId,
    String? permissionId,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (roleId != null) queryParams['roleId'] = roleId;
      if (permissionId != null) queryParams['permissionId'] = permissionId;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.rolePermissions}',
        queryParameters: queryParams,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get role-permissions: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get role-permissions');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting role-permissions: $e');
    }
  }

  // GET /api/role-permissions/:id - Get role-permission by ID (admin only)
  Future<Map<String, dynamic>> getRolePermissionById(String token, String id) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.rolePermissions}/$id',
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get role-permission: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get role-permission');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting role-permission: $e');
    }
  }

  // GET /api/role-permissions/role/:roleId - Get permissions for a specific role (admin only)
  Future<Map<String, dynamic>> getPermissionsByRole(String token, String roleId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.rolePermissions}/role/$roleId',
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get permissions for role: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get permissions for role');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting permissions for role: $e');
    }
  }

  // GET /api/role-permissions/permission/:permissionId - Get roles for a specific permission (admin only)
  Future<Map<String, dynamic>> getRolesByPermission(String token, String permissionId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.rolePermissions}/permission/$permissionId',
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get roles for permission: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get roles for permission');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting roles for permission: $e');
    }
  }

  // PUT /api/role-permissions/:id - Update role-permission assignment (admin only)
  Future<Map<String, dynamic>> updateRolePermission(
    String token,
    String id, {
    String? roleId,
    String? permissionId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (roleId != null) data['roleId'] = roleId;
      if (permissionId != null) data['permissionId'] = permissionId;

      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.rolePermissions}/$id',
        data: data,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update role-permission: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update role-permission');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating role-permission: $e');
    }
  }

  // DELETE /api/role-permissions/:id - Delete role-permission assignment (admin only)
  Future<void> deleteRolePermission(String token, String id) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.rolePermissions}/$id',
        options: _getAuthOptions(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete role-permission: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete role-permission');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting role-permission: $e');
    }
  }

  // DELETE /api/role-permissions/role/:roleId/permission/:permissionId - Delete by role and permission (admin only)
  Future<void> deleteRolePermissionByRoleAndPermission(
    String token,
    String roleId,
    String permissionId,
  ) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.rolePermissions}/role/$roleId/permission/$permissionId',
        options: _getAuthOptions(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete role-permission: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete role-permission');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting role-permission: $e');
    }
  }
}
