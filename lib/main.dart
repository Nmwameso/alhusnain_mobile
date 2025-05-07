import 'package:ah_customer/screens/VehicleDetailsScreen.dart';
import 'package:ah_customer/theme/theme_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ah_customer/providers/auth_provider.dart';
import 'package:ah_customer/providers/home_provider.dart';
import 'package:ah_customer/providers/connectivity_provider.dart';
import 'package:ah_customer/screens/home_screen.dart';
import 'package:ah_customer/screens/login_screen.dart';
import 'dart:async';

// Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initializeNotification();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.instance.subscribeToTopic('general_notifications');

  runApp(const MyApp());
}

/// Background handler (must be top-level)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Background message received: ${message.messageId}");
}

/// Set up all notification handlers
Future<void> _initializeNotification() async {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📲 Foreground message: ${message.notification?.title}");
    // Optionally show a dialog or local notification
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationTap(message);
  });

  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _handleNotificationTap(initialMessage);
  }
}

/// Handle navigation on notification tap
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  final vehicleId = data['vehicle_id'];

  if (vehicleId != null) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => VehicleDetailsScreen(vehicleId: vehicleId),
      ),
    );
  } else {
    navigatorKey.currentState?.pushNamed('/home');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => HomeProvider()..fetchHomeData()),
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'AL-HUSNAIN Motors',
        theme: ThemeManager.buildIOSTheme(),
        home: const SetupScreen(),
        routes: {
          '/home': (context) => HomeScreen(),
          '/login': (context) => LoginScreen(),
        },
      ),
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _locationPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _performSetup();
  }

  Future<void> _performSetup() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _locationPermissionDenied = true;
      }

      await FirebaseMessaging.instance.getToken();

      final prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      if (_locationPermissionDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location access denied. Showing vehicles from Mombasa only.'),
            backgroundColor: Colors.orange.shade700,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }

      Navigator.pushReplacementNamed(context, isLoggedIn ? '/home' : '/login');
    } catch (e) {
      print("Setup Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setup failed. Please restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 14),
            const SizedBox(height: 24),
            const AnimatedText(),
            const SizedBox(height: 24),
            const Text(
              "Getting your experience ready, hang tight...",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedText extends StatefulWidget {
  const AnimatedText({super.key});

  @override
  _AnimatedTextState createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText> {
  int _dotCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      'Setting up${'.' * _dotCount}',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.primary,
      ),
    );
  }
}
