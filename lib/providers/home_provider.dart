import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/home_data.dart';
import '../services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  HomeData? _homeData;
  bool _isLoading = false;
  String? _error;
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  HomeProvider() {
    _init();
  }

  HomeData? get homeData => _homeData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;

  void _init() {
    _checkConnectivity();
    _listenToConnectivityChanges();
  }

  Future<void> _checkConnectivity() async {
    List<ConnectivityResult> connectivity = await Connectivity().checkConnectivity();
    _isOffline = connectivity.isNotEmpty && connectivity.first == ConnectivityResult.none;
    notifyListeners();
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      bool hasInternet = results.isNotEmpty && results.first != ConnectivityResult.none;

      if (_isOffline && hasInternet) {
        // Internet restored, fetch data automatically
        fetchHomeData();
      }

      _isOffline = !hasInternet;
      notifyListeners();
    });
  }

  Future<void> fetchHomeData() async {
    if (_isOffline) {
      _error = "No internet connection. Please check your network and try again.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _homeData = await _apiService.fetchHomeData();
    } catch (e) {
      _error = e.toString();
      _homeData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
