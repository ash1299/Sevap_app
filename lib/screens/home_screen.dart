import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; 
import 'package:file_picker/file_picker.dart';

import '../theme.dart';
import '../services/bluetooth_service.dart';
import '../services/user_preferences.dart'; 
import '../widgets/device_info_card.dart';
import '../widgets/app_drawer.dart'; 
import 'login_screen.dart'; 
import 'schedules_screen.dart'; 

class HomeScreen extends StatefulWidget {
  final String userName; 
  final String phoneNumber;

  const HomeScreen({
    super.key, 
    required this.userName,
    required this.phoneNumber,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); 
  
  String connectionStatus = "Disconnected";
  bool isMotorOn = false; 
  String deviceTime = "--:--"; 
  DateTime? _lastCommandTime;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    
    SevakBluetoothService.instance.statusStream.listen((status) {
      if (mounted) setState(() => connectionStatus = status);
    });
    
    SevakBluetoothService.instance.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          bool recentlyClicked = _lastCommandTime != null && 
              DateTime.now().difference(_lastCommandTime!).inSeconds < 2;

          if (!recentlyClicked && data.containsKey('relayState')) {
            isMotorOn = data['relayState']; 
          }
          
          if (data.containsKey('deviceTime')) {
             deviceTime = data['deviceTime'].toString();
          }
          
          if (data.containsKey('deviceConnected') && data['deviceConnected'] == true) {
             connectionStatus = "Connected";
          }
        });
      }
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan, 
      Permission.bluetoothConnect, 
      Permission.location, 
      Permission.storage
    ].request();
  }

  void _logout() async {
    await UserPreferences().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, 
    );
  }

  void _showDeviceList() {
    SevakBluetoothService.instance.startScan();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              const Text("Select Sevak Device", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white10, height: 20),
              Expanded(
                child: StreamBuilder<List<ScanResult>>(
                  stream: SevakBluetoothService.instance.scanResults,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("Scanning for devices...", style: TextStyle(color: Colors.grey)));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final r = snapshot.data![index];
                        return ListTile(
                          title: Text(r.device.platformName.isNotEmpty ? r.device.platformName : "Unknown Device", style: const TextStyle(color: Colors.white)),
                          trailing: ElevatedButton(
                            onPressed: () { 
                              Navigator.pop(context); 
                              SevakBluetoothService.instance.connectToDevice(r.device); 
                            },
                            child: const Text("Connect"),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() => SevakBluetoothService.instance.stopScan());
  }

  Future<void> _pickAndUploadFirmware() async {
    if (!SevakBluetoothService.instance.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connect to device first!")));
      return;
    }
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['bin']);
    
    if (result == null) return; 
    if (!mounted) return;       

    File file = File(result.files.single.path!);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text("Updating Firmware...", style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [LinearProgressIndicator(color: AppTheme.primaryPlum), SizedBox(height: 15), Text("Uploading...", style: TextStyle(color: Colors.grey))]),
      ),
    );
    
    try {
      await SevakBluetoothService.instance.uploadFirmware(file, (progress) { debugPrint("Upload: $progress"); });
      
      if (mounted) Navigator.pop(context); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Successful!")));
    } catch (e) {
      if (mounted) Navigator.pop(context); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update Failed: $e")));
    }
  }

  void _togglePower() async {
    HapticFeedback.mediumImpact();
    if (SevakBluetoothService.instance.isConnected) {
      _lastCommandTime = DateTime.now();
      setState(() => isMotorOn = !isMotorOn);
      await SevakBluetoothService.instance.toggleMotor(isMotorOn);
    } else {
      _showDeviceList();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isConnected = SevakBluetoothService.instance.isConnected; 

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black, 
      drawer: SevakDrawer(
        userName: widget.userName,
        phoneNumber: widget.phoneNumber,
      ), 
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28), 
          onPressed: () => _scaffoldKey.currentState?.openDrawer()
        ),
        titleSpacing: 0,
        title: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 6.0, right: 2.0),
              child: Text(
                "अपना", 
                style: TextStyle(fontSize: 10, color: Colors.white, height: 1.0),
              ),
            ),
            Text(
              "SEVAK",
              style: TextStyle(
                fontFamily: 'RobotoCondensed', 
                fontWeight: FontWeight.w900, 
                fontSize: 26,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.cloud_upload, color: Colors.white), onPressed: _pickAndUploadFirmware),
          IconButton(
            icon: Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, color: Colors.white), 
            onPressed: isConnected ? SevakBluetoothService.instance.disconnect : _showDeviceList,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.errorRed), 
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DeviceInfoCard(status: connectionStatus, isConnected: isConnected, deviceTime: deviceTime),
              
              const SizedBox(height: 20),
              
              // --- SEVAK DEVICE IMAGE ---
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'Assets/sevak_img.jpeg',
                  height: 260, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 260,
                      width: double.infinity,
                      color: Colors.grey[900],
                      child: const Center(child: Text("Image not found", style: TextStyle(color: Colors.grey))),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 30), 
              
              // --- SCHEDULES BUTTON (New Premium Look) ---
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const SchedulesScreen())
                  );
                },
                child: Container(
                  width: double.infinity, 
                  height: 80, 
                  decoration: BoxDecoration(
                    color: const Color(0xFF281423), 
                    borderRadius: BorderRadius.circular(40), 
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                             SizedBox(
                               width: 40, height: 40,
                               child: Stack(
                                 children: [
                                   const Icon(Icons.calendar_month, color: Colors.white, size: 38),
                                   Positioned(
                                     bottom: 0, right: 0,
                                     child: Container(
                                       padding: const EdgeInsets.all(2),
                                       decoration: const BoxDecoration(color: Color(0xFF281423), shape: BoxShape.circle),
                                       child: const Icon(Icons.access_time_filled, color: Colors.white, size: 14),
                                     )
                                   )
                                 ],
                               ),
                             ),
                             const SizedBox(width: 15),
                             const Text(
                               "Schedules",
                               style: TextStyle(
                                 color: Colors.white,
                                 fontSize: 34, 
                                 fontWeight: FontWeight.w900,
                                 fontFamily: 'Impact', 
                                 letterSpacing: 0.5,
                               ),
                             ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 40) 
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- POWER BUTTON (Restored: "SYSTEM OFF" Text Style) ---
              GestureDetector(
                onTap: _togglePower, 
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity, 
                  height: 80, 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    // Dark plum background
                    color: const Color(0xFF281423), 
                    border: Border.all(
                      // Border Color changes: Green if ON, Red if OFF
                      color: isMotorOn 
                          ? AppTheme.accentGreen 
                          : AppTheme.errorRed, 
                      width: 2
                    ),
                    boxShadow: [
                      if (isMotorOn) 
                        BoxShadow(
                          color: AppTheme.accentGreen.withValues(alpha: 0.4), 
                          blurRadius: 30,
                          spreadRadius: 2
                        )
                    ]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.power_settings_new, 
                        size: 36, 
                        color: isMotorOn ? AppTheme.accentGreen : AppTheme.errorRed
                      ),
                      const SizedBox(width: 15),
                      Text(
                        isMotorOn ? "SYSTEM ON" : "SYSTEM OFF", 
                        style: const TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white,
                          letterSpacing: 1.0,
                        )
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}