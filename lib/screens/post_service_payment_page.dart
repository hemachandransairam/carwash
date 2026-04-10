import 'package:flutter/material.dart';
import '../core/services/mock_database.dart';
import '../widgets/custom_widgets.dart';
import 'feedback_page.dart';
import 'dart:async';


class PostServicePaymentPage extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String toUserId;
  final String workerName;

  const PostServicePaymentPage({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.toUserId,
    required this.workerName,
  });


  @override
  State<PostServicePaymentPage> createState() => _PostServicePaymentPageState();
}

class _PostServicePaymentPageState extends State<PostServicePaymentPage> {
  String? _selectedMethod;
  bool _isProcessing = false;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for status change to COMPLETED (e.g. if worker marks as paid)
    _statusSubscription = MockDatabase.instance.client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', widget.bookingId)
        .listen((data) {
      if (data.isNotEmpty) {
        final status = data.first['status'];
        if (status == 'COMPLETED' && !_isProcessing) {
          _closeAndShowFeedback();
        }
      }
    });
  }

  void _closeAndShowFeedback() {
    if (mounted) {
      Navigator.pop(context);
      FeedbackPage.showFeedbackDialog(
        context,
        bookingId: widget.bookingId,
        toUserId: widget.toUserId,
        workerName: widget.workerName,
      );

    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }


  Future<void> _handlePayment(String method) async {
    setState(() {
      _selectedMethod = method;
      _isProcessing = true;
    });

    // Simulate some loading/delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Update status to COMPLETED
      await MockDatabase.instance
          .from('bookings')
          .update({'status': 'COMPLETED', 'payment_method': method})
          .eq('id', widget.bookingId)
          .build();

      if (mounted) {
        _closeAndShowFeedback();
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Service Completed",
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF01102B)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              "Job Finished by ${widget.workerName}!",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF01102B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "The service for your vehicle has been completed successfully. Please select your payment method to finalize the booking.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Amount to Pay",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    "Rs. ${widget.amount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      color: Color(0xFF01102B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Choose Payment Method",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF01102B),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildOption(
              "Cash",
              Icons.payments_rounded,
              "Pay directly to a worker",
              () => _handlePayment("Cash"),
            ),
            const SizedBox(height: 16),
            _buildOption(
              "UPI / Online",
              Icons.account_balance_wallet_rounded,
              "Pay securely using UPI app",
              () => _handlePayment("UPI"),
            ),
            const Spacer(),
            if (_isProcessing)
              const Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF01102B)),
                  SizedBox(height: 16),
                  Text(
                    "Processing Payment...",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String title, IconData icon, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedMethod == title ? const Color(0xFF01102B) : Colors.grey[200]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF01102B), size: 30),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF01102B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
