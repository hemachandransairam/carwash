import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/services/mock_database.dart';

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const OrderDetailsPage({super.key, required this.booking});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _vehicleDetails = [];
  Map<String, dynamic>? _customerData;
  Map<String, dynamic>? _workerData;
  List<String> _beforePhotos = [];
  List<String> _afterPhotos = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      // 1. Fetch Customer Info
      final customer = await MockDatabase.instance
          .from('users')
          .select('name, phone')
          .eq('id', widget.booking['user_id'])
          .maybeSingle()
          .build<Map<String, dynamic>?>();

      // 2. Fetch Worker Info
      Map<String, dynamic>? worker;
      if (widget.booking['worker_id'] != null) {
        final wRec = await MockDatabase.instance.from('workers').select('user_id').eq('id', widget.booking['worker_id']).maybeSingle().build<Map<String, dynamic>?>();
        if (wRec != null) {
          worker = await MockDatabase.instance.from('users').select().eq('id', wRec['user_id']).maybeSingle().build<Map<String, dynamic>?>();
        }
      }

      // 3. Fetch Photos from Booking ID folders
      final String bookingId = widget.booking['id'].toString();
      List<String> beforeUrls = [];
      List<String> afterUrls = [];

      try {
        final beforeFiles = await MockDatabase.instance.client.storage.from('booking-images').list(path: 'before/$bookingId');
        beforeUrls = beforeFiles.map((f) => MockDatabase.instance.client.storage.from('booking-images').getPublicUrl('before/$bookingId/${f.name}')).toList();

        final afterFiles = await MockDatabase.instance.client.storage.from('booking-images').list(path: 'after/$bookingId');
        afterUrls = afterFiles.map((f) => MockDatabase.instance.client.storage.from('booking-images').getPublicUrl('after/$bookingId/${f.name}')).toList();
      } catch (e) {
        // Silently fail if storage listing errors
      }

      // 4. Fetch all vehicles for this booking
      final vehicles = await MockDatabase.instance
          .from('booking_vehicles')
          .select()
          .eq('booking_id', widget.booking['id'])
          .build<List<Map<String, dynamic>>>();

      List<Map<String, dynamic>> details = [];

      for (var bv in vehicles) {
        // Fetch Vehicle Info
        final vInfo = await MockDatabase.instance
            .from('vehicles')
            .select('brand_name, car_model, license_plate')
            .eq('id', bv['vehicle_id'])
            .maybeSingle()
            .build<Map<String, dynamic>?>();

        // Fetch Services
        final services = await MockDatabase.instance
            .from('booking_vehicle_services')
            .select('service_id')
            .eq('booking_vehicle_id', bv['id'])
            .build<List<Map<String, dynamic>>>();

        List<String> serviceNames = [];
        for (var sRef in services) {
          final sInfo = await MockDatabase.instance
              .from('services')
              .select('name')
              .eq('id', sRef['service_id'])
              .maybeSingle()
              .build<Map<String, dynamic>?>();
          if (sInfo != null) serviceNames.add(sInfo['name']);
        }

        details.add({
          'bv_id': bv['id'],
          'car_name': vInfo != null ? "${vInfo['brand_name']} ${vInfo['car_model']}" : "Unknown Car",
          'license': vInfo?['license_plate'] ?? "N/A",
          'services': serviceNames,
        });
      }

      if (mounted) {
        setState(() {
          _customerData = customer;
          _workerData = worker;
          _beforePhotos = beforeUrls;
          _afterPhotos = afterUrls;
          _vehicleDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.booking['status'] as String? ?? '').toUpperCase();
    final date = DateTime.parse(widget.booking['scheduled_at']).toLocal();
    final formattedDate = DateFormat('d/M/yyyy').format(date);
    final formattedTime = DateFormat('HH:mm').format(date);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF01102B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Order Details",
          style: TextStyle(
            color: Color(0xFF01102B),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Summary Card
                  _buildHeaderCard(status, formattedDate, formattedTime),
                  const SizedBox(height: 24),

                  // Customer & Worker Section
                  Row(
                    children: [
                      Expanded(child: _buildIdentityCard("Customer", _customerData?['name'] ?? "User", _customerData?['phone'] ?? "No Phone", Icons.person)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildIdentityCard("Technician", _workerData?['name'] ?? "Not Assigned", _workerData?['phone'] ?? "No Contact", Icons.engineering)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Vehicles Section Label
                  const Text(
                    "Service Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF01102B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Info
                  ..._vehicleDetails.map((v) => _buildVehicleCard(v)),

                  const SizedBox(height: 32),
                  // Shared Work Photos
                  const Text(
                    "Work Photos",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF01102B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPhotoSection("Before Photos", _beforePhotos),
                  const SizedBox(height: 24),
                  _buildPhotoSection("After Photos", _afterPhotos),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(String status, String date, String time) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF01102B),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Booking ID",
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.booking['id'].toString().substring(0, 8).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderInfo(Icons.calendar_month_outlined, "Date", date),
              _buildHeaderInfo(Icons.access_time, "Time", time),
              _buildHeaderInfo(Icons.directions_car_outlined, "Type", "Sedan"), // Dynamic type can be added later
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.6), size: 24),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildIdentityCard(String label, String name, String sub, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF8F9FA), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF01102B), size: 18),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF01102B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_rounded, color: Color(0xFF01102B), size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v['car_name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF01102B))),
                  Text(v['license'], style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (v['services'] as List<String>).map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(8)),
              child: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF677294))),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String title, List<String> photos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF01102B))),
        const SizedBox(height: 16),
        if (photos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text("No photos available", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    photos[index],
                    width: 160,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 160,
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
