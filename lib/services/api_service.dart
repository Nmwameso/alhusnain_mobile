import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_data.dart';
import 'package:provider/provider.dart';
import 'package:ah_customer/providers/auth_provider.dart';
import '../models/vehicle_details.dart';
import 'package:url_launcher/url_launcher_string.dart';
class ApiService {
  final String baseUrl = 'https://9db2-197-232-248-100.ngrok-free.app/api/customer';

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
  /// /// **Log Car Selection Activity**
    Future<bool> logCarSelectionActivity({
      required AuthProvider authProvider,
      required String selectedDrivingCategory,
      required String selectedMake,
      required String selectedBodyType,
      required String selectedFuel,
      required double engineMin,
      required double engineMax,
    }) async {
      final user = authProvider.currentUser;
      final url = Uri.parse('$baseUrl/car-selection');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('api_token');

      if (token == null || token.isEmpty) {
        throw Exception('User is not authenticated');
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "email": user?.email, // Replace with actual user ID
          "selected_driving_category": selectedDrivingCategory,
          "selected_make": selectedMake,
          "selected_body_type": selectedBodyType,
          "selected_fuel": selectedFuel,
          "engine_range": {
            "min": engineMin.round(),
            "max": engineMax.round(),
          },
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print("Car selection activity logged successfully");
        return true;
      } else {
        print("Failed to log car selection activity: ${response.body}");
        return false;
      }
    }
  /// **Submit Direct Import Request and Share via WhatsApp**
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
      // ✅ Send WhatsApp message after successful submission
      _sendToWhatsApp(
        fullName: fullName,
        phoneNumber: phoneNumber,
        emailAddress: emailAddress,
        make: make,
        model: model,
        carFeatures: carFeatures,
      );
      return true;
    } else {
      throw Exception('Failed to submit direct import request');
    }
  }
  /// ✅ **Send Direct Import Request Details to WhatsApp**
  void _sendToWhatsApp({
    required String fullName,
    required String phoneNumber,
    String? emailAddress,
    required String make,
    required String model,
    required String carFeatures,
  }) async {
    int hour = DateTime.now().hour;
    String greeting = (hour < 12) ? "Good morning" : (hour < 18) ? "Good afternoon" : "Good evening";

    final String message = '''
    📢 *$greeting! I have submitted a direct import request.* 🚗  
    Here are the details:  

  👤 *Full Name:* $fullName  
  📧 *Email:* ${emailAddress ?? "N/A"}  
  🚘 *Vehicle:* $make $model  
  🔹 *Other information:* $carFeatures  
  ''';

    final String phone = "+254748222222"; // ✅ Update with correct WhatsApp number
    final String whatsappLink = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";

    if (!await launchUrlString(whatsappLink, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch WhatsApp';
    }
  }
  /// Fetches direct import requests for the authenticated user
  Future<List<Map<String, dynamic>>> fetchDirectImportRequests(String email) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('api_token');

    if (token == null || token.isEmpty) {
      throw Exception('User is not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/direct-imports?email=$email'), // ✅ Pass email as query parameter
      headers: {
        'Authorization': 'Bearer $token', // ✅ Include authentication token
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


  /// Log customer event to backend
  Future<bool> logCustomerEvent({
    required String eventType,
    Map<String, dynamic>? metadata,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('api_token');

    if (token == null || token.isEmpty) {
      throw Exception('User is not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/event-log'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'event_type': eventType,
        'metadata': metadata ?? {},
      }),
    );

    if (response.statusCode == 200) {
      print("✅ Event '$eventType' logged successfully");
      return true;
    } else {
      print("❌ Failed to log event: ${response.body}");
      return false;
    }
  }

  Future<bool> logFilterActivity(Map<String, String?> filters) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('api_token');

    if (token == null || token.isEmpty) {
      throw Exception('User is not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/filter-log'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'filters': filters,
      }),
    );

    if (response.statusCode == 200) {
      print("✅ Filters logged successfully");
      return true;
    } else {
      print("❌ Failed to log filters: ${response.body}");
      return false;
    }
  }





}
