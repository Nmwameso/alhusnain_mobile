import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class NotificationSetUp {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initializeNotification() async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Handle navigation on notification tap
      });
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final Map<String, dynamic>? data = message.data;

    if (notification != null) {
      String title = notification.title ?? "🚗 Vehicle Update!";
      String make = data?['make_name'] ?? "Unknown Make";
      String model = data?['model_name'] ?? "Unknown Model";
      String engineCC = data?['engine_cc'] ?? "N/A";
      String year = data?['yr_of_mfg'] ?? "N/A";
      String fuel = data?['fuel'] ?? "N/A";
      String mileage = data?['mileage'] ?? "N/A";
      String transmission = data?['transm'] ?? "N/A";
      String color = data?['colour'] ?? "N/A";
      String imageUrl = data?['main_photo'] ?? "";

      // Detailed notification body
      String body =
          "🚘 $make $model is now available!\n"
          "🛠 Engine: ${engineCC}cc | 📅 Year: $year\n"
          "⛽ Fuel: $fuel | 🔄 Transmission: $transmission\n"
          "📏 Mileage: $mileage km | 🎨 Color: $color";

      BigPictureStyleInformation? bigPictureStyle;

      if (imageUrl.isNotEmpty) {
        try {
          final bigPicturePath = await _downloadAndSaveFile(imageUrl, 'vehicle_image.jpg');
          bigPictureStyle = BigPictureStyleInformation(
            FilePathAndroidBitmap(bigPicturePath),
            contentTitle: title,
            summaryText: body,
          );
        } catch (e) {
          print("Error loading image: $e");
        }
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: bigPictureStyle ?? DefaultStyleInformation(true, true),
      );

      final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        0, // Notification ID
        title,
        body,
        platformDetails,
      );
    }
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final response = await http.get(Uri.parse(url));
    final directory = Directory.systemTemp;
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }
}
