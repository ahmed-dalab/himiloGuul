import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class MenuService {
  final Dio _dio;

  MenuService({Dio? dio}) : _dio = dio ?? Dio();

  // Helper method to get auth headers
  Options _getAuthOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // GET /api/menus - Get all menus (with optional parentId query)
  Future<Map<String, dynamic>> getAllMenus({String? parentId, String? token}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (parentId != null) {
        queryParams['parentId'] = parentId;
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.menus}',
        queryParameters: queryParams,
        options: token != null ? _getAuthOptions(token) : null,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get menus: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get menus');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting menus: $e');
    }
  }

  // GET /api/menus/:id - Get menu by ID
  Future<Map<String, dynamic>> getMenuById(String id, {String? token}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.menus}/$id',
        options: token != null ? _getAuthOptions(token) : null,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get menu: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get menu');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting menu: $e');
    }
  }

  // POST /api/menus - Create a new menu (admin only)
  Future<Map<String, dynamic>> createMenu(
    String token, {
    required String name,
    required String path,
    String? parentId,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'path': path,
      };
      if (parentId != null) {
        data['parentId'] = parentId;
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.menus}',
        data: data,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to create menu: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to create menu');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error creating menu: $e');
    }
  }

  // PUT /api/menus/:id - Update menu
  Future<Map<String, dynamic>> updateMenu(
    String token,
    String id, {
    String? name,
    String? path,
    String? parentId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (path != null) data['path'] = path;
      if (parentId != null) {
        data['parentId'] = parentId;
      } else if (parentId == null && data.containsKey('parentId')) {
        data['parentId'] = null;
      }

      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.menus}/$id',
        data: data,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update menu: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update menu');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating menu: $e');
    }
  }

  // DELETE /api/menus/:id - Delete menu
  Future<void> deleteMenu(String token, String id) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.menus}/$id',
        options: _getAuthOptions(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete menu: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete menu');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting menu: $e');
    }
  }
}
