import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class AuthService {
  final Dio _dio;

  AuthService({Dio? dio}) : _dio = dio ?? Dio() {
    // Print base URL at runtime so we can confirm which endpoint is used
    print('Api baseUrl: ${ApiConstants.baseUrl}');

    // Add Dio logging interceptor to print requests/responses
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  // Helper method to get auth headers
  Options _getAuthOptions(String? token) {
    if (token == null) {
      return Options();
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? location,
    String? profilePicture,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.register}',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          if (phone != null) 'phone': phone,
          if (location != null) 'location': location,
          if (profilePicture != null) 'profilePicture': profilePicture,
        },
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Registration failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Registration failed');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.login}',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // Fetch Menus
  // When token is present, calls /menus/me to get permission-filtered menus for the current user.
  // When no token, calls /menus (all menus, e.g. for public).
  Future<List<Map<String, dynamic>>> fetchMenus({String? token, String? parentId}) async {
    try {
      final String url = token != null
          ? '${ApiConstants.baseUrl}${ApiConstants.menusMe}'
          : '${ApiConstants.baseUrl}${ApiConstants.menus}';
      final queryParams = <String, dynamic>{};
      if (parentId != null) {
        queryParams['parentId'] = parentId;
      }

      final response = await _dio.get(
        url,
        queryParameters: queryParams.isEmpty ? null : queryParams,
        options: token != null ? _getAuthOptions(token) : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> menus = response.data['menus'] ?? [];
        return menus.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
