class Schedule {
  final String id;
  String startTime; // Renamed from 'time' to support range
  String endTime;   // NEW: Added for "End at" time [cite: 35]
  final String days;
  bool isEnabled;

  // Note: Supply Check, Extra Fill, and Dry Run are removed here 
  // because they are now managed in the Global Timers screen.

  Schedule({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.days,
    this.isEnabled = true,
  });

  // Helper to convert JSON from the ESP32/Database into this Model
  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] ?? '',
      startTime: json['startTime'] ?? '06:00 AM', // Default start
      endTime: json['endTime'] ?? '06:30 AM',     // Default end
      days: json['days'] ?? '',
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  // Helper to convert this Model back into JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'days': days,
      'isEnabled': isEnabled,
    };
  }
}