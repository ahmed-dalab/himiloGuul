import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/business.dart';

class BusinessService {
  final Dio _dio;

  BusinessService({Dio? dio}) : _dio = dio ?? Dio();

  // Helper method to get auth headers
  Options _getAuthOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // GET /api/business - Browse businesses (public endpoint)
  Future<Map<String, dynamic>> browseBusinesses({
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? search,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (location != null) queryParams['location'] = location;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (search != null) queryParams['search'] = search;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.businesses}',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load businesses: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to load businesses');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching businesses: $e');
    }
  }

  // GET /api/business/my - Get my businesses (seller/owner only)
  Future<Map<String, dynamic>> getMyBusinesses(
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
        '${ApiConstants.baseUrl}${ApiConstants.myBusinesses}',
        queryParameters: queryParams,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load my businesses: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to load my businesses');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching my businesses: $e');
    }
  }

  // GET /api/business/:id - Get business by ID
  Future<Map<String, dynamic>> getBusinessById(String id, {String? token}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.businesses}/$id',
        options: token != null ? _getAuthOptions(token) : null,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load business details: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to load business details');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching business details: $e');
    }
  }

  // POST /api/business - Create business (sellers/owners can create)
  Future<Map<String, dynamic>> createBusiness(
    String token, {
    required String name,
    required String address,
    required String phone,
    required String email,
    String? website,
    String? description,
    String? category,
    double? askingPrice,
    String? location,
    List<String>? imagePaths, // For file uploads, you'll need to use FormData
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
      };
      if (website != null) data['website'] = website;
      if (description != null) data['description'] = description;
      if (category != null) data['category'] = category;
      if (askingPrice != null) data['askingPrice'] = askingPrice;
      if (location != null) data['location'] = location;

      // Note: For file uploads, you'll need to use FormData with multipart/form-data
      // This is a simplified version. For actual file uploads, use:
      // FormData formData = FormData.fromMap({...});
      // formData.files.addAll([...]);

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.businesses}',
        data: data,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to create business: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to create business');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error creating business: $e');
    }
  }

  // PUT /api/business/:id - Update business (only business owner or admin can access)
  Future<Map<String, dynamic>> updateBusiness(
    String token,
    String id, {
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? description,
    String? category,
    double? askingPrice,
    String? location,
    List<String>? imagePaths, // For file uploads
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (address != null) data['address'] = address;
      if (phone != null) data['phone'] = phone;
      if (email != null) data['email'] = email;
      if (website != null) data['website'] = website;
      if (description != null) data['description'] = description;
      if (category != null) data['category'] = category;
      if (askingPrice != null) data['askingPrice'] = askingPrice;
      if (location != null) data['location'] = location;

      // Note: For file uploads, use FormData with multipart/form-data

      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.businesses}/$id',
        data: data,
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update business: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update business');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating business: $e');
    }
  }

  // DELETE /api/business/:id - Delete business (only admin and the business owner can access)
  Future<void> deleteBusiness(String token, String id) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.businesses}/$id',
        options: _getAuthOptions(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete business: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete business');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting business: $e');
    }
  }

  // PUT /api/business/:id/approve - Approve business (admin only)
  Future<Map<String, dynamic>> approveBusiness(String token, String id) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.businesses}/$id/approve',
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

  // PUT /api/business/:id/sold - Mark business as sold (owner or admin)
  Future<Map<String, dynamic>> markBusinessAsSold(
    String token,
    String id, {
    required bool isSold,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.businesses}/$id/sold',
        data: {'isSold': isSold},
        options: _getAuthOptions(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to mark business as sold: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to mark business as sold');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error marking business as sold: $e');
    }
  }

  // Legacy method for backward compatibility
  Future<List<Business>> getBusinesses({String? category, String? search}) async {
    try {
      final result = await browseBusinesses(category: category, search: search);
      final List<dynamic> data = result['data'] ?? [];
      return data.map((json) => Business.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching businesses: $e');
    }
  }
}
