import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ah_customer/providers/auth_provider.dart';
import 'package:ah_customer/providers/home_provider.dart';
import 'package:ah_customer/providers/connectivity_provider.dart';
import 'package:ah_customer/screens/home_screen.dart';
import 'package:ah_customer/screens/login_screen.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ✅ Initialize Firebase before runApp()

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => HomeProvider()..fetchHomeData()),
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()), // ✅ Added ConnectivityProvider
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AL-HUSNAIN Motors',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreen(), // ✅ Now checks user login before navigating
        routes: {
          '/home': (context) => HomeScreen(),
          '/login': (context) => LoginScreen(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// ✅ Checks if the user is logged in and navigates accordingly
  Future<void> _checkLoginStatus() async {
    await Future.delayed(Duration(seconds: 2)); // Simulating splash delay

    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home'); // ✅ Navigate to HomeScreen
    } else {
      Navigator.pushReplacementNamed(context, '/login'); // ✅ Navigate to LoginScreen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20),
            Text(
              'AL-HUSNAIN MOTORS LTD',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Welcome to Premier Destination For Quality Vehicles in Kenya',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(), // ✅ Loading indicator before navigating
          ],
        ),
      ),
    );
  }
}
