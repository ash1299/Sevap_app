import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../theme.dart';
import '../services/user_preferences.dart'; 
import '../screens/update_screen.dart';
import '../screens/login_screen.dart';
import '../screens/feedback_screen.dart'; 
import '../screens/global_timers_screen.dart';

class SevakDrawer extends StatelessWidget {
  final String userName;
  final String phoneNumber;

  const SevakDrawer({
    super.key, 
    required this.userName,
    required this.phoneNumber,
  });

  // --- Helper to Open Social Links ---
  Future<void> _launchSocial(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint("Could not launch $urlString");
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  // --- Centralized Logout Logic ---
  void _performLogout(BuildContext context) async {
    await UserPreferences().logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // LOGOUT CONFIRMATION DIALOG
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to logout?", 
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              _performLogout(context); 
            }, 
            child: const Text("YES, LOGOUT", 
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black, 
      child: Column(
        children: [
          // 1. EXPANDED LIST (Takes up available space)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero, 
              children: [
                // HEADER
                DrawerHeader(
                  decoration: const BoxDecoration(color: AppTheme.cardColor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.transparent, 
                        radius: 35, 
                        child: ClipOval( 
                          child: Image.asset(
                            'Assets/SEVAK_logo.jpg', 
                            width: 70, 
                            height: 70,
                            fit: BoxFit.cover, 
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, color: Colors.white, size: 40);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(userName, 
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(phoneNumber, 
                          style: const TextStyle(color: Colors.grey, fontSize: 14)), 
                    ],
                  ),
                ),

                // MENU ITEMS
                _buildDrawerTile(context, Icons.system_update_outlined, "Updates", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UpdateScreen()));
                }),

                _buildDrawerTile(context, Icons.feedback_outlined, "Feedback", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen()));
                }),

                // ✅ UPDATED: Now "Water Pump Settings" with a Water Drop icon
                _buildDrawerTile(context, Icons.water_drop, "Water Pump Settings", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalTimersScreen()));
                }),
                
                const Divider(color: Colors.white10),
                
                _buildDrawerTile(
                  context, 
                  Icons.logout, 
                  "Logout", 
                  () => _showLogoutConfirmation(context), 
                  textColor: Colors.redAccent
                ),
              ],
            ),
          ),

          // 2. SOCIAL MEDIA FOOTER (Fixed at Bottom)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.black,
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              children: [
                const Text("Follow Us", style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                  children: [
                    // INSTAGRAM
                    _buildSocialIcon(
                      Icons.camera_alt, 
                      "https://www.instagram.com/apna_sevak/" 
                    ), 
                    
                    // FACEBOOK
                    _buildSocialIcon(
                      Icons.facebook, 
                      "https://www.facebook.com/profile.php?id=61573077471603" 
                    ),
                    
                    // WEBSITE
                    _buildSocialIcon(
                      Icons.language, 
                      "https://share.google/e74nUYrhPPEKZLxvX" 
                    ),
                  ],
                ),
                const SizedBox(height: 10), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper for Menu Tiles ---
  Widget _buildDrawerTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color textColor = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
      onTap: onTap,
    );
  }

  // --- Helper for Social Icons ---
  Widget _buildSocialIcon(IconData icon, String url) {
    return IconButton(
      icon: Icon(icon, color: AppTheme.primaryBlue, size: 28),
      onPressed: () => _launchSocial(url),
      tooltip: "Open Link",
    );
  }
}