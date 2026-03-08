import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  // 1. UPDATED: Now accepts and saves 'phoneNumber' too
  Future<void> saveUser(String username, String phoneNumber) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('phoneNumber', phoneNumber); // Save Phone
    await prefs.setBool('isLoggedIn', true);
  }

  // 2. NEW: This function was missing! It retrieves data for your Home Screen.
  Future<Map<String, String>> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? "Sevak User";
    String phoneNumber = prefs.getString('phoneNumber') ?? "";
    
    return {
      'username': username,
      'phoneNumber': phoneNumber,
    };
  }

  Future<bool> isUserLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}