import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/user_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  _navigateToNextScreen() async {
    // 1. Wait for 3 seconds (The "Splash" effect)
    await Future.delayed(const Duration(seconds: 3));

    // 2. Check if user is already logged in (Smart Login)
    final userData = await UserPreferences().getUser();

    if (!mounted) return;

    if (userData['username'] != null && userData['phoneNumber'] != null) {
      // User is already logged in -> Go to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            userName: userData['username']!, 
            phoneNumber: userData['phoneNumber']!
          )
        ),
      );
    } else {
      // User is NOT logged in -> Go to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background, // Black Background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- YOUR LOGO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // FIXED: Replaced deprecated withOpacity() with withValues()
                color: AppTheme.cardColor.withValues(alpha: 0.3), 
              ),
              child: ClipOval(
                child: Image.asset(
                  'Assets/SEVAK_logo.jpg', // Ensure this matches your folder name exactly
                  width: 150, // Big Logo
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // --- APP NAME ---
            const Text(
              "Apna Sevak",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 50),

            // --- LOADING SPINNER ---
            const CircularProgressIndicator(
              color: AppTheme.primaryPlum,
            ),
          ],
        ),
      ),
    );
  }
}