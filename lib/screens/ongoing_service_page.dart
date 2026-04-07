import 'package:flutter/material.dart';
import '../core/services/mock_database.dart';

import 'dart:async';

class OngoingServicePage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const OngoingServicePage({super.key, required this.booking});

  @override
  State<OngoingServicePage> createState() => _OngoingServicePageState();
}

class _OngoingServicePageState extends State<OngoingServicePage> {
  bool _hasShownCompletion = false;
  late final StreamSubscription<List<Map<String, dynamic>>> _bookingSub;

  @override
  void initState() {
    super.initState();
    _bookingSub = MockDatabase.instance.client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', widget.booking['id'])
        .listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        final b = data.first;
        final st = (b['status'] as String? ?? '').toUpperCase();
        if (st == 'COMPLETED' && !_hasShownCompletion) {
          _hasShownCompletion = true;
          _showCompletionDialog();
        }
      }
    });
  }

  @override
  void dispose() {
    _bookingSub.cancel();
    super.dispose();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Work Completed!"),
        content: const Text("Work has completed. Shall we proceed with the payment or do you want to add any services?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text("Add Services", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Proceeding to payment...")),
              );
              Navigator.pop(context); // Go back
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF01102B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Proceed to Payment"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF01102B)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Work in Progress",
          style: TextStyle(
            color: Color(0xFF01102B),
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estimated Time Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF01102B), Color(0xFF032252)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF01102B).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.timer,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Estimated Time Remaining",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "~45 mins",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.directions_car, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "Service in action",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Checklist Section
            const Text(
              "Service Checklist",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF01102B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Watch real-time as your car gets pampered",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: MockDatabase.instance.client
                  .from('booking_checklists')
                  .stream(primaryKey: ['id'])
                  .eq('booking_id', widget.booking['id'])
                  .order('id'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final checklist = snapshot.data ?? [];
                
                if (checklist.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.list_alt, color: Colors.grey[400], size: 48),
                        const SizedBox(height: 12),
                        Text(
                          "No checklist items populated yet.",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: checklist.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = checklist[index];
                    final isDone = item['is_completed'] == true;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDone ? Colors.green[50] : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isDone ? Colors.green : Colors.grey[400],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              item['item_name'] ?? 'Task',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDone ? Colors.grey[800] : const Color(0xFF01102B),
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
