// import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../theme.dart';

class MonitorScreen extends StatefulWidget {
  final SevakBluetoothService bleService;

  const MonitorScreen({super.key, required this.bleService});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  // We will keep a list of the last 50 messages
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Listen to the stream and add new messages to our list
    widget.bleService.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          // Add a timestamp so you can see it's new
          String timestamp = DateTime.now().toString().split(' ')[1].substring(0, 8);
          
          // Format the data to be one line
          String logMessage = "[$timestamp] Relay: ${data['relayState']} | Time: ${data['deviceTime']}";
          
          _logs.add(logMessage);
          
          // Keep list short (max 50 lines) so phone doesn't get slow
          if (_logs.length > 50) {
            _logs.removeAt(0);
          }
        });

        // Auto-scroll to the bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Live Data Log"),
        backgroundColor: AppTheme.cardColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => setState(() => _logs.clear()), // Clear logs button
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Incoming Data Stream (Every 1s):",
              style: TextStyle(color: AppTheme.primaryBlue, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // The Scrolling Box
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: _logs.isEmpty 
                  ? const Center(child: Text("Waiting for data stream...", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(
                              color: AppTheme.accentGreen, 
                              fontFamily: 'monospace', 
                              fontSize: 12
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}