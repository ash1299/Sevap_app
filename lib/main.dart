import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';
import 'screens/splash_screen.dart'; // 1. Import the Splash Screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // We don't check login here anymore.
  // The Splash Screen handles that now.
  runApp(const SevakApp());
}

class SevakApp extends StatelessWidget {
  const SevakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Apna Sevak', 
      theme: AppTheme.darkTheme, 
      
      // 2. Start with the Splash Screen
      // It will automatically decide whether to go to Home or Login
      home: const SplashScreen(), 
    );
  }
}