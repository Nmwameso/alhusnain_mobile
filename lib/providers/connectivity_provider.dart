import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool get isOffline => _isOffline;

  ConnectivityProvider() {
    _init();
  }

  void _init() async {
    await _checkConnectivity(); // Check internet on app start
    _listenToConnectivityChanges(); // Listen for network changes
  }

  Future<void> _checkConnectivity() async {
    List<ConnectivityResult> connectivity = await Connectivity().checkConnectivity();
    _isOffline = connectivity.isNotEmpty && connectivity.first == ConnectivityResult.none;
    notifyListeners();
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      bool hasInternet = results.isNotEmpty && results.first != ConnectivityResult.none;
      _isOffline = !hasInternet;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
