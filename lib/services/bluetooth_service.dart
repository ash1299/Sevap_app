import 'dart:async';
import 'dart:convert';
import 'dart:io'; 
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class SevakBluetoothService {
  // --- SINGLETON ---
  static final SevakBluetoothService _instance = SevakBluetoothService._internal();
  factory SevakBluetoothService() => _instance;
  SevakBluetoothService._internal();
  static SevakBluetoothService get instance => _instance;

  // --- CONFIG (Matches Your ESP32) ---
  static const String serviceUUID = "d0820a87-4f00-49a0-b085-365f743fed05";
  static const String charUUID = "8c36ec61-213c-4aad-a311-f0c8893be298";
  static const String otaUUID = "e093f3b5-00a3-a9e5-9eca-4ca6ea921d4f";

  // --- VARIABLES ---
  BluetoothDevice? _device;
  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _otaChar;
  StreamSubscription<List<int>>? _deviceSubscription; 
  bool isConnected = false;

  // --- PERSISTENT MEMORY ---
  int memWaterInterval = 5;
  int memTankInterval = 2;
  int memDryRunInterval = 10;
  int memTankThreshold = 2000;
  int memFlowThreshold = 2000;
  bool memRelayState = false;

  // --- STREAMS ---
  final StreamController<String> _statusController = StreamController.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  final StreamController<Map<String, dynamic>> _dataStreamController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;

  final StreamController<String> _rawStringController = StreamController.broadcast();
  Stream<String> get deviceDataStream => _rawStringController.stream;

  // --- 1. CONNECT & SYNC ---
  Future<void> connectToDevice(BluetoothDevice device) async {
    _statusController.add("Connecting...");
    try {
      await FlutterBluePlus.stopScan();
      await _deviceSubscription?.cancel(); 
      await device.connect(autoConnect: false);
      
      // Request bigger packet size for Android (Faster OTA)
      if (Platform.isAndroid) {
        try { await device.requestMtu(512); } catch (_) {}
      }

      _device = device;
      isConnected = true;
      _statusController.add("Connected");
      await _discoverServices(device);

      // --- AUTOMATIC SETUP ---
      await Future.delayed(const Duration(milliseconds: 500)); 
      await syncDeviceTime(); // Send Phone Time
      await sendCommand("GET"); // Request Status Update

    } catch (e) {
      _statusController.add("Connection Failed");
      disconnect();
    }
  }

  Future<void> syncDeviceTime() async {
    final now = DateTime.now();
    // Command Format: "T,HH,MM,SS"
    String timeCommand = "T,${now.hour},${now.minute},${now.second}";
    print("Auto-Syncing Time: $timeCommand");
    await sendCommand(timeCommand);
  }

  // --- 2. COMMAND HANDLING ---
  Future<void> sendCommand(String command) async {
    if (_commandChar != null) {
      try {
        await _commandChar!.write(utf8.encode(command), withoutResponse: false);
        print("Sent Real Command: $command");
      } catch (e) { print("Error sending command: $e"); }
    } else {
      print("Error: Not Connected.");
    }
  }

  // Helper function (UI buttons might call this)
  Future<void> toggleMotor(bool turnOn) async {
    await sendCommand(turnOn ? "z" : "y");
  }

  // --- 3. CONNECTION HELPERS ---
  void startScan() {
    _statusController.add("Scanning...");
    try { FlutterBluePlus.startScan(timeout: const Duration(seconds: 15)); } catch (e) {}
  }

  void stopScan() {
    try { FlutterBluePlus.stopScan(); } catch (e) {}
  }

  // ✅ ✅ ✅ FIXED: FILTERING ADDED HERE ✅ ✅ ✅
  // This now checks every device found. If it has no name, it is REMOVED from the list.
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.onScanResults.map(
    (results) => results
        .where((r) => r.device.platformName.isNotEmpty) // ONLY allow devices with names
        .toList(),
  );

  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var s in services) {
      if (s.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
        for (var c in s.characteristics) {
          // Command Channel
          if (c.uuid.toString().toLowerCase() == charUUID.toLowerCase()) {
            _commandChar = c;
            await c.setNotifyValue(true);
            _deviceSubscription = c.onValueReceived.listen(_handleIncomingData);
          }
          // OTA Channel
          if (c.uuid.toString().toLowerCase() == otaUUID.toLowerCase()) {
            _otaChar = c;
          }
        }
      }
    }
  }

  void disconnect() {
    isConnected = false;
    _deviceSubscription?.cancel(); 
    _device?.disconnect();
    _statusController.add("Disconnected");
  }

  // --- 4. INCOMING DATA HANDLING ---
  void _handleIncomingData(List<int> bytes) async {
    if (bytes.isEmpty) return;
    try {
      String rawString = utf8.decode(bytes).trim(); 
      _rawStringController.add(rawString); 

      // --- CRITICAL FIX: DETECT SCHEDULE DATA (NON-JSON) ---
      if (rawString.startsWith("S1") || rawString.startsWith("S2") || rawString.startsWith("S3")) {
        int firstComma = rawString.indexOf(',');
        if (firstComma != -1) {
            String key = rawString.substring(0, firstComma); 
            String value = rawString.substring(firstComma + 1); 
            
            Map<String, dynamic> scheduleData = { key: value };
            _dataStreamController.add(scheduleData);
            return; 
        }
      }

      // JSON LOGIC (For Telemetry)
      String rawJson = rawString;

      // JSON Cleanup (Fixes ESP32 partial packets)
      if (rawJson.contains('}{')) rawJson = rawJson.replaceAll('}{', '},{');
      if (!rawJson.startsWith('[')) rawJson = "[$rawJson]"; 
      
      List<dynamic> list = jsonDecode(rawJson);
      if (list.isNotEmpty) {
          Map<String, dynamic> data = list.last;
          _dataStreamController.add(data);

          // Update Memory
          if (data['relayState'] != null) memRelayState = data['relayState'];

          // Save to Offline Storage
          final prefs = await SharedPreferences.getInstance();
          
          if (data['waterFlowCheckingInterval_mins'] != null) {
            var val = data['waterFlowCheckingInterval_mins'];
            memWaterInterval = (val is double) ? val.toInt() : val;
            await prefs.setInt('water_flow_local', memWaterInterval);
          }
          if (data['tankFullStateInterval_mins'] != null) {
            var val = data['tankFullStateInterval_mins'];
            memTankInterval = (val is double) ? val.toInt() : val;
            await prefs.setInt('tank_full_local', memTankInterval);
          }
          if (data['dryRunCheckInterval_mins'] != null) {
            var val = data['dryRunCheckInterval_mins'];
            memDryRunInterval = (val is double) ? val.toInt() : val;
            await prefs.setInt('dry_run_local', memDryRunInterval);
          }
          if (data['tankStateThreshold'] != null) {
            memTankThreshold = data['tankStateThreshold'];
            await prefs.setInt('tank_thresh_local', memTankThreshold);
          }
          if (data['waterFlowStateThreshold'] != null) {
            memFlowThreshold = data['waterFlowStateThreshold'];
            await prefs.setInt('flow_thresh_local', memFlowThreshold);
          }
      }
    } catch (e) {
      // Ignore parse errors
    }
  }

  // --- 5. OTA UPLOAD ---
  Future<void> uploadFirmware(File f, Function(double) p) async {
    if (_otaChar == null) throw Exception("OTA Not Supported.");
    
    // FIX: Check if the device supports fast writing. 
    bool canWriteFast = _otaChar!.properties.writeWithoutResponse;
    print("OTA Upload Mode: ${canWriteFast ? 'FAST' : 'SAFE'}");

    List<int> bytes = await f.readAsBytes();
    int chunkSize = 240; 
    int offset = 0;

    while (offset < bytes.length) {
      int end = offset + chunkSize;
      if (end > bytes.length) end = bytes.length;
      
      await _otaChar!.write(bytes.sublist(offset, end), withoutResponse: canWriteFast);
      
      offset += (end - offset);
      p(offset / bytes.length);
      
      await Future.delayed(const Duration(milliseconds: 5));
    }

    print("Sending EOF Signal...");
    await _otaChar!.write(utf8.encode("EOF"), withoutResponse: false);
    print("Firmware Upload Complete!");
  }
}