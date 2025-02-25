import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_data.dart';
import '../models/vehicle.dart';
import '../models/vehicle_details.dart';

class ApiService {
  final String baseUrl = 'https://alhusnainmotors.co.ke/api/customer';

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
}
