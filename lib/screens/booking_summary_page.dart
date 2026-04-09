import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';
import 'payment_methods_page.dart';
import '../core/services/mock_database.dart';

class BookingSummaryPage extends StatefulWidget {
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
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;
  Map<String, dynamic>? _appliedCoupon;
  String? _couponError;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isApplyingCoupon = true;
      _couponError = null;
      _appliedCoupon = null;
    });

    try {
      final user = MockDatabase.instance.auth.currentUser;

      // 1. Fetch coupon by code
      final results = await MockDatabase.instance
          .from('coupons')
          .select()
          .eq('code', code)
          .eq('is_active', true)
          .build<List<Map<String, dynamic>>>();

      if (results.isEmpty) {
        setState(() {
          _couponError = 'Invalid or expired coupon code.';
          _isApplyingCoupon = false;
        });
        return;
      }

      final coupon = results.first;

      // 2. Check validity dates
      final now = DateTime.now();
      if (coupon['valid_from'] != null) {
        final from = DateTime.parse(coupon['valid_from']);
        if (now.isBefore(from)) {
          setState(() {
            _couponError = 'This coupon is not active yet.';
            _isApplyingCoupon = false;
          });
          return;
        }
      }
      if (coupon['valid_to'] != null) {
        final until = DateTime.parse(coupon['valid_to']);
        if (now.isAfter(until)) {
          setState(() {
            _couponError = 'This coupon has expired.';
            _isApplyingCoupon = false;
          });
          return;
        }
      }

      // 3. Check min order value
      final minOrder = (coupon['min_order_value'] as num?)?.toDouble() ?? 0.0;
      if (widget.totalPrice < minOrder) {
        setState(() {
          _couponError = 'Minimum order value of ₹${minOrder.toStringAsFixed(0)} required.';
          _isApplyingCoupon = false;
        });
        return;
      }

      // 4. Check per-user usage limit (no global usage_limit column exists)
      if (user != null) {
        final perUserLimit = (coupon['usage_limit_per_user'] as num?)?.toInt() ?? 1;
        final userUsage = await MockDatabase.instance
            .from('coupon_usage')
            .select()
            .eq('coupon_id', coupon['id'])
            .eq('user_id', user['id'])
            .build<List<Map<String, dynamic>>>();
        if (userUsage.length >= perUserLimit) {
          setState(() {
            _couponError = 'You have already used this coupon.';
            _isApplyingCoupon = false;
          });
          return;
        }
      }

      // 6. Check if user-specific coupon belongs to this user
      if (coupon['user_id'] != null && user != null) {
        if (coupon['user_id'] != user['id']) {
          setState(() {
            _couponError = 'This coupon is not valid for your account.';
            _isApplyingCoupon = false;
          });
          return;
        }
      }

      setState(() {
        _appliedCoupon = coupon;
        _isApplyingCoupon = false;
      });
    } catch (e) {
      setState(() {
        _couponError = 'Failed to apply coupon. Please try again.';
        _isApplyingCoupon = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponError = null;
      _couponController.clear();
    });
  }

  double _calculateCouponDiscount(double baseAmount) {
    if (_appliedCoupon == null) return 0;
    final type = _appliedCoupon!['discount_type']?.toString() ?? 'FLAT';
    final value = (_appliedCoupon!['discount_value'] as num?)?.toDouble() ?? 0.0;
    final maxCap = (_appliedCoupon!['max_discount'] as num?)?.toDouble();

    double discount = 0;
    if (type.toUpperCase() == 'PERCENTAGE') {
      discount = baseAmount * (value / 100);
      if (maxCap != null && discount > maxCap) discount = maxCap;
    } else {
      discount = value;
    }
    return discount > baseAmount ? baseAmount : discount;
  }

  @override
  Widget build(BuildContext context) {
    final user = MockDatabase.instance.auth.currentUser;
    final bool isApartmentPlan =
        user?['subscription_tier'] == 'APARTMENT_PLAN' ||
        user?['is_apartment_resident'] == true;

    final bool isCoveredWash = widget.selectedServices.any(
      (s) =>
          s['name'].toString().toLowerCase().contains('spray wash') ||
          s['name'].toString().toLowerCase().contains('foam wash plan') ||
          s['name'].toString().toLowerCase().contains('group plan'),
    );

    double baseTotal = widget.totalPrice;

    if (isApartmentPlan && isCoveredWash) baseTotal = 0;

    double apartmentDiscount = 0;
    if (isApartmentPlan && !isCoveredWash) {
      apartmentDiscount = baseTotal * 0.10;
      baseTotal -= apartmentDiscount;
    }

    final double couponDiscount = _calculateCouponDiscount(baseTotal);
    final double finalTotal = baseTotal - couponDiscount;

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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF01102B)),
            ),
            const SizedBox(height: 20),

            // Price breakdown card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Services", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF01102B))),
                  const SizedBox(height: 20),
                  ...widget.selectedServices.map(
                    (service) => _buildPriceItem(
                      service['name'],
                      isApartmentPlan && isCoveredWash ? "Rs. 0" : "Rs. ${service['price']}",
                    ),
                  ),

                  // Apartment discount
                  if (isApartmentPlan) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFF0F0F0))),
                    if (isCoveredWash)
                      const Text("Covered under Apartment Plan: ₹0",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.green))
                    else if (apartmentDiscount > 0)
                      _buildDiscountRow("Apartment Member Discount (10%)", apartmentDiscount),
                  ],

                  // Coupon discount
                  if (couponDiscount > 0) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFF0F0F0))),
                    _buildDiscountRow(
                      'Coupon: ${_appliedCoupon!['code']}',
                      couponDiscount,
                    ),
                  ],

                  const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFF0F0F0))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Amount (Including GST)",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey)),
                      Text("Rs. ${finalTotal.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF01102B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Address + vehicles card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF01102B))),
                      Text(widget.addressLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF01102B), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(widget.addressText,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(widget.selectedVehicles.length > 1 ? "Vehicles" : "Vehicle",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF01102B))),
                  const SizedBox(height: 12),
                  ...widget.selectedVehicles.map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car, color: Color(0xFF01102B), size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v['car_model'] != null && v['car_model']!.isNotEmpty
                                    ? v['car_model']!
                                    : "${v['brand_name']} Vehicle",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF01102B)),
                              ),
                              Text(
                                [
                                  v['brand_name'],
                                  v['vehicle_type'],
                                  if (v['license'] != null && v['license']!.isNotEmpty)
                                    "•••• ${v['license']!.substring(v['license']!.length > 4 ? v['license']!.length - 4 : 0)}",
                                ].where((e) => e != null && e.isNotEmpty).join(" • "),
                                style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
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

            // Coupon field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_appliedCoupon != null)
                    // Applied state
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _appliedCoupon!['code'],
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF01102B), fontSize: 14),
                                ),
                                Text(
                                  'You save ₹${couponDiscount.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _removeCoupon,
                            child: const Text("Remove", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
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
                            onPressed: _isApplyingCoupon ? null : _applyCoupon,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF01102B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isApplyingCoupon
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Apply", style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  if (_couponError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 8),
                      child: Text(_couponError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 100),
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
                builder: (context) => PaymentMethodsPage(
                  selectedServices: widget.selectedServices.map((s) => s['name'] as String).toList(),
                  selectedServiceIds: widget.selectedServices.map((s) => s['id'] as String).toList(),
                  selectedVehicleIds: widget.selectedVehicles.map((v) => v['id'] as String).toList(),
                  totalPrice: finalTotal,
                  selectedDate: widget.selectedDate,
                  selectedTime: widget.selectedTime,
                  vehicle: widget.vehicle,
                  addressLabel: widget.addressLabel,
                  addressText: widget.addressText,
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                  couponId: _appliedCoupon?['id']?.toString(),
                  couponCode: _appliedCoupon?['code']?.toString(),
                  couponDiscount: couponDiscount,
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
            child: Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF01102B))),
        ],
      ),
    );
  }

  Widget _buildDiscountRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.green),
              overflow: TextOverflow.ellipsis),
        ),
        Text("- Rs. ${amount.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.green)),
      ],
    );
  }
}
