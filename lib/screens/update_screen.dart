import 'package:flutter/material.dart';
import '../theme.dart'; 

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  // Version strings from Sevak 2.0 specifications
  final String currentVersion = "v.24m.00.01";
  final String latestVersion = "v.24m.00.02";

  @override
  Widget build(BuildContext context) {
    // Logic: The update button is enabled only when current != latest
    bool isUpdateAvailable = currentVersion != latestVersion;

    return Scaffold(
      // Use standard black for background to avoid "undefined getter" errors
      backgroundColor: Colors.black, 
      appBar: AppBar(
        title: const Text("Updates"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(
              Icons.system_update_outlined, 
              size: 100, 
              // Fixes unused import by using AppTheme property
              color: AppTheme.primaryBlue, 
            ),
            const SizedBox(height: 50),

            // Current Version Section
            _buildVersionInfoTile(
              title: "Current Version",
              version: currentVersion,
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 20),

            // Latest Version Section
            _buildVersionInfoTile(
              title: "Latest Version",
              version: latestVersion,
              icon: Icons.new_releases_outlined,
            ),

            const Spacer(),

            // Update Button Logic
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // Button is blue if update is ready, grey if not
                  backgroundColor: isUpdateAvailable ? AppTheme.primaryBlue : Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isUpdateAvailable ? () {
                  // This triggers the OTA upload process
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Starting OTA Update...")),
                  );
                } : null, 
                child: Text(
                  isUpdateAvailable ? "UPDATE NOW" : "DEVICE UP TO DATE",
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper widget to match the "Version" sections in Figure 5
  Widget _buildVersionInfoTile({
    required String title, 
    required String version, 
    required IconData icon
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Fixes unused import by using AppTheme property
        color: AppTheme.cardColor, 
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 24),
          const SizedBox(width: 15),
          Text(
            title, 
            style: const TextStyle(color: Colors.grey, fontSize: 16)
          ),
          const Spacer(),
          Text(
            version, 
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 16, 
              fontWeight: FontWeight.bold
            )
          ),
        ],
      ),
    );
  }
}