import 'package:flutter/material.dart';
import '../core/services/mock_database.dart';
import '../widgets/custom_widgets.dart';
import 'e_ticket_page.dart';

class PaymentMethodsPage extends StatefulWidget {
  final List<String> selectedServices;
  final double totalPrice;
  final DateTime selectedDate;
  final String selectedTime;
  final Map<String, String> vehicle;
  final String addressLabel;
  final String addressText;

  const PaymentMethodsPage({
    super.key,
    required this.selectedServices,
    required this.totalPrice,
    required this.selectedDate,
    required this.selectedTime,
    required this.vehicle,
    required this.addressLabel,
    required this.addressText,
  });

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  String _selectedMethod = "Cash";
  bool _isSaving = false;

  void _confirmPayment() async {
    setState(() => _isSaving = true);
    final user = MockDatabase.instance.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in")));
        setState(() => _isSaving = false);
      }
      return;
    }

    try {
      // 1. Fetch all 'APPROVED' workers from the workers table
      final List<Map<String, dynamic>> approvedWorkers = await MockDatabase.instance.client
          .from('workers')
          .select('id, user_id')
          .eq('status', 'APPROVED')
          .build<List<Map<String, dynamic>>>();

      if (approvedWorkers.isEmpty) {
        throw Exception("No approved workers are currently on duty. Our team is expanding!");
      }

      // 2. Find an approved worker who is NOT busy at the selected time
      Map<String, dynamic>? assignedWorkerData;
      String? assignedWorkerId;
      final selectedIso = widget.selectedDate.toUtc().toIso8601String().split('T')[0];
      
      for (var worker in approvedWorkers) {
        final String workerTableId = worker['id']; // This is what bookings.worker_id references
        final String userId = worker['user_id'];

        // Check if this worker has any bookings on the selected day
        final busyBookings = await MockDatabase.instance.client
            .from('bookings')
            .select('id')
            .eq('worker_id', workerTableId)
            .build<List<Map<String, dynamic>>>();
        
        bool isBusy = busyBookings.any((b) {
          final bDate = b['scheduled_at']?.toString().split('T')[0];
          return bDate == selectedIso;
        });

        if (!isBusy) {
          // Worker is free! Now get their user details (name, etc.)
          final userDetails = await MockDatabase.instance.client
              .from('users')
              .select()
              .eq('id', userId)
              .maybeSingle()
              .build<Map<String, dynamic>?>();
          
          if (userDetails != null) {
            assignedWorkerData = userDetails;
            assignedWorkerId = workerTableId;
            break;
          }
        }
      }

      // Fallback: If everyone is busy, we follow the previous instruction and pick the first approved worker anyway
      if (assignedWorkerId == null && approvedWorkers.isNotEmpty) {
        final fallbackWorker = approvedWorkers.first;
        final userDetails = await MockDatabase.instance.client
            .from('users')
            .select()
            .eq('id', fallbackWorker['user_id'])
            .maybeSingle()
            .build<Map<String, dynamic>?>();
        
        if (userDetails != null) {
          assignedWorkerData = userDetails;
          assignedWorkerId = fallbackWorker['id'];
        }
      }

      if (assignedWorkerId == null || assignedWorkerData == null) {
        throw Exception("Unable to find an available approved worker right now.");
      }

      // 3. Create the booking with the designated worker_id
      // Mock mapping of service names to UUIDs for the service_id array
      final List<String> serviceUuids = widget.selectedServices.map((name) {
        return '00000000-0000-0000-0000-${name.length.toRadixString(16).padLeft(12, '0')}';
      }).toList();

      final response = await MockDatabase.instance.client.from('bookings').insert({
        'user_id': user['id'],
        'service_id': serviceUuids,
        'vehicle_id': widget.vehicle['id'],
        'worker_id': assignedWorkerId,
        'booking_type': 'SCHEDULED',
        'scheduled_at': widget.selectedDate.toUtc().toIso8601String(),
        'service_start': widget.selectedDate.toUtc().toIso8601String(), 
        'service_end': widget.selectedDate.add(const Duration(hours: 1)).toUtc().toIso8601String(), 
        'status': 'ASSIGNED',
        'base_amount': widget.totalPrice,
        'discount_amount': 0.0,
        'final_amount': widget.totalPrice + 199 + 20,
        'qr_token': 'QR-${DateTime.now().millisecondsSinceEpoch}',
        'latitude': 0.0,
        'longitude': 0.0,
      }).select().single().build<Map<String, dynamic>>();

      if (mounted) {
        setState(() => _isSaving = false);
        _showSuccessDialog(assignedWorkerData, response['id']?.toString(), response['qr_token']?.toString());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving booking: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> worker, String? bookingId, String? qrToken) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF01102B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Order Received",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF01102B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Your order for the Carwash has been received. Our worker ${worker['name']} will arrive at ${widget.selectedTime}.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                                builder:
                                    (context) => ETicketPage(
                                      bookingId: bookingId,
                                      qrToken: qrToken,
                                      vehicle: widget.vehicle,
                                      selectedServices: widget.selectedServices,
                                      selectedDate: widget.selectedDate,
                                      selectedTime: widget.selectedTime,
                                      addressLabel: widget.addressLabel,
                                      addressText: widget.addressText,
                                      totalPrice: widget.totalPrice,
                                      worker: worker,
                                    ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF01102B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Ok",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: buildGlobalAppBar(context: context, title: "Payment Methods"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Cash"),
            _buildPaymentOption(
              "Cash",
              Icons.payments_outlined,
              isSelected: _selectedMethod == "Cash",
              onTap: () => setState(() => _selectedMethod = "Cash"),
            ),
            const SizedBox(height: 16),

            _buildSectionTitle("Credit & Debit Card"),
            _buildPaymentOption(
              "Add Card",
              Icons.credit_card_outlined,
              isAction: true,
              onTap: () {
                // Add card functionality
              },
            ),
            const SizedBox(height: 16),
            _buildSectionTitle("More Payment Options"),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildPaymentOption(
                    "Paypal",
                    Icons.paypal_outlined,
                    isSelected: _selectedMethod == "Paypal",
                    noShadow: true,
                    onTap: () => setState(() => _selectedMethod = "Paypal"),
                  ),
                  const Divider(
                    indent: 70,
                    height: 1,
                    color: Color(0xFFF0F0F0),
                  ),
                  _buildPaymentOption(
                    "Apple Pay",
                    Icons.apple_outlined,
                    isSelected: _selectedMethod == "Apple",
                    noShadow: true,
                    onTap: () => setState(() => _selectedMethod = "Apple"),
                  ),
                  const Divider(
                    indent: 70,
                    height: 1,
                    color: Color(0xFFF0F0F0),
                  ),
                  _buildPaymentOption(
                    "Google Pay",
                    Icons.g_mobiledata_outlined,
                    isSelected: _selectedMethod == "Google",
                    noShadow: true,
                    onTap: () => setState(() => _selectedMethod = "Google"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            buildPrimaryButton(
              text: _isSaving ? "Processing..." : "Confirm Payment",
              onTap: _isSaving ? null : _confirmPayment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Color(0xFF01102B),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String label,
    IconData icon, {
    bool isSelected = false,
    bool isAction = false,
    bool noShadow = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: noShadow ? EdgeInsets.zero : const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              noShadow ? BorderRadius.zero : BorderRadius.circular(20),
          boxShadow:
              noShadow
                  ? null
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          border:
              !noShadow && isSelected
                  ? Border.all(color: const Color(0xFF01102B), width: 1.5)
                  : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF6F6F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF01102B), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF01102B),
                ),
              ),
            ),
            if (isAction)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected
                            ? const Color(0xFF01102B)
                            : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF01102B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                        : null,
              ),
          ],
        ),
      ),
    );
  }
}
