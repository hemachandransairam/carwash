import 'package:flutter/material.dart';
import '../core/services/mock_database.dart';
import '../widgets/custom_widgets.dart';

class FeedbackPage extends StatefulWidget {
  final String bookingId;
  final String toUserId; // The worker/employee being rated
  final String? workerName;

  const FeedbackPage({
    super.key,
    required this.bookingId,
    required this.toUserId,
    this.workerName,
  });

  /// Static method to show the feedback dialog anywhere in the app
  static void showFeedbackDialog(
    BuildContext context, {
    required String bookingId,
    required String toUserId,
    String? workerName,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Feedback",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return FeedbackPage(
          bookingId: bookingId,
          toUserId: toUserId,
          workerName: workerName,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: anim1, curve: Curves.easeIn),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a rating"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = MockDatabase.instance.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Using the user's provided SQL schema: public.feedbacks
      await MockDatabase.instance.client.from('feedbacks').insert({
        'booking_id': widget.bookingId,
        'from_user_id': user['id'],
        'to_user_id': widget.toUserId,
        'rating': _rating,
        'comment': _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
        'role': 'EMPLOYEE', // Default as per SQL schema
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).build();

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessAnimation();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting rating: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessAnimation() {
    Navigator.of(context).pop(); // Close feedback dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              const Text(
                "Thank You!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF01102B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your feedback helps us provide better service.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 32),
              buildPrimaryButton(
                text: "Done",
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48), // Spacer
                      const Text(
                        "Feedback",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF01102B),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF01102B).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF01102B),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Rate Your Experience",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF01102B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.workerName != null
                        ? "How was the service provided by ${widget.workerName}?"
                        : "How was your experience with our service?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starRating = index + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = starRating),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 1.0,
                            end: _rating >= starRating ? 1.2 : 1.0,
                          ),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Icon(
                                _rating >= starRating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: _rating >= starRating
                                    ? const Color(0xFFFFD700)
                                    : Colors.grey[300],
                                size: 48,
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _feedbackController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Write your review here...",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF01102B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Submit Feedback",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
