import 'package:flutter/material.dart';
import '../core/services/mock_database.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_widgets.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final user = MockDatabase.instance.auth.currentUser;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: buildGlobalAppBar(
          context: context,
          title: "Booking History",
          showBackButton: Navigator.canPop(context),
          bottom: const TabBar(
            labelColor: Color(0xFF01102B),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF01102B),
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: "Ongoing"),
              Tab(text: "Unpaid"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body:
            user == null
                ? const Center(child: Text("Please login to view history"))
                : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: MockDatabase.instance
                      .from('bookings')
                      .stream(primaryKey: ['id'])
                      .eq('user_id', user['id'])
                      .order('created_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    final bookings = snapshot.data ?? [];

                    final ongoing =
                        bookings.where((b) {
                          final s = (b['status'] ?? '').toLowerCase();
                          return [
                            'pending',
                            'confirmed',
                            'accepted',
                            'in_progress',
                            'arrived',
                          ].contains(s);
                        }).toList();

                    final unpaid =
                        bookings.where((b) {
                          final s = (b['status'] ?? '').toLowerCase();
                          return [
                            'payment_pending',
                            'work_completed',
                          ].contains(s);
                        }).toList();

                    final completed =
                        bookings.where((b) {
                          final s = (b['status'] ?? '').toLowerCase();
                          return [
                            'completed',
                            'cancelled',
                            'rejected',
                          ].contains(s);
                        }).toList();

                    return TabBarView(
                      children: [
                        _buildBookingList(ongoing, "No ongoing orders"),
                        _buildBookingList(
                          unpaid,
                          "No unpaid orders",
                          isUnpaid: true,
                        ),
                        _buildBookingList(completed, "No past orders"),
                      ],
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildBookingList(
    List<Map<String, dynamic>> bookings,
    String emptyMessage, {
    bool isUnpaid = false,
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(context, bookings[index], isUnpaid: isUnpaid);
      },
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    Map<String, dynamic> booking, {
    bool isUnpaid = false,
  }) {
    final date = DateTime.parse(booking['created_at']);
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    final status = booking['status'] ?? 'Pending';
    final price = booking['total_price'] ?? 0;

    // Check payment method. If not present, default to Cash.
    final paymentMethod = booking['payment_method'] ?? 'Cash';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                "Rs. $price",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF01102B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            booking['vehicle_name'] ?? "Car Wash Service",
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF01102B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formattedDate,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(height: 32, color: Color(0xFFF0F0F0)),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking['address_text'] ??
                      booking['address'] ??
                      "No address provided",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF01102B),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (isUnpaid) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    () => _showPaymentDialog(context, booking, paymentMethod),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF01102B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.payment, size: 20),
                label: const Text(
                  "Pay Now",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else if (status.toLowerCase().contains('pending')) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _cancelBooking(context, booking['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF01102B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Cancel Booking",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    Map<String, dynamic> booking,
    String method,
  ) {
    // If UPI/Online -> Show QR.
    // If Cash -> Show Amount + Pay button.
    // Assuming method detection logic.
    final bool isOnline = method.toLowerCase() != 'cash';
    final double amount = (booking['total_price'] ?? 0).toDouble();

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOnline ? "Scan to Pay" : "Pay via Cash",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF01102B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isOnline)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.network(
                        "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=upi://pay?pa=merchant@upi&pn=WinkWash&am=$amount&tn=Order${booking['id']}",
                        errorBuilder:
                            (_, __, ___) =>
                                const Icon(Icons.qr_code_2, size: 64),
                        loadingBuilder:
                            (_, child, progress) =>
                                progress == null
                                    ? child
                                    : const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        const Icon(Icons.money, size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        Text(
                          "Rs. $amount",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF01102B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Please hand over cash to the agent"),
                      ],
                    ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Mark as Paid/Completed
                        Navigator.pop(context);
                        await _completePayment(context, booking['id']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Confirm Payment",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _completePayment(BuildContext context, dynamic bookingId) async {
    try {
      await MockDatabase.instance
          .from('bookings')
          .update({'status': 'completed'}) // Mark as fully completed
          .eq('id', bookingId)
          .build<void>();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment Successful! Order Completed."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelBooking(BuildContext context, dynamic bookingId) async {
    try {
      await MockDatabase.instance
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId)
          .build();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Booking cancelled."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // handle error
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'confirmed':
      case 'accepted':
      case 'in_progress':
      case 'payment_pending':
      case 'work_completed':
        return const Color(0xFF01102B);
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return const Color(0xFF01102B);
    }
  }
}
