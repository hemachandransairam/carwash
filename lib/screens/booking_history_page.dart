import 'package:flutter/material.dart';
import '../core/services/mock_database.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_widgets.dart';
import 'e_ticket_page.dart';
import 'booking_details_page.dart';

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
          actions: [
            IconButton(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh, color: Color(0xFF01102B)),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF01102B),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF01102B),
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: "Ongoing"),
              Tab(text: "Cancelled"),
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
                          final s = (b['status'] ?? '').toUpperCase();
                          return [
                            'PENDING',
                            'CONFIRMED',
                            'ACCEPTED',
                            'IN_PROGRESS',
                            'ARRIVED',
                            'ASSIGNED',
                          ].contains(s);
                        }).toList();

                    final cancelled =
                        bookings.where((b) {
                          final s = (b['status'] ?? '').toUpperCase();
                          return [
                            'CANCELLED',
                            'REJECTED',
                          ].contains(s);
                        }).toList();

                    final completed =
                        bookings.where((b) {
                          final s = (b['status'] ?? '').toUpperCase();
                          return s == 'COMPLETED';
                        }).toList();

                    return TabBarView(
                      children: [
                        _buildBookingList(ongoing, "No ongoing bookings"),
                        _buildBookingList(cancelled, "No cancelled bookings"),
                        _buildBookingList(completed, "No completed bookings"),
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
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        return Future.delayed(const Duration(milliseconds: 800));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(context, bookings[index], isUnpaid: isUnpaid);
        },
      ),
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

    return GestureDetector(
      onTap: () {
        if (status.toUpperCase() == 'COMPLETED') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => BookingDetailsPage(booking: booking)));
        } else if (['PENDING', 'CONFIRMED', 'ACCEPTED', 'IN_PROGRESS', 'ARRIVED', 'ASSIGNED'].contains(status.toUpperCase())) {
          _navigateToTicket(context, booking);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
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
                  color: _getStatusColor(status).withValues(alpha: 0.1),
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

          if (['PENDING', 'CONFIRMED', 'ACCEPTED', 'IN_PROGRESS', 'ARRIVED', 'ASSIGNED'].contains(status.toUpperCase())) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToTicket(context, booking),
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text("View Ticket", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF01102B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => _cancelBooking(context, booking['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    );
  }

  Future<void> _navigateToTicket(BuildContext context, Map<String, dynamic> booking) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final vehicle = await MockDatabase.instance.from('vehicles').select().eq('id', booking['vehicle_id']).maybeSingle().build<Map<String, dynamic>?>();
      final address = await MockDatabase.instance.from('addresses').select().eq('user_id', booking['user_id']).limit(1).maybeSingle().build<Map<String, dynamic>?>();
      Map<String, dynamic>? worker;
      if (booking['worker_id'] != null) {
        final workerRec = await MockDatabase.instance.from('workers').select('user_id').eq('id', booking['worker_id']).maybeSingle().build<Map<String, dynamic>?>();
        if (workerRec != null) {
          worker = await MockDatabase.instance.from('users').select().eq('id', workerRec['user_id']).maybeSingle().build<Map<String, dynamic>?>();
        }
      }

      if (context.mounted) {
        Navigator.pop(context); // Remove loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ETicketPage(
              bookingId: booking['id']?.toString(),
              qrToken: booking['qr_token']?.toString(),
              vehicle: vehicle ?? {},
              selectedServices: List<String>.from(booking['service_id'] ?? []),
              selectedDate: DateTime.parse(booking['scheduled_at']),
              selectedTime: DateFormat('hh:mm a').format(DateTime.parse(booking['scheduled_at'])),
              addressLabel: "Home",
              addressText: address != null ? [address['house_no'], address['street'], address['city']].where((e) => e != null).join(", ") : "No Address",
              totalPrice: (booking['final_amount'] ?? 0).toDouble(),
              worker: worker,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _cancelBooking(BuildContext context, dynamic bookingId) async {
    // Find the booking to check scheduled time
    final bookings = await MockDatabase.instance
        .from('bookings')
        .select()
        .eq('id', bookingId)
        .build<List<Map<String, dynamic>>>();

    if (bookings.isEmpty) return;

    final booking = bookings.first;
    final scheduledAt = DateTime.tryParse(booking['scheduled_at'] ?? '');
    final String status = (booking['status'] ?? '').toUpperCase();
    
    // Determine penalty strings and behavior
    String warningMessage = "Are you sure you want to cancel this booking? Free cancellation applies.";
    
    final bool isEnRoute = ['ASSIGNED', 'ARRIVED', 'IN_PROGRESS'].contains(status);
    
    if (isEnRoute) {
        warningMessage = "Worker is en route or has arrived. A 50% penalty applies to this cancellation. Are you sure you wish to proceed?";
    } else if (scheduledAt != null) {
      final cutoff = scheduledAt.subtract(const Duration(hours: 2));
      if (DateTime.now().isAfter(cutoff)) {
        warningMessage = "You are cancelling within 2 hours of the scheduled slot. A nominal cancellation fee of ₹100 applies. Are you sure you wish to proceed?";
      }
    }

    // Confirmation dialog
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancel Booking?"),
        content: Text(warningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Keep it", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await MockDatabase.instance
          .from('bookings')
          .update({'status': 'CANCELLED'})
          .eq('id', bookingId)
          .build();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Booking cancelled. Applicable refunds will be processed in 3–5 business days."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to cancel: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'CONFIRMED':
      case 'ACCEPTED':
      case 'IN_PROGRESS':
      case 'PAYMENT_PENDING':
      case 'WORK_COMPLETED':
      case 'ASSIGNED':
        return const Color(0xFF01102B);
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return const Color(0xFF01102B);
    }
  }
}
