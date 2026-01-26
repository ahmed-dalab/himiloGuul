import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class ContactService {
  final Dio _dio;

  ContactService({Dio? dio}) : _dio = dio ?? Dio();

  // Helper method to get auth headers
  Options _getAuthOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // POST /api/contacts - Create contact (buyers can create)
  Future<Map<String, dynamic>> createContact(
    String token, {
    required String sellerRef,
    required String businessRef,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.contacts}',
        data: {
          'sellerRef': sellerRef,
          'businessRef': businessRef,
          'message': message,
        },
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to create contact: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to create contact');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error creating contact: $e');
    }
  }

  // GET /api/contacts/my - Get my contacts (buyer or seller can view their contacts)
  Future<Map<String, dynamic>> getMyContacts(
    String token, {
    int? page,
    int? limit,
    String? status,
    String? role, // 'buyer' or 'seller'
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (status != null) queryParams['status'] = status;
      if (role != null) queryParams['role'] = role;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.contacts}/my',
        queryParameters: queryParams,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get contacts: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get contacts');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting contacts: $e');
    }
  }

  // GET /api/contacts/:id - Get contact details by ID
  Future<Map<String, dynamic>> getContactById(String token, String id) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.contacts}/$id',
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get contact: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get contact');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting contact: $e');
    }
  }

  // PUT /api/contacts/:id - Update contact (buyer or seller can update)
  Future<Map<String, dynamic>> updateContact(
    String token,
    String id, {
    String? message,
    String? status, // 'pending', 'responded', or 'closed'
  }) async {
    try {
      final data = <String, dynamic>{};
      if (message != null) data['message'] = message;
      if (status != null) data['status'] = status;

      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.contacts}/$id',
        data: data,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update contact: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update contact');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating contact: $e');
    }
  }

  // DELETE /api/contacts/:id - Delete contact (buyer or seller can delete)
  Future<void> deleteContact(String token, String id) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.contacts}/$id',
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
