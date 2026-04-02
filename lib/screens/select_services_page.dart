import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';
import 'booking_summary_page.dart';

class SelectServicesPage extends StatefulWidget {
  final DateTime selectedDate;
  final String selectedTime;
  final String address;
  final String addressLabel;
  final Map<String, String> vehicle;

  const SelectServicesPage({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.address,
    required this.addressLabel,
    required this.vehicle,
  });

  @override
  State<SelectServicesPage> createState() => _SelectServicesPageState();
}

class _SelectServicesPageState extends State<SelectServicesPage> {
  final Set<String> _selectedServices = {};

  final List<Map<String, dynamic>> _availableServices = [
    {"name": "Exterior Cleaning", "icon": Icons.local_car_wash, "price": 299},
    {"name": "Vacuum Cleaning", "icon": Icons.cleaning_services, "price": 199},
    {
      "name": "Interior Cleaning",
      "icon": Icons.airline_seat_recline_extra,
      "price": 399,
    },
    {"name": "Engine Bay Cleaning", "icon": Icons.engineering, "price": 150},
    {"name": "Car Polish Cleaning", "icon": Icons.auto_fix_high, "price": 499},
    {"name": "Tire Cleaning", "icon": Icons.tire_repair, "price": 99},
  ];

  double get _totalPrice {
    double total = 0;
    for (var s in _availableServices) {
      if (_selectedServices.contains(s['name'])) {
        total += s['price'];
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: buildGlobalAppBar(context: context, title: "Select Services"),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Choose Services",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF01102B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select the services you want for your vehicle",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._availableServices.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: buildServiceTile(
                        title: s['name'],
                        icon: s['icon'],
                        price: s['price'].toDouble(),
                        isSelected: _selectedServices.contains(s['name']),
                        onTap:
                            () => setState(() {
                              _selectedServices.contains(s['name'])
                                  ? _selectedServices.remove(s['name'])
                                  : _selectedServices.add(s['name']);
                            }),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Bottom price bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Price",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      "Rs. ${_totalPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF01102B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                buildPrimaryButton(
                  text: "Continue to Summary",
                  onTap:
                      _selectedServices.isEmpty
                          ? null
                          : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BookingSummaryPage(
                                      selectedServices:
                                          _availableServices
                                              .where(
                                                (s) => _selectedServices
                                                    .contains(s['name']),
                                              )
                                              .toList(),
                                      totalPrice: _totalPrice,
                                      selectedDate: widget.selectedDate,
                                      selectedTime: widget.selectedTime,
                                      vehicle: widget.vehicle,
                                      addressLabel: widget.addressLabel,
                                      addressText: widget.address,
                                    ),
                              ),
                            );
                          },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
