import 'package:flutter/foundation.dart';
import '../../core/models/business.dart';
import '../../core/services/business_service.dart';

class BusinessProvider with ChangeNotifier {
  final BusinessService _businessService;
  
  List<Business> _businesses = [];
  bool _isLoading = false;
  String? _error;

  Business? _selectedBusiness;

  BusinessProvider({BusinessService? businessService})
      : _businessService = businessService ?? BusinessService();

  List<Business> get businesses => _businesses;
  Business? get selectedBusiness => _selectedBusiness;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBusinesses({String? category, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _businesses = await _businessService.getBusinesses(
        category: category,
        search: search,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBusinessById(String id, {String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _businessService.getBusinessById(id, token: token);
      // Extract business data from response
      final businessData = response['data'] ?? response;
      _selectedBusiness = Business.fromJson(businessData);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedBusiness() {
    _selectedBusiness = null;
    _error = null;
    notifyListeners();
  }
}
