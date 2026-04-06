import 'package:flutter/material.dart';
import '../core/services/mock_database.dart';
import '../widgets/custom_widgets.dart';

class FeedbackPage extends StatefulWidget {
  /// Pass a specific bookingId to rate a completed booking.
  /// If null, the page shows a list of completed bookings to choose from.
  final String? bookingId;
  final String? workerName;

  const FeedbackPage({super.key, this.bookingId, this.workerName});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _completedBookings = [];
  String? _selectedBookingId;
  bool _isLoadingBookings = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _selectedBookingId = widget.bookingId;
    } else {
      _loadCompletedBookings();
    }
  }

  Future<void> _loadCompletedBookings() async {
    setState(() => _isLoadingBookings = true);
    final user = MockDatabase.instance.auth.currentUser;
    if (user == null) return;
    try {
      final data = await MockDatabase.instance
          .from('bookings')
          .select()
          .eq('user_id', user['id'])
          .eq('status', 'COMPLETED')
          .build<List<Map<String, dynamic>>>();
      setState(() {
        _completedBookings = data;
        _isLoadingBookings = false;
      });
    } catch (_) {
      setState(() => _isLoadingBookings = false);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: buildGlobalAppBar(context: context, title: "Rate Your Service"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "How was your experience?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF01102B),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.workerName != null)
                Text(
                  "Rate your professional: ${widget.workerName}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              const SizedBox(height: 8),
              Text(
                "Your rating is private and only visible to our team.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),

              // Booking selector
              if (widget.bookingId == null) ...[
                if (_isLoadingBookings)
                  const CircularProgressIndicator()
                else if (_completedBookings.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "No completed bookings to rate yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("Select a completed booking"),
                        value: _selectedBookingId,
                        items: _completedBookings.map((b) {
                          final id = b['id']?.toString() ?? '';
                          final date = b['scheduled_at'] != null
                              ? DateTime.tryParse(b['scheduled_at'])
                              : null;
                          final label = date != null
                              ? 'Booking ${id.substring(0, 6).toUpperCase()} — ${date.day}/${date.month}/${date.year}'
                              : 'Booking ${id.substring(0, 6).toUpperCase()}';
                          return DropdownMenuItem(value: id, child: Text(label));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedBookingId = v),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // Star rating
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () => setState(() => _rating = index + 1),
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: index < _rating
                            ? const Color(0xFFFFD700)
                            : Colors.grey.shade300,
                        size: 45,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Comment box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: "Tell us about your experience (optional)...",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF01102B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF01102B),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Submit Rating",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

    if (_selectedBookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a booking to rate"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = MockDatabase.instance.auth.currentUser;
      await MockDatabase.instance.from('feedback').insert({
        'user_id': user?['id'],
        'booking_id': _selectedBookingId,
        'rating': _rating,
        'comment': _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
        'rated_by': 'CUSTOMER',
        'created_at': DateTime.now().toIso8601String(),
      }).build<void>();

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF01102B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF01102B),
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Thank You!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF01102B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your rating helps us improve our service.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF01102B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Done",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
