import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_data.dart';
import 'package:provider/provider.dart';
import 'package:ah_customer/providers/auth_provider.dart';
import '../models/vehicle_details.dart';

class ApiService {
  final String baseUrl = 'https://1f62-197-232-248-100.ngrok-free.app/api/customer';

  /// Fetch Home Data from API
  Future<HomeData> fetchHomeData() async {
    final response = await http.get(Uri.parse('$baseUrl/home'));

    if (response.statusCode == 200) {
      return HomeData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load home data');
    }
  }

  /// Check if the user exists in the database
  Future<bool> checkUserExists() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('api_token');

    if (token == null || token.isEmpty) {
      return false; // User is not authenticated
    }

    final response = await http.get(
      Uri.parse('$baseUrl/customer/check'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // ✅ Print full API response for debugging
      return data['exists']; // API should return { "exists": true/false }
    } else {
      return false; // User does not exist or invalid token
    }
  }

  Future<VehicleDetails> fetchVehicleDetails(String vehicleId) async {
    final response = await http.get(Uri.parse('$baseUrl/vehicle/$vehicleId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return VehicleDetails.fromJson(data);
    } else {
      throw Exception('Failed to load vehicle details');
    }
  }

  /// **Submit Upcoming Car Notification Request**
  Future<bool> submitUpcomingCarNotification({
    required String vehicleId,
    required String fullName,
    required String email,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('api_token');

    if (token == null || token.isEmpty) {
      throw Exception('User is not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/notify-upcoming-car'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'vehicle_id': vehicleId,
        'full_name': fullName,
        'email_address': email,

      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Failed to register for notifications');
    }
  }

  /// ❌ Remove upcoming car notification (if backend supports it)
  Future<bool> removeUpcomingCarNotification(String vehicleId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('api_token');

    if (token == null || token.isEmpty) {
      throw Exception('User is not authenticated');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/notify-upcoming-car/$vehicleId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to remove notification');
    }
  }

  /// **Submit Direct Import Request**
  Future<bool> submitDirectImport({
    required String fullName,
    required String phoneNumber,
    String? emailAddress,
    required String make,
    required String model,
    required String carFeatures,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('api_token');

    if (token == null || token.isEmpty) {
      throw Exception('User is not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/direct-import'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'full_name': fullName,
        'phone_number': phoneNumber,
        'email_address': emailAddress,
        'make': make,
        'model': model,
        'car_features': carFeatures,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Failed to submit direct import request');
    }
  }

  /// Fetches direct import requests for the authenticated user
  Future<List<Map<String, dynamic>>> fetchDirectImportRequests() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('api_token');

    if (token == null || token.isEmpty) {
      throw Exception('User is not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/direct-imports'), // ✅ Use `baseUrl`
      headers: {
        'Authorization': 'Bearer $token', // ✅ Pass authentication token
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['direct_import_requests']);
    } else {
      throw Exception('Failed to fetch direct import requests: ${response.body}');
    }
  }


}
