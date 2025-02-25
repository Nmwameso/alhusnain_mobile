import 'package:flutter/foundation.dart';
import '../models/home_data.dart';
import '../services/api_service.dart';

class HomeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  HomeData? _homeData;
  bool _isLoading = false;
  String? _error;

  HomeData? get homeData => _homeData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchHomeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _homeData = await _apiService.fetchHomeData();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _homeData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}