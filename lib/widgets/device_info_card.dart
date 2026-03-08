import 'package:flutter/material.dart';
import '../theme.dart';

class DeviceInfoCard extends StatelessWidget {
  final String status;      // e.g., "Disconnected" or "Scanning..."
  final bool isConnected;   // To toggle red/green indicator
  final String deviceTime;  // Real-time clock from ESP32

  const DeviceInfoCard({
    super.key, 
    required this.status, 
    required this.isConnected,
    required this.deviceTime, // Added this new parameter
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: AppTheme.cardColor, // Ensure consistency with your theme
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- TOP ROW: CONNECTION & VERSION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, 
                      size: 12, 
                      color: isConnected ? AppTheme.accentGreen : AppTheme.errorRed
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? "Connected" : "Offline",
                      style: TextStyle(
                        color: isConnected ? AppTheme.accentGreen : AppTheme.errorRed, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ],
                ),
                // UPDATED: Version matches Sevak 2.0 requirements
                const Text("v.24m.00.01", style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              ],
            ),
            const Divider(height: 30, color: Colors.white10),

            // --- BOTTOM ROW: DYNAMIC INFO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Display real device time instead of a placeholder
                _buildInfoItem("Device Time", deviceTime), 
                _buildInfoItem("Status", status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
        const SizedBox(height: 4),
        Text(
          value, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
        ),
      ],
    );
  }
}