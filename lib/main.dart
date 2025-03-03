import 'package:ah_customer/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
        title: 'AL-HUSNAIN Motors',
        theme: ThemeManager.buildIOSTheme(),
        home: SplashScreen(),
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

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    Navigator.pushReplacementNamed(
        context,
        isLoggedIn ? '/home' : '/login'
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 24),
            Text(
              'AL-HUSNAIN MOTORS LTD',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                letterSpacing: 0.5,
                color: colors.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Welcome to Premier Destination For Quality Vehicles in Kenya',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            const CupertinoActivityIndicator(radius: 14),
          ],
        ),
      ),
    );
  }
}