import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for saving data
import '../theme.dart';
import '../models/schedule_model.dart';
import '../services/bluetooth_service.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  // 1. Initialize with placeholder data (will be overwritten by Load or Sync)
  List<Schedule> mySchedules = [
    Schedule(id: '1', startTime: '--:--', endTime: '--:--', days: 'Schedule 1', isEnabled: false),
    Schedule(id: '2', startTime: '--:--', endTime: '--:--', days: 'Schedule 2', isEnabled: false),
    Schedule(id: '3', startTime: '--:--', endTime: '--:--', days: 'Schedule 3', isEnabled: false),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedSchedules(); // 1. Load saved data from phone memory first
    
    // 2. Wait 500ms then ASK DEVICE for real data
    Future.delayed(const Duration(milliseconds: 500), _requestDeviceData);

    // 3. Listen for connection changes (Auto-Sync on Reconnect)
    SevakBluetoothService.instance.statusStream.listen((status) {
      if (status == "Connected") {
        _requestDeviceData();
      }
    });

    // 4. Listen for incoming data from the IoT Device (Auto-Sync)
    SevakBluetoothService.instance.dataStream.listen((data) {
      if (!mounted) return;
      
      // Expected Device format: S1 -> "6,30,7,30,1"
      _checkForScheduleUpdate(data, 0, 'S1');
      _checkForScheduleUpdate(data, 1, 'S2');
      _checkForScheduleUpdate(data, 2, 'S3');
    });
  }

  // --- NEW: Ask Device for Data ---
  void _requestDeviceData() {
    if (SevakBluetoothService.instance.isConnected) {
      // Sends a "GET" command. 
      // NOTE: Your Arduino/ESP32 code must be programmed to reply 
      // with S1, S2, S3 data when it receives "GET".
      SevakBluetoothService.instance.sendCommand("GET"); 
      debugPrint("Sent GET command to device");
    }
  }

  void _checkForScheduleUpdate(Map<String, dynamic> data, int index, String key) {
    if (data.containsKey(key)) {
      String rawVal = data[key].toString(); 
      List<String> parts = rawVal.split(',');
      
      if (parts.length >= 5) {
        setState(() {
          int startH = int.parse(parts[0]);
          int startM = int.parse(parts[1]);
          int endH = int.parse(parts[2]);
          int endM = int.parse(parts[3]);
          bool enabled = parts[4] == '1';

          // Force App to match Device
          mySchedules[index].startTime = _formatTime(startH, startM);
          mySchedules[index].endTime = _formatTime(endH, endM);
          mySchedules[index].isEnabled = enabled;
        });
        // Save the new real data to memory
        _saveScheduleLocal(index);
      }
    }
  }

  // --- HELPER: Save to Phone Memory ---
  Future<void> _saveScheduleLocal(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('schedule_${index}_start', mySchedules[index].startTime);
    await prefs.setString('schedule_${index}_end', mySchedules[index].endTime);
    await prefs.setBool('schedule_${index}_enabled', mySchedules[index].isEnabled);
  }

  // --- HELPER: Load from Phone Memory ---
  Future<void> _loadSavedSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < 3; i++) {
        String? savedStart = prefs.getString('schedule_${i}_start');
        String? savedEnd = prefs.getString('schedule_${i}_end');
        bool? savedEnabled = prefs.getBool('schedule_${i}_enabled');

        if (savedStart != null) mySchedules[i].startTime = savedStart;
        if (savedEnd != null) mySchedules[i].endTime = savedEnd;
        if (savedEnabled != null) mySchedules[i].isEnabled = savedEnabled;
      }
    });
  }

  String _formatTime(int h, int m) {
    TimeOfDay t = TimeOfDay(hour: h, minute: m);
    String period = t.period == DayPeriod.am ? "AM" : "PM";
    int hour = t.hourOfPeriod;
    if (hour == 0) hour = 12;
    String minute = m.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  // Send Data TO Device
  void _syncScheduleToDevice(int index, Schedule schedule) {
    if (!SevakBluetoothService.instance.isConnected) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not connected to device")),
      );
      return;
    }
    
    TimeOfDay start = _parseTime(schedule.startTime);
    TimeOfDay end = _parseTime(schedule.endTime);
    
    // Command: S[ID],[StartHour],[StartMin],[EndHour],[EndMin],[Enabled 1/0]
    String command = "S${index + 1},${start.hour},${start.minute},${end.hour},${end.minute},${schedule.isEnabled ? 1 : 0}";
    SevakBluetoothService.instance.sendCommand(command);
    
    // Save to local memory immediately
    _saveScheduleLocal(index);
  }

  TimeOfDay _parseTime(String timeStr) {
    if (timeStr == '--:--') return TimeOfDay.now();
    try {
      final format = RegExp(r'(\d+):(\d+)\s(AM|PM)');
      final match = format.firstMatch(timeStr);
      if (match != null) {
        int h = int.parse(match.group(1)!);
        int m = int.parse(match.group(2)!);
        String ampm = match.group(3)!;
        if (ampm == "PM" && h != 12) h += 12;
        if (ampm == "AM" && h == 12) h = 0;
        return TimeOfDay(hour: h, minute: m);
      }
    } catch (e) {
      debugPrint("Parsing error: $e");
    }
    return TimeOfDay.now();
  }

  // Edit Time Logic
  Future<void> _editSchedule(int index) async {
    TimeOfDay currentStart = _parseTime(mySchedules[index].startTime);
    
    final TimeOfDay? newStart = await showTimePicker(
      context: context,
      initialTime: currentStart,
      helpText: "START TIME (Schedule ${index + 1})",
      builder: (context, child) => Theme(
        data: AppTheme.darkTheme, 
        // THIS FORCES THE CLOCK TO BE 12-HOUR WITH AM/PM!
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        ),
      ),
    );
    if (newStart == null) return;

    if (!mounted) return;

    final TimeOfDay? newEnd = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (newStart.hour + 1) % 24, minute: newStart.minute),
      helpText: "END TIME (Schedule ${index + 1})",
      builder: (context, child) => Theme(
        data: AppTheme.darkTheme, 
        // THIS FORCES THE CLOCK TO BE 12-HOUR WITH AM/PM!
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        ),
      ),
    );

    if (newEnd != null) {
      setState(() {
        // THIS FORCES THE TEXT ON SCREEN TO ALWAYS INCLUDE AM/PM!
        mySchedules[index].startTime = _formatTime(newStart.hour, newStart.minute);
        mySchedules[index].endTime = _formatTime(newEnd.hour, newEnd.minute);
        mySchedules[index].isEnabled = true; 
      });
      _syncScheduleToDevice(index, mySchedules[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure Black Background
      appBar: AppBar(
        title: const Text("Scheduled Runs", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // REFRESH BUTTON (To manually pull data from device)
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Sync from Device",
            onPressed: () {
              _requestDeviceData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Requesting data from device..."), duration: Duration(seconds: 1)),
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3, // EXACTLY 3 ITEMS
        itemBuilder: (context, index) {
          return _buildScheduleCard(index, mySchedules[index]);
        },
      ),
    );
  }

  // --- CUSTOM CARD WITH SLIDER ---
  Widget _buildScheduleCard(int index, Schedule schedule) {
    bool isSet = schedule.startTime != '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1A2C), // Dark Purple Card Color
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Schedule ${index + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Transform.scale(
                scale: 1.2, 
                child: Switch(
                  value: schedule.isEnabled,
                  activeThumbColor: Colors.greenAccent, 
                  inactiveThumbColor: Colors.grey,
                  // Replaced withOpacity with withValues
                  inactiveTrackColor: Colors.grey.withValues(alpha: 0.5),
                  onChanged: (val) {
                    setState(() => schedule.isEnabled = val);
                    _syncScheduleToDevice(index, schedule);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSet ? "${schedule.startTime} - ${schedule.endTime}" : "Not Set",
                style: TextStyle(
                  color: isSet ? Colors.white70 : Colors.grey,
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _editSchedule(index),
              ),
            ],
          ),
        ],
      ),
    );
  }
}