import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class AdminService {
  final Dio _dio;

  AdminService({Dio? dio}) : _dio = dio ?? Dio();

  // Helper method to get auth headers
  Options _getAuthOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // Dashboard (admin only)
  Future<Map<String, dynamic>> getDashboard(String token) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.adminDashboard}',
        options: _getAuthOptions(token),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load dashboard: ${response.statusMessage}');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to load dashboard');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Recent activity (admin only)
  Future<Map<String, dynamic>> getRecentActivity(String token, {int? limit}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.adminActivities}',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: _getAuthOptions(token),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load activity: ${response.statusMessage}');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to load activity');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Business Management

  // GET /api/admin/businesses - List all businesses (admin only)
  Future<Map<String, dynamic>> listAllBusinesses(
    String token, {
    int? page,
    int? limit,
    String? status,
    String? category,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.adminBusinesses}',
        queryParameters: queryParams,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to list businesses: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to list businesses');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error listing businesses: $e');
    }
  }

  // GET /api/admin/businesses/pending - List pending businesses (admin only)
  Future<Map<String, dynamic>> listPendingBusinesses(
    String token, {
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.adminPendingBusinesses}',
        queryParameters: queryParams,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to list pending businesses: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to list pending businesses');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error listing pending businesses: $e');
    }
  }

  // PUT /api/admin/businesses/:id/approve - Approve business (admin only)
  Future<Map<String, dynamic>> approveBusiness(String token, String id) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.adminBusinesses}/$id/approve',
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to approve business: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to approve business');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error approving business: $e');
    }
  }

  // PUT /api/admin/businesses/:id/reject - Reject business (admin only)
  Future<Map<String, dynamic>> rejectBusiness(String token, String id) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.adminBusinesses}/$id/reject',
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to reject business: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to reject business');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error rejecting business: $e');
    }
  }

  // User Management

  // GET /api/admin/users - List all users (admin only)
  Future<Map<String, dynamic>> listAllUsers(
    String token, {
    int? page,
    int? limit,
    String? roleId,
    bool? isBanned,
    String? sortBy,
    String? sortOrder,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (roleId != null) queryParams['roleId'] = roleId;
      if (isBanned != null) queryParams['isBanned'] = isBanned;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
      if (search != null) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.adminUsers}',
        queryParameters: queryParams,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to list users: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to list users');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error listing users: $e');
    }
  }

  // PUT /api/admin/users/:id/ban - Ban/unban user (admin only)
  Future<Map<String, dynamic>> banUnbanUser(
    String token,
    String id, {
    required bool isBanned,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.adminUsers}/$id/ban',
        data: {'isBanned': isBanned},
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to ban/unban user: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to ban/unban user');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error banning/unbanning user: $e');
    }
  }

  // DELETE /api/admin/users/:id - Delete user (admin only)
  Future<void> deleteUser(String token, String id) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.adminUsers}/$id',
        options: _getAuthOptions(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete user');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Contact Management

  // GET /api/admin/contacts - List all contacts (admin only)
  Future<Map<String, dynamic>> listAllContacts(
    String token, {
    int? page,
    int? limit,
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (status != null) queryParams['status'] = status;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.adminContacts}',
        queryParameters: queryParams,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to list contacts: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to list contacts');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error listing contacts: $e');
    }
  }

  // DELETE /api/admin/contacts/:id - Delete contact (admin only)
  Future<void> deleteContact(String token, String id) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.adminContacts}/$id',
        options: _getAuthOptions(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete contact: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete contact');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting contact: $e');
    }
  }
}
