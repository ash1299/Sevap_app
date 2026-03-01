import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Database
import 'package:intl_phone_field/intl_phone_field.dart';
import '../theme.dart';
import '../services/user_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  // Stores the complete number with country code
  String fullPhoneNumber = '';

  // Direct Login Function (No OTP)
  void _submitLogin() async {
    // 1. Validate Input
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text.trim();

      // Added stricter logic check for name length
      if (name.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Name must be at least 3 characters")),
        );
        return;
      }

      if (fullPhoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid phone number")),
        );
        return;
      }

      // --- 2. SHOW LOADING SPINNER ---
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Force Logout ensures every login creates a NEW User ID.
        await FirebaseAuth.instance.signOut();

        // --- 3. CREATE ACCOUNT IN FIREBASE (No OTP) ---
        UserCredential userCredential =
            await FirebaseAuth.instance.signInAnonymously();
        User? user = userCredential.user;

        if (user != null) {
          // Prepare data object first
          final Map<String, dynamic> userDataMap = {
            'uid': user.uid,
            'name': name,
            'phoneNumber': fullPhoneNumber,
            'createdAt': FieldValue.serverTimestamp(),
            'loginMethod': 'Direct (No OTP)',
          };

          // Execute Firestore save AND Local save in PARALLEL.
          await Future.wait([
            // Task 1: Save to Firestore
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set(userDataMap),
            // Task 2: Save Locally
            UserPreferences().saveUser(name, fullPhoneNumber),
          ]);

          // Ensure widget is still mounted before modifying UI after async gaps
          if (!mounted) return;
          Navigator.pop(context); // Close loading dialog

          // --- 6. GO TO HOME SCREEN ---
          Navigator.pushReplacement(
            context,
            // Passing BOTH name and phone number
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                userName: name,
                phoneNumber: fullPhoneNumber,
              ),
            ),
          );
        } else {
          // Handle rare case where user is null despite no error thrown
          throw Exception("Authentication succeeded but user is null");
        }
      } catch (e) {
        // Handle Errors
        if (!mounted) return;
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Header ---
                    // Updated Text Here
                    const Text(
                      "Welcome to Apna SEVAK", 
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Please enter your details to continue",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 40),

                    // --- Name Field ---
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Full Name", Icons.person),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => (value == null || value.isEmpty)
                          ? "Please enter your name"
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // --- Phone Field ---
                    IntlPhoneField(
                      decoration: _inputDecoration("Phone Number", Icons.phone),
                      style: const TextStyle(color: Colors.white),
                      dropdownTextStyle: const TextStyle(color: Colors.white),
                      dropdownIcon:
                          const Icon(Icons.arrow_drop_down, color: Colors.white),
                      initialCountryCode: 'IN',
                      onChanged: (phone) {
                        fullPhoneNumber = phone.completeNumber;
                      },
                    ),
                    const SizedBox(height: 40),

                    // --- Login Button ---
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _submitLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(12)),
      errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(12)),
      focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(12)),
    );
  }
}