import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String userName;
  final String phoneNumber;

  const OtpScreen({
    super.key, 
    required this.userName, 
    required this.phoneNumber
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // 4 Input Controllers
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  int _resendTimer = 30;
  late Timer _timer;
  bool _isLoading = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendTimer = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        _timer.cancel();
      }
    });
  }

  void _verifyAndLogin() async {
    // 1. Combine inputs
    String code = _controllers.map((c) => c.text).join();
    
    if (code.length < 4) {
      setState(() => _errorMessage = "Please enter the full code");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    // --- MOCK VERIFICATION ---
    // In a real app, you would verify the code with Firebase here.
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    if (code == "1234") {
      // ✅ SUCCESS: Now we save the data (This logic moved here from Login Screen)
      await _saveUserData();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Invalid OTP. Please try '1234'";
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      });
    }
  }

  Future<void> _saveUserData() async {
    try {
      String name = widget.userName;
      String phone = widget.phoneNumber;

      // 1. LOCAL SAVE (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      await prefs.setString('phoneNumber', phone);
      await prefs.setBool('isLoggedIn', true);

      // 2. CLOUD SAVE (Firebase)
      try {
        await FirebaseFirestore.instance.collection('clients').doc(phone).set({
          'name': name,
          'phone': phone,
          'last_login': FieldValue.serverTimestamp(),
          'app_version': 'Sevak 2.0',
          'platform': Theme.of(context).platform.toString(),
        }, SetOptions(merge: true));
        debugPrint("Data sent to Firebase successfully");
      } catch (e) {
        debugPrint("Firebase Error (Offline?): $e");
      }

      // 3. NAVIGATION
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userName: name, phoneNumber: phone),
          ),
          (route) => false, // Clears the back stack so user can't go back to OTP
        );
      }
    } catch (e) {
      debugPrint("Save Error: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "System Error. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text("Verification", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Text("We sent a code to ${widget.phoneNumber}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 50),

            // PIN INPUTS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60, height: 60,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLength: 1,
                    cursorColor: AppTheme.primaryBlue,
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2)),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        if (index < 3) FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                        if (index == 3) FocusScope.of(context).unfocus();
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                      }
                    },
                  ),
                );
              }),
            ),
            
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent))),
              ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyAndLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify & Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: _resendTimer == 0 ? _startResendTimer : null,
                child: Text(
                  _resendTimer > 0 ? "Resend code in ${_resendTimer}s" : "Resend Code",
                  style: TextStyle(color: _resendTimer > 0 ? Colors.grey : AppTheme.primaryBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}