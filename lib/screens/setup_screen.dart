import 'package:flutter/material.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 24),
            Text(
              "Setting up Al-Husnain Motors...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colors.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
