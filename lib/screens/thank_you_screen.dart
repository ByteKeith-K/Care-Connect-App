import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Exit the app after 3 seconds
    Future.delayed(const Duration(seconds: 2), () {
      SystemNavigator.pop();
    });
    return const Scaffold(
      backgroundColor: Color(0xFF42A5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.health_and_safety, color: Colors.white, size: 80),
            SizedBox(height: 32),
            Text(
              'Thank you for using our health app!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Text(
              'Stay healthy and safe.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
