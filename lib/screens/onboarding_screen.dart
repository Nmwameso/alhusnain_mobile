import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/car_chooser.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          _buildOnboardingPage(
            title: "Welcome!",
            description: "Find the perfect car tailored to your needs.",
            image: "assets/images/onboarding1.png",
          ),
          _buildOnboardingPage(
            title: "Select Your Preferences",
            description: "Choose body type, fuel, and brand.",
            image: "assets/images/onboarding2.png",
          ),
          CarChooserScreen(),
        ],
      ),
      bottomSheet: _currentIndex < 2
          ? _buildBottomNavigation()
          : const SizedBox.shrink(), // Hide buttons on last step
    );
  }

  Widget _buildOnboardingPage({required String title, required String description, required String image}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(image, height: 250),
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => _pageController.jumpToPage(2), // Skip to last
            child: const Text("SKIP", style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            child: const Text("NEXT"),
          ),
        ],
      ),
    );
  }

  void _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }
}
