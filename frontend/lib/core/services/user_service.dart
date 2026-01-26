import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class UserService {
  final Dio _dio;

  UserService({Dio? dio}) : _dio = dio ?? Dio();

  // Helper method to get auth headers
  Options _getAuthOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // GET /api/users/profile - Get current user profile
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.userProfile}',
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get user profile: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get user profile');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting user profile: $e');
    }
  }

  // PUT /api/users/profile - Update own profile
  Future<Map<String, dynamic>> updateUserProfile(
    String token, {
    String? name,
    String? phone,
    String? location,
    String? profilePicture,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (location != null) data['location'] = location;
      if (profilePicture != null) data['profilePicture'] = profilePicture;

      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.userProfile}',
        data: data,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update profile: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update profile');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // GET /api/users/:id - Get user public info
  Future<Map<String, dynamic>> getUserById(String id, {String? token}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.users}/$id',
        options: token != null ? _getAuthOptions(token) : null,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get user: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get user');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  // PUT /api/users/:id - Update user (self or admin)
  Future<Map<String, dynamic>> updateUser(
    String token,
    String id, {
    String? name,
    String? email,
    String? role,
    String? phone,
    String? location,
    String? profilePicture,
    bool? isBanned,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (role != null) data['role'] = role;
      if (phone != null) data['phone'] = phone;
      if (location != null) data['location'] = location;
      if (profilePicture != null) data['profilePicture'] = profilePicture;
      if (isBanned != null) data['isBanned'] = isBanned;

      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.users}/$id',
        data: data,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update user: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update user');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // DELETE /api/users/:id - Delete user (admin and the user himself can access)
  Future<void> deleteUser(String token, String id) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.users}/$id',
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

  // GET /api/users - Get all users (only admin can access)
  Future<Map<String, dynamic>> getAllUsers(
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
        '${ApiConstants.baseUrl}${ApiConstants.users}',
        queryParameters: queryParams,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get users: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get users');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting users: $e');
    }
  }
}
