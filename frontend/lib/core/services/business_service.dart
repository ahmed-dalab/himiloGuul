import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/business.dart';

class BusinessService {
  final Dio _dio;

  BusinessService({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<Business>> getBusinesses({String? category, String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.businesses}',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Business.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load businesses');
      }
    } catch (e) {
      throw Exception('Error fetching businesses: $e');
    }
  }

  Future<Business> getBusinessById(String id) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.businesses}/$id',
      );

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        // Check if wrapped in data object or direct
        final businessData = (data is Map<String, dynamic> && data.containsKey('data')) 
            ? data['data'] 
            : data;
            
        return Business.fromJson(businessData);
      } else {
        throw Exception('Failed to load business details');
      }
    } catch (e) {
      throw Exception('Error fetching business details: $e');
    }
  }
}
