import 'package:flutter/material.dart';
import '../models/schedule_model.dart'; 
import '../theme.dart';

class ScheduleTile extends StatefulWidget {
  final Schedule schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final Function(Schedule) onUpdate;

  const ScheduleTile({
    super.key,
    required this.schedule,
    required this.onToggle,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<ScheduleTile> createState() => _ScheduleTileState();
}

class _ScheduleTileState extends State<ScheduleTile> {
  bool isExpanded = false;

  // 1. Helper Function to Open Time Picker
  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final initialTimeStr = isStart ? widget.schedule.startTime : widget.schedule.endTime;
    TimeOfDay initialTime = _parseTime(initialTimeStr);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: AppTheme.darkTheme.copyWith(
          timePickerTheme: const TimePickerThemeData(
            dialHandColor: AppTheme.primaryBlue,
            dialBackgroundColor: AppTheme.cardColor,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          widget.schedule.startTime = picked.format(context);
        } else {
          widget.schedule.endTime = picked.format(context);
        }
      });
      // Notify parent immediately
      widget.onUpdate(widget.schedule); 
    }
  }

  // 2. Helper to Parse "06:30 AM" -> TimeOfDay
  TimeOfDay _parseTime(String timeStr) {
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
      debugPrint("Time Parse Error: $e");
    }
    return TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20), // Added padding here instead of ListTile
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // Highlight border if enabled, otherwise subtle
          color: widget.schedule.isEnabled ? AppTheme.primaryBlue.withOpacity(0.3) : Colors.white10,
          width: 1,
        ),
        boxShadow: [
          if (widget.schedule.isEnabled)
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Column(
        children: [
          // --- ROW 1: TIME DISPLAY (Full Width) ---
          // This gives the time text plenty of space
          Row(
            children: [
              Text(
                widget.schedule.startTime,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
              ),
              Text(
                widget.schedule.endTime,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 12), // Vertical space to separate controls from time

          // --- ROW 2: DAYS & CONTROLS (Moved down) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // "Every Day" Text
              Text(
                widget.schedule.days,
                style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 14),
              ),

              // Switch + Edit Button
              Row(
                children: [
                  Transform.scale(
                    scale: 0.8, // Slightly smaller switch fits better
                    child: Switch(
                      value: widget.schedule.isEnabled,
                      onChanged: widget.onToggle,
                      activeThumbColor: AppTheme.primaryBlue,
                      activeTrackColor: AppTheme.primaryBlue.withOpacity(0.3),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => isExpanded = !isExpanded),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        isExpanded ? Icons.expand_less : Icons.edit,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // --- EXPANDED STATE (Edit Times) ---
          if (isExpanded) ...[
            const Divider(color: Colors.white10, height: 24),
            
            // Start Time Picker Row
            _buildTimeRow("Start Time", widget.schedule.startTime, () => _pickTime(context, true)),
            
            // End Time Picker Row
            _buildTimeRow("End Time", widget.schedule.endTime, () => _pickTime(context, false)),

            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                  label: const Text("Remove", style: TextStyle(color: AppTheme.errorRed)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  onPressed: () {
                    widget.onUpdate(widget.schedule);
                    setState(() => isExpanded = false);
                  },
                  child: const Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  // 3. Helper Widget for Time Rows
  Widget _buildTimeRow(String label, String timeDisplay, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryBlue),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: Text(
                timeDisplay,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}