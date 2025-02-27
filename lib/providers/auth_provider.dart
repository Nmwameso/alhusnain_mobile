import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart'; // ✅ Import ApiService

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiService _apiService = ApiService(); // ✅ Use ApiService

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  AuthProvider() {
    _loadUserFromPrefs();
  }

  /// ✅ Login with Google & Send Data to API
  Future<bool> loginWithGoogle(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false; // User canceled login
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        _currentUser = UserModel.fromFirebaseUser(user);
        notifyListeners();

        final response = await _sendUserDataToApi(user);
        _isLoading = false;
        notifyListeners();

        if (response) {
          await _saveUserToPrefs(_currentUser!); // ✅ Save user data locally
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login successful! Welcome, ${user.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return response;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print("Google Sign-In Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  /// ✅ Send User Data to API & Save Token
  Future<bool> _sendUserDataToApi(User user) async {
    final String apiUrl = '${_apiService.baseUrl}/login/google'; // ✅ Use ApiService baseUrl

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': user.displayName,
          'email': user.email,
          'photo_url': user.photoURL,
          'google_uid': user.uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('api_token', data['token']);
        // ✅ Set `isLoggedIn` to true
        await prefs.setBool('isLoggedIn', true);
        return true;
      } else {
        print("Failed to store user data: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error sending data to API: $e");
      return false;
    }
  }

  /// ✅ Save User Data to SharedPreferences
  Future<void> _saveUserToPrefs(UserModel user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    notifyListeners();
  }

  /// ✅ Load User Data from SharedPreferences
  Future<void> _loadUserFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user_data');

    if (userData != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userData));
      notifyListeners();
    }
  }

  /// ✅ Logout User & Clear Data
  Future<void> logout(BuildContext context) async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // ✅ Clear all stored user data

    _currentUser = null;
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged out successfully.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// ✅ Save user searches in SharedPreferences
  Future<void> saveUserSearch(String searchTerm) async {
    if (searchTerm.isEmpty) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> searchHistory = prefs.getStringList('search_history') ?? [];

    // Prevent duplicates and limit to last 10 searches
    searchHistory.remove(searchTerm);
    searchHistory.insert(0, searchTerm);
    if (searchHistory.length > 10) {
      searchHistory = searchHistory.sublist(0, 10); // Keep only the last 10 searches
    }

    await prefs.setStringList('search_history', searchHistory);
  }

  /// ✅ Retrieve stored search history
  Future<List<String>> getUserSearchHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('search_history') ?? [];
  }

}
