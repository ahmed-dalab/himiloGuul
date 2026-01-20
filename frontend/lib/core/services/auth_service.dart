import 'package:dio/dio.dart';
import '../constants/api_constants.dart';


class AuthService {
  final Dio _dio;

  AuthService({Dio? dio}) : _dio = dio ?? Dio();

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/login',
        data: {
          'email': email,
          'password': password,
        },
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
  Future<List<String>> fetchMenus(String token) async {
    try {
      // Assuming GET /api/menus returns list of menu objects with 'name' property
      // If endpoint doesn't exist or fails, we fallback in provider, but here we try request.
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/menus',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((item) => item['name'] as String).toList();
      }
      return [];
    } catch (e) {
      // Return empty list to trigger fallback
      return [];
    }
  }
}
