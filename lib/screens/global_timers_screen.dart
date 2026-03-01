import 'dart:convert'; // Required for parsing JSON
import 'dart:async';   // Required for StreamSubscription
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../theme.dart';

// IMPORTANT: Ensure this matches the file name of your service
import '../services/bluetooth_service.dart'; 

class GlobalTimersScreen extends StatefulWidget {
  const GlobalTimersScreen({super.key});

  @override
  State<GlobalTimersScreen> createState() => _GlobalTimersScreenState();
}

class _GlobalTimersScreenState extends State<GlobalTimersScreen> {
  // Stream Subscription to listen to data
  StreamSubscription? _dataSubscription;

  // --- 1. TIMER VALUES ---
  int _waterFlowCheck_mins = 5;
  int _tankFullInterval_mins = 2;
  int _dryRunCheck_mins = 10;

  // --- 2. THRESHOLD VALUES ---
  int _tankThreshold = 2000;
  int _flowThreshold = 2000;

  // 3. PIN VALUES (Mutable so they update live)
  int _tankStatePin = 0; 
  int _waterFlowStatePin = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings(); 
    _startListeningToDevice();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  // --- NEW: LOAD SAVED SETTINGS ---
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    
    setState(() {
      _waterFlowCheck_mins = prefs.getInt('water_flow_local') ?? SevakBluetoothService.instance.memWaterInterval;
      _tankFullInterval_mins = prefs.getInt('tank_full_local') ?? SevakBluetoothService.instance.memTankInterval;
      _dryRunCheck_mins = prefs.getInt('dry_run_local') ?? SevakBluetoothService.instance.memDryRunInterval;
      
      _tankThreshold = prefs.getInt('tank_thresh_local') ?? SevakBluetoothService.instance.memTankThreshold;
      _flowThreshold = prefs.getInt('flow_thresh_local') ?? SevakBluetoothService.instance.memFlowThreshold;
    });
  }

  // --- BLUETOOTH LISTENER ---
  void _startListeningToDevice() {
    _dataSubscription = SevakBluetoothService.instance.deviceDataStream.listen((data) {
      _updateUIFromData(data);
    }, onError: (error) {
      debugPrint("Error receiving data: $error");
    });
  }

  // --- DATA PARSING LOGIC ---
  void _updateUIFromData(String receivedData) {
    if (!mounted) return; 

    try {
      String cleanData = receivedData.trim();
      if (!cleanData.startsWith('{')) return;

      Map<String, dynamic> data = jsonDecode(cleanData);

      setState(() {
        _tankStatePin = data['tankStatePin'] ?? _tankStatePin;
        _waterFlowStatePin = data['waterFlowStatePin'] ?? _waterFlowStatePin;
      });
    } catch (e) {
      debugPrint("Error parsing JSON in GlobalTimers: $e");
    }
  }

  // --- SEND DATA LOGIC ---
  void _sendConfigToDevice() {
    String command = "CFG,$_waterFlowCheck_mins,$_tankFullInterval_mins,$_dryRunCheck_mins,$_tankThreshold,$_flowThreshold";
    SevakBluetoothService.instance.sendCommand(command);
    debugPrint("Sent Config: $command");
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          // ✅ CHANGED: Title is now "Water Pump Settings"
          title: const Text("Water Pump Settings"),
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white), 
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryBlue,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              // ✅ CHANGED: Icon is now a Water Drop
              Tab(icon: Icon(Icons.water_drop), text: "Timers"),
              Tab(icon: Icon(Icons.tune), text: "Thresholds"),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  // --- TAB 1: TIMERS (Minutes) ---
                  _buildScrollablePage([
                    _buildSectionHeader("Pump Safety Timers", "Set intervals in non-negative minutes."),
                    _buildTimerSlider(
                        label: "Water Flow Check",
                        value: _waterFlowCheck_mins.toDouble(),
                        unit: "mins",
                        max: 60,
                        onChanged: (val) => setState(() => _waterFlowCheck_mins = val.toInt())),
                    _buildTimerSlider(
                        label: "Tank Full Interval",
                        value: _tankFullInterval_mins.toDouble(),
                        unit: "mins",
                        max: 30,
                        onChanged: (val) => setState(() => _tankFullInterval_mins = val.toInt())),
                    _buildTimerSlider(
                        label: "Dry Run Check",
                        value: _dryRunCheck_mins.toDouble(),
                        unit: "mins",
                        max: 120,
                        onChanged: (val) => setState(() => _dryRunCheck_mins = val.toInt())),
                  ]),

                  // --- TAB 2: THRESHOLDS & PINS ---
                  _buildScrollablePage([
                    _buildSectionHeader("Sensor Sensitivity", "Adjust sensor trigger levels (0-4095)."),
                    _buildThresholdSlider(
                        label: "Tank State Threshold",
                        value: _tankThreshold.toDouble(),
                        onChanged: (val) => setState(() => _tankThreshold = val.toInt())),
                    _buildThresholdSlider(
                        label: "Flow State Threshold",
                        value: _flowThreshold.toDouble(),
                        onChanged: (val) => setState(() => _flowThreshold = val.toInt())),
                    
                    const SizedBox(height: 30),
                    _buildSectionHeader("Live Sensor Status", "Real-time sensor feedback."),
                    _buildPinStatusCard("Tank State Pin", _tankStatePin, _tankThreshold),
                    _buildPinStatusCard("Flow State Pin", _waterFlowStatePin, _flowThreshold),
                  ]),
                ],
              ),
            ),

            // GLOBAL SAVE BUTTON
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () async {
                  // --- 1. SAVE TO PHONE MEMORY ---
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('water_flow_local', _waterFlowCheck_mins);
                  await prefs.setInt('tank_full_local', _tankFullInterval_mins);
                  await prefs.setInt('dry_run_local', _dryRunCheck_mins);
                  await prefs.setInt('tank_thresh_local', _tankThreshold);
                  await prefs.setInt('flow_thresh_local', _flowThreshold);

                  // --- 2. CHECK CONNECTION & SEND ---
                  bool isConnected = SevakBluetoothService.instance.isConnected; 

                  if (isConnected) {
                    _sendConfigToDevice();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Configuration Sent & Saved!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    // --- 3. OFFLINE FEEDBACK ---
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Device Offline: Settings Saved to App Only"),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Apply All Changes", 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildScrollablePage(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(height: 25),
    ]);
  }

  Widget _buildTimerSlider({required String label, required double value, required String unit, required double max, required Function(double) onChanged}) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Text("${value.toInt()} $unit", style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
      ]),
      Slider(value: value, min: 0, max: max, activeColor: AppTheme.primaryBlue, onChanged: onChanged),
      const SizedBox(height: 15),
    ]);
  }

  Widget _buildThresholdSlider({required String label, required double value, required Function(double) onChanged}) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Text(value.toInt().toString(), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
      ]),
      Slider(value: value, min: 0, max: 4095, activeColor: Colors.amber, onChanged: onChanged),
      const SizedBox(height: 15),
    ]);
  }

  Widget _buildPinStatusCard(String label, int pinValue, int threshold) {
    bool isOn = pinValue < threshold; 
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text("Current: $pinValue", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              // ✅ FIXED: Using .withValues(alpha: ...) instead of deprecated .withOpacity(...)
              color: isOn ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(isOn ? "STATE: ON" : "STATE: OFF", 
              style: TextStyle(color: isOn ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}