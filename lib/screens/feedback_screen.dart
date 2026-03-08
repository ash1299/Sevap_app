import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // REQUIRED: Database
import '../theme.dart';
import '../services/user_preferences.dart'; // REQUIRED: User Info

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  int _rating = 0; // Tracks stars (1-5)
  bool _isSubmitting = false; // Tracks loading state

  // Function to send data to Firebase
  Future<void> _submitFeedback() async {
    // 1. Validation: Must select stars
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a star rating first!")),
      );
      return;
    }

    String message = _feedbackController.text.trim();
    
    // 2. Validation: Message optional? Let's make it required for better feedback.
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please tell us how we can improve.")),
      );
      return;
    }

    setState(() => _isSubmitting = true); // Start Loading

    try {
      // 3. Get User Details (Name & Phone)
      Map<String, String> userData = await UserPreferences().getUser();
      String name = userData['username'] ?? "Anonymous";
      String phone = userData['phoneNumber'] ?? "Unknown";

      // 4. Upload to Firebase Firestore
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'userName': name,
        'userPhone': phone,
        'rating': _rating,  // Saving the Star Count
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 5. Success UI
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Thank you for your $_rating-star review!"),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      
      Navigator.pop(context); // Go back to Dashboard

    } catch (e) {
      // Error UI
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send: $e"),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false); // Stop Loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Feedback & Support"), 
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Rate your experience", 
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 15),
              
              // --- STAR RATING SYSTEM ---
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1),
                    iconSize: 36,
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: index < _rating ? Colors.amber : Colors.grey,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              
              const Text(
                "How can we improve SEVAK?", 
                style: TextStyle(color: Colors.white, fontSize: 16)
              ),
              const SizedBox(height: 15),
              
              // --- FEEDBACK INPUT ---
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Tell us what you think...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E), // Using Card Color manually if AppTheme missing
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // --- SUBMIT BUTTON ---
              SizedBox(
                height: 55,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit Review", 
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}