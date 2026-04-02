import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_widgets.dart';
import 'home_screen.dart';

class ETicketPage extends StatelessWidget {
  final Map<String, String> vehicle;
  final List<String> selectedServices;
  final DateTime selectedDate;
  final String selectedTime;
  final String addressLabel;
  final String addressText;
  final double totalPrice;

  const ETicketPage({
    super.key,
    required this.vehicle,
    required this.selectedServices,
    required this.selectedDate,
    required this.selectedTime,
    required this.addressLabel,
    required this.addressText,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFBDBDBD,
      ), // Dimmable background like the image
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // Main Ticket Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            // Celebratory Icon
                            const Text("🎉", style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            const Text(
                              "Thank You!",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF01102B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Your order has been placed\nsuccessfully",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Dashed Divider Alternative
                            Row(
                              children: List.generate(
                                30,
                                (index) => Expanded(
                                  child: Container(
                                    height: 1,
                                    color:
                                        index % 2 == 0
                                            ? Colors.grey[200]
                                            : Colors.transparent,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Ticket Content
                            _buildInfoGrid(),

                            const SizedBox(height: 20),

                            // Handled By Section
                            const Text(
                              "YOUR ORDER WILL BE HANDLED BY",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildWorkerCard(),

                            const SizedBox(height: 20),

                            // Footer Dashed line
                            Row(
                              children: List.generate(
                                30,
                                (index) => Expanded(
                                  child: Container(
                                    height: 1,
                                    color:
                                        index % 2 == 0
                                            ? Colors.grey[200]
                                            : Colors.transparent,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // QR Section
                            _buildQRSection(),
                          ],
                        ),
                      ),
                    ),

                    // Side Cutouts (Circles)
                    Positioned(
                      left: -15,
                      top: 180, // Approximate position
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBDBDBD),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -15,
                      top: 180,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBDBDBD),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              buildPrimaryButton(
                text: "Continue",
                onTap: () {
                  // Navigate to Home screen and clear the stack
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              "CAR DETAILS",
              vehicle['model'] != null && vehicle['model']!.isNotEmpty
                  ? vehicle['model']!
                  : vehicle['name'] ?? 'Car',
              flex: 3,
            ),
            _buildInfoItem(
              "CAR TYPE",
              vehicle['type'] ?? 'Sedan',
              flex: 1,
              align: CrossAxisAlignment.end,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              "SERVICES",
              selectedServices.join('\n'), // Dynamic Services
              flex: 3,
            ),
            _buildInfoItem(
              "LOCATION",
              addressText.length > 15
                  ? "${addressText.substring(0, 15)}..."
                  : addressText,
              flex: 1,
              align: CrossAxisAlignment.end,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              "DATE & TIME",
              "${DateFormat('d MMM yyyy').format(selectedDate)} - $selectedTime",
              flex: 3,
            ),
            _buildInfoItem(
              "AMOUNT",
              "Rs. ${totalPrice.toStringAsFixed(0)}",
              flex: 1,
              align: CrossAxisAlignment.end,
              subtitle: "(incl tax)",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    int flex = 1,
    CrossAxisAlignment align = CrossAxisAlignment.start,
    String? subtitle,
  }) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF01102B),
              height: 1.4,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 20,
            child: Icon(Icons.person, color: Colors.grey[400]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Tom Holland",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                Text(
                  "WinkWash Team",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection() {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                "https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=WinkWashOrder${(totalPrice * 3).toInt()}", // Dynamic QR data based on price as unique seed for now
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Icon(Icons.error, color: Colors.red),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Download QR",
              style: TextStyle(
                color: Color(0xFF3498DB),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        const Expanded(
          child: Text(
            "Show this QR to our Team member!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF01102B),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
