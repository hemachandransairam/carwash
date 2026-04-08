import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';
import 'payment_methods_page.dart';
import '../core/services/mock_database.dart';

class BookingSummaryPage extends StatelessWidget {
  final List<Map<String, dynamic>> selectedServices;
  final List<Map<String, dynamic>> selectedVehicles;
  final double totalPrice;
  final DateTime selectedDate;
  final String selectedTime;
  final Map<String, dynamic> vehicle;
  final String addressLabel;
  final String addressText;
  final double latitude;
  final double longitude;

  const BookingSummaryPage({
    super.key,
    required this.selectedServices,
    required this.selectedVehicles,
    required this.totalPrice,
    required this.selectedDate,
    required this.selectedTime,
    required this.vehicle,
    required this.addressLabel,
    required this.addressText,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Fetch user to check for Apartment Plan constraints
    final user = MockDatabase.instance.auth.currentUser;
    final bool isApartmentPlan =
        user?['subscription_tier'] == 'APARTMENT_PLAN' ||
        user?['is_apartment_resident'] == true;

    // We assume if it's explicitly a plan wash, it zeroes out
    final bool isCoveredWash = selectedServices.any(
      (s) =>
          s['name'].toString().toLowerCase().contains('spray wash') ||
          s['name'].toString().toLowerCase().contains('foam wash plan') ||
          s['name'].toString().toLowerCase().contains('group plan'),
    );

    double baseTotal = totalPrice;
    double fee = 0;
    double tax = 0;

    if (isApartmentPlan && isCoveredWash) {
      baseTotal = 0;
      fee = 0;
      tax = 0;
    }

    double finalTotal = baseTotal + fee + tax;
    double apartmentDiscount = 0;

    if (isApartmentPlan && !isCoveredWash) {
      apartmentDiscount = finalTotal * 0.10; // 10% off for non-plan washes
      finalTotal -= apartmentDiscount;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: buildGlobalAppBar(context: context, title: "Booking Summary"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Review Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF01102B),
              ),
            ),
            const SizedBox(height: 20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Services",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF01102B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...selectedServices.map(
                    (service) => _buildPriceItem(
                      service['name'],
                      isApartmentPlan && isCoveredWash
                          ? "Rs. 0"
                          : "Rs. ${service['price']}",
                    ),
                  ),

                  if (isApartmentPlan) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFF0F0F0), thickness: 1),
                    ),
                    if (isCoveredWash)
                      const Text(
                        "Covered under Apartment Plan: ₹0",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                        ),
                      )
                    else if (apartmentDiscount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Apartment Benefit",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            "- Rs. ${apartmentDiscount.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: Color(0xFFF0F0F0), thickness: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Amount (Including GST)",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "Rs. ${finalTotal.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF01102B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Address",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF01102B),
                        ),
                      ),
                      Text(
                        addressLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF01102B),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          addressText,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    selectedVehicles.length > 1 ? "Vehicles" : "Vehicle",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF01102B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...selectedVehicles.map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: Color(0xFF01102B),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v['car_model'] != null &&
                                        v['car_model']!.isNotEmpty
                                    ? v['car_model']!
                                    : "${v['brand_name']} Vehicle",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF01102B),
                                ),
                              ),
                              Text(
                                [
                                      v['brand_name'],
                                      v['vehicle_type'],
                                      if (v['license'] != null &&
                                          v['license']!.isNotEmpty)
                                        "•••• ${v['license']!.substring(v['license']!.length > 4 ? v['license']!.length - 4 : 0)}",
                                    ]
                                    .where((e) => e != null && e.isNotEmpty)
                                    .join(" • "),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Promo Code",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF01102B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Apply",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Spacing for button
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: buildPrimaryButton(
          text: "Continue",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => PaymentMethodsPage(
                      selectedServices:
                          selectedServices
                              .map((s) => s['name'] as String)
                              .toList(),
                      selectedServiceIds:
                          selectedServices
                              .map((s) => s['id'] as String)
                              .toList(),
                      selectedVehicleIds:
                          selectedVehicles
                              .map((v) => v['id'] as String)
                              .toList(),
                      totalPrice: finalTotal,
                      selectedDate: selectedDate,
                      selectedTime: selectedTime,
                      vehicle: vehicle,
                      addressLabel: addressLabel,
                      addressText: addressText,
                      latitude: latitude,
                      longitude: longitude,
                    ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPriceItem(String title, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF01102B),
            ),
          ),
        ],
      ),
    );
  }
}
